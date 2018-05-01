public with sharing class MarkTest03 {
	final static String regex = '(?m)@(.+)=(.*)';
		
	public static void findMatches() {
		String testString = 
			'@tag=1,2,3\n\n'
			+ 'some stuff\n\n'
			+ '@tag2=abc\n\n'
			+ 'some more stuff\n\n'
			+ '@jsonTag={"fieldName": "fieldValue"}\n'
			+ '@emptyTag=\n'
			+ '@tagWithValue=some information';

		Pattern thePattern = Pattern.compile(regex); 
		Matcher myMatcher = thePattern.matcher(testString);
		while(myMatcher.find()) {
			String tagName = myMatcher.group(1);
			String tagValue = myMatcher.group(2);
			System.debug('tagName: ' + tagName);
			System.debug('tagValue: ' + tagValue);
		}
	}				
}