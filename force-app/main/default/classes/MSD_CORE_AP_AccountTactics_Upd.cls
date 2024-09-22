/** 
 * Batch Apex Name : MSD_CORE_AP_AccountTactics_Upd
 * This Batch Apex Class updates MSD_CORE_Temp_Account_Tactics_Id__c. This field help in Account Plan Cloning. 
 * @version        1.0
 * @author         Ankur Mehrotra 
 */
 
 global class MSD_CORE_AP_AccountTactics_Upd implements Database.Batchable<sObject> {
 
 global Database.QueryLocator start(Database.BatchableContext BC) {
       String query = 'SELECT Id,MSD_CORE_Temp_Account_Tactics_Id__c FROM Account_Tactic_vod__c where MSD_CORE_Temp_Account_Tactics_Id__c = null or createddate = LAST_N_DAYS:2';       
        return Database.getQueryLocator(query);
    }
    
    
    global void execute(Database.BatchableContext BC, List<Account_Tactic_vod__c> scope) {
    
    List<Account_Tactic_vod__c> AT= new List<Account_Tactic_vod__c>();
    for(Account_Tactic_vod__c ATV: scope){
    ATV.MSD_CORE_Temp_Account_Tactics_Id__c = ATV.Id;
    AT.add(ATV);
    }
    update AT;
    //system.debug('Ankur '+ scope);
    
    }
    
    global void finish(Database.BatchableContext BC) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
 
//mail.setToAddresses(new String[] {email});
String[] toAddresses = new String[] {'ankur.mehrotra2@merck.com'};
mail.setToAddresses(toAddresses);
mail.setReplyTo('ankur.mehrotra2@merck.com');
mail.setSenderDisplayName('Batch Processing');
mail.setSubject('Batch Process Completed');
mail.setPlainTextBody('Batch Process has completed');
 
Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    }