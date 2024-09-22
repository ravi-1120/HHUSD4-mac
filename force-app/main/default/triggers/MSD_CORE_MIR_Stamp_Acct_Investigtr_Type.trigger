/* 
 * Trigger: MSD_CORE_MIR_Stamp_Acct_Investigtr_Type
 * Date: 2/27/2019
 * Author: KRB
 * Description: Stamp the Account's Investigator Type on the Custom MIR record 
 *              
 * 
 * History:
 *  2/27/2019 - Initial Creation 19R2.0
*/

trigger MSD_CORE_MIR_Stamp_Acct_Investigtr_Type on Medical_Inquiry_vod__c (before insert) {

    Set<Id> AccountIdSet = new Set<Id>();
    List<Id> AccountIdList = new List<Id>();
    Map<Id,Account> acctMap = new Map<Id,Account>();
    Map<ID,Schema.RecordTypeInfo> rt_Map = Medical_Inquiry_vod__c.sObjectType.getDescribe().getRecordTypeInfosById();

    
    for(Medical_Inquiry_vod__c medInqNew : trigger.new) {
       //if(medInqNew.RecordType.name == 'Medical Custom Request') {
        if(rt_map.get(medInqNew.recordTypeID).getName().containsIgnoreCase('Medical Custom Request')){
          if(medInqNew.Account_vod__c != null) {
             AccountIdSet.add(medInqNew.Account_vod__c);
           }
       } 
    }
    
    //Convert to List for SQL
    if(!AccountIdSet.isEmpty()){
       for(Id acctId: AccountIdSet){
                AccountIdList.add(acctId);
       }
    }
    
    //Get the investigator Type of the Accounts
    acctMap = new Map<Id, Account>([SELECT Id, 
                                           MSD_CORE_Investigator_Type__c 
                                    FROM   Account
                                    WHERE  Id in :AccountIdList]);    

    
    //Loop through Trigger Object and populate the Investtigator Type if Acct has one...

    if(!acctMap.isEmpty()){
       for(Medical_Inquiry_vod__c medInqNew : trigger.new) {
          if(rt_map.get(medInqNew.recordTypeID).getName().containsIgnoreCase('Medical Custom Request')){
              if(acctMap.containsKey(medInqNew.Account_vod__c)){
                 medInqNew.MSD_CORE_Invstgtr_Type__c = acctMap.get(medInqNew.Account_vod__c).MSD_CORE_Investigator_Type__c;
              }
           }
        }
    } 
}