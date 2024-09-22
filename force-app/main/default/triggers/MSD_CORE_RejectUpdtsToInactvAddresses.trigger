trigger MSD_CORE_RejectUpdtsToInactvAddresses on Data_Change_Request_vod__c (before insert) {
    /*
    * KRB 10/2/2015 REL 6.0 - Trigger sets Status of Address EDIT DCRs to Rejected if Status
    * of the Address is Inactive  
    */ 
   
   String usrProfileName = [select u.Profile.Name from User u where u.id = :Userinfo.getUserId()].Profile.Name;
   String validationBypassProfiles = System.Label.MSD_CORE_DCR_Edit_Validation_Bypass_Profiles;
   
   Boolean isSystemAdminProfile = validationBypassProfiles.contains(usrProfileName);

   if(!isSystemAdminProfile){
       
        List<Address_vod__c> associatedAddresses = new List<Address_vod__c>();
        List<id> addressIds = new List<id>();

        for(Data_Change_Request_vod__c dcr: Trigger.new){
            
            system.debug('KRB: dcr.Type_vod__c...:' + dcr.Type_vod__c);
                        system.debug('KRB: dcr.Address_vod__c...:' + dcr.Address_vod__c);
                        system.debug('KRB: dcr.RecordTypeId...:' + dcr.RecordTypeId);
                        system.debug('KRB: RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Address_vod)...:' + RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Address_vod));
            

           if((dcr.Type_vod__c == 'Edit_vod') && 
              (dcr.Address_vod__c != NULL) && 
              (dcr.RecordTypeId == RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Address_vod))){
                  addressIds.add(dcr.Address_vod__c);
           } 
        }
       
       if(addressIds.isEmpty()){
           return;
       }
       
        associatedAddresses = new List <Address_vod__c>(
                     [SELECT Id,  Inactive_vod__c
                      FROM   Address_vod__c
                      WHERE  Id in :addressIds]);
 
       
        for(Data_Change_Request_vod__c dcr: Trigger.new){
           if((dcr.Type_vod__c == 'Edit_vod') && 
              (dcr.Address_vod__c != NULL) && 
              (dcr.RecordTypeId == RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Address_vod)) ){
                  
                 //Find the Matching Account Record
                  for(Address_vod__c addr : associatedAddresses){
                      if(addr.id == dcr.Address_vod__c){
                          if(addr.Inactive_vod__c == TRUE ) {
                                                      system.debug('KRB: Found a Match' );

                               dcr.Status_vod__c = 'Rejected';
                               dcr.MSD_CORE_DCR_Status__c = 'Rejected';
                          }
                      }                      
                  }
           }
        }   
   }

}