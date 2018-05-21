global class RIT_SupportEmailHandler implements Messaging.InboundEmailHandler {
	public static final String endNewMessageIndicator = '====== Please type any reply above this line ======';    
	public static final String supportTeamAddress = 'mmaslow00+supteam@gmail.com';
	private String fullMessage;
	private String newMessage;
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
    	fullMessage = Email_Helper.makeDescription(email);
    	Integer endPos = fullMessage.indexOf(endNewMessageIndicator);
    	if(endPos < 0) {
    		newMessage = fullMessage;
    	}
    	else {
    		newMessage = fullMessage.substring(0, endPos - 1);
    	}
		Case theCase = Email_Helper.getExistingCase(email);
		if(theCase == null) {
			theCase = createNewCase(email);
			theCase = [select Contact.FirstName, Contact.LastName, CaseNumber from Case where Id = :theCase.Id];
			Messaging.SingleEmailMessage notificationEmail = RIT_SupportResponseEmails.newCase(fullMessage, email, theCase);
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { notificationEmail });
			
		}
		else {
			Map<String, String> tagMap = Email_Helper.getTags(newMessage);
			if(tagMap.keySet().contains('open')) {
				openCase();	
			}
		}
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        if(Test.isRunningTest()) {
        	result.message = theCase.Id;
        }
		result.success=true;
   	    return result;		
		
    }
    
    private Case createNewCase(Messaging.InboundEmail email) {
		Case newCase = New Case(
			Priority = null,
			Subject = Email_Helper.cleanUpSubject(email.subject),
			Server_Message__c = email.htmlBody
		);
		newCase.suppliedEmail = email.fromAddress;
		newCase.suppliedName = email.fromName;
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
    	
    }
}