/*
	RIT_SupportEmailHandler
	
	Author: Mark Maslow - June 2018

	Handle support emails	
*/
global class RIT_SupportEmailHandler implements Messaging.InboundEmailHandler {
	//Static variables used by helper class as well as this class.
	public static final String endNewMessageIndicator = '====== Please type any reply above this line ======';    
	public static List<String> supportTeamMembers = new List<String>();
	public static String emailHandlerAddress;

	//Instance variables to be populated and used in various methods, to avoid having to pass them betwen methods
	private Case theCase;
	private Messaging.InboundEmail emailReceived;
	private String fullMessage;
	private String newMessage;
	private User invokingUser;
	private Boolean inputError=false;

	//Static initializer
	//Get name of support queue and address of handler from custom setting.
	//Then populate supportTeamMembers from queue.
	//These static variables may be used by Email_Helper to send to team members or reply-to
	static {
		RIT_Support_Information__c supportInfo = RIT_Support_Information__c.getInstance(UserInfo.getProfileId());
		emailHandlerAddress = supportInfo.RIT_Email_Handler_Address__c;		
		Set<Id> userIds = Utilities.getUsersInQueue(supportInfo.Support_Team_Queue__c);
		List<User> usrList = [select Email from User where Id in :userIds];
		for(User usr : usrList) {
			supportTeamMembers.add(usr.Email);
		}
	}
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
    	//Put email received into instance variable.
    	emailReceived = email;

    	//Put entire contents of email into instance variable.
    	//Email_Helper will return message in plain text format.
    	fullMessage = Email_Helper.makeDescription(emailReceived);

		//Instance variable newMessage should contain only the latest message.
		//Previous messages should be after the indicator.
		//Strip off indicator and anything following it.
    	Integer endPos = fullMessage.indexOf(endNewMessageIndicator);
    	if(endPos <= 0) {
    		newMessage = fullMessage;
    	}
    	else {
    		newMessage = fullMessage.substring(0, endPos - 1);
    	}
    	
		Messaging.SingleEmailMessage notificationEmail;
    	Boolean caseIsNew = false;
		theCase = Email_Helper.getExistingCase(emailReceived);
		Map<String, String> tagMap = Email_Helper.getTags(newMessage);

		if(theCase == null) {
			theCase = createNewCase();
			caseIsNew = true;
			notificationEmail = RIT_SupportResponseEmails.newCase(fullMessage, emailReceived, theCase);
		}
		else {
			if(tagMap.size() > 0) {
				invokingUser = Utilities.getUserByEmail(emailReceived.fromAddress);
				if(invokingUser == null) {
					notificationEmail = RIT_SupportResponseEmails.bounce(newMessage, emailReceived);
				}
				else {
					if(tagMap.keySet().contains('open')) {
						notificationEmail = openCase();	
					}
					else if(tagMap.keySet().contains('close')) {
						notificationEmail = closeCase();
					}
					else if(tagMap.keySet().contains('assign')) {
						notificationEmail = assignCase(tagMap.get('assign'));
					}
					else if(tagMap.keySet().contains('labor')) {
						notificationEmail = addHours(tagMap.get('labor'));
					}
				}
			}
		}
		
		Boolean publishComment = ! (tagMap.keySet().contains('hidden') || tagMap.keySet().contains('hide') || tagMap.keySet().contains('private'));
		
		if( ! inputError ) {
			String newCaseComment = Email_Helper.removeTags(newMessage);
			if( ! String.isBlank(newCaseComment)) {
				CaseComment comment = new CaseComment(CommentBody=newCaseComment, ParentId=theCase.Id, IsPublished=publishComment);
				insert comment;
			}
		}
		
		Email_Helper.copyEmailtoCase(emailReceived, theCase.Id, caseIsNew ? '0' : '1');
		if(notificationEmail != null) {
			addAttachments(notificationEmail);
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { notificationEmail });
		}
		
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        if(Test.isRunningTest()) {
        	result.message = theCase.Id;
        }

		result.success=true;
   	    return result;		
    }
    
    private Case createNewCase() {
		Case newCase = New Case(
			Priority = null,
			Subject = Email_Helper.cleanUpSubject(emailReceived.subject),
			Server_Message__c = emailReceived.htmlBody
		);
		newCase.suppliedEmail = emailReceived.fromAddress;
		newCase.suppliedName = emailReceived.fromName;
  		newCase.Notify_Contact_On_Creation__c = False;							//FALSE TO prevent looping with out-of-office replies.
		newCase.Type = 'Other';													
		newCase.description = fullMessage;
		
		//If there is an existing contact, lets associate it.  This is automatically done by the Web-to-Case and Email-To-Case 
		//functionality, but in this custom email handler, we need to do it.

        Email_Helper.ContactsWithEmail contacts = new Email_Helper.ContactsWithEmail(newCase.suppliedEmail);
        if(contacts.primaryList.size() == 1) {
            newCase.ContactId = contacts.primaryList.get(0).Id;
        }
        else if(contacts.primaryList.size() > 1) {
			//we match with more than one contact - this is a potential problem.
            newCase.autoCaseComment__c = '==> Unable to create a new contact using the supplied name: ' + newCase.SuppliedName;
        }
        else if(contacts.alternateList.size() == 1) {
            newCase.ContactId = contacts.alternateList.get(0).Id;
        }
       
		//Set DML Options (this ensures that the auto-assignment rules and autoresponse rules get fired)
		newCase.setOptions(Email_Helper.getDMLOptions());

		insert newCase;

		//Retrieve newly inserted case to get CaseNumber and Contact information
		newCase = [select Id, CaseNumber, Description, OwnerId, Contact.FirstName, Contact.LastName, Contact.Account.Name from Case where Id=:newCase.Id];

		System.debug('newCase.description: ' + newCase.description);

		return newCase;
    }
    private Messaging.SingleEmailMessage openCase() {
    	Messaging.SingleEmailMessage notificationEmail;
		if(theCase.Status == 'Open') {
   			inputError = true;
			notificationEmail = RIT_SupportResponseEmails.caseAlreadyOpened(newMessage, emailReceived, theCase);
		}
		else {
			theCase.Status = 'Open';
			theCase.OwnerId = invokingUser.Id;
			update theCase;
			notificationEmail = RIT_SupportResponseEmails.caseOpened(newMessage, emailReceived, theCase);
		}
    	return notificationEmail;
    }
    private Messaging.SingleEmailMessage closeCase() {
		Messaging.SingleEmailMessage notificationEmail;
   		User usr = Utilities.getUserByEmail(emailReceived.fromAddress);
   		if(theCase.Status == 'Closed') {
   			inputError = true;
			notificationEmail = RIT_SupportResponseEmails.caseAlreadyClosed(newMessage, emailReceived, theCase);
   		}
   		else {
   			theCase.Status = 'Closed';
   			update theCase;
			notificationEmail = RIT_SupportResponseEmails.caseClosed(newMessage, emailReceived, theCase);
   		}
		return notificationEmail;
    }
    private Messaging.SingleEmailMessage assignCase(String assignee) {
    	Id ownerId;
		Messaging.SingleEmailMessage notificationEmail;
   		if(invokingUser.Id != theCase.OwnerId) {
   			//Sender is not case owner
   			inputError = true;
			notificationEmail = RIT_SupportResponseEmails.bounce(newMessage, emailReceived);
   		}
   		
   		if(notificationEmail == null) {
	    	User usr = Utilities.getUserByAlias(assignee);
	    	if(usr != null) {
	    		ownerId = usr.Id;
	    	}
	    	else {
	    		Id queueId = Utilities.getQueueIdByName(assignee);
	    		if(queueId != null) {
	    			ownerId = queueId;
	    		}
	    	}
   		}
	    
	    if(ownerId == null) {
	    	inputError = true;
			notificationEmail = RIT_SupportResponseEmails.bounce(newMessage, emailReceived);
	    }
	    else {
	    	theCase.OwnerId = ownerId;
	    	update theCase;
	    	notificationEmail = RIT_SupportResponseEmails.caseAssigned(newMessage, emailReceived, theCase);
   		}

		return notificationEmail;
    }
    private Messaging.SingleEmailMessage addHours(String hoursString) {
 		Messaging.SingleEmailMessage notificationEmail;
   		Double newHours=0;
   		if(Utilities.isNumeric(hoursString)) {
   			newHours = Decimal.valueOf(hoursString);
   			Double existingHours = theCase.Total_Labor__c;
   			if(existingHours == null) {
   				existingHours = 0;
   			}
   			theCase.Total_Labor__c = existingHours + newHours;
   			update theCase;
   		}
		else {
			//Error - hours is not numeric
			inputError = true;
			notificationEmail = RIT_SupportResponseEmails.bounce(newMessage, emailReceived);
		}
		return notificationEmail;  		
    }
    
    private void addAttachments(Messaging.SingleEmailMessage message) {
		if(message.getFileAttachments() != null) {
			List<Attachment>attachList = new List<Attachment>();
			for(Messaging.EmailFileAttachment msgAttach : message.getFileAttachments()) {
				Attachment attach = new Attachment(
					ParentId = theCase.Id,
					Body = msgAttach.Body,
					Name = msgAttach.FileName,
					ContentType = msgAttach.ContentType
				);
				attachList.add(attach);
			}
			if( ! attachList.isEmpty()) {
				insert attachList;
			}
		}
    }
}