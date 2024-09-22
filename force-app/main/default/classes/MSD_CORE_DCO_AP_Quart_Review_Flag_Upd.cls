/** 
 * Batch Apex Name : MSD_CORE_DCO_AP_Quart_Review_Flag_Upd
 * This Batch Apex Class is programmed to update the Quarterly Review checkbox set by the DCO's
 */
 
global class MSD_CORE_DCO_AP_Quart_Review_Flag_Upd implements Database.Batchable<sObject> {
global Date myDate = date.today();

    global Database.QueryLocator start(Database.BatchableContext BC) {
       String query = 'SELECT Id,Name, MSD_CORE_Quarterly_Review__c FROM Account_Plan_vod__c where MSD_CORE_Quarterly_Review__c = true';       
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<Account_Plan_vod__c> scope) {
   
     Set<Id> AccountPlanIds = new Set<Id>();
   
          //Add Account Ids to the set
         for(Account_Plan_vod__c AP : Scope){
         if(AP.MSD_CORE_Quarterly_Review__c == true) {
            AccountPlanIds.add(AP.Id);
           }
         }
   
 
//List to update the Account Plan records.
List <Account_Plan_vod__c> APtoUpdate = new List <Account_Plan_vod__c>();
for(Account_Plan_vod__c APTU : [Select Id,Name,MSD_CORE_Quarterly_Review__c from Account_Plan_vod__c Where Id in :AccountPlanIds])
{
   
   APTU.MSD_CORE_Quarterly_Review__c = false;
    
   APtoUpdate.add(APTU);
}
Update(APtoUpdate);     

    
   }
    
        
    global void finish(Database.BatchableContext BC) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
 
//mail.setToAddresses(new String[] {email});
String[] toAddresses = new String[] {'ankur.mehrotra2@merck.com'};
mail.setToAddresses(toAddresses);
mail.setReplyTo('ankur.mehrotra2@merck.com');
mail.setSenderDisplayName('Batch Processing');
mail.setSubject('Batch Process Completed to Update DCO AP Quarterly Review Flag');
mail.setPlainTextBody('Batch Process Completed to Update DCO AP Quarterly Review Flag');
 
Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}