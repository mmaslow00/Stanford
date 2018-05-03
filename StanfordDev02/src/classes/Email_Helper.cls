public with sharing class Email_Helper {

/////////////////// UTILITY FUNCTIONS ////////////////////////

	//clean up carriage returns in plain text email.
	public static String cleanPlainTextBodyCarriageReturns(String originalPTB) {
		String ptb = originalPTB.replace('\n\n','~!!~').replace('\n',' ').replace('~!!~','\n\n');
		//system.debug('PTB Before:' + email.plainTextBody +'\n\nPTB After:' + ptb);
		return ptb;
	}

	//Do a basic regEx search
	public static Boolean regExMatch(String content, String regEx) {
		if (content == null) return false; 
		Matcher match = Pattern.compile(regEx).matcher(content);
		Boolean regExExists = match.find();
		//system.debug('regExExists: ' + regExExists + ' with content=[' + content + '] and search string = [' + regEx+ ']');
		return regExExists;
	}

	//Do a regEx search and return a group
	public static String regExMatchReturnGroup(String content, String regEx, Integer groupNumber) {
		if (content == null) return ''; 
		Matcher match = Pattern.compile(regEx).matcher(content);
		if (match.find()) {
			return match.group(groupNumber);
		} else {
			//system.debug('Unable to find regEx: [' + regEx + '] in content [' + content + '] so we are unable to return group [' + groupNumber +']');
			return '';
		}
	}

/////////////////// SPECIFIC FUNCTIONS ////////////////////////

	public static Case getExistingCase(Messaging.InboundEmail email) {
		// Determine if there is an existing case by the contents of this email.
		// Step 1: look for a case number in the subject
		String vcn = parseValidCaseNumber(email.subject);
		if (vcn != '') {return getCaseByCaseNumber(vcn);}		//found case number
		
		// Step 2: look for a case ThreadId
		String ref = parseThreadId(email.subject);
		if (ref == '') {ref = parseThreadId(email.htmlBody);}
		if (ref == '') {ref = parseThreadId(email.plainTextBody);}
		if (ref != '') {return getCaseByThreadId(ref);}			//found thread

		//failed to find anything
		return null;
	}

		
	public static String cleanUpSubject(String content) {
		// Remove the prefix from the subject
		String sCleanUpSubject = '^(\\[redcap-help]\\s)';
		return content.replaceFirst(sCleanUpSubject,'');
	}

	public static String getAction(String content) {
		// Try to get the REDCap server request action the content of the email
		// Options are: Approve Changes to Production DB, Move DB to Production
		String sRequestType1 = 			'changes\\ for\\ the\\ production\\ database';
		//String sRequestType2 =		'Request\\ to\\ Move\\ Database\\ to\\ Production';
		String sRequestType2 =			'requested\\ that\\ the\\ following\\ database\\ be\\ moved\\ to\\ production\\ status';
		if (regExMatch(content, sRequestType1)) {
			return 'Approve Changes to Production DB';
		} else if (regExMatch(content, sRequestType2)) {
			return 'Move DB to Production';
		} else {
			return 'Other';
		}
	}
	
	public static Boolean IsREDCapServerMessage(Messaging.InboundEmail email) {
		// a redcap server message must contain the following in the first line of the HTML content
		// [This message was automatically generated by REDCap]
		// [This message was automatically generated by REDCap Survey]
		String sREDCapEmailSignature = 	'\\[This\\ message\\ was\\ automatically\\ generated\\ by\\ (REDCap[^\\]]*)';
		return regExMatch(email.htmlBody, sREDCapEmailSignature);
	}

	public static String getREDCapServerSignature(String content) {
		// a redcap server message must contain the following in the first line of the HTML content
		// [This message was automatically generated by REDCap]
		// [This message was automatically generated by REDCap Survey]
		String sREDCapEmailSignature = 	'\\[This\\ message\\ was\\ automatically\\ generated\\ by\\ (REDCap[^\\]]*)';
		return regExMatchReturnGroup(content, sREDCapEmailSignature, 1);
	}

	public static void copyEmailtoCase (Messaging.InboundEmail email, String parentCaseId, String status) {
		// Takes the inbound email and envelope and uses it to generate a new email including all attachments
		EmailMessage msg = new EmailMessage (
			ToAddress = email.toAddresses[0],
			FromAddress = email.fromAddress,
			FromName = email.fromName,
			Subject =  email.subject,
			TextBody = makeDescription(email),
			HtmlBody = email.htmlBody,
			Incoming = true,
			Status = status,									//'0' = New,'1' = Read,'2' = Replied,'3' = Sent,'4' = Forwarded
			ParentID = parentCaseId
		);
		insert msg;
		String newEmailId = msg.id;
		//find attachments
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
			insert(newAttachments);
		}
	}

	public static Database.DMLOptions getDMLOptions () {
    	//Apply the assignment rules to this new Case (otherwise the owner would default to the script user, who is me right now)
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;
		dmo.EmailHeader.triggerAutoResponseEmail = true;
		dmo.EmailHeader.triggerUserEmail = true;		
		return dmo;
	}


	public static String parseEmail(String content) {
		// Try to get the REDCap server user's email message from the content of the email
		String sMatchEmail1 = '<a href=["\']mailto:([^"\']*)';
		String sMatchEmail2 = 'user_email=([^&>]*)';
		String result = regExMatchReturnGroup(content, sMatchEmail1, 1);
		if (result!='') {
			return result;
		} else {
			result = regExMatchReturnGroup(content, sMatchEmail2, 1);
			if (result!='') {
				return result;
			} else {
				return '';
			}
		}
	}

	public static String parseFullname(String content) {
		// Try to get the REDCap server user's fullname from the content of the email
		String sFullName1 = 'The\\ REDCap\\ user\\ <b>([^\\<]*)';
		String sFullName2 =	'These\\ changes\\ were\\ requested\\ by\\ ([^\\(]*)';
		String result = regExMatchReturnGroup(content, sFullName1, 1);
		if (result!='') {
			return result;
		} else {
			result = regExMatchReturnGroup(content, sFullName2, 1);
			if (result!='') {
				return result;
			} else {
				return '';
			}
		}
	}

	public static String parseDatabaseName(String content) {
		// Try to get the REDCap server user's database name from the content of the email
		String sDBName1 = 'titled\\ ["\']([^"\']*)';
		String sDBName2 = 'moved\\ to\\ production\\ status:\\s*<b>([^\\<]*)';
		String result = regExMatchReturnGroup(content, sDBName1, 1);
		if (result!='') {
			return result;
		} else {
			result = regExMatchReturnGroup(content, sDBName2, 1);
			if (result!='') {
				return result;
			} else {
				return '';
			}
		}
	}

	public static String parseActionURL(String content) {
		// Try to get the REDCap server ActionURL from the content of the email
		String sMatchActionURL = 		'(http://redcap.stanford.edu/[^"\']*)';
		String result = regExMatchReturnGroup(content, sMatchActionURL, 1);
		if (result!='') {
			return result;
		} else {
			return '';
		}
	}

	public static String parseValidCaseNumber (String content) {
		// Search for a case number in the content and check to see if it is valid
		// If so, return the the case Number - otherwise ''
		String sGetCaseNumber = '(CASE-\\d{6})';
		String result = regExMatchReturnGroup(content, sGetCaseNumber, 1);
		if (result=='') {
			return '';
		} else {
			if (getCaseByCaseNumber(result) == null) {
				return '';
			} else {
				return result;
			}
		}
	}

	public static Case getCaseByCaseNumber (String caseNumber) {
		// Search for a case number in the content and then return the Case object
		// We found a match, lets see if it is valid
		List<Case> matchingCases = [SELECT Id, caseNumber, subject, status FROM Case WHERE CaseNumber=:caseNumber];
		if (matchingCases.size()==1) {
			Case c = matchingCases.get(0);
			system.debug('** Returning a preexisting case: ' + c.CaseNumber);
			return c;
		} else {
			system.debug('** We were expecting a single valid case but got a size of: ' + matchingCases.size());
			return null;
		}
	}

	public static String parseThreadId (String content) {
		// Search for a thread id from the content
		String sThreadFormat = '(ref:\\w+?\\.\\w+?:ref)';
		String result = regExMatchReturnGroup(content, sThreadFormat, 1);
		if (result=='') {
			// no match
			return '';
		} else {
			system.debug('** Found ThreadID Match:  ' + result);
			return result;
		}
	}

	public static Case getCaseByThreadId (String ref) {
		String likeClause = '%' + ref + '%';
		List<Case> matchingCases = [SELECT Id, caseNumber, subject, status FROM Case WHERE reference__c LIKE :likeClause];
		if (matchingCases.size()==1) {
			Case c = matchingCases.get(0);
			system.debug('** Returning a preexisting case: ' + c.CaseNumber + ' from thread: ' + ref);
			return c;
		} else {
			return null;
		}
	}

	public static String makeDescription (Messaging.InboundEmail email) {
		String sDesc = '';
		if (email.plainTextBody != '' && email.plainTextBody != null) {
			sDesc = email.plainTextBody;
		} else {
			sDesc = StripHTML(email.htmlBody);
		}
		return sDesc;
	}

	public static String StripHTML(String html) {
		String result = '';
		//This is a poor man's attempt to convert html email content into standard text...
		result = html.replaceAll('\n', '');
		result = result.replaceAll('\r', '');
//		result = result.replaceAll('(?i)<br/>', '\n');
//		result = result.replaceAll('(?i)<br />', '\n');
		result = result.replaceAll('(?i)<(tr|br|ul|p)(| |/| .*?)>', '\n');		//replace tr br ul or p tags (ignore class) with linefeed
//		result = result.replaceAll('(?i)<ul(| |/| .*?)>', '\n');		//replace ul with linefeed
		result = result.replaceAll('(?i)</(li|p)>', '\n');				//replace \li or \p with linefeed 
		result = result.replaceAll('(?i)<li(| |/| .*?)>', '\t\\* ');	//replace li with tab* 
		result = result.replaceAll('(?i)<td(| |/| .*?)>', '\t');		//replace td with tab* 
		result = result.replaceAll('(?i)&nbsp;', ' ');
/*		
		//regular expression to match all HTML/XML tags
		string HTML_TAG_PATTERN = '<\\w.*?>';							//replace most other html tags with nothing
		pattern myPattern = pattern.compile(HTML_TAG_PATTERN);
		matcher myMatcher = myPattern.matcher(result);
		result = myMatcher.replaceAll('');
        return result;
*/
		return result.stripHtmlTags();
	}

    public class ContactsWithEmail {
        public ContactsWithEmail(String emailAddr) {
            primaryList = [
                select Id from Contact where Email = :emailAddr
            ];
            String qry = 'select Id from Contact where Alternate_Emails__c like \'%' + String.escapeSingleQuotes(emailAddr) + '%\'';
            alternateList = Database.query(qry);
        }
        public List<Contact> primaryList;
        public List<Contact> alternateList;
    }
}