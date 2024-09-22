trigger MRK_Update_Address_After_Submit on Call2_vod__c (After Update) {
//9/11/2012 bjd On a Submitted call, if the Ship To address is populated, 
//look up the address and update the Address Send Status to Pending

  String usrProfileName = [select u.Profile.Name from User u where u.id = :Userinfo.getUserId()].Profile.Name;        
  //only want to handle UI inserted Campaign Targets...    
  if (usrProfileName != 'MRK - Integration User'){


    Set<Id> shipToAddressIds = new Set<Id>();
    for(Call2_vod__c theCall : trigger.new) {
        if(theCall.Status_vod__c == 'Submitted_vod' && theCall.Ship_To_Address_vod__c != NULL){
            shipToAddressIds.Add(theCall.Ship_To_Address_vod__c);
        }
    }
    
    if(!shipToAddressIds.IsEmpty()) {
        List<Address_vod__c> ADR = [Select a.Name, a.Address_line_2_vod__c, a.City_vod__c, a.State_vod__c, 
                                    a.Zip_vod__c, a.Address_Send_Status_MRK__c
                                    From Address_vod__c a where a.id in :shipToAddressIds];
        List<Address_vod__c> addrToUpdate = new List<Address_vod__c>();
        for(Address_vod__c addr : ADR) {
            for(Call2_vod__c theCall : trigger.new) {
                if(theCall.Ship_To_Address_vod__c == addr.Id){
                    //If this address not previously shipped to, change the status to Pending to stop more ships until it's validated
                    if (addr.Address_Send_Status_MRK__c == 'Unknown'){
                        addr.Address_Send_Status_MRK__c = 'Pending';
                        addrToUpdate.add(addr);
                        }    
               }

            }
        }
        if(!addrToUpdate.isEmpty()) {
            update(addrToUpdate);
        }
    }
  }
}