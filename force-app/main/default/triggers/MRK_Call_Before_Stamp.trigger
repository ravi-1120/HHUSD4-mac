/**************************************************************************************
 * Trigger: MRK_Call_Before_Stamp
 * Date: 4/22/2013
 * Author: KRB
 * Description: Stamp the Merck Address Id on the Call record at the time of the Call.
 * 
 * History:
 *  4/22/2013 - Initial Creation 
 *  2/28/2014 - Stamp the Email address and the Sales Team associated to the Account 
 *              assoicated to the Call Record.
 *  3/10/2014 - KRB - Added additional stamped Fields on the Call:  Account_Email_MRK__c,
 *                    Sales_Team_Code_MRK__c and Sales_Team_MRK__c.
 *  4/9/2020 - KRB - 20R1.0.1 - Events - If Medical Event Field is populated and the EM Event is not, 
 *                                       populate the EM Event based on the associated Medical Event
 *                                       Record.   
 *  4/13/2020 - KRB - 20R1.0.1 - Events - Additional Logic Added: 
 *                                        On Insert of a call and Update of a Call, look for the following condition: 
                                          IF (the field Call2_vod__c.Medical_Event_vod__c is not null) AND 
                                          (Call2_vod__c.EM_Event_vod__c is null OR <> Call2_vod__c.Medical_Event_vod__c) AND 
                                          (Status <> Submitted>, THEN populate EM_Event with Medical Event Value
 *                               
 */
 
trigger MRK_Call_Before_Stamp on Call2_vod__c (before insert, before update) {

    
    String usrProfileName = [select u.Profile.Name from User u where u.id = :Userinfo.getUserId()].Profile.Name;
    Id MeetingBriefRTId = [Select Id from RecordType where SObjecttype = 'Call2_vod__c' and DeveloperName = 'MeetingBrief_vod'].Id; //24R2.0 Release
    
    //only want to handle UI inserted Call records. 
    if (usrProfileName != 'MRK - Integration User') {
       
        Map<Id,Address_vod__c> addrMap = new Map<Id,Address_vod__c>();
        Map<Id,Address_vod__c> shipToAddrMap = new Map<Id,Address_vod__c>();
        Map<Id,Account> callAccountMap = new Map<Id,Account>();
        Map<Id,User_Sales_Team_MRK__c> userSalesTeamMap = new Map<Id,User_Sales_Team_MRK__c>();
        Map<Id,Sales_Team_MRK__c> salesTeamMap = new Map<Id,Sales_Team_MRK__c>();
        
        System.debug('KRBDEBUG -MRK_Call_Before_Stamp on Call2_vod__c trigger');
        Set<Id> AddressIdSet = new Set<Id>();
        Set<Id> ShipToAddressIdSet = new Set<Id>();
        Set<Id> CallAccountIdSet = new Set<Id>();
        Set<Id> userIdSet = new Set<Id>();
        
        List<Id> AddressIdList = new List<Id>();
        List<Id> ShipToAddressIdList = new List<Id>();
        List<Id> CallAccountIdList = new List<Id>();
        List<Id> userIdList = new List<Id>();
        List<Id> salesTeamIdList = new List<Id>();
        
        //EM Events Processing - 20R1.0.1 KRB 4/9/2020
        Map<Id,Medical_Event_vod__c> medicalEventMap = new Map<Id,Medical_Event_vod__c>();
        Set<Id> medicalEventIdSet = new Set<Id>();
        List<Id> medicalEventIdList = new List<Id>();
        //END - EM Events Processing - 20R1.0.1 KRB 4/9/2020
        
              
        //Create a set of Ids for those records with Parent_Address data...
        for(Call2_vod__c call : trigger.new) {
            
           //EM Events Processing - 20R1.0.1 KRB 4/9/2020
           medicalEventIdSet.add(call.Medical_Event_vod__c);
            
           if(call.Parent_Address_vod__c != null) {
               System.debug('KRBDEBUG -Found a Parent Address: ' + call.Parent_Address_vod__c );
               AddressIdSet.add(call.Parent_Address_vod__c);
           }

           if(call.Ship_To_Address_vod__c != null) {
               ShipToAddressIdSet.add(call.Ship_To_Address_vod__c);
           }

           if(call.Account_vod__c != null) {
               CallAccountIdSet.add(call.Account_vod__c);
               userIdSet.add(call.CreatedById);
           }

        }
        

        //Convert the Sets into Lists to be used in the SOQL Statements below...
        if(!AddressIdSet.isEmpty()){
            for(Id addrId: AddressIdSet){
                AddressIdList.add(addrId);
            }
        }
        
        if(!ShipToAddressIdSet.isEmpty()){
            for(Id shipToAddrId: ShipToAddressIdSet){
                ShipToAddressIdList.add(shipToAddrId);
            }
        }
        
        if(!CallAccountIdSet.isEmpty()){
            for(Id callAcctId: CallAccountIdSet){
                CallAccountIdList.add(callAcctId);
            }
        }

        if(!userIdSet.isEmpty()){
            for(Id userId: userIdSet){
                userIdList.add(userId);
            }
        }
  
        //EM Events Processing - 20R1.0.1 KRB 4/9/2020
        if(!medicalEventIdSet.isEmpty()){
            for(Id medEventId: medicalEventIdSet ){
                medicalEventIdList.add(medEventId);
            }
        }
        
        if(!medicalEventIdList.isEmpty()){
            medicalEventMap = new Map<Id, Medical_Event_vod__c> ([SELECT Id, EM_Event_vod__c 
                                                              FROM Medical_Event_vod__c 
                                                              WHERE Id in: medicalEventIdList]);
        }
        //End - EM Events Processing - 20R1.0.1 KRB 4/9/2020
        
        
        addrMap = new Map<Id, Address_vod__c>([SELECT Id, 
                                                      Merck_Address_ID_MRK__c 
                                               FROM   Address_vod__c 
                                               WHERE  Id in :AddressIdList]);
             
    
        shipToAddrMap = new Map<Id, Address_vod__c>([SELECT Id, 
                                                            Phone_vod__c 
                                                     FROM   Address_vod__c 
                                                     WHERE  Id in :ShipToAddressIdList]);
        
        userSalesTeamMap = new Map<Id,User_Sales_Team_MRK__c>([SELECT Id, Sales_Team_MRK__c, User_MRK__c
                                                               FROM   User_Sales_Team_MRK__c 
                                                               WHERE  User_MRK__c in :userIdList]);
       
        callAccountMap = new Map<Id,Account>([SELECT Id, PersonEmail 
                                              FROM   Account 
                                              WHERE  Id in :CallAccountIdList]);
        
        if (!userSalesTeamMap.isEmpty()){
            for(Id ustRecId: userSalesTeamMap.keySet()){
                if(userSalesTeamMap.containsKey(ustRecId)){
                   salesTeamIdList.add(userSalesTeamMap.get(ustRecId).Sales_Team_MRK__c);
                }
            }
        
            salesTeamMap = new Map<Id,Sales_Team_MRK__c>([SELECT Id, Name, Sales_Team_Code_MRK__c
                                                          FROM   Sales_Team_MRK__c 
                                                          WHERE  Id in :salesTeamIdList]);
        }
       
    /*
     * loop through list of calls...
     * For all Submitted Calls with RecordType 'CallReport_vod', if the Parent Address 
     * and Ship To Address Ids are not null, copy the Merck Address Id and Phone 
     * from Address Record to Call.
    */    
    
    for(Call2_vod__c call : trigger.new) {
        
        //EM Events Processing - 20R1.0.1 KRB 4/9/2020 - updated 4/13/2020 for new Requirement
        system.debug('KRB: call.EM_Event_vod__c: ' + call.EM_Event_vod__c);
        system.debug('KRB: call.Medical_Event_vod__c: ' + call.Medical_Event_vod__c);
       
        if(
            ((String.isBlank(call.EM_Event_vod__c)) || 
               (String.isNotBlank(call.EM_Event_vod__c) && 
                String.isNotBlank(call.Medical_Event_vod__c) && 
                call.EM_Event_vod__c != call.Medical_Event_vod__c )
            ) 
            && String.isNotBlank(call.Medical_Event_vod__c) 
            && call.Status_vod__c != 'Submitted_vod' 
          ){ 
              System.debug('KRB: #1');
              if(medicalEventMap.containsKey(call.Medical_Event_vod__c)){
                  System.debug('KRB: #2');
                 call.EM_Event_vod__c = medicalEventMap.get(call.Medical_Event_vod__c).EM_Event_vod__c; 
              }
        }// End - EM Events Processing - 20R1.0.1 KRB 4/9/2020

      
        if((call.RecordTypeId == RT.getId(Call2_vod__c.SObjectType, RT.Name.CallReport_vod)) 
           || (call.RecordTypeId == RT.getId(Call2_vod__c.SObjectType, RT.Name.MSD_CORE_Remote_Detail))
      //   || (call.RecordTypeId == RT.getId(Call2_vod__c.SObjectType, RT.Name.MeetingBrief_vod))
            || (call.RecordTypeId == MeetingBriefRTId) //24R2.0 Release
                     ) {
           
              
           if(call.Status_vod__c == 'Submitted_vod' ){ 
              
              if(call.Parent_Address_vod__c != null) {
                  if(addrMap.containsKey(call.Parent_Address_vod__c)){
                     call.Merck_Address_ID_MRK__c = addrMap.get(call.Parent_Address_vod__c).Merck_Address_ID_MRK__c; 
                  }
              }                   

              if(call.Ship_To_Address_vod__c != null) {
                 if(shipToAddrMap.containsKey(call.Ship_To_Address_vod__c)){
                    call.Ship_To_Phone_MRK__c = shipToAddrMap.get(call.Ship_To_Address_vod__c).Phone_vod__c;
                 }
              }  
               
              //Add the Email of the Account assigned to the Call
              if(call.Account_vod__c != null) {
                 if(callAccountMap.containsKey(call.Account_vod__c)){
                    call.Account_Email_MRK__c = callAccountMap.get(call.Account_vod__c).PersonEmail;
                 }
              }  
              
              //Get the Sales Team of the Creator...(Pick the first one if there are multiple?)
              if(call.CreatedById != null){
                  system.debug('Kevin: Enter the Created By Logic...');
                  List<User_Sales_Team_MRK__c> usersSalesTeams = new List<User_Sales_Team_MRK__c> ();
                  
                  for (Id ustId : userSalesTeamMap.keySet()){
                      system.debug('Kevin: Enter the Created By Logic...');
                      User_Sales_Team_MRK__c ust = userSalesTeamMap.get(ustId);
 
                      
                      if(ust.User_MRK__c == call.CreatedById){
                          usersSalesTeams.add(ust);
                      }
                  }
                 
                  if(!usersSalesTeams.isEmpty()){
                     
                      User_Sales_Team_MRK__c ust = new User_Sales_Team_MRK__c();
                      ust = usersSalesTeams[0];
                      
                      if (salesTeamMap.containsKey(ust.Sales_Team_MRK__c)){
                          call.Sales_Team_Code_MRK__c = salesTeamMap.get(ust.Sales_Team_MRK__c).Sales_Team_Code_MRK__c;
                          call.Sales_Team_MRK__c = salesTeamMap.get(ust.Sales_Team_MRK__c).Name;
                      }
                      
                  }
                      
              }              
              
           }
        }
    }
        
        
   }  
}