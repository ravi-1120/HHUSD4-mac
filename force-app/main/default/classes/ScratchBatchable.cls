// NOTE: must implement Database.Stateful to maintain instance variable state across
// transactions
global class ScratchBatchable implements Database.Batchable<sObject>, Database.Stateful {

   global final String query;
   global final String emailTo;
   global String output = '';
   global Map<String, MRK_UserInfo> useridToUserInfoMap = new Map<String, MRK_UserInfo>();
   
   global ScratchBatchable(String q, String et) {
       query = q;
       emailTo = et;
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope) {
       for (sObject o : scope) {
       	String userid = (String)o.get('Id');
       	try {
       		useridToUserInfoMap.put(userid, MRK_UserInfo.getByUserid(userid));
       	} catch (Exception e) {

       	}
      }
   }

   global void finish(Database.BatchableContext BC) {

   	MRK_CommunicationServices.assignEventsToTargets(useridToUserInfoMap);

   	/*

		// can't manually insert UserTerritory records
		// need to do via ATL

   	Set<Id> allUseridList = new Set<Id>();
   	for (User u : [select id from User where Merck_Employee_ID_MRK__c != null]) {
   		allUseridList.add(u.Id);
   	}

   	Set<Id> useridsNotHavingTerritories = new Set<Id>();
   	for (UserTerritory ut : [select UserId from UserTerritory where not(UserId in :allUseridList)]) {
   		useridsNotHavingTerritories.add(ut.UserId);
   	}

   	List<Id> allTerritoryIdList = new List<Id>();
   	for (Territory t : [select Id from Territory]) {
   		allTerritoryIdList.add(t.id);
   	}

   	List<UserTerritory> utList = new List<UserTerritory>();
   	for (Id userid : useridsNotHavingTerritories) {
   		UserTerritory ut = new UserTerritory(
   			UserId=userid,
   			TerritoryId=allTerritoryIdList[Math.round( Math.random() * (allTerritoryIdList.size() - 1) )]
   		);
   		utList.add(ut);
   	}
   	insert utList;
   	*/

   	// need to remove events that exist but are no longer in a published state.

   	/*
   	Set<Id> usersHavingGeneralProduct = new Set<Id>();
   	for (My_Setup_Products_vod__c msp : [select OwnerId from My_Setup_Products_vod__c where Product_vod__r.Name = 'General']) {
			usersHavingGeneralProduct.add(msp.OwnerId);
   	}

   	Id generalProductId = [select id from product_vod__c where name = 'General'][0].Id;
		List<My_Setup_Products_vod__c> mspList = new List<My_Setup_Products_vod__c>();
   	for (User u : [select id from user where not(id in :usersHavingGeneralProduct)]) {
   		My_Setup_Products_vod__c msp = new My_Setup_Products_vod__c(
   			OwnerId = u.id,
   			Product_vod__c=generalProductId
   		);
   		mspList.add(msp);
   	}

   	insert mspList;
   	*/


   	// schedule the following for every 1 hours

   	// are there any events that need processing?

   	// check if job is already queued
   	String apexJobClassName = 'ScratchBatchable';
   	String apexClassId = null;   	
   	List<ApexClass> apexClassList = [select Id from ApexClass where name = :apexJobClassName and Status = 'Active'];
   	if (apexClassList.size() > 0) {
   		apexClassId = apexClassList[0].Id;
   	}

   	List<AsyncApexJob> asyncApexJobList = [select Id, JobType, ApexClassId, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, CompletedDate, MethodName, ExtendedStatus, ParentJobId, LastProcessed, LastProcessedOffset from AsyncApexJob where JobType IN ('BatchApex', 'BatchApexWorker') and Status = 'Queued' and ApexClassId = :apexClassId];
		// don't run if job already queued
		if (asyncApexJobList.size() > 0) {
			System.debug('AsyncApexJob for class "' + apexJobClassName + ' already running.');
			return;		   		
		}

   	Map<String, MRK_UserInfo> useridToUserInfoMap = new Map<String, MRK_UserInfo>();
   	for (User u : [select id from user where username in ('kenneth.fernando@merck.com.hhusc3')]) {
   		useridToUserInfoMap.put(u.id, MRK_UserInfo.getByUserid(u.id));
   	}

		//, 'sales.user@merck.com.hhusc3', 'commuser@merck.com.hhusc3', 'commrep01@merck.com.hhusc3'   
   	


   	// pass useridToUserInfoMap to new EventCreatorBatchable
		String soql = 'select Id, Communication_Event_MRK__c, Profile_MRK__c, Product_MRK__c, Team_MRK__c, Type_MRK__c, Communication_Event_MRK__r.Name, Communication_Event_MRK__r.Start_DateTime_MRK__c, Communication_Event_MRK__r.End_DateTime_MRK__c, Communication_Event_MRK__r.Title_MRK__c, Communication_Event_MRK__r.Source_MRK__c from Communication_Event_Target_MRK__c where Communication_Event_MRK__r.Status_MRK__c = \'Published\' and Communication_Event_MRK__r.Active_MRK__c = true and Communication_Event_MRK__r.End_DateTime_MRK__c >= YESTERDAY';   	
		List<Communication_Event_Target_MRK__c> ceList = Database.query(soql);
		
		Map<Id,Set<Id>> commEventToAssignedUsersMap = new Map<Id,Set<Id>>();

		Map<String,Map<String,Object>> userToEventListMap = new Map<String,Map<String,Object>>();

		for (Communication_Event_Target_MRK__c ce : ceList) {

			Set<Id> assignedUsers = commEventToAssignedUsersMap.get(ce.Communication_Event_MRK__c);
			if (assignedUsers == null) {
				assignedUsers = new Set<Id>();
			}

			for (String userid : useridToUserInfoMap.keySet()) {
				MRK_UserInfo ui = useridToUserInfoMap.get(userid);
				Set<String> productNames = new Set<String>();
				productNames.addAll(ce.Product_MRK__c.split(';'));
				productNames.retainAll(ui.assignedProductNames);

				Set<String> teamNames = new Set<String>();
				teamNames.addAll(ce.Team_MRK__c.split(';'));
				teamNames.retainAll(ui.territoryPathDescriptionSet);

				Set<String> profileNames = new Set<String>();
				profileNames.addAll(ce.Profile_MRK__c.split(';'));
				if ( (profileNames.contains(ui.profileName)) && (productNames.size() >0) && (teamNames.size() >0) ) {
					Map<String,Object> eventMap = (Map<String,Object>)userToEventListMap.get(userid);
					if (eventMap == null) {
						eventMap = new Map<String,Object>();
					}

					Communication_Event_Target_MRK__c uce = (Communication_Event_Target_MRK__c)eventMap.get(ce.Communication_Event_MRK__c);
					if ((uce == null) || ((ce.Type_MRK__c == 'Required') && (uce.Type_MRK__c == 'Optional'))) {
						eventMap.put(ce.Communication_Event_MRK__c, ce);	
					}
					
					userToEventListMap.put(userid, eventMap);
				}

			commEventToAssignedUsersMap.put(ce.Communication_Event_MRK__c, assignedUsers);

			}			
		}

		// ***
		// clean up / delete any events older than a week old
		// ***

		List<Event> deleteEventList = new List<Event>();

		String commEventRecordTypeId = '';

		
		for (Id commEventId : commEventToAssignedUsersMap.keySet()) {
			Set<Id> userids = commEventToAssignedUsersMap.get(commEventId);
			List<Event> eventList = [select Id from Event where RecordTypeId = :commEventRecordTypeId and WhatId = :commEventId and OwnerId not in :userids];
			deleteEventList.addAll(deleteEventList);
		}
		delete deleteEventList;
		try {
			Database.emptyRecycleBin(deleteEventList);
		} catch (Exception e) { /* eat exception */}
		

		List<Event> eventList = new List<Event>();
		for (String userid : userToEventListMap.keySet()) {
			Map<String,Object> eventMap = userToEventListMap.get(userid);
			for (Object cet : eventMap.values()) {
				Event e = MRK_CommunicationServices.createEvent(new Map<String,Object>{'object' => cet}, userid);
				eventList.add(e);
			}
		}

		insert eventList;

   		//output += 'useridToUserInfoMap.values().size() = ' + useridToUserInfoMap.values().size() + '\n\n';
   		//output += JSON.serializePretty(useridToUserInfoMap);
			output += JSON.serializePretty(userToEventListMap);

			System.debug('output = ' + output);

			/*
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

       mail.setToAddresses(new String[] {emailTo});
       mail.setReplyTo(emailTo);
       mail.setSenderDisplayName('ScratchBatchable Batch Processing');
       mail.setSubject('ScratchBatchable Batch Process Completed');
       mail.setPlainTextBody('Parameters\nquery = ' + query + '\nOutput\n' + output);
       
       Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
       attachment.setBody( Blob.valueOf(output) );
       attachment.setContentType('text/plain');
       attachment.setFileName('output.txt');
       mail.setFileAttachments(new Messaging.EmailFileAttachment[] {attachment});
       
       Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			*/
   }
}