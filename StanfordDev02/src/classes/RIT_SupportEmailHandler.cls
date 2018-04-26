global class RIT_SupportEmailHandler implements Messaging.InboundEmailHandler {    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
		String caseStatus;
		Case theCase = Email_Helper.getExistingCase(email);
		if(theCase == null) {
			theCase = createNewCase(email);
			caseStatus = '1';
		}
		else {
			caseStatus = '0';
			//IF CASE IS CLOSED, WE SHOULD RE-OPEN IT!
			String statusDescription = theCase.Status;
			if (theCase.Status != 'Open') {
				theCase.Status = 'Open';
				statusDescription = '**REOPENED IN RESPONSE TO EMAIL**';
				update theCase;
			}

			//add a comment to the case, which should notify the owner.
			//As an optional method, we could save the contents of this email to a case field and use a workflow to
			//send the email - this would allow us to customize the template.
			CaseComment cc = new CaseComment(
				ParentId = theCase.Id,
				CommentBody = 'Case Status:   ' + statusDescription + '\n' +
							  'Email From:    ' + email.fromName + ' (' + email.fromAddress + ')\n' +
							  'Email Subject: ' + email.subject + '\n' +
							  'Email Content:\n' +  Email_Helper.makeDescription(email) + '\n' +
							  '\nPlease review this case and related emails from the link below:');
			cc.setOptions(Email_Helper.getDMLOptions());
			insert cc;
		}
		Email_Helper.copyEmailtoCase(email, theCase.Id, caseStatus);
		
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
		// IS THIS A REDCAP SERVER MESSAGE
		String msgType = Email_Helper.getREDCapServerSignature(email.htmlBody);
		if ((msgType=='REDCap') || (msgType=='REDCap Survey')) {
			//REDCap or REDCap Survey Message
			newCase.suppliedEmail = Email_Helper.parseEmail(email.htmlBody);
			newCase.suppliedName = Email_Helper.parseFullname(email.htmlBody);
			newCase.ActionURL__c = Email_Helper.parseActionURL(email.htmlBody);
			newCase.Case_Areas__c = Email_Helper.getAction(email.htmlBody);
			newCase.Type = msgType;													//[REDCap] or [REDCap Survey]
			newCase.REDCap_StudyName__c = Email_Helper.parseDatabaseName(email.htmlBody);
			newCase.Origin = 'Server Message';										//I'm pretty sure this is set for us...
//			newCase.CustomOrigin__c = 'REDCap Email';								//Sets autoresponse email template
		} else {
			system.debug ('==> This is not a REDCap Server Message: ' + email.fromAddress);
			newCase.suppliedEmail = email.fromAddress;
			newCase.suppliedName = email.fromName;
   			newCase.Notify_Contact_On_Creation__c = False;							//FALSE TO prevent looping with out-of-office replies.
			newCase.Type = 'Other';													
			newCase.description = Email_Helper.makeDescription(email);
//			newCase.CustomOrigin__c = 'Other';										//determines recordType
			newCase.Origin = 'REDCap Email';
		}
	
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
}