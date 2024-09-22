/** 
 * Batch Apex Name : MRK_Comm_Processing_DeleteAll
 * This Batch Apex Class Deletes all the records after taking the backup of MRK_COMM_PROCESSING Object.  
 * @version        1.0
 * @author         Ankur Mehrotra 
 */

global class MRK_Comm_Processing_DeleteAll implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
       String query = 'SELECT Id,Name,Communication_Target_Id__c,Comm_Name__c,Communication_Calendar__c,CT_Created_by__c,CT_CreatedDate__c,CT_LastModifiedBy__c,CT_LastModifiedDate__c,Errors__c,New_Product__c,New_Profile__c,New_Team__c,New_Type__c,No_Change__c,Observations__c,Prod_External_Id__c,Product__c,Profile__c,Ready_for_Processing__c,Sales_Team_Codes__c,Team__c,Type__c,Communication_Event_Target_Id__c,Calendar_Event_Id__c,Communication_Id__c,Last_Retarget_Date__c,Operation__c FROM MRK_MYCOMM_PROCESSING__c';       
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<MRK_MYCOMM_PROCESSING__c> scope) {
        
         //List to hold Processing Records for backup
         List<MRK_COMM_PROCESSING_BKP__c> BKP = new List<MRK_COMM_PROCESSING_BKP__c>();
                               
         for(MRK_MYCOMM_PROCESSING__c a : scope)
         {    
              MRK_COMM_PROCESSING_BKP__c bkpRecord= new MRK_COMM_PROCESSING_BKP__c();
              
              bkpRecord.Comm_Target_Id__c = a.Communication_Target_Id__c;
              bkpRecord.Communication_Event_Target_Id__c = a.Communication_Event_Target_Id__c;
              bkpRecord.Communication_Calendar__c = a.Communication_Calendar__c;
              bkpRecord.CT_Created_by__c = a.CT_Created_by__c;
              bkpRecord.CT_CreatedDate__c = a.CT_CreatedDate__c;
              bkpRecord.CT_LastModifiedBy__c = a.CT_LastModifiedBy__c;
              bkpRecord.CT_LastModifiedDate__c = a.CT_LastModifiedDate__c;
              bkpRecord.Errors__c = a.Errors__c;
              bkpRecord.New_Product__c = a.New_Product__c;
              bkpRecord.New_Profile__c = a.New_Profile__c;
              bkpRecord.New_Team__c = a.New_Team__c;
              bkpRecord.New_Type__c = a.New_Type__c;
              bkpRecord.No_Change__c = a.No_Change__c;
              bkpRecord.Observations__c =  a.Observations__c;
              bkpRecord.Prod_External_Id__c = a.Prod_External_Id__c;
              bkpRecord.Product__c = a.Product__c;
              bkpRecord.Profile__c = a.Profile__c;
              bkpRecord.Ready_for_Processing__c = a.Ready_for_Processing__c;
              bkpRecord.Sales_Team_Codes__c = a.Sales_Team_Codes__c;
              bkpRecord.Team__c = a.Team__c;
              bkpRecord.Type__c = a.Type__c;
              bkpRecord.Calendar_Event_Id__c= a.Calendar_Event_Id__c;
              bkpRecord.Communication_Id__c= a.Communication_Id__c;
              bkpRecord.Last_Retarget_Date__c= a.Last_Retarget_Date__c;
              bkpRecord.Operation__c= a.Operation__c;
                       
              BKP.add(bkpRecord);
           }
         insert BKP;
         
         // System.debug('Testing BKP '  + BKP);
         
          List<MRK_MYCOMM_PROCESSING__c> ProcLst = [select id from MRK_MYCOMM_PROCESSING__c limit 50000] ;
          if(ProcLst.size() > 0)
          delete ProcLst ;
         
         
          //System.debug('Testing ProcList'  + ProcLst);
    }   
    
        
    global void finish(Database.BatchableContext BC) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
 
//mail.setToAddresses(new String[] {email});
String[] toAddresses = new String[] {'ankur.mehrotra2@merck.com'};
mail.setToAddresses(toAddresses);
mail.setReplyTo('ankur.mehrotra2@merck.com');
mail.setSenderDisplayName('MRK Apex Batch Processing');
mail.setSubject('Batch Process Completed');
mail.setPlainTextBody('Batch Processing to Backup & Delete MRK_MYCOMM_PROCESSING__c Object has been completed');
 
Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}