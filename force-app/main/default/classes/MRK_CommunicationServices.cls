/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_CommunicationServices.cls
* @description - Services class for Communications capabilities
* @createdate - July 8th, 2013
*
*/

@RestResource(urlMapping='/mrk/communication/*')
global class MRK_CommunicationServices {

	public static final String SETTING_NAME = 'COMMUNICATIONS_APPLICATION';
	public static final Id communicationEventRecordTypeId = Database.query(MRK_Setting.getString(SETTING_NAME, 'communication event record type id soql'))[0].Id;

	public MRK_CommunicationServices() {
		
	}

	/*
	* @methodDescription: indicates whether the communications functionality is
	* available for the given userid
	*/
	public static Boolean communicationFunctionalityEnabledForUser(String userid) {
		Boolean globalPilotMode = MRK_Setting.getBoolean(SETTING_NAME, 'pilot mode');
		if (!globalPilotMode) {
			return true;
		} else {
			String fieldName = MRK_Setting.getString(SETTING_NAME, 'pilot user field api name');
			User u = (User)Database.query('select ' + fieldName + ' from user where id = \'' + userid + '\'' )[0];
			return (Boolean)u.get(fieldName);
		}
	}

	/*
	public static Map<String, Set<String>> getTargetDataForUser(String userid) {

		 Map<String, Set<String>> targetData = new Map<String, Set<String>>();

		// *** profiles / level ***
		// Profile - Rep, Manager, Director
		String profileName = [select Profile.Name from user where Id = :userid].Profile.Name;
		Map<String,Object> profileNameToLevelNameMap = (Map<String,Object>)MRK_Setting.getObject(SETTING_NAME, 'profile to level map');
		targetData.put('levelNameSet', new Set<String>{(String)profileNameToLevelNameMap.get(profileName)});

		// profile name to user-friendly mapping stored in JSON settings
		// e.g. "MRK - Sales Representative" -> "Rep"

		// *** my products ***
		List<My_Setup_Products_vod__c> detailProducts = [SELECT Product_vod__c, Product_vod__r.Name FROM My_Setup_Products_vod__c WHERE OwnerId = :userid and Product_vod__r.Product_Type_vod__c = 'Detail'];

		Set<String> productNameSet = new Set<String>();
		for (My_Setup_Products_vod__c sp : detailProducts) {
			productNameSet.add(sp.Product_vod__r.Name);
		}

		targetData.put('productNameSet', productNameSet);

		// *** sales team ***
		List<String> territoryPathList = new List<String>();
		List<String> territoryPathDescriptionList = new List<String>();
		Set<String> territoryPathDescriptionsSet = new Set<String>();
		Set<String> threeLevelTerritoryPathDescriptionsSet = new Set<String>();
		
		// get *my* territory
		String territoryId = [select TerritoryId from UserTerritory where UserId = :userid and IsActive = true].TerritoryId;

		// walk up the hierarchy
		while (territoryId != null) {
			Territory t = [select ParentTerritoryId, Name, Description from Territory where Id = :territoryId];
			territoryId = t.ParentTerritoryId;
		   territoryPathList.add(t.ParentTerritoryId);
		   territoryPathDescriptionsSet.add(t.Description);
		   territoryPathDescriptionList.add(t.Description);
		}

		Integer levels = MRK_Setting.getInteger(SETTING_NAME, 'territory targeting levels');
		Integer counter = 0;
		for (Integer i = (territoryPathDescriptionList.size() - 1); i >=0; i--) {
			if (counter++ < levels) {
				threeLevelTerritoryPathDescriptionsSet.add(territoryPathDescriptionList[i]);	
			}
		}

		targetData.put('territoryNameSet', threeLevelTerritoryPathDescriptionsSet);

		return targetData;

	}
	*/

	public static Map<string,object> getCommunicationForUser(String userid, String objectId) {
		return getCommunicationsForUser(userid).get(objectId);
	}

	// 

	/*
	* @methodDescription: returns map of communication ids -> comm type (action or background)
	*/	
	public static Map<Id,Map<string,object>> getCommunicationsForUser(String userid) {

		MRK_UserInfo ui = MRK_UserInfo.getByUserid(userid);

		String releasedStatus = '\'Released\'';

		String userTargetMode = MRK_Setting.getString(SETTING_NAME, 'user target mode');
		System.debug('getCommunicationsForUser: userTargetMode = ' + userTargetMode);

		String baseSoqlTemplate = MRK_Setting.getString(SETTING_NAME, 'communications base soql template');
		String soql = string.format(baseSoqlTemplate, new String[]{releasedStatus});		

		String soqlTemplate = MRK_Setting.getString(SETTING_NAME, 'communications for user soql where filter template');

		if (userTargetMode == 'profile,product,sales team') {
			// filter communications only if the user has product assignments and a sales team
			if ((ui.assignedProductExternalIds.size() > 0) && (ui.salesTeamCodes.size() > 0)) {
				soql = soql + ' and ' + string.format(soqlTemplate, new String[]{'\'' + ui.profileName + '\'', stringSetJoin( ui.assignedProductExternalIds ), stringSetJoin( ui.salesTeamCodes )});
			}
		} else { // (userTargetMode == 'profile,product,territory')
			// filter communications only if the user has product assignments and has a territory
			if ((ui.assignedProductNames.size() > 0) && (ui.territoryPathDescriptionSet.size() > 0)) {
				soql = soql + ' and ' + string.format(soqlTemplate, new String[]{'\'' + ui.profileName + '\'', stringSetJoin( ui.assignedProductNames ), stringSetJoin( ui.territoryPathDescriptionSet )});
			}
		}

		
		System.debug('getCommunicationsForUser: soql = ' + soql);

		List<Communication_Target_MRK__c> commTargetList = Database.query(soql);
		Map<Id,Map<string,object>> commIdToCommDataMap = new Map<Id,Map<string,object>>();
		for (Communication_Target_MRK__c commTarget : commTargetList) {
			Map<string,object> commMap = commIdToCommDataMap.get(commTarget.Communication_MRK__c);
			String commType = null;
			if (commMap == null) {
				commMap = new Map<string,object>();

				// store the communication/communication target object
				commMap.put('object', commTarget);

				// pre-populate with unread
				commMap.put('Read_Status_MRK__c', 'unread');
			} else {
				commType = (String)commMap.get('audience');
			}
			
			// add to map if doesn't exist
			// if it does exist already, but is background, override with Action
			if ((commType == null) || ((commType == 'Background') && (commTarget.Type_MRK__c == 'Action'))) {
				commMap.put('audience', commTarget.Type_MRK__c);
				commIdToCommDataMap.put(commTarget.Communication_MRK__c, commMap);
			}

		}

		// add read status
		for (Communication_Activity_MRK__c ca : [select Id, Name, Communication_MRK__c, Read_Status_MRK__c, User_MRK__c from Communication_Activity_MRK__c where User_MRK__c = :userid and Communication_MRK__c in :commIdToCommDataMap.keySet()]) {
			System.debug('Read_Status_MRK__c = ' + ca.Read_Status_MRK__c);
			Map<string,object> commMap = commIdToCommDataMap.get(ca.Communication_MRK__c);
			commMap.put('Read_Status_MRK__c', ca.Read_Status_MRK__c);
			commIdToCommDataMap.put(ca.Communication_MRK__c, commMap);
		}

		//System.debug( JSON.serializePretty(commTargetList) );
		//System.debug( 'commIdToCommDataMap = \n' + JSON.serializePretty(commIdToCommDataMap) );

		return commIdToCommDataMap;
	}

	public static Map<Id,Map<string,object>> getEventsForUser(MRK_UserInfo ui) {

		String profileName = ui.profileName;

		String userTargetMode = MRK_Setting.getString(SETTING_NAME, 'user target mode');
		System.debug('getEventsForUser: userTargetMode = ' + userTargetMode);

		String baseSoqlTemplate = MRK_Setting.getString(SETTING_NAME, 'communication events base soql template');
		String soql = baseSoqlTemplate;

		String soqlTemplate = MRK_Setting.getString(SETTING_NAME, 'communication events for user soql where filter template');

		if (userTargetMode == 'profile,product,sales team') {
			// filter communications only if the user has product assignments and a sales team
			if ((ui.assignedProductExternalIds.size() > 0) && (ui.salesTeamCodes.size() > 0)) {
				soql = soql + ' and ' + string.format(soqlTemplate, new String[]{'\'' + ui.profileName + '\'', stringSetJoin( ui.assignedProductExternalIds ), stringSetJoin( ui.salesTeamCodes )});
			}
		} else { // (userTargetMode == 'profile,product,territory')
			// filter communications only if the user has product assignments and has a territory
			if ((ui.assignedProductNames.size() > 0) && (ui.territoryPathDescriptionSet.size() > 0)) {
				soql = soql + ' and ' + string.format(soqlTemplate, new String[]{'\'' + ui.profileName + '\'', stringSetJoin( ui.assignedProductNames ), stringSetJoin( ui.territoryPathDescriptionSet )});
			}
		}
		
		System.debug('getEventsForUser: soql = ' + soql);		


		// String soql = 'select Id, Communication_Event_MRK__c, Profile_MRK__c, Product_MRK__c, Team_MRK__c, Type_MRK__c, Communication_Event_MRK__r.Version_MRK__c, Communication_Event_MRK__r.Name, Communication_Event_MRK__r.Status_MRK__c, Communication_Event_MRK__r.Active_MRK__c, Communication_Event_MRK__r.Start_DateTime_MRK__c, Communication_Event_MRK__r.End_DateTime_MRK__c, Communication_Event_MRK__r.Title_MRK__c, Communication_Event_MRK__r.Description_MRK__c, Communication_Event_MRK__r.Source_MRK__c, Communication_Event_MRK__r.Category_MRK__c, Communication_Event_MRK__r.Location_MRK__c, Communication_Event_MRK__r.Time_to_Complete_MRK__c, Communication_Event_MRK__r.Contact_Type_MRK__c from Communication_Event_Target_MRK__c where (Profile_MRK__c includes(:profileName)) and (Product_MRK__c includes (' + stringSetJoin( ui.assignedProductNames ) + ')) and (Team_MRK__c includes (' + stringSetJoin( ui.territoryPathDescriptionSet ) + '))';
		// System.debug('soql = ' + soql);

		List<Communication_Event_Target_MRK__c> commTargetList = Database.query(soql);
		Map<Id,Map<string,object>> eventIdToEventDataMap = new Map<Id,Map<string,object>>();
		for (Communication_Event_Target_MRK__c target : commTargetList) {
			Map<string,object> dataMap = eventIdToEventDataMap.get(target.Communication_Event_MRK__c);
			String audienceType = null;
			if (dataMap == null) {
				dataMap = new Map<string,object>();

				// store the communication/communication target object
				dataMap.put('object', target);
			} else {
				audienceType = (String)dataMap.get('audience');
			}
			
			// add to map if doesn't exist
			// if it does exist already, but is background, override with Action
			if ((audienceType == null) || ((audienceType == 'Optional') && (target.Type_MRK__c == 'Required'))) {
				dataMap.put('audience', target.Type_MRK__c);
				eventIdToEventDataMap.put(target.Communication_Event_MRK__c, dataMap);
			}

		}

		return eventIdToEventDataMap;
	}

	public static void assignEvents() {
		delete [select Id from event where RecordTypeId = :communicationEventRecordTypeId];

		List<Event> eventList = new List<Event>();
		List<User> userList = [select id from user where username = 'commrep01@merck.com.hhusc3' limit 1];
		for (User u : userList) {
			Map<Id,Map<string,object>> eventIdToEventDataMap = getEventsForUser(MRK_UserInfo.getByUserid(u.id));
			for (Map<string,object> eventData : eventIdToEventDataMap.values()) {
				Event e = createEvent(eventData, u.id);
				eventList.add(e);
			}
		}

		insert eventList;
	}

	public static Event createEvent(Map<string,object> eventData, String userid) {
		Communication_Event_Target_MRK__c ce = (Communication_Event_Target_MRK__c)eventData.get('object');

		Event e = new Event(
			Communication_Event_Version_MRK__c=ce.Communication_Event_MRK__r.Version_MRK__c,
			WhatId=ce.Communication_Event_MRK__c,
			RecordTypeId=communicationEventRecordTypeId,
			Subject=ce.Communication_Event_MRK__r.Title_MRK__c,
			Description=ce.Communication_Event_MRK__r.Description_MRK__c,
			Location=ce.Communication_Event_MRK__r.Location_MRK__c,
			ActivityDate=Date.newInstance(ce.Communication_Event_MRK__r.Start_DateTime_MRK__c.year(), ce.Communication_Event_MRK__r.Start_DateTime_MRK__c.month(), ce.Communication_Event_MRK__r.Start_DateTime_MRK__c.day()),
			ActivityDateTime=ce.Communication_Event_MRK__r.Start_DateTime_MRK__c,
			StartDateTime=ce.Communication_Event_MRK__r.Start_DateTime_MRK__c,
			EndDateTime=ce.Communication_Event_MRK__r.End_DateTime_MRK__c,
			OwnerId=userid,
			Color_vod__c=MRK_Setting.getString(SETTING_NAME, 'communication event color'),
			Category_MRK__c=ce.Communication_Event_MRK__r.Category_MRK__c,
			Source_MRK__c=ce.Communication_Event_MRK__r.Source_MRK__c,
			Time_to_Complete_MRK__c=ce.Communication_Event_MRK__r.Time_to_Complete_MRK__c,
			Contact_Type_MRK__c=ce.Communication_Event_MRK__r.Contact_Type_MRK__c,
			Audience_MRK__c=ce.Type_MRK__c
		);

		return e;
	}

	private static Boolean isEventTargetingJobQueued() {

		Boolean jobQueued = false;

		// exit if apex job is already queued
   	String apexJobClassName = MRK_Setting.getString(SETTING_NAME, 'communication event assignment job class name');
   	String apexClassId = null;   	
   	List<ApexClass> apexClassList = [select Id from ApexClass where name = :apexJobClassName and Status = 'Active'];
   	if (apexClassList.size() > 0) {
   		apexClassId = apexClassList[0].Id;
   	}

   	List<AsyncApexJob> asyncApexJobList = [select Id, JobType, ApexClassId, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, CompletedDate, MethodName, ExtendedStatus, ParentJobId, LastProcessed, LastProcessedOffset from AsyncApexJob where JobType IN ('BatchApex', 'BatchApexWorker') and Status = 'Queued' and ApexClassId = :apexClassId];
		// don't run if job already queued
		if (asyncApexJobList.size() > 0) {
			System.debug('AsyncApexJob for class "' + apexJobClassName + ' already running.');
			jobQueued = true;
		}

		return jobQueued;

	}

	public static void runAssignEventsToTargetsJob() {

		if (isEventTargetingJobQueued()) {
			return;
		}

		MRK_BatchCommunicationEventPublish b = new MRK_BatchCommunicationEventPublish('select id from User where Merck_Employee_ID_MRK__c != null limit 100', 'brian_pfeil@merck.com');
		Id batchProcessID = Database.executeBatch(b, MRK_Setting.getInteger(SETTING_NAME, 'communication event assignment job batch size'));
		System.debug('Returned batch process ID: ' + batchProcessID);
	}

	public static void deleteExpiredEvents() {
		// ***
		// clean up / delete any events older than a week old
		// ***

		/*
		List<Event> deleteEventList = new List<Event>();

		
		for (Id commEventId : commEventToAssignedUsersMap.keySet()) {
			Set<Id> userids = commEventToAssignedUsersMap.get(commEventId);
			List<Event> eventList = [select Id from Event where RecordTypeId = :communicationEventRecordTypeId and WhatId = :commEventId and OwnerId not in :userids];
			deleteEventList.addAll(deleteEventList);
		}
		delete deleteEventList;
		try {
			Database.emptyRecycleBin(deleteEventList);
		} catch (Exception e) {}
		*/
	}

	public static void communicationEventPublishForUserList(List<sObject> scope) {
   		List<Event> insertEventList = new List<Event>();
			List<Event> deleteEventList = new List<Event>();   		

     for (sObject o : scope) {
     	String userid = (String)o.get('Id');
     	MRK_UserInfo ui = MRK_UserInfo.getByUserid(userid);

     	// DEBUG: hold
			//ui.territoryPathIdList = userInfoTemplate.territoryPathIdList.clone();
			//ui.territoryPathDescriptionSet = userInfoTemplate.territoryPathDescriptionSet.clone();

			//System.debug('ui = ' + JSON.serializePretty(ui));

			Set<Id> userCommEventIdsToDelete = new Set<Id>();


			// this returns all events for user regardless of Published status, Active, Date, etc.
			Map<Id,Map<string,object>> eventIdToEventDataMap = MRK_CommunicationServices.getEventsForUser(ui);

			//System.debug('eventIdToEventDataMap = ' + JSON.serializePretty(eventIdToEventDataMap));

			// delete events where (Status_MRK__c != 'Released' or Active_MRK__c = false)
			for (Map<string,object> eventData : eventIdToEventDataMap.values()) {
				Communication_Event_Target_MRK__c cet = (Communication_Event_Target_MRK__c)eventData.get('object');

				if ((cet.Communication_Event_MRK__r.Status_MRK__c != 'Released') || (cet.Communication_Event_MRK__r.Active_MRK__c == false)) {
					userCommEventIdsToDelete.add(cet.Communication_Event_MRK__c);
				}
			}

			// identify comm events that have changed
			// -> delete corresponding user event
			// -> add new updated event

			Set<Id> userCommEventIdsToAddAsResultOfUpdate = new Set<Id>();
			Set<Id> userCommEventIdsThatDidNotChange = new Set<Id>();
			for (Event e : [select Id, WhatId, Communication_Event_Version_MRK__c from Event where RecordTypeId = :MRK_CommunicationServices.communicationEventRecordTypeId and OwnerId = :userid]) {
				Map<string,object> eventDataMap = eventIdToEventDataMap.get(e.WhatId);

				// delete if not in users target list
				if (eventDataMap == null) {
					userCommEventIdsToDelete.add(e.WhatId);
				} else {

					Communication_Event_Target_MRK__c cet = (Communication_Event_Target_MRK__c)eventDataMap.get('object');
					if (e.Communication_Event_Version_MRK__c != cet.Communication_Event_MRK__r.Version_MRK__c) {

						// update if not in the delete list
						if (!userCommEventIdsToDelete.contains(e.WhatId)) {
							userCommEventIdsToDelete.add(e.WhatId);
							userCommEventIdsToAddAsResultOfUpdate.add(e.WhatId);
						}

					} else { // event didn't change
						userCommEventIdsThatDidNotChange.add(e.WhatId);
					}
				}

			}

			// System.debug('userCommEventIdsToAddAsResultOfUpdate = ' + JSON.serializePretty(userCommEventIdsToAddAsResultOfUpdate));			
			// System.debug('userCommEventIdsToDelete = ' + JSON.serializePretty(eventIdToEventDataMap));			
			// System.debug('eventIdToEventDataMap = ' + JSON.serializePretty(eventIdToEventDataMap));

			// eventIdToEventDataMap.keySet() - userCommEventIdsToDelete + userCommEventIdsToAddAsResultOfUpdate
			Set<Id> commEventIdsToAddForUser = eventIdToEventDataMap.keySet().clone();

			// remove deleted comm events
			for (Id commEventId : userCommEventIdsToDelete) {
				commEventIdsToAddForUser.remove(commEventId);				
			}

			commEventIdsToAddForUser.addAll(userCommEventIdsToAddAsResultOfUpdate);

			//System.debug('commEventIdsToAddForUser = ' + JSON.serializePretty(commEventIdsToAddForUser));

			for (Id commEventId : commEventIdsToAddForUser) {

				if (!userCommEventIdsThatDidNotChange.contains(commEventId)) {
					Map<string,object> eventDataMap = eventIdToEventDataMap.get(commEventId);				
					Event e = MRK_CommunicationServices.createEvent(eventDataMap, userid);
					insertEventList.add(e);
				}

			}

			deleteEventList.addAll([select id from event where OwnerId = :userid and WhatId in :userCommEventIdsToDelete]);
    }

    System.debug('deleteEventList = ' + JSON.serializePretty(deleteEventList));

    delete deleteEventList;
    if (deleteEventList.size() > 0) {
    	try { Database.emptyRecycleBin(deleteEventList); } catch (Exception e) {}    	
    }

    insert insertEventList;

    System.debug('Limits.getQueries() = ' + Limits.getQueries());
    System.debug('Limits.getLimitQueries() = ' + Limits.getLimitQueries());      


    System.debug('Limits.getQueryRows() = ' + Limits.getQueryRows());
    System.debug('Limits.getLimitQueryRows() = ' + Limits.getLimitQueryRows());      

	}

	public static void runCommunicationEventPublish() {
		// 'select Id, Username from User where username like \'%commrep01%\' limit 1';
    String usersToTargetSOQL = MRK_Setting.getString(SETTING_NAME, 'users for event publish soql');    
    MRK_BatchCommunicationEventPublish b = new MRK_BatchCommunicationEventPublish(usersToTargetSOQL, 'brian_pfeil@merck.com');
		Id batchProcessID = Database.executeBatch(b, MRK_Setting.getInteger(SETTING_NAME, 'communication event publish job batch size'));
		System.debug('Returned batch process ID: ' + batchProcessID);		
	}

	public static void testCommunicationEventPublish() {
		// MRK_CommunicationUtils.purgeEventsAssociatedWithCommunicationEvents();
		// MRK_CommunicationUtils.purgeCommunicationEvents();
		// MRK_CommunicationUtils.generateCommunicationEvents();
		String usersToTargetSOQL = MRK_Setting.getString(SETTING_NAME, 'users for event publish soql');
  	communicationEventPublishForUserList( Database.query(usersToTargetSOQL) );
  	// runCommunicationEventPublish();  	
	}

	public static Map<String, MRK_UserInfo> generateMockUseridToUserInfoMap() {
		Map<String, MRK_UserInfo> useridToUserInfoMap = new Map<String, MRK_UserInfo>();
		MRK_UserInfo userInfoTemplate = MRK_UserInfo.getByUserid([select id from user where username = 'commrep01@merck.com.hhusc3'][0].Id);

		for (User u : [select Id, Profile.Name from User where Merck_Employee_ID_MRK__c != null and CompanyName != null]) {
			MRK_UserInfo ui = new MRK_UserInfo();
			ui.profileName = u.Profile.Name;
			ui.assignedProductIds = userInfoTemplate.assignedProductIds.clone();
			ui.assignedProductNames = userInfoTemplate.assignedProductNames.clone();
			ui.territoryPathIdList = userInfoTemplate.territoryPathIdList.clone();
			ui.territoryPathDescriptionSet = userInfoTemplate.territoryPathDescriptionSet.clone();
			useridToUserInfoMap.put(u.id, ui);
		}
		return useridToUserInfoMap;
	}

	public static void assignEventsToTargets(Map<String, MRK_UserInfo> useridToUserInfoMap) {

		deleteExpiredEvents();

		//, 'sales.user@merck.com.hhusc3', 'commuser@merck.com.hhusc3', 'commrep01@merck.com.hhusc3'   
  
  	/* 
    Map<String, MRK_UserInfo> useridToUserInfoMap = new Map<String, MRK_UserInfo>();
   	for (User u : [select id from user where username in ('kenneth.fernando@merck.com.hhusc3')]) {
   		useridToUserInfoMap.put(u.id, MRK_UserInfo.getByUserid(u.id));
   	}
   	*/

   	// pass useridToUserInfoMap to new EventCreatorBatchable
		
   	// TODO: remove hard coded event from SOQL
		String soql = 'select Id, Communication_Event_MRK__c, Profile_MRK__c, Product_MRK__c, Team_MRK__c, Type_MRK__c, Communication_Event_MRK__r.Name, Communication_Event_MRK__r.Start_DateTime_MRK__c, Communication_Event_MRK__r.End_DateTime_MRK__c, Communication_Event_MRK__r.Title_MRK__c, Communication_Event_MRK__r.Location_MRK__c, Communication_Event_MRK__r.Source_MRK__c, Communication_Event_MRK__r.Category_MRK__c, Communication_Event_MRK__r.Time_to_Complete_MRK__c, Communication_Event_MRK__r.Contact_Type_MRK__c from Communication_Event_Target_MRK__c where Communication_Event_MRK__r.Status_MRK__c = \'Released\' and Communication_Event_MRK__r.Active_MRK__c = true and Communication_Event_MRK__r.End_DateTime_MRK__c >= YESTERDAY and Communication_Event_MRK__r.Title_MRK__c = \'Test Event 0\'';   	
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

		List<Event> eventList = new List<Event>();
		for (String userid : userToEventListMap.keySet()) {
			Map<String,Object> eventMap = userToEventListMap.get(userid);
			for (Object cet : eventMap.values()) {
				Event e = MRK_CommunicationServices.createEvent(new Map<String,Object>{'object' => cet}, userid);
				eventList.add(e);
			}
		}

		insert eventList;


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

	}

	private static String stringSetJoin(Set<String> stringSet) {
		String result = '';
		for (String s : stringSet) {
			result += '\'' + String.escapeSingleQuotes(s) + '\',';
		}

	  // Strip terminal comma.
	  if (result.endsWith(',')) {
	     result = result.substring(0, result.lastIndexOf(','));        	
	  }

		return result;
	} 

    private static Map<String,Object> createNotification(Map<string,object> commData) {
        Communication_Target_MRK__c ct = (Communication_Target_MRK__c)commData.get('object');      
        Datetime releaseDate = ct.Communication_MRK__r.Effective_Date_MRK__c;
        //Datetime releaseDate = (Datetime)ct.Communication_MRK__r.Effective_Date_MRK__c.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        Datetime currentTime  = Datetime.now();
        if(currentTime >= releaseDate){
            Map<String,Object> n = new Map<String,Object>();
            n.put('type', 'communication');
            n.put('id', ct.Communication_MRK__c);
            //Assuming Effective_Date_MRK__c is a DateTime field
            n.put('date', releaseDate);
            //n.put('date', releaseDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''));
            // n.put('date', releaseDate.format('hh:mm a'));
            n.put('date1', releaseDate.format('MM/dd/yyyy hh:mm a'));
            //n.put('date', releaseDate.format('MM/dd/yyyy hh:mm a z'));
            n.put('title', ct.Communication_MRK__r.Title_MRK__c);
            n.put('source', ct.Communication_MRK__r.Source_MRK__c);
            n.put('read', commData.get('Read_Status_MRK__c'));
            n.put('url', '/apex/MRK_Communication?id=' + ct.Communication_MRK__c);
            return n;
        }
        else{
            return null;
        }
    }

	private static Map<String,Object> createCommunicationHeader(Map<string,object> commData) {
		Communication_Target_MRK__c ct = (Communication_Target_MRK__c)commData.get('object');
		Map<String,Object> m = createNotification(commData);
		String audience = (String)commData.get('audience');
		m.put('audience', audience);
		// TODO: put image URL in settings
		//m.put('audienceImageURL', audience == 'Action' ? '//static-01.s3.amazonaws.com/force.com-communications/images/accept.png' : '//static-01.s3.amazonaws.com/force.com-communications/images/information.png');
		m.put('audienceImageURL', MRK_CommunicationServices.getAudienceImageURL(audience));		

		m.put('name', ct.Communication_MRK__r.Name);
		m.put('summary', ct.Communication_MRK__r.Summary_MRK__c);
		m.put('category', ct.Communication_MRK__r.Category_MRK__c);
		return m;
	}

	public static List<Map<String,Object>> getCommunicationHeaderList(String userid) {
			List<Map<String,Object>> mapList = new List<Map<String,Object>>();
			Map<Id,Map<string,object>> comms = getCommunicationsForUser(userid);

			for (Map<string,object> commData : comms.values()) {
				mapList.add( createCommunicationHeader(commData) );
			}

			return mapList;
	}

	 public static List<Map<String,Object>> getNotifications(String userid) {
			
			List<Map<String,Object>> notifications = new List<Map<String,Object>>();
			Map<Id,Map<string,object>> comms = getCommunicationsForUser(userid);

			for (Map<string,object> commData : comms.values()) {
				notifications.add( createNotification(commData) );
			}

			return notifications;
	} 

	public static String getKeywordsStringForCommunication(Communication_MRK__c c) {
		String searchKeywords = c.Name + ';' + c.Title_MRK__c + ';' + c.Category_MRK__c + ';' + c.Content_Owner_MRK__c;	
		
		// truncate to 255 characters
		return (searchKeywords.length() > 255) ? searchKeywords.substring(0, 254) : searchKeywords;
	}

	public static String getKeywordsStringForCommunicationEvent(Communication_Event_MRK__c ce) {
		String searchKeywords = ce.Name + ';' + ce.Title_MRK__c + ';' + ce.Category_MRK__c + ';' + ce.Contact_Type_MRK__c + ';' + ce.Content_Owner_MRK__c;	
		
		// truncate to 255 characters
		return (searchKeywords.length() > 255) ? searchKeywords.substring(0, 254) : searchKeywords;
	}

	public static String getResourceURL() {
		 return MRK_StaticResourceUtil.getResourceURL('mrk_comms');
	}

	public static String getAudienceImageURL(String audienceType) {
		return (audienceType.toLowerCase() == 'action') ? (getResourceURL() + '/images/accept.png') : (getResourceURL() + '/images/information.png');
	}


	@HttpGet
	global static Map<String,String> getAllCommunications() {
		RestRequest req = RestContext.request;
    String userid = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
    Map<String, String> result = new Map<String,String>();
    String itemsAsJSON = JSON.serializePretty( getCommunicationHeaderList(userid) );
    result.put('items', itemsAsJSON);
    result.put('settings', JSON.serializePretty( MRK_Setting.getValues(SETTING_NAME) ));
    result.put('timestamp', DateTime.now().format('dd/MM/yy hh:mm:ss a') );
    return result;
	}

  @HttpPut
  global static String doPut(Map<String, String> data) {
		RestRequest req = RestContext.request;
    String userid = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);  	
  	List<Object> activities = (List<Object>)JSON.deserializeUntyped( data.get('activities') );

  	List<Communication_Activity_MRK__c> caList = new List<Communication_Activity_MRK__c>();
  	for (Object obj : activities) {
  		Map<String,Object> a = (Map<String,Object>)obj;
  		Communication_Activity_MRK__c ac = new Communication_Activity_MRK__c(
  			External_ID_MRK__c = userid + ';' + (String)a.get('id'),
  			Communication_MRK__c=(String)a.get('id'),
  			Read_Status_MRK__c=(String)a.get('read'),
  			User_MRK__c=userid);

			caList.add(ac);  		
  	}

  	upsert caList External_ID_MRK__c;

    return '***' + data.get('activities') + '***';
  }	

}