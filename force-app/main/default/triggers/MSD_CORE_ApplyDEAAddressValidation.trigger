trigger MSD_CORE_ApplyDEAAddressValidation on Data_Change_Request_Line_vod__c (after insert) {
    //KRB Release 6.0 7/7/2015 - This Trigger sets the DCR Status to Rejected (ootb Status to Processed)
    //When an Address Edit DCR Line item is for a DEA Valid Address and contains one of 5 Fields:
    //Name, Address_line_2_vod__c, Address_Line_3_MRK__c, City_vod__c, State_vod__c, Zip_vod__c

    
    List<Id> associatedDCRIdsList = new List<Id>();
    
    //get a list of all the associate DCRs - new Gateway Method  need DCR Id and Address Id
    for(Data_Change_Request_Line_vod__c dcrl: Trigger.new){
        associatedDCRIdsList.add(dcrl.Data_Change_Request_vod__c);
    }

    //Only need to work on the ones that are of type "Edit" and Record Type =Address_vod
    Map<Id, Data_Change_Request_vod__c> associatedAddressEditTypeDCRMap = new Map<Id, Data_Change_Request_vod__c>();
    associatedAddressEditTypeDCRMap = MSD_CORE_DCRServiceGateway.retrieveAddressEditTypeDCRMapByDCRIdList(associatedDCRIdsList);
    
    if(associatedAddressEditTypeDCRMap.isEmpty()){
       return; 
    }
    
    //get all the Address Ids of the Edit Address type DCRs - need this to determine if DEA# populated
    List<Id> addressIDList = new List<Id>();
    for(Id dcrId: associatedAddressEditTypeDCRMap.keySet()){
        addressIDList.add(associatedAddressEditTypeDCRMap.get(dcrId).Address_vod__c);
    }
    
    
     //create a MAP of all the Address Ids that have DEA Status = Valid 
     //			New Gateway method that returns Address Ids of those having DEA# populated.
     Map<Id, Address_vod__c> DEAAddressMap = new Map<Id, Address_vod__c>();
     DEAAddressMap = MSD_CORE_DCRServiceGateway.retrieveValidDEAAddressesByAddressIdList(addressIDList);
    
    //If none of the Addresses associated to the DCRL's DCR are Valid DEAs, exit out. 
    if(DEAAddressMap.isEmpty()){
       return;
    }

    //Create a Map of the DCRL coming into the Trigger and and sort/group them by Address Id <Addr Id, List<DCRL>>
    //loop through each list if any of the fields contained in the list include:  addr line 1 2 3 /city/state/zip, 
    //add the DCRL.DCR Id to a set<DCR Ids to Reject>
    //update the DCR to "Rejected" 
    
    //List<Id> DCRIdsToUpdate = new List<Id>(); 
    List<Data_Change_Request_vod__c> DCRsToUpdate = new List<Data_Change_Request_vod__c>();
    Set<Id> DCRsToUpdateIdSet = new Set<Id>();
    //Main Processing
    for(Data_Change_Request_Line_vod__c dcrl: Trigger.new){
       
       //is the the associated DCR an Address Edit Type DCR....
       if (associatedAddressEditTypeDCRMap.containsKey(dcrl.Data_Change_Request_vod__c)) {
          
          Data_Change_Request_vod__c dcr = associatedAddressEditTypeDCRMap.get(dcrl.Data_Change_Request_vod__c); 
           
          //is the Address associated to the DCR a "DEA" Address
          if(DEAAddressMap.containsKey(dcr.Address_vod__c)){
              
             //If the value of the API Name = addr line 1 2 3 /city/state/zip, reject...
              if(dcrl.Field_API_Name_vod__c == 'Name' || 
                 dcrl.Field_API_Name_vod__c == 'Address_line_2_vod__c' ||
                 dcrl.Field_API_Name_vod__c == 'Address_Line_3_MRK__c' || 
                 dcrl.Field_API_Name_vod__c == 'City_vod__c' ||
                 dcrl.Field_API_Name_vod__c == 'State_vod__c' ||
                 dcrl.Field_API_Name_vod__c == 'Zip_vod__c'|| 
                 ((dcrl.Field_API_Name_vod__c == 'Inactive_vod__c') && (dcrl.New_Value_vod__c == 'true'))
                 
                ){
                 DCRsToUpdateIdSet.add(dcr.Id);
              } 
          }   
       }     
    }

    for (Id dcrId: DCRsToUpdateIdSet){
       DCRsToUpdate.add(associatedAddressEditTypeDCRMap.get(dcrId));
    }
    
    //Update the Status of the DCRs to set them as Rejected...
    for(Data_Change_Request_vod__c dcr: DCRsToUpdate){
        dcr.MSD_CORE_DCR_Status__c = 'Rejected';
        dcr.Status_vod__c = 'Processed_vod';
    }
    
    update DCRsToUpdate;

}