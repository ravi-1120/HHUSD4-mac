/** 
 * Batch Apex Name : MRK_User_Emp_AccountId_Upd
 * This Batch Apex Class update the Employee Account Id Field on the User Object.
 */
 
global class MRK_User_Emp_AccountId_Upd implements Database.Batchable<sObject> {
global Date myDate = date.today();

    global Database.QueryLocator start(Database.BatchableContext BC) {
       String query = 'SELECT Id,Active_MRK__c,Merck_Employee_ID_MRK__c,MSD_CORE_Employee_Account_Id__c FROM User where MSD_CORE_Employee_Account_Id__c = null and Merck_Employee_ID_MRK__c != null';       
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<User> scope) {
   
       system.debug('Ankur scope ' + scope);
              system.debug('Ankur scope size ' + scope.size());
    Set<Id> UserIds = new Set<Id>();
    Set<String> EmpAcctIds = new Set<String>();
    
     //Add User Ids to the set
         for(User usr : Scope){
         system.debug('Ankur 1 ' + usr.MSD_CORE_Employee_Account_Id__c + ' ' + usr.Id + ' ' + usr.Merck_Employee_ID_MRK__c);
         if(usr.MSD_CORE_Employee_Account_Id__c == null) {
           system.debug('Ankur xyz');
            UserIds.add(usr.Id);
           }
         }
         
         for(Account Act : [SELECT Id, MSD_CORE_Merck_Employee_ID__c,RecordType.Name FROM Account WHERE RecordType.Name = 'Employee']){
         EmpAcctIds.add(Act.MSD_CORE_Merck_Employee_ID__c);
         }
         
         system.debug('Ankur User Ids ' + UserIds );
                  system.debug('Ankur User Ids size ' + UserIds.size() );
                  system.debug('Ankur User Ids ' + EmpAcctIds);
                  system.debug('Ankur User Ids size ' + EmpAcctIds.size() );
         
    Map<String,Account> EmpAcct = new Map<String,Account>();
    for(Account Acc:[SELECT Id, MSD_CORE_Merck_Employee_ID__c,RecordType.Name FROM Account WHERE RecordType.Name = 'Employee']){
    EmpAcct.put(Acc.MSD_CORE_Merck_Employee_ID__c, Acc);
    }    
         
         system.debug('Ankur EmpAcct Map ' + EmpAcct );
                  system.debug('Ankur EmpAcct Map size ' + EmpAcct.size() );
        
    //User List to be updated.
   List <User> UserList = new List <User>(); 
   for(User U : [SELECT Id,Active_MRK__c,Merck_Employee_ID_MRK__c,MSD_CORE_Employee_Account_Id__c FROM User where Id in :UserIds and Merck_Employee_ID_MRK__c in :EmpAcctIds])
    {
     U.MSD_CORE_Employee_Account_Id__c = EmpAcct.get(U.Merck_Employee_ID_MRK__c).Id;
    // system.debug('Ankur in loop ' + EmpAcct.get(U.MSD_CORE_Employee_Account_Id__c).Id);
      
   UserList.add(U);
}

system.debug('User List Update' + UserList);
system.debug('User List Update Size' + UserList.size());
Update(UserList);     
     
         
    }
    
  
        
    global void finish(Database.BatchableContext BC) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
 
//mail.setToAddresses(new String[] {email});
String[] toAddresses = new String[] {'ankur.mehrotra2@merck.com'};
mail.setToAddresses(toAddresses);
mail.setReplyTo('ankur.mehrotra2@merck.com');
mail.setSenderDisplayName('Batch Processing');
mail.setSubject('User Batch Process Completed ');
mail.setPlainTextBody('User Batch Process has completed');
 
Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}