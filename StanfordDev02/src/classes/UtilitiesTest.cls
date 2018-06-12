@isTest
private class UtilitiesTest {
    static Id profileId;

    static {
		profileId = [SELECT Id FROM profile WHERE name='Standard User'].Id;    
    }
    
	@isTest
    static void getUsersInQueueTest() {
    	List<User> userList = new List<User>();
		User user1 = createUser('First1', 'Last1');
		User user2 = createUser('First2', 'Last2');
		User user3 = createUser('First3', 'Last3');
		userList.add(user1);
		userList.add(user2);
		userList.add(user3);
		insert userList;
		
		List<Group> groupList = new List<Group>(); 
		Group group1 = new Group(Name='Group1',Type='Regular');
		Group group2 = new Group(Name='Group2',Type='Regular');
		Group group3 = new Group(Name='Group3',Type='Regular');
		Group queue1 = new Group(Name='Queue1',Type='Queue');
		groupList.add(group1);
		groupList.add(group2);
		groupList.add(group3);
		groupList.add(queue1);
		insert groupList;
		
		List<GroupMember> mbrList = new List<GroupMember>();
		//Group1 contains User1
		GroupMember mbr1 = new GroupMember(GroupId=group1.Id, UserOrGroupId=user1.Id);
		//Group2 contains User2
		GroupMember mbr2 = new GroupMember(GroupId=group2.Id, UserOrGroupId=user2.Id);
		//Group3 contains Group2
		GroupMember mbr3 = new GroupMember(GroupId=group3.Id, UserOrGroupId=group2.Id);
		//Add Group1 to Queue
		GroupMember mbr4 = new GroupMember(GroupId=queue1.Id, UserOrGroupId=group1.Id);
		//Add Group3 to Queue
		GroupMember mbr5 = new GroupMember(GroupId=queue1.Id, UserOrGroupId=group3.Id);
		//Add User3 directly to Queue
		GroupMember mbr6 = new GroupMember(GroupId=queue1.Id, UserOrGroupId=user3.Id);
		mbrList.add(mbr1);
		mbrList.add(mbr2);
		mbrList.add(mbr3);
		mbrList.add(mbr4);
		mbrList.add(mbr5);
		mbrList.add(mbr6);
		insert mbrList;
		
		Set<Id> queueUsers = Utilities.getUsersInQueue(queue1.Name);
		System.assertEquals(3, queueUsers.size());
		System.assert(queueUsers.contains(user1.Id));
		System.assert(queueUsers.contains(user2.Id));
		System.assert(queueUsers.contains(user3.Id));
    }
	@isTest
    static void getUserByEmailTest() {
    	User user1 = createUser('First1', 'Last1');
    	insert user1;
    	User user2 = Utilities.getUserByEmail(user1.Email);
    	System.assertEquals(user1.Id, user2.Id);
    }
	private static User createUser(String firstName, String lastName) {
		string aliasText = '';
        if(FirstName != null && FirstName != '' && Lastname.length()>1){
                aliasText = FirstName.substring(0,1);
        }
        if(Lastname != null && Lastname != '' && Lastname.length()>2){
            aliasText += Lastname.substring(0,3);
        }
        else{
            aliasText +=Lastname;
        }
		String Email = firstName + '.' + lastName + '@test.com';
        User usr = new User(
        	firstName = FirstName,
            lastName = LastName,
            Email = Email,
            profileId = profileId,
            userName = Email,
            Alias = aliasText,
            localesidkey = UserInfo.getLocale(),
            emailEncodingKey = 'UTF-8',
            languagelocalekey = 'en_US',
            timeZoneSidKey = 'America/Los_Angeles'
        );
        return usr;
	}
}