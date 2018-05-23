public with sharing class RIT_SupportResponseEmails {
    public static Messaging.SingleEmailMessage openCase(String messageReceived, Messaging.InboundEmail emailReceived, Case theCase) {
    	Messaging.SingleEmailMessage returnMessage = new Messaging.SingleEmailMessage();
    	returnMessage.setToAddresses(new String[]{emailReceived.fromAddress});
    	returnMessage.setReplyTo(RIT_SupportEmailHandler.supportTeamAddress);
    	returnMessage.setSubject(emailReceived.subject + ' - ' + theCase.CaseNumber);
    	
    	return null;
    }
    public static Messaging.SingleEmailMessage newCase(String messageReceived, Messaging.InboundEmail emailReceived, Case newCase) {
    	Messaging.SingleEmailMessage returnMessage = new Messaging.SingleEmailMessage();
    	returnMessage.setToAddresses(new String[]{RIT_SupportEmailHandler.supportTeamAddress});
    	returnMessage.setReplyTo(RIT_SupportEmailHandler.supportTeamAddress);
    	returnMessage.setSubject(emailReceived.subject + ' - ' + newCase.CaseNumber);
    	
		String reply = RIT_SupportEmailHandler.endNewMessageIndicator + '\n\n' +
		'A new Ticket was created by ' + newCase.Contact.FirstName + ' ' + newCase.Contact.LastName + '.\n' +
		'Please reply above the separator.\n' +
		'You can take ownership of this case by replying to this email using the action tag: @open.\n\n' +
		'Description:\n\n' +
		messageReceived;

    	returnMessage.setPlainTextBody(reply);
    	List<Messaging.EmailFileAttachment> outAttachments = new List<Messaging.EmailFileAttachment>();
    	if(emailReceived.BinaryAttachments != null) { 
			for(Messaging.Inboundemail.BinaryAttachment ba : emailReceived.BinaryAttachments) {    	
	        	Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
	        	attach.body = ba.Body;
	        	attach.fileName = ba.fileName;
	        	attach.ContentType = ba.mimeTypeSubType;
	        	outAttachments.add(attach);
			}
    	}
    	if(emailReceived.TextAttachments != null) {
			for(Messaging.Inboundemail.TextAttachment ta : emailReceived.TextAttachments) {    	
	        	Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
	        	attach.body = Blob.valueOf(ta.Body);
	        	attach.fileName = ta.fileName;
	        	attach.ContentType = ta.mimeTypeSubType;
	        	outAttachments.add(attach);
			}
    	}
    	if( ! outAttachments.isEmpty()) {
    		returnMessage.setFileAttachments(outAttachments);
    	}
    	
    	return returnMessage;
    }
    public static Messaging.SingleEmailMessage caseOpened(String messageReceived, Messaging.InboundEmail emailReceived, Case theCase) {
    	Messaging.SingleEmailMessage returnMessage = new Messaging.SingleEmailMessage();
    	returnMessage.setToAddresses(new String[]{theCase.Contact.Email});
    	returnMessage.setReplyTo(RIT_SupportEmailHandler.supportTeamAddress);
    	returnMessage.setSubject(emailReceived.subject);
    	
		String reply = RIT_SupportEmailHandler.endNewMessageIndicator + '\n\n' +
		Email_Helper.removeTags(messageReceived);

    	returnMessage.setPlainTextBody(reply);
    	List<Messaging.EmailFileAttachment> outAttachments = new List<Messaging.EmailFileAttachment>();
    	if(emailReceived.BinaryAttachments != null) { 
			for(Messaging.Inboundemail.BinaryAttachment ba : emailReceived.BinaryAttachments) {    	
	        	Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
	        	attach.body = ba.Body;
	        	attach.fileName = ba.fileName;
	        	attach.ContentType = ba.mimeTypeSubType;
	        	outAttachments.add(attach);
			}
    	}
    	if(emailReceived.TextAttachments != null) {
			for(Messaging.Inboundemail.TextAttachment ta : emailReceived.TextAttachments) {    	
	        	Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
	        	attach.body = Blob.valueOf(ta.Body);
	        	attach.fileName = ta.fileName;
	        	attach.ContentType = ta.mimeTypeSubType;
	        	outAttachments.add(attach);
			}
    	}
    	if( ! outAttachments.isEmpty()) {
    		returnMessage.setFileAttachments(outAttachments);
    	}
    	
    	return returnMessage;
    }
    public static Messaging.SingleEmailMessage caseAlreadyOpened(String messageReceived, Messaging.InboundEmail emailReceived, Case theCase) {
    	Messaging.SingleEmailMessage returnMessage = new Messaging.SingleEmailMessage();
    	returnMessage.setToAddresses(new String[]{emailReceived.fromAddress});
    	returnMessage.setReplyTo(RIT_SupportEmailHandler.supportTeamAddress);
    	returnMessage.setSubject(theCase.CaseNumber + ' Case Already Taken By ' + theCase.Owner.Name);
    	
    	List<User> usrList = [
    		select Id, Name, Email
    		from User
    		where Email = :emailReceived.fromAddress
    	];
    	String reply = '';
    	if(usrList.size() == 1) {
    		reply = 'Hi ' + usrList.get(0).Name + '\n\n';
    	}
    	reply += 'This case was already opened by ' + theCase.Owner.Name + '.\n\n' +
    		'Your comments have NOT been added to the case.\n\n' +
    		'To add comments please use Salesforce.\n\n' +
    		'----------------------------------------\n\n' +
    		messageReceived + '\n\n' +
    		'----------------------------------------\n\n' +
    		theCase.Description;
    	
    	returnMessage.plainTextBody = reply;
    	return returnMessage;
    }
}