trigger MRK_Medical_Event_Before_Update_Insert on Medical_Event_vod__c (Before insert, Before update) {
 
 
    //KRB Rel 8.0 9/9/2016 - KOL Veeva Loaded data will not include Address Information. Made the appropriate adjustments for this. 
 
   //Get a Set of the Address Objects that are used in the Records being Passed in. 
   Set<Id> medEventAddressIds = new Set<Id>();
   
   for(Medical_Event_vod__c me : trigger.new) {
      
      if(me.Address_vod__c != null){
         medEventAddressIds.add(me.Address_vod__c);
      }
    }   
    
    //pull back a Map of the Addresses via the Set
    Map<Id,Address_vod__c> addrMap = new Map<Id, Address_vod__c>();
    
    
    
    if(!medEventAddressIds.isEmpty()){
    addrMap = new Map<Id, Address_vod__c>([SELECT Id, State_vod__c,Merck_Address_ID_MRK__c
                                               FROM   Address_vod__c 
                                               WHERE  Id in :medEventAddressIds]);
    }
    
    
    if(!addrMap.isEmpty()){
       if (Trigger.isInsert){
       //Update the State value with the Selected Address' State.
        
          for (Medical_Event_vod__c me: Trigger.new) {
           
             if(addrMap.containsKey(me.Address_vod__c)){
             
                if (me.State_MRK__c != addrMap.get(me.Address_vod__c).State_vod__c ) {
                   me.State_MRK__c = addrMap.get(me.Address_vod__c).State_vod__c;
                   me.Merck_Address_ID_MRK__c = addrMap.get(me.Address_vod__c).Merck_Address_ID_MRK__c;            
                } 
          
             }else{
                me.Address_vod__c = null;
             
             }
          }
    

       }else{ 
        /* Since this is an Update, check to see if the 
           Address changed and it is not blank/null, Update 
           the State value with the Selected Address' State.
        */
     
          for (Medical_Event_vod__c newME: Trigger.new) {
       
       
             Medical_Event_vod__c oldME = Trigger.oldMap.get(newME.ID);
                    
             if(addrMap.containsKey(newME.Address_vod__c)){
                //Don't want to delete the State field if the Address gets deleted. 
                if ((oldME.Address_vod__c != newME.Address_vod__c) && (newME.Address_vod__c != null)) {
                   newME.State_MRK__c = addrMap.get(newME.Address_vod__c).State_vod__c;
                   newME.Merck_Address_ID_MRK__c = addrMap.get(newME.Address_vod__c).Merck_Address_ID_MRK__c;            
                }
             }else{
                newME.Address_vod__c = null;
             
             } 
             
                  
          }
       
      }
   }
         
}