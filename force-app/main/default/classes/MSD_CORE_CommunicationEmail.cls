/**
* This class is designed to handle a list of communication Ids. If the list contains at least one Id, 
* It triggers the execution of a batch class.
*
* @author : Charan Bhagavathi
* @version : 1.0
*/

public with sharing class MSD_CORE_CommunicationEmail {
    /**
* Invocable method to send emails to users based on communication and target records.
* This method is designed to be invoked from a Flow(MyComm Notifications).
*
* @param commId is used for List of Communication IDs to process and send emails for.
*/
    @InvocableMethod(label='Send Emails to Users')
    public static void sendEmails(List<Id> CommId) {
        if(CommId.size()>0){
            try {
                String existTargetusers ='Select Id, MyComm__c From MSD_CORE_Target_Users__c Where MyComm__c IN: CommId';
                List<MSD_CORE_Target_Users__c> targetUsers = new List<MSD_CORE_Target_Users__c>();
                targetUsers = Database.Query(existTargetusers);
                if(targetUsers.size()>0){
                    delete targetUsers;
                }
                Database.executeBatch(new MSD_CORE_BatchTargetUsers(CommId),1);
            }catch (Exception e) {
                logException(e, 'MSD_CORE_CommunicationEmail', 'sendEmails','', 'Error');
                System.debug('An exception occurred' + e.getMessage());
            }
        }
    } 
    private static void logException(Exception ex, String className, String methodName, String recordId, String logType) {
        MSD_CORE_ExceptionLogs.logException(ex, className, methodName, recordId, logType);
    }
}