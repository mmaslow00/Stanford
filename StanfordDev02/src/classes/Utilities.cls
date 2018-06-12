public with sharing class Utilities {
	public static Set<Id> getUsersInQueue(String queueName) {
/*
	Method getUsersInQueue
	
	Author: Mark Maslow - June 2018
	
	Input - Name of queue
	Output - Set of user Ids of queue members
	
	Queues can contain individual users as well as public groups of users.
	This method will return all individual users as well as all users in public groups that are queue members.
*/
		//Set to return
		Set<Id> queueUsers = new Set<Id>();
		
		//Queue was passed by Name - get Id
		
		List<Group> groupIdList = [select Id from Group where Type = 'Queue' and Name = :queueName];
		//Continue only if an Id for a queue with the passed Name was found. Otherwise, return empty set.
		if( ! groupIdList.isEmpty()) {
			Id groupId = groupIdList.get(0).Id;
			
			//Create set and populate with user or group Ids that are queue members
			Set<Id> groupMemberIds = new Set<Id>();
			for(GroupMember mbr : [select UserOrGroupId from GroupMember where GroupId = :groupId]) {
				groupMemberIds.add(mbr.UserOrGroupId);
			}
			//Get all group members
			queueUsers = getGroupMembers(groupMemberIds);
		}
		return queueUsers;
	}
	public static Set<Id> getUsersInQueue(Id queueId) {
		//Create set and populate with user or group Ids that are queue members
		Set<Id> groupMemberIds = new Set<Id>();
		for(GroupMember mbr : [select UserOrGroupId from GroupMember where GroupId = :queueId]) {
			groupMemberIds.add(mbr.UserOrGroupId);
		}
		//Get all group members
		return getGroupMembers(groupMemberIds);
	}
	private static Set<Id> getGroupMembers(Set<Id> idList) {
		//Add individual group members to userIds set.
		//Add public group members to groupIds set.
		Set<Id> userIds = new Set<Id>();
		Set<Id> groupIds = new Set<Id>();
		for(Id userOrGroupId : idList) {
			if(userOrGroupId.getSobjectType() == User.sObjectType) {
				userIds.add(userOrGroupId);
			}
			else {
				groupIds.add(userOrGroupId);
			}
		}

		//If there are public group members, get all the users in the public groups.
		//Note that public groups can themselves contain public group members.
		//This method calls itself recursively when passed a list containing one ore more group Ids, 
		//so groups nested inside groups are handled.
		
		if( ! groupIds.isEmpty() ) {
			Set<Id> idsInGroup = new Set<Id>();
			for(GroupMember grpMbr : [select userOrGroupId from GroupMember where GroupId in :groupIds]) {
				if(grpMbr.userOrGroupId.getSobjectType() == User.sObjectType) {
					//Id for user - add to user ids.
					userIds.add(grpMbr.userOrGroupId);
				}
				else {
					//Id for group - do recursive call to get users in group
					Set<Id> grpSet = new Set<Id>();
					grpSet.add(grpMbr.userOrGroupId);
					userIds.addAll(getGroupMembers(grpSet));				
				}
			}
		}
		return userIds;
	}
	public static User getUserByEmail(String email) {
/*
	Method getUserByEmail
	
	Input - Email address of user
	Output - If User with email exists, User with Id and Name, otherwise, null
*/
		User usr;
		List<User> userList = [select Id, Name, Alias from User where Email = :email];
		if( ! userList.isEmpty() ) {
			usr = userList.get(0);
		}
		return usr;
	}
/*
	Method getUserByAlias
	
	Input - Alias of user
	Output - If User with Alias exist, User with Id and Name, otherwise, null
*/
	public static User getUserByAlias(String alias) {
		User usr;
		List<User> userList = [select Id, Name from User where Alias = :alias];
		if( ! userList.isEmpty() ) {
			usr = userList.get(0);
		}
		return usr;
	}
/*
	Method getQueueIdByName
	
	Input - Name of queue
	Output - Id of queue, if queue exists, otherwise, null
*/
	public static Id getQueueIdByName(String queueName) {
		Id groupId;
		List<Group> groupIdList = [select Id from Group where Type = 'Queue' and Name = :queueName];
		if( ! groupIdList.isEmpty()) {
			groupId = groupIdList.get(0).Id;
		}
		return groupId; 
	}
}