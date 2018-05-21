public with sharing class RIT_SupportResponseEmails {
    public static Messaging.SingleEmailMessage openCase(String messageReceived, Messaging.InboundEmail emailReceived, Case newCase) {
    	Messaging.SingleEmailMessage returnMessage = new Messaging.SingleEmailMessage();
    	returnMessage.setToAddresses(new String[]{emailReceived.fromAddress});
    	returnMessage.setReplyTo(RIT_SupportEmailHandler.supportTeamAddress);
    	returnMessage.setSubject(emailReceived.subject + ' - ' + newCase.CaseNumber);
    	
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
    /*
    private static Messaging.SingleEmailMessage addAttachments(Messaging.InboundEmail email) {
		List<Messaging.Inboundemail.TextAttachment> tAttachments = email.textAttachments;
		List<Messaging.Inboundemail.BinaryAttachment> bAttachments = email.BinaryAttachments;
		List<Attachment> newAttachments = new List<Attachment>();
		if (tAttachments != null) {
			for (Messaging.Inboundemail.TextAttachment t:tAttachments) {
				System.debug('==> Found text attachment: ' + t.fileName);
				Attachment a = new Attachment(
					Body = Blob.valueOf(t.body),
					Name = t.fileName,
					ParentId = newEmailId,
					ContentType = t.mimeTypeSubType
				);
				newAttachments.add(a);
			}
		}
		if (bAttachments != null) {
			for (Messaging.Inboundemail.BinaryAttachment b:bAttachments) {
				System.debug('==> Found binary attachment: ' + b.fileName);
				Attachment a = new Attachment(
					Body = b.body,
					Name = b.fileName,
					ParentId = newEmailId,
					ContentType = b.mimeTypeSubType
				);
				newAttachments.add(a);
			}
		}
		if (newAttachments.size()>0) {
			email.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
		}
    }
    
        List<Messaging.InboundEmail.BinaryAttachment> attachmentList = new List<Messaging.InboundEmail.BinaryAttachment>();
        attachmentList.add(attach);
        email.binaryAttachments = attachmentList;
    
    
    
    */
}