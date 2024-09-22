/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_AccountPlanApprovalProcessServices.cls
* @description - Account Plan specific approval process services
* @createdate - Mar 24th, 2014
*
*/

public without sharing class MRK_AccountPlanApprovalProcessServices implements MRK_IApprovalProcessServices {

    public MRK_AccountPlanApprovalProcessServices() {

    }

    private Account_Plan_vod__c getRecord(Id objectId) {
       // return [select CreatedById, Approval_Submitter_MRK__c, Approval_Approver_MRK__c, Status__c from Account_Plan_vod__c where Id=:objectId];        
        return [select CreatedById, OwnerId, Approval_Submitter_MRK__c, Approval_Approver_MRK__c, Status__c from Account_Plan_vod__c where Id=:objectId];        
    }

    /**
     * allowSubmitForApproval
     *
     * looks at the state of the record to determine if it can be submitted
     * for approval
     */
    public Boolean allowSubmitForApproval(Id objectId, Id requestorUserId) {
        Account_Plan_vod__c ap = getRecord(objectId);

        // TODO: verify the following logic is correct
      // return (ap.Status__c == 'Draft' || ap.Status__c == 'Revisions Required') && (ap.CreatedById == requestorUserId);
        return (ap.Status__c == 'Draft' || ap.Status__c == 'Revisions Required') && (ap.OwnerId == requestorUserId);
    }

    /**
     * allowRecallApprovalRequest
     *
     * looks at the state of the record to determine if the approval request can
     * be recalled
     */
    public Boolean allowRecallApprovalRequest(Id objectId, Id requestorUserId) {
        Account_Plan_vod__c ap = getRecord(objectId);
        return ap.Status__c == 'Submitted' && (ap.Approval_Submitter_MRK__c == requestorUserId);
    }

    /**
     * allowRecallApprovalRequest
     *
     * looks at the state of the record to determine if the approval request can
     * be recalled
     */
    public Boolean allowApproveReject(Id objectId, Id requestorUserId) {
        Account_Plan_vod__c ap = getRecord(objectId);
        return ap.Status__c == 'Submitted' && (ap.Approval_Approver_MRK__c == requestorUserId);
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

        // fetch account for this account plan
        Id accountId = [select Id, Account_vod__c from Account_Plan_vod__c where Id =: recordId].Account_vod__c;

        // get territory record for approverUserid
        // KRB 2/12/2020 - out for TM2.0
        //List<UserTerritory> userTerritoryList = [select TerritoryId from UserTerritory where UserId = :approverUserid and IsActive = true];
        
        List<UserTerritory2Association> userTerritoryList = [select Territory2Id 
                                                             from   UserTerritory2Association 
                                                             where  UserId = :approverUserid 
                                                             and    IsActive = true
                                                             AND    Territory2.Territory2Model.state ='Active'];

        if (userTerritoryList.size() == 0) {
            throw new MRK_AppException('Failed to grant visibilty to this Account Plan for selected approver.  Selected Approver does not have an active territory.');
        }
        
        Id territoryId = userTerritoryList[0].Territory2Id;
        Territory2 t = [select Id, Name from Territory2 where Id = :territoryId];

        if (!isTerritoryAlignedToAccount(t.Id, accountId)) {
            try {
                alignAccount(accountId, t.Name);
            } catch (Exception e) {
                throw new MRK_AppException('Failed to grant visibilty to this Account Plan for selected approver.  Failed to align account plan account to selected approver.');
            }

        }
        
        return true;
    }

    public Boolean isTerritoryAlignedToAccount(Id territoryId, Id accountId) {
        Map<Id,Territory2> territoryIdToTerritoryMap = getTerritoriesAlignedToAccount(accountId);
        Territory2 t = (Territory2)territoryIdToTerritoryMap.get(territoryId);
        return t != null;
    }

    public Map<Id,Territory2> getTerritoriesAlignedToAccount(Id acctId) {
              
      Set<String> groupIds = new Set<String>();
      for (AccountShare acctShare : [Select UserOrGroupId From AccountShare Where AccountId=:acctId And RowCause In ('Territory','TerritoryManual', 'Territory2AssociationManual')]) {
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

      return new Map<Id,Territory2>([Select Id,Name,Description From Territory2 Where Id In :territoryIds]);
    }

    public void alignAccount(Id accountId, String territoryName) {

        Account_Territory_Loader_vod__c atl = null;

    List <Account_Territory_Loader_vod__c> atlList = [select Id, Territory_vod__c from Account_Territory_Loader_vod__c where Account_vod__c = :accountId] ;
    String delimitedTerritoryToAddString = ';' + territoryName + ';';

    // ATL record exists
    if (atlList.size() == 1) {
        atl = atlList[0];
            atl.Territory_To_Add_vod__c = delimitedTerritoryToAddString;
            update atl;     
    } else { // no existing ATL record

        // add existing territories aligned to account
        for (Territory2 t : getTerritoriesAlignedToAccount(accountId).values()) {
            delimitedTerritoryToAddString += (t.Name + ';');
        }

            atl = new Account_Territory_Loader_vod__c(
                Territory_vod__c = delimitedTerritoryToAddString,
                Account_vod__c=accountId,
                External_ID_vod__c=accountId
            );

            // *** for dev only.  remove when done ***
            /*
        try {
            MRK_Logger.loggingEnabled = true;
            MRK_Logger.debug('inserting new ATL record: ' + JSON.serializePretty(atl));
        } catch (Exception e) {} finally {
            MRK_Logger.flush();
            MRK_Logger.loggingEnabled = false;
        }
        */

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

    public String getPostSubmitForApprovalRedirectURL(Id recordId, Id submitterUserId)   {
        return '/apex/AccountPlanSubmissionLandingView?id=' + recordId;
    }

}