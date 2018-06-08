public with sharing class Utilities {
	public static Set<Id> getUsersInQueue(String queueName) {
/*
	Method getUsersInQueue
	
	Author: Mark Maslow - June 2018
	
	Input - Developer Name of queue
	Output - Set of user Ids of queue members
	
	Queues can contain individual users as well as public groups of users.
	This method will return all individual users as well as all users in public groups that are queue members.
	
*/
		//Set to return
		Set<Id> queueUsers = new Set<Id>();
		
		//Queue was passed by DevloperName - get Id
		
		List<Group> groupIdList = [select Id from Group where Type = 'Queue' and DeveloperName = :queueName];
		//Continue only if an Id for a queue with the passed DeveloperName was found. Otherwise, return empty set.
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
					userIds.add(grpMbr.userOrGroupId);
				}
				else {
					Set<Id> grpSet = new Set<Id>();
					grpSet.add(grpMbr.userOrGroupId);
					userIds.addAll(getGroupMembers(grpSet));				
				}
			}
		}
		return userIds;
	}
}