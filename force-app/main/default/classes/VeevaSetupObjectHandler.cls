public without sharing class VeevaSetupObjectHandler {

    final String EXECUTOR_CLASS_NAME = 'VeevaCreateRecordsQueueable';
    final Integer DELAY_PER_JOB_IN_MINS = 1;
    public void createRecords(List<SObject> objectRecords) {
        if (objectRecords == null || objectRecords.isEmpty()) {
            return;
        }

        if (System.isFuture() || System.isBatch()) {
            insert objectRecords;
        } else {
            Integer delay = getDelayTimeForTasks();
            if(delay>10){
                VeevaQueuedCreatedRecordsQueueable createRecordJobsHandler = new VeevaQueuedCreatedRecordsQueueable(objectRecords);
                System.enqueueJob(createRecordJobsHandler,10);
            }else{
                VeevaCreateRecordsQueueable createRecordJobs = new VeevaCreateRecordsQueueable(objectRecords);
                System.enqueueJob(createRecordJobs,delay);
            }
        }
    }

    public Integer getDelayTimeForTasks(){
        String executorClassId = [SELECT Id FROM ApexClass WHERE Name= :EXECUTOR_CLASS_NAME LIMIT 1].Id;
        List<AsyncApexJob> pendingJobs = [SELECT Id, CreatedDate, Status FROM AsyncApexJob WHERE ApexClassId= :executorClassId AND Status in ('Holding','Queued','Processing','Preparing')];
        Integer noOfJobs = pendingJobs.size();
        Integer delay = DELAY_PER_JOB_IN_MINS*noOfJobs;
        return delay;
    }

    public void deleteRecords(List<Id> recordIds) {
        deleteRecords(recordIds, null);
    }

    public void deleteRecords(List<Id> recordIds, String objectName) {
        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }

        if (System.isFuture() || System.isBatch()) {
            delete createSObjects(recordIds, objectName);
        } else {
            deleteRecordsAsync(recordIds, objectName);
        }
    }

    public void deleteRecords(List<SObject> objectRecords) {
        if (objectRecords == null || objectRecords.isEmpty()) {
            return;
        }

        if (System.isFuture() || System.isBatch()) {
            delete objectRecords;
        } else {
            String recordsJson = Json.serialize(objectRecords);
            deleteRecordsAsync(recordsJson);
        }
    }


    @Future
    public static void deleteRecordsAsync(String recordsJson) {
        delete (List<SObject>)Json.deserialize(recordsJson, List<SObject>.class);
    }

    @Future
    public static void deleteRecordsAsync(List<Id> recordIds, String objectName) {
        delete createSObjects(recordIds, objectName);
    }

    private static List<SObject> createSObjects(List<Id> recordIds) {
        return createSObjects(recordIds, null);
    }

    private static List<SObject> createSObjects(List<Id> recordIds, String objectName) {
        List<SObject> records = new List<SObject>();
        Schema.SObjectType objectType = objectName == null? recordIds.get(0).getSObjectType(): Schema.getGlobalDescribe().get(objectName);
        for (Id recordId: recordIds) {
            records.add( objectType.newSObject(recordId) );
        }

        return records;
    }
}