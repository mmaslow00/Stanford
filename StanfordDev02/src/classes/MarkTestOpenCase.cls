public with sharing class MarkTestOpenCase {
    public static void test01() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

 		String sSubject = 'RE: Help! - CASE-029799';
		String sBody = 
			'@open\n' + 
			'Hi user_abc,\n' +
			'Inna (or someone with user privileges) has to add you to the projects, so you can see them.\n' + 
			'Here is a short video to show how to add users to projects:\n' +
			'https://www.useloom.com/share/xxxxxxxx\n' +
			'Be aware you should use the SUNet ID and not the email address.\n\n' +
			'Hope that helps,\n' + 
			'All the best\n\n' +
			'-Alvaro\n\n' +
			RIT_SupportEmailHandler.endNewMessageIndicator + '\n\n' +
			'more stuff';

        email.subject = sSubject;
		email.toAddresses = new String[]{'mmaslow00+supteam@gmail.com'};
        email.plainTextBody = sBody;
        env.fromAddress = 'mmaslow00@gmail.com';
        email.fromAddress = 'mmaslow00@gmail.com';
        
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