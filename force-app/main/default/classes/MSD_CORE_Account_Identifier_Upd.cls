/***
 * Batch Apex Name : MSD_CORE_Account_Identifier_Upd
 * This Batch Apex Class is programmed to initially perform a bulk update to update CM Id on Account Identifier field.
 */
 
global class MSD_CORE_Account_Identifier_Upd implements Database.Batchable<sObject> {
global Date myDate = date.today();

    global Database.QueryLocator start(Database.BatchableContext BC) {
      String query = 'SELECT Id,Account_Identifier_vod__c,External_ID_vod__c,Merck_ID_MRK__c FROM Account where Merck_ID_MRK__c != null'; //full load
      
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<Account> scope) {
   
     Set<Id> AccountIds = new Set<Id>();        
         for(Account CT: Scope){
                   AccountIds.add(CT.Id);
           }


//List to update the Account
List <Account> AccUpd = new List <Account>();
for(Account A : [SELECT Id,Account_Identifier_vod__c,Merck_ID_MRK__c FROM Account WHERE Id in :AccountIds])
{
   A.Account_Identifier_vod__c = A.Merck_ID_MRK__c;
   //A.Account_Identifier_vod__c = 'xxxxxxxx';
   AccUpd.add(A);
}
Update(AccUpd);     
}
    
       
    global void finish(Database.BatchableContext BC) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
 
//mail.setToAddresses(new String[] {email});
String[] toAddresses = new String[] {'ankur.mehrotra2@merck.com'};
mail.setToAddresses(toAddresses);
mail.setReplyTo('ankur.mehrotra2@merck.com');
mail.setSenderDisplayName('Update Account Identifier Batch Processing');
mail.setSubject('Update Account Identifier Batch Processing');
mail.setPlainTextBody('Update Account Identifier Batch Processinge Batch Process has been completed');
 
Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}