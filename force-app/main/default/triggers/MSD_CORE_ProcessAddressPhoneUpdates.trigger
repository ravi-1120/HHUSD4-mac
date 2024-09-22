trigger MSD_CORE_ProcessAddressPhoneUpdates on Data_Change_Request_Line_vod__c (after insert) {

    /*
     * KRB 10/2/2015 - if the DCL Line Record is an Address Phone EDIT, we are updating the
     * Address' Phone Field immediately, and also writing the DCR via normal Veeva
     * OOTB Processing
     */
    
    Set <Id> dcrIdSet = new Set <Id>();
    List<Id> dcrIdList = new List<Id>();
    List<Data_Change_Request_vod__c> relatedEditDCRList = new List<Data_Change_Request_vod__c>();
    Set<Id> AddressIdSet = new Set<Id>();
    List<Id> AddressIdList = new List<Id>();
    
    for(Data_Change_Request_Line_vod__c dcrl: Trigger.new){
       if((dcrl.Field_API_Name_vod__c == 'Phone_vod__c') && (dcrl.New_Value_vod__c != '')){
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
                     [SELECT Id,  Address_vod__c
                      FROM Data_Change_Request_vod__c
                      WHERE Type_vod__c = 'Edit_vod'
                      AND RecordType.name = 'Address_vod'
                      AND Address_vod__c != null
                      AND Id in :dcrIdList]);
     
    if(relatedEditDCRList.isEmpty()){
        return;
    }
    
    List<Id> addrIdList = new List<Id>();
    
    for (Data_change_request_vod__c dcr: relatedEditDCRList){
        addrIdList.add(dcr.Address_vod__c);
    }
    
    List <Address_vod__c> relatedAddressList = new  List <Address_vod__c>();
    
    relatedAddressList = new List <Address_vod__c>(
                     [SELECT Id,  Phone_vod__c
                      FROM   Address_vod__c
                      WHERE  Id in :addrIdList]);
    
    List <Address_vod__c> addressUpdateList = new  List <Address_vod__c>();
    
    boolean foundMatch;
    for(Data_Change_Request_Line_vod__c dcrl: Trigger.new){
        System.debug('KRB: Entering Loop...' );
    
       foundMatch = false;    
       
 
       if((dcrl.Field_API_Name_vod__c == 'Phone_vod__c') && (dcrl.New_Value_vod__c != '')){
        System.debug('KRB: Field_API_Name_vod__c == Phone_vod__c' );

           
           //find the matching DCR record...
           for (Data_change_request_vod__c dcr: relatedEditDCRList){
               System.debug('KRB: find the matching DCR record...' );
               if(foundMatch == true){break;}
               
               if (dcr.id == dcrl.Data_Change_Request_vod__c){
                   System.debug('KRB: found the matching DCR record...' );
                   //now find the matching Phone Object and update the Phone Field.
                   for(Address_vod__c addr :relatedAddressList ){
                       if(addr.id == dcr.Address_vod__c){
                           System.debug('KRB: found the matching Address record...' );
                           System.debug('KRB: assigning...' + dcrl.New_Value_vod__c );

                           addr.Phone_vod__c = dcrl.New_Value_vod__c;
                           foundMatch = true;
                           addressUpdateList.add(addr);
                           break;
                       }
                   }
               }       
           }
       }
    }
 
    System.debug('KRB: addressUpdateList.isEmpty()...' + addressUpdateList.isEmpty() );

    if(!addressUpdateList.isEmpty()){
       update addressUpdateList;
    }    

}