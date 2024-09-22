/** 
 * Batch Apex Name : MSD_CORE_Manager_Change
 * This Batch Apex Class is designed to perform certain tasks when the reporting hierarchy is changed i.e., change in Manager.
 * @version        1.0
 * @author         Ankur Mehrotra 
 */
 
global class MSD_CORE_Manager_Change implements Database.Batchable<sObject> {
global Date myDate = date.today();

global Database.QueryLocator start(Database.BatchableContext BC) {

       
       String query = 'SELECT Id,Name,Manager.Id,MSD_CORE_Change_in_Mgr__c FROM User where Active_MRK__c = true and MSD_CORE_Change_in_Mgr__c = true';       
        return Database.getQueryLocator(query);

    }
    
    global void execute(Database.BatchableContext BC, List<User> scope) {
   
   //Set of User records where Manager is changed.
      Set<Id> UserIds = new Set<Id>();
      for(User U : Scope){
         UserIds.add(U.Id);
       }
       
       //Map contains the User & Manager Id's
       Map<Id,User> UserMap = new Map<Id,User>(); 
       UserMap = new Map<Id,User>([Select Id,ManagerId from User where Id in :UserIds]);

       //List of Coaching Reports where Manager need to be changed.
       List <Survey_Target_vod__c> CoachingReportsUpd = new List<Survey_Target_vod__c>();     
       for(Survey_Target_vod__c CoachingReport : [SELECT Id,Employee_vod__c,Coach_vod__c,Name,Recordtype.Name FROM Survey_Target_vod__c where Employee_vod__c IN :UserIds and RecordType.Name = 'Coaching_Report_vod' and Report_Status_vod__c = 'Completed_vod'])
       {
       CoachingReport.Coach_vod__c = UserMap.get(CoachingReport.Employee_vod__c).ManagerId;
       CoachingReportsUpd.add(CoachingReport);
       }

        /*
        Placeholder to write additional logic to update historical records.
        */

        //Reset the change in Manager Flag
        List <User> UserUpd = new List<User>();
        for(User U : [Select Id,MSD_CORE_Change_in_Mgr__c from User where Id in :UserIds])
        {
            U.MSD_CORE_Change_in_Mgr__c = false;
            UserUpd.add(U);
        }

     update(CoachingReportsUpd); 
       
        /*
        Placeholder for update statements.
        */
     update(UserUpd);
    }
    
    
     global void finish(Database.BatchableContext BC) {
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
     
   // mail.setToAddresses(new String[] {email});
    String[] toAddresses = new String[] {'ankur.mehrotra2@merck.com'};
    mail.setToAddresses(toAddresses);
    mail.setReplyTo('ankur.mehrotra2@merck.com');
   mail.setSenderDisplayName('Batch Processing Change in Manager');
   mail.setSubject('Batch Process Completed Change in Manager');
   mail.setPlainTextBody('Batch Process for Manager Change has completed');
     
   Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
}