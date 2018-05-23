public with sharing class MarkTestCaseAlreadyOpened {
    public static void test01() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

 		String sSubject = 'RE: Help! - CASE-029811';
		String sBody = 
			'@open\n' + 
			'Hi user_abc,\n' +
			'Inna (or someone with user privileges) has to add you to the projects, so you can see them.\n' + 
			'Here is a short video to show how to add users to projects:\n' +
			'https://www.useloom.com/share/xxxxxxxx\n' +
			'Be aware you should use the SUNet ID and not the email address.\n\n' +
			'Hope that helps,\n' + 
			'All the best\n\n' +
			'-Alvaro';

        email.subject = sSubject;
		email.toAddresses = new String[]{'mmaslow00@gmail.com'};
        email.plainTextBody = sBody;
        env.fromAddress = 'mmaslow00@gmail.com';
        email.fromAddress = 'mmaslow00@gmail.com';
        RIT_SupportEmailHandler emailServObj = new RIT_SupportEmailHandler();
        Messaging.Inboundemailresult result = emailServObj.handleInboundEmail(email, env);
    }
}