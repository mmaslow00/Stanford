public with sharing class MarkTest04 {
	final static String regex = '(?m)@([^\\s]+)=(.+)|@([^\\s]+)';
		
	public static void findMatches() {
		String testString = 
			'@tag=1,2,3\n\n'
			+ 'some stuff\n\n'
			+ '@tag2=abc\n\n'
			+ 'some more stuff\n\n'
			+ '@jsonTag={"fieldName": "fieldValue"}\n'
			+ '@emptyTag\n'
			+ '@tagWithValue=some information';

		Pattern thePattern = Pattern.compile(regex); 
		Matcher myMatcher = thePattern.matcher(testString);
		while(myMatcher.find()) {
			String tagValue = null;
			String tagName = myMatcher.group(1);
			if(tagName == null) {
				tagName = myMatcher.group(3);
			}
			else {
				tagValue = myMatcher.group(2);
			}
			System.debug('Found Match - tagName: ' + tagName + ' - tagValue: ' + tagValue);
		}
	}				
}