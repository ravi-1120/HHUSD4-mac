/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_AccountPlanHandler.cls
* @description - processing logic for the Account_Plan_vod__c object
* @createdate - Apr 1st, 2014
*
*/

public class MRK_AccountPlanHandler implements MRK_ITrigger {

    private List<Account_Plan_vod__c> accountPlansToUpdateList = new List<Account_Plan_vod__c>();
    
    public MRK_AccountPlanHandler() {
        
    }

    public void bulkBefore() {}
    
    public void bulkAfter() {

        if(!Trigger.isUpdate){
            return;
        }

        ensureSingleActivePlanForAccountAndOwner();
    }

    public void beforeInsert(SObject so) {}
    public void beforeUpdate(SObject oldSo, SObject so) {

        Account_Plan_vod__c ap = (Account_Plan_vod__c)so;
        Account_Plan_vod__c oldAp = (Account_Plan_vod__c)oldSo;
        if ( (ap.Status__c == 'Approved') && (ap.Name != oldAp.Name) ) {
            so.addError('Cannot change the name of an Account Plan once it is approved.');
        }

    }

    public void beforeDelete(SObject so) {

        if ( !MRK_AccountPlanServices.getInstance().allowDeleteAccountPlanOrChildRecords(so.Id) ) {
            so.addError('Cannot delete an Approved or Submitted Account Plan');
        } else {
            try {
                MRK_AccountPlanServices.getInstance().deleteAccountPlanChildRecords(so.Id);
            } catch (Exception e) {
                so.addError(e);
            }
        }

    }

    public void afterInsert(SObject so) {}

    public void afterUpdate(SObject oldSo, SObject so) {
        Account_Plan_vod__c ap = (Account_Plan_vod__c)so;
        Account_Plan_vod__c oldAp = (Account_Plan_vod__c)oldSo;
        if (ap.Status__c != oldAp.Status__c) {
            MRK_AccountPlanServices.getInstance().updateChildObjectRecordTypesForStatus(ap.Id, ap.Status__c);
        }
    }
    
    public void afterDelete(SObject so) {}
    
    public void andFinally() {
        // update account plans if needed
            if (accountPlansToUpdateList.size() > 0) {
            system.debug('Ankur accountPlansToUpdateList ' + accountPlansToUpdateList);
            update accountPlansToUpdateList;                
            }

    }


    // 

    /**
     * ensureSingleActivePlanForAccountAndOwner
     *
     * only a single plan can be acitve for an account + plan owner combintation
     */
    private void ensureSingleActivePlanForAccountAndOwner() {

      Set<Id> accountIds = new Set<Id>();
      Set<Id> newlyApprovedAccountPlanIds = new Set<Id>();
      Set<String> newUserAccountKeySet = new Set<String>();
      
      // fetch plans that are newly approved and [current time] >= start date
      // batch job will activate plans with a start date in the future
      for (Account_Plan_vod__c ap : (List<Account_Plan_vod__c>)trigger.new) {
        Account_Plan_vod__c oldAp = (Account_Plan_vod__c)trigger.oldMap.get(ap.ID);
        if ( (ap.Status__c == 'Approved' && oldAp.Status__c != 'Approved') &&
            (DateTime.now() >= ap.Start_Date_MRK__c) ) {
            //String userAccountKey = ap.CreatedById + '_' + ap.Account_vod__c; Commented on 5/25 as part of 7.0 release
            String userAccountKey = ap.OwnerId + '_' + ap.Account_vod__c;
            newUserAccountKeySet.add(userAccountKey);
          accountIds.add(ap.Account_vod__c);
          newlyApprovedAccountPlanIds.add(ap.Id);
        }
      }

      // exit if nothing to do
      /*
      if ( newlyApprovedAccountPlanIds.IsEmpty() ) {
        return;
      }
      */
    
    // get all account
    List<Account_Plan_vod__c> allAccountPlansForAccounts = [SELECT OwnerId,CreatedById, Account_vod__c,Active_vod__c,Status__c 
             FROM Account_Plan_vod__c
             WHERE Account_vod__c IN :accountIds AND
                   Status__c = 'Approved'];

    Map<String,List<Account_Plan_vod__c>> userAccountKeyToAccountPlanListMap = new Map<String,List<Account_Plan_vod__c>>();
    for (Account_Plan_vod__c ap : allAccountPlansForAccounts) {
        //String userAccountKey = ap.CreatedById + '_' + ap.Account_vod__c; Commented on 5/25 as part of 7.0 release
        String userAccountKey = ap.OwnerId + '_' + ap.Account_vod__c;
        List<Account_Plan_vod__c> userAccountKeyToAccountPlanList = (List<Account_Plan_vod__c>)userAccountKeyToAccountPlanListMap.get(userAccountKey);
            if (userAccountKeyToAccountPlanList == null) {
                userAccountKeyToAccountPlanList = new List<Account_Plan_vod__c>();
                userAccountKeyToAccountPlanListMap.put(userAccountKey, userAccountKeyToAccountPlanList);
            }
            userAccountKeyToAccountPlanList.add(ap);
    }

    // for each user+account combination
    for (String userAccountKey : newUserAccountKeySet) {
        List<Account_Plan_vod__c> userAccountKeyToAccountPlanList = (List<Account_Plan_vod__c>)userAccountKeyToAccountPlanListMap.get(userAccountKey);
    
        if (userAccountKeyToAccountPlanList != null) {

            // each plan for user+account combination
            for (Account_Plan_vod__c ap : userAccountKeyToAccountPlanList) {
                // not a newly approved plan
                if ( !newlyApprovedAccountPlanIds.contains(ap.Id) ) {
                    // set to inactive if active
                    if (ap.Active_vod__c == true) {
                            ap.Active_vod__c = false;
                            accountPlansToUpdateList.add(ap);
                    } else {
                        // do nothing with the plan
                    }
                } else { // newly approved plan
                    ap.Active_vod__c = true;    
                    accountPlansToUpdateList.add(ap);                   
                }
            }
        }
        }

        /*
    MRK_Logger.loggingEnabled = true;
    MRK_Logger.debug('*** ensureSingleActivePlanForAccountAndOwner ***');
    MRK_Logger.debug('allAccountPlansForAccounts\n' + JSON.serializePretty(allAccountPlansForAccounts));
    MRK_Logger.debug('newUserAccountKeySet\n' + JSON.serializePretty(newUserAccountKeySet));
    MRK_Logger.debug('userAccountKeyToAccountPlanListMap\n' + JSON.serializePretty(userAccountKeyToAccountPlanListMap));
    MRK_Logger.debug('accountPlansToUpdateList\n' + JSON.serializePretty(accountPlansToUpdateList));
    MRK_Logger.flush();
        */
        
    }

}