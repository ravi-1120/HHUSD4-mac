/* 
 * Trigger: MSD_CORE_ACCOUNT_EM_EVENT
 * 
 * Trigger created to handle EM Events Logic on Account
 * 
 * Author: Kevin Brace
 * 
 * Change Log: 
 * KRB 6/21/2019 - Initial Version - added Logic to process Account.PW_Client_ID__c Field Update needed for PW  
*/

trigger MSD_CORE_ACCOUNT_EM_EVENT on Account (before insert, before update) {

   if (Trigger.isBefore){
       
      if(Trigger.isUpdate){
         
         for(Account acct: Trigger.new){

            //If the Merck Id Changes from one value to another...
            if((!String.isBlank(Trigger.oldMap.get(acct.ID).Merck_ID_MRK__c)) 
               && (!String.isBlank(acct.Merck_ID_MRK__c)) 
               && (Trigger.oldMap.get(acct.ID).Merck_ID_MRK__c != acct.Merck_ID_MRK__c)){
              
               acct.PW_Client_ID__c = acct.Merck_ID_MRK__c;
            }
            
            //If the Merck Id was Blank but now has Value... 
            if((String.isBlank(Trigger.oldMap.get(acct.ID).Merck_ID_MRK__c)) && 
               (!String.isBlank(acct.Merck_ID_MRK__c) )){

               acct.PW_Client_ID__c = acct.Merck_ID_MRK__c;     
            }
         }
      }
    
      if(Trigger.isInsert){
      
         for(Account acct: Trigger.new){
            if (!String.isBlank(acct.Merck_ID_MRK__c)){
               acct.PW_Client_ID__c = acct.Merck_ID_MRK__c;
            }
         }
      }
       
   }
}