global class MSD_CORE_ListManagementTestSuite {

    public static void deleteLogItems() {
        delete [select Id from MSD_CORE_Log_Item__c limit 9000];
    }

    public static void deleteJobQueueGroups() {
        delete [select Id from MSD_CORE_Job_Queue_Group__c];
    }

    public static void deleteListItems() {
        delete [select Id from MSD_CORE_List_Item__c];
    }

    public static void testUnpackListAttachment(Map<String,String> opts) {

        deleteLogItems();
        deleteJobQueueGroups();
        deleteListItems();

        MSD_CORE_ListServices.asyncUnpackListAttachment(opts.get('listAttachmentId'));
    }


    public static void testUpdateRecordsOperationJob(Map<String,String> opts) {

        deleteLogItems();
        deleteJobQueueGroups();

        MSD_CORE_RecordsOperationServices.asyncExecute(opts);
    }

    public static void verifyTestUpdateRecordsOperationJob(Map<String,String> opts) {
        MSD_CORE_Logger.loggingEnabled = true;
        Map<String,String> params = (Map<String,String>)MSD_CORE_Setting.getStringToStringMap('LIST_MANAGER', 'updateRecordsOperationJobParamsTemplate');
        String listAttachmentId = opts.get('listAttachmentId');
        String fieldName = params.get('fieldName');
        String fieldValue = params.get('fieldValue');

        String totalCountQuery = 'select count() from MSD_CORE_List_Item__c where MSD_CORE_List_Attachment__c = \'' + listAttachmentId + '\'';
        String filteredCountQuery = 'select count() from MSD_CORE_List_Item__c where MSD_CORE_List_Attachment__c = \'' + listAttachmentId + '\' and ' + fieldName + ' = \'' + fieldValue + '\'';

        Integer totalCount = Database.countQuery(totalCountQuery);
        Integer filteredCount = Database.countQuery(filteredCountQuery);

        if ((totalCount != 0) && (totalCount == filteredCount)) {
            MSD_CORE_Logger.debug('MSD_CORE_ListManagementTestSuite.verifyTestUpdateRecordsOperationJob: SUCCESS. totalCount=' + totalCount + ', filteredCount=' + filteredCount);
        } else {
            MSD_CORE_Logger.debug('MSD_CORE_ListManagementTestSuite.verifyTestUpdateRecordsOperationJob: FAIL. totalCount=' + totalCount + ', filteredCount=' + filteredCount);
        }
        MSD_CORE_Logger.flush();
    }

    public static void testAccountMatchJob(Map<String,String> opts) {
        deleteLogItems();

        MSD_CORE_ListServices.asyncAccountMatch(opts.get('listAttachmentId'));
    }

    public static void testExportToAttachmentJob(Map<String,String> opts) {
        deleteLogItems();

        Map<String,String> jobOpts = (Map<String,String>)MSD_CORE_Setting.getStringToStringMap('LIST_MANAGER', 'exportToAttachmentJobOptions');
        Map<String,String> params = (Map<String,String>)MSD_CORE_Setting.getStringToStringMap('LIST_MANAGER', 'exportToAttachmentJobParamsTemplate');
        params.putAll(opts);
        jobOpts.put('params', JSON.serializePretty(params));
        MSD_CORE_JobQueueService.addJob(jobOpts);
        MSD_CORE_JobQueueService.run();
    }

}