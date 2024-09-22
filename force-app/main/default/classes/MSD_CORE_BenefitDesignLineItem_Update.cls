/** 
 * Batch Apex Name : MSD_CORE_BenefitDesignLineItem_Update
 * This Batch Apex Class update the override done by HQ AM User Profile users. As a business rule the NULL out should happen in 60 days.  
 * @version        1.0
 * @author         Ankur Mehrotra 
 */
 
global class MSD_CORE_BenefitDesignLineItem_Update implements Database.Batchable<sObject> {
global Date myDate = date.today();

global Database.QueryLocator start(Database.BatchableContext BC) {

       system.debug('Ankur Custom Label call ' + System.label.BDLI_Override_Update);
       String query = 'SELECT Id, Name, Benefit_Design_vod__c,HQ_Updated_Date__c,MRK_Days_Since_Last_HQ_Modified__c,Copay_vod__c,Notes_vod__c,Restrictions_vod__c,Status_vod__c FROM Benefit_Design_Line_vod__c where MRK_Days_Since_Last_HQ_Modified__c = ' + System.label.BDLI_Override_Update;       
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Benefit_Design_Line_vod__c> scope) {
    
    List <Benefit_Design_Line_vod__c> BDLItemList = new List <Benefit_Design_Line_vod__c>();
      for(Benefit_Design_Line_vod__c BDLI : Scope){
            
      BDLI.Copay_vod__c = null;
      BDLI.Notes_vod__c = null;
      BDLI.Restrictions_vod__c = null;
      BDLI.Status_vod__c = null;
      BDLI.HQ_Updated_Date__c = null;
      
      BDLItemList.add(BDLI);


      }
      //system.debug('Ankur before update ' +BDLItemList );
      update(BDLItemList);     
    }
    
    
     global void finish(Database.BatchableContext BC) {
       // Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
     
    //mail.setToAddresses(new String[] {email});
   // String[] toAddresses = new String[] {'ankur.mehrotra2@merck.com'};
   // mail.setToAddresses(toAddresses);
   // mail.setReplyTo('ankur.mehrotra2@merck.com');
   // mail.setSenderDisplayName('Batch Processing');
   // mail.setSubject('Batch Process Completed');
   // mail.setPlainTextBody('Batch Process has completed');
     
   // Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
}