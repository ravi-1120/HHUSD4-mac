//*******************************************************************************************
 //
 //    Author Jim lukens 021414 jim.lukens@veeva.com 
 //     Design to populate personaccount phone and business account phone 
 //     From the primary address phone field value for use in an HCO Veeva 
 //     Account Identifier Stamping Workflow Rule and Field Update
 //     Implemented as part of Merck CRM 5.0 Release
 //     
 //     KRB 9/4/2019 - 19R4.0 - fixed issue with Integration getting "Dupe Id in List" Error.
 //                           - fixed issue with process loading up a blank phone number on Account. 
 //    
 //******************************************************************************************
  
  trigger MRK_Address_vod_Update_Account_Phone on Address_vod__c (after insert, after update) {

     List<Id> accountIds=new List<Id>();
     Set<Id> processedAccountIds = new Set<Id>();
     Set<Id> acctIdSet= new Set<Id>();
  
     for(Address_vod__c add:trigger.new){
        if(add.Account_vod__c!=null && add.Primary_vod__c==true) acctIdSet.add(add.Account_vod__c);
     }
      
     if(!acctIdSet.isEmpty()){    
        for(Id acctId : acctIdSet ){
           accountIds.add(acctId);   
        }
     }
      
     if(accountIds.size()==0) return;
      
     Map<Id,Account> accountMap=new Map<Id,Account>(
                [Select Id,Phone,PersonHomePhone,RecordTypeId from Account where Id in:accountIds]);

     List<Account> updateAccounts=new List<Account>();
     Map<Id, Schema.RecordTypeInfo> acctRt= Account.SObjectType.getDescribe().getRecordTypeInfosByID();
  
     for(Address_vod__c add:trigger.new){
      
        if(add.Primary_vod__c!=true || add.Account_vod__c==null || add.Phone_vod__c == null ||String.isBlank(add.Phone_vod__c) ) continue;
    
        Account acct=accountMap.get(add.Account_vod__c);
        String rtName =acctRt.get(acct.RecordtypeId).getName();
    
        System.debug('KRB: Processing account id: ' + add.Account_vod__c);  
        System.debug('KRB: processedAccountIds.isEmpty(): ' + processedAccountIds.isEmpty());
    
        if(!processedAccountIds.isEmpty()){
           System.debug('KRB: processedAccountIds.contains(add.Account_vod__c): ' + processedAccountIds.contains(add.Account_vod__c));          
        }
    
        System.debug('KRB: add.Phone_vod__c: ' + add.Phone_vod__c);
     
        if (processedAccountIds.isEmpty() || !processedAccountIds.contains(add.Account_vod__c)){
        
           processedAccountIds.add(add.Account_vod__c);  
           
           System.debug('KRB: #1 - processedAccounIds was empty or the Account Id did not exist in the Set...');
           processedAccountIds.add(add.Account_vod__c);
          
           if(rtName=='HCP' || rtName=='HBP'){    
              acct.PersonHomePhone=add.Phone_vod__c;
           } else {
              acct.Phone=add.Phone_vod__c;
           }
           
           updateAccounts.add(acct);
     
     }else{
         System.debug('KRB: #2'); 
     }
            
  }
  //*******************************************************************************************
  //
  //    Inserting Records
  //    
  //*******************************************************************************************

  Database.SaveResult[] srs=Database.update(updateAccounts, true);

  for(Database.SaveResult sr : srs){
    if(!sr.isSuccess()){
      if(accountMap.containsKey(sr.getId())){
        for(Database.Error err:sr.getErrors()){
          accountMap.get(sr.getId()).addError(err.getMessage());
        }
      }
    }
  }  

}