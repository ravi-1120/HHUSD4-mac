/** 
 * Batch Apex Name : MSD_CORE_Clinical_Trial_RT_Upd
 * This Batch Apex Class updates the VT Record Type Id based on the Source.
 */
 
global class MSD_CORE_Clinical_Trial_RT_Upd implements Database.Batchable<sObject> {
global Date myDate = date.today();

    global Database.QueryLocator start(Database.BatchableContext BC) {
       String query = 'SELECT Id,RecordTypeId,MSD_CORE_Source__c FROM Clinical_Trial__c where RecordType.Name = \'Merck Trials\' and MSD_CORE_Source__c = \'VT\' and LastModifiedDate = Today';
      // String query1 =  'where RecordType.Name = \'Merck Trials\' and MSD_CORE_Source__c = \'VT\' and LastModifiedDate = Yesterday';       
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<Clinical_trial__c> scope) {
   
     Set<Id> CTIds = new Set<Id>();
     Id MISPRecordTypeId = Schema.SObjectType.Clinical_Trial__c.getRecordTypeInfosByName().get('MISP').getRecordTypeId();
        
          //Add Clinical Trail Ids to the set
         for(Clinical_Trial__c CT: Scope){
                   CTIds.add(CT.Id);
           }


//List to update the MISP Record Type
List <Clinical_Trial__c> CTRTUPD = new List <Clinical_Trial__c>();
for(Clinical_Trial__c C : [SELECT Id,RecordTypeId FROM Clinical_Trial__c WHERE Id in :CTIds])
{
   C.RecordTypeId = MISPRecordTypeId;
   CTRTUPD.add(C);
}
Update(CTRTUPD);     
}
    
       
    global void finish(Database.BatchableContext BC) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
 
//mail.setToAddresses(new String[] {email});
String[] toAddresses = new String[] {'ankur.mehrotra2@merck.com'};
mail.setToAddresses(toAddresses);
mail.setReplyTo('ankur.mehrotra2@merck.com');
mail.setSenderDisplayName('Update Clinical Trial MISP Record Type Batch Processing');
mail.setSubject('Update Clinical Trial MISP Record Type Batch Process Completed');
mail.setPlainTextBody('Update Clinical Trial MISP Record Type Batch Process has been completed');
 
Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}