public class MSD_Core_VeevaGwetIntegrationLogHelper {
    
    //Method to return virtual event and it's log map
    public List<MSD_Virtual_Event_Publisher_Log__c> getvEventLogDetails(Set<Id> EventIds){
        //Query Virutal Event Log table
        List<MSD_Virtual_Event_Publisher_Log__c> vEventLog = new List<MSD_Virtual_Event_Publisher_Log__c>();
        vEventLog = [Select Id,EventId__c from MSD_Virtual_Event_Publisher_Log__c Where EventId__c =:EventIds Order By CreatedDate ASC];
        
        return vEventLog;
    }

}