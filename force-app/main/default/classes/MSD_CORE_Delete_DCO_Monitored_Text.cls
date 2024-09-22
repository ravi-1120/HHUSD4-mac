global class MSD_CORE_Delete_DCO_Monitored_Text implements Database.Batchable<sObject> {
global Date myDate = date.today();

    global Database.QueryLocator start(Database.BatchableContext BC) {
       String query = 'Select Id from MSD_CORE_DCO_Monitored_Text__c'; 
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<Monitored_Text_vod__c > scope) {
   
   //Delete DCO Monitored Text Violation Object
    List<MSD_CORE_DCO_Monitored_Text__c> ProcLst = [select id from MSD_CORE_DCO_Monitored_Text__c limit 50000] ;
          if(ProcLst.size() > 0)
          delete ProcLst ;
    
       
}
    
       
    global void finish(Database.BatchableContext BC) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
 
//mail.setToAddresses(new String[] {email});
String[] toAddresses = new String[] {'ankur.mehrotra2@merck.com'};
mail.setToAddresses(toAddresses);
mail.setReplyTo('ankur.mehrotra2@merck.com');
mail.setSenderDisplayName('DCO Monitored Text Deletion');
mail.setSubject('DCO Monitored Text Deletion complete');
mail.setPlainTextBody('DCO Monitored Text Deletion complete');
 
Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}