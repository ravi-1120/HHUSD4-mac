@RestResource(urlMapping='/msdcore/recordsoperation/*')
global without sharing class MSD_CORE_RecordsOperationServices {

    // TODO: stub for future
    @HttpPost
    global static Map<String,String> doPost(Map<String, String> data) {
        Map<String,String> result = new Map<String,String>();

        String method = (String)data.get('method');
        if (method == '') {
            result = execute(data);
        }

        if (method == 'asyncExecute') {
            result = asyncExecute(data);
        }
        return result;
    }

  public static Map<String,String> createRecordsOperationJobItem(Map<String,String> opts) {
    String listAttachmentId = opts.get('listAttachmentId');

    Map<String,Object> jobItem = MSD_CORE_JobQueueService.getJobItemTemplate(opts.get('jobItemTemplate'));
    Map<String,String> jobItemParams = MSD_CORE_JobQueueService.getJobItemParamsTemplate(opts.get('jobItemTemplate'));

    Map<String,String> m = new Map<String,String>();

    if ((opts.get('jobItemTemplate') == 'listItemsUpdate') || (opts.get('jobItemTemplate') == 'listItemsDelete')) {
        String soqlWhereClauseTemplate = jobItemParams.get('soqlWhereClauseTemplate');
        String soqlWhereClause = string.format(soqlWhereClauseTemplate, new String[]{ '\'' + listAttachmentId + '\''});

        // merge in opts that were passed in
        jobItemParams.putAll(opts);

        jobItemParams.put('soqlWhereClause', soqlWhereClause);
        jobItemParams.put('listAttachmentId', listAttachmentId);
        jobItem.put('params', JSON.serializePretty(jobItemParams));

    }


    for (String key : jobItem.keySet()) {
        m.put(key, (String)jobItem.get(key));
    }

    return m;
  }

    public static Map<String,Object> createRecordsOperationJobGroup(Map<String,String> opts) {

        List<Map<String,String>> jobItemList = new List<Map<String,String>>();
        jobItemList.add( createRecordsOperationJobItem(opts) );

        Map<String,Object> jobGroup = new Map<String,Object>();
        jobGroup.put('name', 'Records Operation');
        jobGroup.put('jobItemList', jobItemList);

        return jobGroup;
    }

  public static Map<String,String> asyncExecute(Map<String,String> opts) {

    MSD_CORE_JobQueueService.addJobGroup(createRecordsOperationJobGroup(opts));
    MSD_CORE_JobQueueService.run();

    return new Map<String,String>();
  }



    public static Map<String,String> execute(Map<String,String> opts) {

        Map<String, String> result = new Map<String,String>();

        String op = opts.get('op');

        if (op == 'update') {
            result = updateOperation(opts);
        }

        if (op == 'delete') {
            result = deleteOperation(opts);
        }


        return result;
    }

    public static Map<String,String> updateOperation(Map<String,String> opts) {
        Map<String, String> result = opts.clone();

        String soqlWhereClause = opts.get('soqlWhereClause');
        String objectName = opts.get('objectName');
        String fieldName = opts.get('fieldName');
        String fieldValue = opts.get('fieldValue');
        String maxRecords = opts.get('maxRecords');

        String recordCountLeftToProcessString = opts.get('recordCountLeftToProcess');
        if (recordCountLeftToProcessString == null || recordCountLeftToProcessString == '') {
            String parentRecordSelectSoql = 'select Id, ' + opts.get('parentFieldName') + ' from ' + opts.get('parentObjectName') + ' where Id =\'' + opts.get('parentId') + '\'';
            result.put('parentRecordSelectSoql', parentRecordSelectSoql);
            sObject rec = Database.query(parentRecordSelectSoql);
            rec.put(opts.get('parentFieldName'), (opts.get('parentFieldValue') == 'inactive') ? 'inactivating' : 'activating');
            Database.SaveResult sr = Database.update(rec);

            // TODO: handle error
            if (!sr.isSuccess()) {
            }

        }

        String soql = 'select Id, ' + fieldName + ' from ' + objectName + ' where ' + soqlWhereClause + ' and ' + fieldName + ' != \'' + fieldValue + '\'';
        String soqlCount = 'select count() from ' + objectName + ' where ' + soqlWhereClause + ' and ' + fieldName + ' != \'' + fieldValue + '\'';
        soqlCount += ' limit 1';

        String soqlWithLimit = soql + ' limit ' + maxRecords;
        List<sObject> objList = Database.query(soqlWithLimit);

        for (sObject obj : objList) {
            obj.put(fieldName, fieldValue);
        }

        // TODO: error handling
        Database.SaveResult[] srList = Database.update(objList);

        Integer recordCountLeftToProcess = Database.countQuery(soqlCount);
        result.put('recordCountLeftToProcess', recordCountLeftToProcess + '');
        result.put('done', (recordCountLeftToProcess == 0) ? 'true' : 'false');

        if (recordCountLeftToProcess == 0) {
            String parentRecordSelectSoql = 'select Id, ' + opts.get('parentFieldName') + ' from ' + opts.get('parentObjectName') + ' where Id =\'' + opts.get('parentId') + '\'';
            result.put('parentRecordSelectSoql', parentRecordSelectSoql);
            sObject rec = Database.query(parentRecordSelectSoql);
            rec.put(opts.get('parentFieldName'), opts.get('parentFieldValue'));
            Database.SaveResult sr = Database.update(rec);

            // TODO: handle error
            if (!sr.isSuccess()) {
            }

        }

        return result;
    }


    public static Map<String,String> deleteOperation(Map<String,String> opts) {
        Map<String, String> result = opts.clone();

        String soqlWhereClause = opts.get('soqlWhereClause');
        String objectName = opts.get('objectName');
        String fieldName = opts.get('fieldName');
        String fieldValue = opts.get('fieldValue');
        String maxRecords = opts.get('maxRecords');

        String soql = 'select Id, ' + fieldName + ' from ' + objectName + ' where ' + soqlWhereClause;
        String soqlCount = 'select count() from ' + objectName + ' where ' + soqlWhereClause;
        soqlCount += ' limit 1';

        String soqlWithLimit = soql + ' limit ' + maxRecords;
        List<sObject> objList = Database.query(soqlWithLimit);

        /*
        for (sObject obj : objList) {
            obj.put(fieldName, fieldValue);
        }
        */

        // TODO: error handling
        Database.DeleteResult[] srList = Database.delete(objList);

        Integer recordCountLeftToProcess = Database.countQuery(soqlCount);
        result.put('recordCountLeftToProcess', recordCountLeftToProcess + '');
        result.put('done', (recordCountLeftToProcess == 0) ? 'true' : 'false');

        if (recordCountLeftToProcess == 0) {
            String parentRecordSelectSoql = 'select Id, ' + opts.get('parentFieldName') + ' from ' + opts.get('parentObjectName') + ' where Id =\'' + opts.get('parentId') + '\'';
            result.put('parentRecordSelectSoql', parentRecordSelectSoql);
            sObject rec = Database.query(parentRecordSelectSoql);
            rec.put(opts.get('parentFieldName'), opts.get('parentFieldValue'));
            Database.DeleteResult sr = Database.delete(rec);

            // TODO: handle error
            if (!sr.isSuccess()) {
            }

        }

        return result;
    }

    public static Map<String,String> postDeletedRecordsForTracking(List<sObject> objectList) {
        MSD_CORE_Logger.loggingEnabled = true;

        Map<String,String> result = new Map<String,String>();
        Boolean allSuccessfullyInserted = false;
        try {
            String countryCode = MSD_CORE_Setting.getString('RECORDS_OPERATION', 'countryCode');
            List<MSD_CORE_Deleted_Record__c> deletedRecordList = new List<MSD_CORE_Deleted_Record__c>();
            for (sObject obj : objectList) {

                // get name of object from Id
                String objectName = obj.Id.getSObjectType().getDescribe().getName();

                // fetch the settings for *this* objectName
                Map<String,String> objectDeleteSettings = (Map<String,String>)MSD_CORE_Setting.getStringToStringMap('RECORDS_OPERATION', objectName);

                // check if tracking deleted is enabled for *this* objectName
                if (objectDeleteSettings != null && objectDeleteSettings.get('enabled') == 'true') {
                    MSD_CORE_Deleted_Record__c deletedRecord = new MSD_CORE_Deleted_Record__c(
                        MSD_CORE_Country_Code__c = '',
                        MSD_CORE_Object_Name__c = objectName,
                        MSD_CORE_Record_ID__c = obj.Id,
                        MSD_CORE_Record_Name__c = (String)obj.get('Name')
                    );
                    deletedRecordList.add(deletedRecord);
                }
            }

            // see if we have any records to insert
            if (deletedRecordList.size() > 0) {
                Database.SaveResult[] saveResultList = Database.insert(deletedRecordList);
                allSuccessfullyInserted = true;
                for (Database.SaveResult saveResult : saveResultList) {
                    allSuccessfullyInserted = allSuccessfullyInserted && saveResult.isSuccess();
                }
            }

            result.put('success', allSuccessfullyInserted ? 'true' : 'false');
            result.put('allSuccessfullyInserted', allSuccessfullyInserted + '');
            result.put('deletedRecordListCount', deletedRecordList.size() + '');

        } catch (Exception e) {
            MSD_CORE_Logger.loggingEnabled = true;
            String errString = e + ', line #:' + e.getLineNumber() + '\nStack Trace:\n' + e.getStackTraceString();
            result.put('error', errString);
            result.put('success', 'false');
            MSD_CORE_Logger.error(errString);
        } finally {
            MSD_CORE_Logger.flush();
        }
        return result;
    }

}