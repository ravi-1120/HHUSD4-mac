/*
* InteractionLogControllerMVN
* Created By: Kevin Brace
* Created Date: 7/29/2019
* Description: Controller Class for the MSD_CORE_Quick_Action_Buttons.cmp Aura Lightning Component. 


* Change Log: 
*               KRB REL 19R4.0 7/29/2019 - Initial Version
*                
*/

public with sharing class MSD_CORE_CC_QuickActionButtonsController {
    
   @AuraEnabled
   public static String createRepFollowUpTask(Id caseId){
             
       Task repFollowUpTask = new Task();
       repFollowUpTask.Subject = Label.MSD_CORE_Rep_Follow_Up;
       repFollowUpTask.OwnerId = UserInfo.getUserId();
       repFollowUpTask.WhatId = caseId;
       Date today = Date.today();
       repFollowUpTask.ActivityDate = today.addDays(3);
       
        Savepoint sp = Database.setSavepoint();
        try{

            insert repFollowUpTask;
            system.debug('repFollowUpTask'+repFollowUpTask);
            return repFollowUpTask.Id;

        }catch(Exception e){

            Database.rollback(sp);
            return 'Exception';

        }
       
   }
    
    
     @AuraEnabled
    public static InteractionWrapper getCaseInfo(String csId){
      	InteractionWrapper wrap = new InteractionWrapper();
        wrap.objCase =  [SELECT Id, AccountId, MSD_CORE_AE_Description__c 
                         FROM Case
                         WHERE id =: csId];
        wrap.userProfile = [SELECT Profile.Name FROM User WHERE Id =: UserInfo.getUserId()].Profile.Name;
        return wrap;
    }
    
    public class InteractionWrapper{
               
        @AuraEnabled
        public Case objCase;
       
         @AuraEnabled
        public String userProfile;
    }
    
}