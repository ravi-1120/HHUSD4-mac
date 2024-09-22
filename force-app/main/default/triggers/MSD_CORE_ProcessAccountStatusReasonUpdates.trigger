trigger MSD_CORE_ProcessAccountStatusReasonUpdates on Data_Change_Request_Line_vod__c (after insert) {
    /*
     * KRB 10/2/2015 - If the DCL Line Record is an Account Status Field EDIT, we are updating the
     * Account's Status Field immediately, and also writing the DCR via normal Veeva
     * OOTB Processing
     */

    
    Set <Id> dcrIdSet = new Set <Id>();
    List<Id> dcrIdList = new List<Id>();
    List<Data_Change_Request_vod__c> relatedEditDCRList = new List<Data_Change_Request_vod__c>();
    Set<Id> AddressIdSet = new Set<Id>();
    List<Id> AddressIdList = new List<Id>();
    
    for(Data_Change_Request_Line_vod__c dcrl: Trigger.new){
       if((dcrl.Field_API_Name_vod__c == 'Status_Reason_MRK__c') && (dcrl.New_Value_vod__c != '')){
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
                     [SELECT Id,  Account_vod__c
                      FROM Data_Change_Request_vod__c
                      WHERE Type_vod__c = 'Edit_vod'
                      AND RecordType.name = 'Account_vod'
                      AND Account_vod__c != null
                      AND Id in :dcrIdList]);
     
    if(relatedEditDCRList.isEmpty()){
        return;
    }
    
    List<Id> acctIdList = new List<Id>();
    
    for (Data_change_request_vod__c dcr: relatedEditDCRList){
        acctIdList.add(dcr.Account_vod__c);
    }
    
    List <Account> relatedAccountList = new  List <Account>();
    
    relatedAccountList = new List <Account>(
                     [SELECT Id,  Status_Reason_MRK__c
                      FROM   Account
                      WHERE  Id in :acctIdList]);
    
    List <Account> accountUpdateList = new  List <Account>();
    
    boolean foundMatch;
    for(Data_Change_Request_Line_vod__c dcrl: Trigger.new){
        System.debug('KRB: Entering Loop...' );
    
       foundMatch = false;    
       
 
       if((dcrl.Field_API_Name_vod__c == 'Status_Reason_MRK__c') && (dcrl.New_Value_vod__c != '')){
        System.debug('KRB: Field_API_Name_vod__c == Status_Reason_MRK__c' );

           
           //find the matching DCR record...
           for (Data_change_request_vod__c dcr: relatedEditDCRList){
               System.debug('KRB: find the matching DCR record...' );
               if(foundMatch == true){break;}
               
               if (dcr.id == dcrl.Data_Change_Request_vod__c){
                   System.debug('KRB: found the matching DCR record...' );
                   //now find the matching Phone Object and update the Phone Field.
                   for(Account acct :relatedAccountList ){
                       if(acct.id == dcr.Account_vod__c){
                           System.debug('KRB: found the matching Account record...' );
                           System.debug('KRB: assigning...' + dcrl.New_Value_vod__c );

                           acct.Status_Reason_MRK__c = dcrl.New_Value_vod__c;
                           foundMatch = true;
                           accountUpdateList.add(acct);
                           break;
                       }
                   }
               }       
           }
       }
    }
 
    System.debug('KRB: addressUpdateList.isEmpty()...' + accountUpdateList.isEmpty() );

    if(!accountUpdateList.isEmpty()){
       update accountUpdateList;
    }        
    
   
}