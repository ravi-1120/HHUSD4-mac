/*
 * Trigger: Updates Account's Primary address to the address marked as "Primary"
 * Author: Ramesh Elapakurthi
*/
trigger MSD_CORE_Update_Account_Primary_Address on Address_vod__c (after insert, after update) {
    
    List<Id> accountIds=new List<Id>();
    for(Address_vod__c add:trigger.new){
        
        if(add.Account_vod__c!=null && add.Primary_vod__c==true && !accountIds.contains(add.Account_vod__c)) {
            System.debug('Account Id from Address:' +add.Account_vod__c);
            accountIds.add(add.Account_vod__c);
        }
            
    }
    
    if(accountIds.size()==0) return;
    
    Map<Id,Account> accountMap=new Map<Id,Account>([Select Id,MSD_CORE_Primary_Address__c,MSD_CORE_Primary_Address_Line_1__c,MSD_CORE_Primary_Address_Line_2__c,MSD_CORE_Primary_Address_Line_3__c,MSD_CORE_Primary_City__c,MSD_CORE_Primary_State__c,MSD_CORE_Primary_Zip__c from Account where Id in:accountIds]);
    
    List<Account> updateAccounts=new List<Account>();
    
    for(Address_vod__c add:trigger.new){
        if(add.Primary_vod__c!=true || add.Account_vod__c==null) continue;
        
        Account acct=accountMap.get(add.Account_vod__c);
        acct.MSD_CORE_Primary_Address__c = add.Id;
        acct.MSD_CORE_Primary_address_Line_1__c = add.Name;
        acct.MSD_CORE_Primary_address_Line_2__c = add.Address_line_2_vod__c;
        acct.MSD_CORE_Primary_Address_Line_3__c = add.Address_Line_3_MRK__c;
        acct.MSD_CORE_Primary_City__c = add.City_vod__c;
        acct.MSD_CORE_Primary_State__c = add.State_vod__c;
        acct.MSD_CORE_Primary_Zip__c = add.Zip_vod__c;  
        
        if(!updateAccounts.contains(acct)){
            system.debug('updateAccounts Id:'+ acct.Id);
            updateAccounts.add(acct);
        }
             
            
    }
    
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