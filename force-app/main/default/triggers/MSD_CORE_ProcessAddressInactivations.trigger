trigger MSD_CORE_ProcessAddressInactivations on Data_Change_Request_Line_vod__c (after insert) {
   
    Set <Id> dcrIdSet = new Set <Id>();
    List<Id> dcrIdList = new List<Id>();
    List<Data_Change_Request_vod__c> relatedEditDCRList = new List<Data_Change_Request_vod__c>();
    Set<Id> AddressIdSet = new Set<Id>();
    List<Id> AddressIdList = new List<Id>();
    List<Data_Change_Request_vod__c> dcrDeleteList = new List<Data_Change_Request_vod__c>();
    List<Data_Change_Request_vod__c> updateDCRToRejectedList = new List<Data_Change_Request_vod__c>();

    for(Data_Change_Request_Line_vod__c dcrl: Trigger.new){
          if((dcrl.Field_API_Name_vod__c == 'Inactive_vod__c') && (dcrl.New_Value_vod__c == 'true')){
              dcrIdSet.add(dcrl.Data_Change_Request_vod__c);
          }
    }
    
    if (dcrIdSet.isEmpty()){
        return;
    }
    
    for(Id dcrId:dcrIdSet ){
       dcrIdList.add(dcrId);    
    }    
    
    relatedEditDCRList = new List <Data_change_request_vod__c>(
                     [SELECT Id,  Address_vod__c, Address_vod__r.Primary_vod__c,
                             Address_vod__r.DEA_Status_vod__c
                      FROM Data_Change_Request_vod__c
                      WHERE Type_vod__c = 'Edit_vod'
                      AND RecordType.name = 'Address_vod'
                      AND Address_vod__c != null
                      AND Id in :dcrIdList]);
    
    if(relatedEditDCRList.isEmpty()){
        return;
    }
    
    for (Data_Change_Request_vod__c dcr: relatedEditDCRList){
       for(Data_Change_Request_Line_vod__c dcrl: Trigger.new){
           if (dcrl.Data_Change_Request_vod__c == dcr.id){
              if((dcrl.Field_API_Name_vod__c == 'Inactive_vod__c')  && (dcrl.New_Value_vod__c == 'true')){
                  if (dcr.Address_vod__r.Primary_vod__c == true) {
                     //dcrl.addError('The Address Inactive Field cannot be updated to true on a Primary Address.'); 
                     
                     updateDCRToRejectedList.add(dcr); //New Code 11/15/2015
                     break;
                  } else if (dcr.Address_vod__r.DEA_Status_vod__c == 'Valid_vod'){ 
                     dcrl.addError('The Address Inactive Field cannot be updated to true on a DEA Address.'); 
                     break;                  
                  } else{ 
                    AddressIdSet.add(dcr.Address_vod__c);
                  }              
              }
          } 
       }
    }
    
    
    for (Id addrId : AddressIdSet){
        AddressIdList.add(addrId);
    }    
    
    List <Address_vod__c> relatedAddressList = new  List <Address_vod__c>();
    
    relatedAddressList = new List <Address_vod__c>(
                     [SELECT Id,  Inactive_vod__c, Primary_vod__c, DEA_Status_vod__c
                      FROM Address_vod__c
                      WHERE  Id in :AddressIdList]);
   
    List <Id> invalidAddrinactiveRequests = new List <Id>();
    
    for (Address_vod__c addr : relatedAddressList){
        if((addr.Primary_vod__c == false) &&(addr.DEA_Status_vod__c != 'Valid_vod')){
           addr.Inactive_vod__c = true;
        }
    }

    if(!relatedAddressList.isEmpty()){
       update relatedAddressList;
    }
    
    //New Code 11/12/2015
    if (!updateDCRToRejectedList.isEmpty()){
        for (Data_Change_Request_vod__c dcrToReject : updateDCRToRejectedList){
           dcrToReject.MSD_CORE_DCR_Status__c = 'Rejected';
           dcrToReject.Status_vod__c = 'Processed_vod';
        }
        
        update updateDCRToRejectedList;
    }
    
}