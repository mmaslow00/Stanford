public with sharing class MarkTestNewCase {
    public static void test01() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

 		String sSubject = 'Help!';
		String sBody = 
			'Hi, \n\n' + 
			'I am hoping you can help me gain access to REDCAP, I am a temporary employee filling in for Ni Deng working with xxxx  xxx. ' +
			 'I am able to get into Redcap, but I do not have access to Projects.  Below is a screenshot display.\n\n' + 
			'Please advise.\n' +
			'Thanks,\n' +
			'user_abc.';
		
		
        email.subject = sSubject;
		email.toAddresses = new String[]{'mmaslow00+supteam@gmail.com'};
        email.plainTextBody = sBody;
        env.fromAddress = 'mmaslow00+enduser@gmail.com';
        email.fromAddress = 'mmaslow00+enduser@gmail.com';
        
        StaticResource sr = [select Body, ContentType from StaticResource where Name='DocuSignLogo'];
        Messaging.InboundEmail.BinaryAttachment attach = new Messaging.InboundEmail.BinaryAttachment();
        attach.body = sr.Body;
        attach.fileName = 'Test Binary Attachment';
        attach.mimeTypeSubType = sr.ContentType;
        
        List<Messaging.InboundEmail.BinaryAttachment> attachmentList = new List<Messaging.InboundEmail.BinaryAttachment>();
        attachmentList.add(attach);
        email.binaryAttachments = attachmentList;
 
        RIT_SupportEmailHandler emailServObj = new RIT_SupportEmailHandler();
        Messaging.Inboundemailresult result = emailServObj.handleInboundEmail(email, env);
    }
    
}