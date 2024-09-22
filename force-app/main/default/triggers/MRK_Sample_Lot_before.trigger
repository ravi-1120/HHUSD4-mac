trigger MRK_Sample_Lot_before on Sample_Lot_vod__c (before insert) {

   /*
      KRB - 12/3/2012 - MRK's External Id field, External_ID_MRK__c, will be populated by Integration Processes
                        with "Win_num_Lot Number". This trigger needs to handle all other inserts not
                        done via Integration.

	  KRB - 19R4.0 8/22/2019 - Implementing Virtual Sampling for BRCs (Sample Sends) 
						Because all Virtual Samples will have "No_Lot_vod" as the Sample Lot #, and because
                        Sample Lot is unique, we need to have different logic to ensure the External_ID_MRK__c
                        is unique. 
                        NOTE: This trigger only handles Lots created due to situations where the recieving Rep
						did not have a Sample Lot record already created for the Sample Transfered the them. 
						All other Sample Lot records are created and managed by Integration. 
 
   */

     String usrProfileName = [select u.Profile.Name from User u where u.id = :Userinfo.getUserId()].Profile.Name;
 
     if (usrProfileName != 'MRK - Integration User'){
                  
        for (Sample_Lot_vod__c sampleLot: Trigger.new) {
            String usrMerckEmployeeId = [select u.Merck_Employee_ID_MRK__c from User u where u.id = :sampleLot.OwnerId].Merck_Employee_ID_MRK__c; 
            
            if (sampleLot.Name == 'No_Lot_vod'){
               sampleLot.External_ID_MRK__c = usrMerckEmployeeId +'_' + sampleLot.Sample_vod__c; 
            }else{
               sampleLot.External_ID_MRK__c = usrMerckEmployeeId +'_' + sampleLot.Name;
            }

        }
     }
}