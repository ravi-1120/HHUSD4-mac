trigger MSD_CORE_RejectUpdtsToPendingorInactvAccounts on Data_Change_Request_vod__c (before insert) {
    
    /*
    * KRB 10/2/2015 REL 6.0 - Trigger sets Status of Account EDIT DCRs to Rejected if Status
    * of the Account is Pending or Inactive  
    */ 
   
   String usrProfileName = [select u.Profile.Name from User u where u.id = :Userinfo.getUserId()].Profile.Name;
   String validationBypassProfiles = System.Label.MSD_CORE_DCR_Edit_Validation_Bypass_Profiles;
   
   Boolean isSystemAdminProfile = validationBypassProfiles.contains(usrProfileName);

   if(!isSystemAdminProfile){
       
        List<Account> associatedAccounts = new List<Account>();
        List<id> accountIds = new List<id>();

        for(Data_Change_Request_vod__c dcr: Trigger.new){
           if((dcr.Type_vod__c == 'Edit_vod') && (dcr.Account_vod__c != NULL) && 
               (dcr.RecordTypeId == RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Account_vod))){
                  accountIds.add(dcr.Account_vod__c);
           } 
        }
       
       if (accountIds.isEmpty()){
           return;
       }
       
        associatedAccounts = new List <Account>(
                     [SELECT Id,  Status_MRK__c
                      FROM   Account
                      WHERE  Id in :accountIds]);
 
       
        for(Data_Change_Request_vod__c dcr: Trigger.new){
           if((dcr.Type_vod__c == 'Edit_vod') && 
              (dcr.Account_vod__c != NULL) && 
              (dcr.RecordTypeId == RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Account_vod)) ){
                  
                 //Find the Matching Account Record
                  for(Account acct : associatedAccounts){
                      if(acct.id == dcr.Account_vod__c){
                          if((acct.Status_MRK__c == 'INACTIVE')|| (acct.Status_MRK__c == 'PENDING')) {
                               dcr.Status_vod__c = 'Rejected';
                               dcr.MSD_CORE_DCR_Status__c = 'Rejected';
                          }
                      }                      
                  }
           }
        }   
   }

}