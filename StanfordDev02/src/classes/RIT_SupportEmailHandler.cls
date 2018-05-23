global class RIT_SupportEmailHandler implements Messaging.InboundEmailHandler {
	public static final String endNewMessageIndicator = '====== Please type any reply above this line ======';    
	public static String supportTeamAddress = 'mmaslow00+supteam@gmail.com';
	private Case theCase;
	private Messaging.InboundEmail emailReceived;
	private String fullMessage;
	private String newMessage;
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
    	emailReceived = email;
    	fullMessage = Email_Helper.makeDescription(emailReceived);
    	Integer endPos = fullMessage.indexOf(endNewMessageIndicator);
    	if(endPos <= 0) {
    		newMessage = fullMessage;
    	}
    	else {
    		newMessage = fullMessage.substring(0, endPos - 1);
    	}
		theCase = Email_Helper.getExistingCase(emailReceived);
		if(theCase == null) {
			theCase = createNewCase();
			theCase = [select Id, CaseNumber, Description, Contact.FirstName, Contact.LastName from Case where Id=:theCase.Id];
			Email_Helper.copyEmailtoCase(emailReceived, theCase.Id, '0');
			Messaging.SingleEmailMessage notificationEmail = RIT_SupportResponseEmails.newCase(fullMessage, emailReceived, theCase);
			CaseComment comment = new CaseComment(CommentBody=fullMessage, ParentId=theCase.Id);
			insert comment;
			addAttachments(notificationEmail);
			
			//Don't know why this is necessary, but description on saved case is null without it.
			//I suspect an insert trigger is messing with the description, but updates don't
			Case refreshedCase = new Case(Id=theCase.Id, Description=theCase.Description);
			update refreshedCase;
			
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { notificationEmail });
		}
		else {
			Map<String, String> tagMap = Email_Helper.getTags(newMessage);
			if(tagMap.keySet().contains('open')) {
				if(theCase.Status == 'Open') {
					caseAlreadyOpened();
				}
				else {
					openCase();	
				}
			}
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
		return newCase;
    }
    private void openCase() {
    	List<User> usrList = [
    		select Id, Name, Email
    		from User
    		where Email = :emailReceived.fromAddress
    	];
    	if(usrList.size() == 1) {
    		theCase.Status = 'Open';
    		theCase.OwnerId = usrList.get(0).Id;
    		update theCase;
    		if( ! String.isBlank(newMessage)) {
				CaseComment comment = new CaseComment(CommentBody=newMessage, ParentId=theCase.Id);
				insert comment;
				Email_Helper.copyEmailtoCase(emailReceived, theCase.Id, '1');
				Messaging.SingleEmailMessage notificationEmail = RIT_SupportResponseEmails.caseOpened(newMessage, emailReceived, theCase);
				addAttachments(notificationEmail);
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { notificationEmail });
    		}
    	}
    }
    private void caseAlreadyOpened() {
		Messaging.SingleEmailMessage notificationEmail = RIT_SupportResponseEmails.caseAlreadyOpened(newMessage, emailReceived, theCase);
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { notificationEmail });
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