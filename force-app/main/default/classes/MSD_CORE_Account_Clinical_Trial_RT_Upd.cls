/** 
 * Batch Apex Name : MSD_CORE_Account_Clinical_Trial_RT_Upd
 * This Batch Apex Class updates the VT Record Type Id based on the Source.
 */
 
global class MSD_CORE_Account_Clinical_Trial_RT_Upd implements Database.Batchable<sObject> {
global Date myDate = date.today();

    global Database.QueryLocator start(Database.BatchableContext BC) {
       String query = 'SELECT Id,RecordTypeId,MSD_CORE_Source__c FROM Stakeholder_Clinical_Trial_vod__c where RecordType.Name = \'Merck Trials\' and MSD_CORE_Source__c = \'VT\' and LastModifiedDate = Today';
      // String query1 =  'where RecordType.Name = \'Merck Trials\' and MSD_CORE_Source__c = \'VT\' and LastModifiedDate = Yesterday';       
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<Stakeholder_Clinical_trial_vod__c> scope) {
   
     Set<Id> CTIds = new Set<Id>();
     Id MISPRecordTypeId = Schema.SObjectType.Stakeholder_Clinical_Trial_vod__c.getRecordTypeInfosByName().get('MISP').getRecordTypeId();
        
          //Add Clinical Trail Ids to the set
         for(Stakeholder_Clinical_Trial_vod__c CT: Scope){
                   CTIds.add(CT.Id);
           }


//List to update the MISP Record Type
List <Stakeholder_Clinical_Trial_vod__c> CTRTUPD = new List <Stakeholder_Clinical_Trial_vod__c>();
for(Stakeholder_Clinical_Trial_vod__c C : [SELECT Id,RecordTypeId FROM Stakeholder_Clinical_Trial_vod__c WHERE Id in :CTIds])
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
mail.setSenderDisplayName('Update Stakeholder Clinical Trial MISP Record Type Batch Processing');
mail.setSubject('Update Stakeholder Clinical Trial MISP Record Type Batch Process Completed');
mail.setPlainTextBody('Update Stakeholder Clinical Trial MISP Record Type Batch Process has been completed');
 
Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}