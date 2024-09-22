/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_CoachingReportApprovalPrcssServices.cls
* @description - Coaching Report specific approval process services
* @createdate - Apr 10th, 2014
*
*/

public without sharing class MRK_CoachingReportApprovalPrcssServices implements MRK_IApprovalProcessServices {

	public MRK_CoachingReportApprovalPrcssServices() {

	}

	private Coaching_Report_vod__c getRecord(Id objectId) {
		return [select CreatedById, OwnerId, Approval_Submitter_MRK__c, Approval_Approver_MRK__c, Status__c from Coaching_Report_vod__c where Id=:objectId];		
	}

	/**
	 * allowSubmitForApproval
	 *
	 * looks at the state of the record to determine if it can be submitted
	 * for approval
	 */
	public Boolean allowSubmitForApproval(Id objectId, Id requestorUserId) {
		Coaching_Report_vod__c rec = getRecord(objectId);

		// TODO: verify the following logic is correct
		return (rec.Status__c == 'In Progress' || rec.Status__c == 'Rejected') && (rec.CreatedById == requestorUserId);
	}

	/**
	 * allowRecallApprovalRequest
	 *
	 * looks at the state of the record to determine if the approval request can
	 * be recalled
	 */
	public Boolean allowRecallApprovalRequest(Id objectId, Id requestorUserId) {
		Coaching_Report_vod__c rec = getRecord(objectId);
		return rec.Status__c == 'Pending Approval' && (rec.Approval_Submitter_MRK__c == requestorUserId);
	}

	/**
	 * allowRecallApprovalRequest
	 *
	 * looks at the state of the record to determine if the approval request can
	 * be recalled
	 */
	public Boolean allowApproveReject(Id objectId, Id requestorUserId) {
		Coaching_Report_vod__c rec = getRecord(objectId);
		return rec.Status__c == 'Pending Approval' && (rec.Approval_Approver_MRK__c == requestorUserId);
	}

	public List<User> getAvailableApprovers(Id submitterUserid, Id objectId) {
		String objectTypeName = ((Id)objectId).getSObjectType().getDescribe().getName();
		List<User> userList = new List<User>();

		Map<String, Object> objectNameToAvailableApproversBaseSOQL = (Map<String, Object>)MRK_Setting.getObject(MRK_ApprovalProcessServices.SETTING_NAME, 'object name to available approvers base soql');
		String baseSOQL = (String)objectNameToAvailableApproversBaseSOQL.get(objectTypeName);

		for (User u : (List<User>)Database.query(baseSOQL)) {
			userList.add(u);
		}
		return userList;
	}

	public User getDefaultApprover(Id submitterUserid, Id objectId) {
		// if previous user selection was made, use that
		// otherwise; set set selected user to manager of user submitting for approval
		
		Id lastSelectedApproverUserId = [select Id, Last_Selected_Approver_MRK__c from User where Id =: submitterUserid].Last_Selected_Approver_MRK__c;
		if (lastSelectedApproverUserId != null) {
			return [select Id, Username, Name, LastName, FirstName, Title, Department from User where Id =: lastSelectedApproverUserId][0];
		}

		Id managerUserId = [select Id, ManagerId from User where Id =: submitterUserid].ManagerId;
		if (managerUserId != null) {
			return [select Id, Username, Name, LastName, FirstName, Title, Department from User where Id =: managerUserId][0];
		}

		return null;
	}

	public Boolean ensureApproverVisibiltyToObject(Id approverUserid, Id recordId) {
		
        //KRB 2/13/2020 - out for TM2.0
		//List<UserTerritory> userTerritoryList = [select TerritoryId from UserTerritory where UserId = :approverUserid and IsActive = true];
		List<UserTerritory2Association> userTerritoryList =  [SELECT Territory2Id 
                                                              FROM   UserTerritory2Association 
                                                              WHERE  UserId = :approverUserid 
                                                              AND    IsActive = true
                                                              AND    Territory2.Territory2Model.state ='Active'];
		
        
        if (userTerritoryList.size() == 0) {
			throw new MRK_AppException('Failed to grant visibilty to this Coaching Report for selected approver.  Selected Approver does not have an active territory.');
		}
        
        //KRB 2/13/2020 - out for TM2.0
		//Id approverTerritoryId = userTerritoryList[0].TerritoryId;
        Id approverTerritoryId = userTerritoryList[0].Territory2Id;
        
		Coaching_Report_vod__c rec = getRecord(recordId);
		
		Set<Id> recordOwnerTerritoryIdSet = new Set<Id>();
		MRK_UserInfo recordOwnerUserInfo = MRK_UserInfo.getByUserid(rec.OwnerId);
		recordOwnerTerritoryIdSet.addAll(recordOwnerUserInfo.territoryPathIdList);
		
		// check if the approver is anywhere in the territory hierarchy above
		// the record owner
		if ( recordOwnerTerritoryIdSet.contains(approverTerritoryId) ) {
			return true;
		}

		// approver doesn't have access to record. create a share record
		// to provide access
		try {

			Coaching_Report_vod__Share share = new Coaching_Report_vod__Share(
				AccessLevel = 'edit',
				ParentId = recordId,
				RowCause = Schema.Coaching_Report_vod__Share.RowCause.Approver_Access_MRK__c,
				UserOrGroupId = approverUserid
			);
			insert share;

		} catch (Exception e) {
			throw new MRK_AppException('Failed to grant visibilty to this Coaching Report for selected approver.\n' + e);
		}
		
		return true;
	}

	/*
	public Boolean isTerritoryAlignedToAccount(Id territoryId, Id accountId) {
		Map<Id,Territory> territoryIdToTerritoryMap = getTerritoriesAlignedToAccount(accountId);
		Territory t = (Territory)territoryIdToTerritoryMap.get(territoryId);
		return t != null;
	}

	public Map<Id,Territory> getTerritoriesAlignedToAccount(Id acctId) {
	      	  
	  Set<String> groupIds = new Set<String>();
	  for (AccountShare acctShare : [Select UserOrGroupId From AccountShare Where AccountId=:acctId And RowCause In ('Territory','TerritoryManual')]) {
	      groupIds.add(acctShare.UserOrGroupId);
	  }
	  
	  if (groupIds.size() <= 0)
	      return null;
	          
	  Set<String> territoryIds = new Set<String>();
	  for (Group gr : [Select RelatedId From Group Where Id In :groupIds]) {
	      territoryIds.add(gr.RelatedId);
	  }
	  
	  if (territoryIds.size() <= 0) {
	  	return null;
	  }

	  return new Map<Id,Territory>([Select Id,Name,Description From Territory Where Id In :territoryIds]);
	}

	public void alignAccount(Id accountId, String territoryName) {

		Account_Territory_Loader_vod__c atl = null;

    List <Account_Territory_Loader_vod__c> atlList = [select Id, Territory_vod__c from Account_Territory_Loader_vod__c where Account_vod__c = :accountId] ;
    String delimitedTerritoryToAddString = ';' + territoryName + ';';
    if (atlList.size() == 1) {
    	atl = atlList[0];
			atl.Territory_To_Add_vod__c = delimitedTerritoryToAddString;
			update atl;    	
    } else {
			atl = new Account_Territory_Loader_vod__c(
				Territory_To_Add_vod__c = delimitedTerritoryToAddString,
				Account_vod__c=accountId,
				External_ID_vod__c=accountId
			);
			insert atl;
    }

		GAS_Alignment_History_vts__c history = new GAS_Alignment_History_vts__c();
		history.Account__c = accountId;
		history.Account_Territory_Loader__c = atl.Id;
		history.End_Date_MRK__c = null;
		history.New_Territory__c = territoryName;
		history.Processed_MRK__c = false;
		history.Source_MRK__c = 'CAP';
		insert history;

	}
	*/

	public String getPostSubmitForApprovalRedirectURL(Id recordId, Id submitterUserId)	 {
		return '/' + recordId;
	}

}