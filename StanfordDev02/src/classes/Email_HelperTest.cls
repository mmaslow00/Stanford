@isTest
private class Email_HelperTest {

    static testMethod void cleanCarriageReturnTest() {
        String content = 'Hello\n\nThis sentence is being cut\nin two pieces.';
        String properResult = 'Hello\n\nThis sentence is being cut in two pieces.';
        System.assertEquals(Email_Helper.cleanPlainTextBodyCarriageReturns(content), properResult);
    }

    static testMethod void regExTests() {
        String myContent = 'These changes were requested by Sreedevi Thiyagarajan (sreedevi@stanford.edu).';
		String myRegEx = '\\(([^\\)]*)'; 	//Find anything between parenthesis
        String properResult = 'sreedevi@stanford.edu';
        System.assertEquals(Email_Helper.regExMatch(myContent, myRegEx), true);
        System.assertEquals(Email_Helper.regExMatch(myContent, 'not\\ in\\ here'), false);
        String sResult = Email_Helper.regExMatchReturnGroup(myContent, myRegEx, 1);
        System.assertEquals(sResult, properResult);
		System.assert(Email_Helper.regExMatch(null, myRegEx)==false, 'null returns false');
		System.assert(Email_Helper.regExMatchReturnGroup(null, myRegEx, 1)=='', 'null returns empty string');
    }

    static testMethod void cleanUpSubjectTest() {
        String content = '[redcap-help] This is a some other stuff';
        String negativecontent = 'This is a some other stuff';
        String properResult = 'This is a some other stuff';
        System.assert(Email_Helper.cleanUpSubject(content) == properResult, 'cleanUpSubject failed: ');
        System.assert(Email_Helper.cleanUpSubject(negativecontent) == properResult, 'cleanUpSubject2 failed: ');
    }

    static testMethod void parseEmailTest() {
        String content = 'jane has an email of <a href="mailto:jane@tarzan.com">jane@tarzan.com</a>';
        String negativecontent = 'This is a some other stuff';
        String properResult = 'jane@tarzan.com';
        System.assert(Email_Helper.parseEmail(content) == properResult, 'parseEmail failed: ');
        System.assert(Email_Helper.parseEmail(negativecontent) == '', 'parseEmail2 failed: ');
    }

	static testMethod void findCaseTest() {
		Case newCase1 = new Case(
			Subject='My Unique Test Subject1',
			Description='Hi there ref:12345678.12345:ref');
		insert newCase1;
		
		List<Case> c1 = [SELECT Id, CaseNumber FROM Case WHERE Subject='My Unique Test Subject1' LIMIT 1];
		String cn = c1.get(0).CaseNumber;
		
		Messaging.InboundEmail email = new Messaging.InboundEmail();
		email.subject = 'A Test Subject (' + cn + ')';
		email.toAddresses = new List<String>();
		email.toAddresses.add('ToSomeone@scci.com');
		email.plainTextBody = 'Hi there';
		email.messageId = 'TEST-METHOD';
		
		Case cf = Email_Helper.getExistingCase(email);
		System.assert(cf.Subject == 'My Unique Test Subject1', 'findCaseTest problem: ' + cf.Subject);			
	}

	static testMethod void findCaseTest2() {
		Case newCase2 = new Case(
			Subject='My Unique Test Subject2',
			Description='Hi there');
		insert newCase2;
		
		List<Case> c2 = [SELECT Id, reference__c FROM Case WHERE Subject='My Unique Test Subject2' LIMIT 1];
		String ref = c2.get(0).reference__c;
		
		system.debug ('=====> REF:' + ref);
		
		Messaging.InboundEmail email = new Messaging.InboundEmail();
		email.subject = 'A Test Subject';
		email.toAddresses = new List<String>();
		email.toAddresses.add('ToSomeone@scci.com');
        email.plainTextBody = 'Hi there ' + ref;
		email.messageId = 'TEST-METHOD';
		
		Case cf = Email_Helper.getExistingCase(email);
		System.assert(cf!=null, 'Found the case: ' + cf.Id);			
		System.assert(cf.Id == c2.get(0).Id, 'findCaseTest2 problem');			
	}

	static testMethod void copyEmailTest() {
		Case newCase3 = new Case(
			Subject='My Unique Test Subject3',
			Description='Hi there');
		insert newCase3;
		
		Messaging.InboundEmail email = new Messaging.InboundEmail();
		email.subject = 'A Test Subject';
		email.toAddresses = new List<String>();
		email.toAddresses.add('ToSomeone@scci.com');
		email.htmlBody = 'Hi there';
//        email.plainTextBody = 'Hi there';
		email.messageId = 'TEST-METHOD';
        System.assert(Email_Helper.IsREDCapServerMessage(email) == False, 'skiptest2 failed: ');

        Email_Helper.copyEmailtoCase(email, newCase3.Id, '1');
        //System.assert(newEmail.subject == 'A Test Subject', 'skiptest3 failed: ');		
        System.assert(Email_Helper.makeDescription(email)!=null, 'makeDescription failure');
	}

    static testMethod void SkipTest() {
        System.assert(Email_Helper.parseActionURL('asdf') == '', 'skiptest1 failed: ');
        
        System.assert(Email_Helper.getREDCapServerSignature('asdf') == '', 'skiptest4 failed: ');

		Database.DMLOptions dmo = Email_Helper.getDMLOptions();

		String fn = Email_Helper.parseFullname('blah blah blah');
		String db = Email_Helper.parseDatabaseName('blah blah blah');		
		
		System.assert(Email_Helper.getAction('asdf')=='Other', 'getAction failure');
		System.assert(Email_Helper.parseEmail('asdf')=='', 'parseEmail failure');
		System.assert(Email_Helper.parseEmail('user_email=a@b\\.com')=='a@b\\.com', 'parseEmail2 failture');

		System.assert(Email_Helper.parseValidCaseNumber('CASE-999999')=='', 'parsevalidcasenumber failure');
		System.assert(Email_Helper.getCaseByThreadId('asdf')==null, 'get case by thread id problem');
    }


}