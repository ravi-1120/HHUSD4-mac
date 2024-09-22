/**
* Component Name:      MSD_CORE_OTPPurgeJob
* Created By:          Focal CXM
* Description:         Schedulable batch class to purge old OTP records
* Test Class:          MSD_CORE_OTPPurgeJobTest
*/
global without sharing class MSD_CORE_OTPPurgeJob implements Schedulable, Database.Batchable<sObject> {
    global void execute(SchedulableContext SC) {
        MSD_CORE_OTPPurgeJob b = new MSD_CORE_OTPPurgeJob();
        Database.executeBatch(b);
    }
    
    global Database.Querylocator start(Database.BatchableContext bc){
        return Database.getQuerylocator('SELECT Id, MSD_CORE_Type__c FROM MSD_CORE_OTP__c WHERE MSD_CORE_Expiration_DateTime__c < YESTERDAY AND MSD_CORE_Expired__c = True');
    } 
    
    global void execute(Database.BatchableContext bc, List<MSD_CORE_OTP__c> scope){
        try{
            delete scope;
        }catch(Exception e){

        }
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}