@RestResource(urlMapping='/msdcore/exporttoattachment/*')
global without sharing class MSD_CORE_ExportToAttachmentServices {


  @HttpPost
  global static Map<String,String> doPost(Map<String, String> data) {
    Map<String,String> result = new Map<String,String>();

    String method = (String)data.get('method');
    if (method == 'unpackListAttachment') {
        // result = unpackListAttachment(data);
    }

    if (method == 'asyncExportToAttachment') {
        result = asyncExportToAttachment(data);
    }

    return result;
  }


  public static Map<String,String> createExportToAttachmentJobItem(Map<String,String> opts) {

    Map<String,Object> jobItem = MSD_CORE_JobQueueService.getJobItemTemplate('exportToAttachment');
    Map<String,String> jobItemParams = MSD_CORE_JobQueueService.getJobItemParamsTemplate('exportToAttachment');

    // merge in opts that were passed in
    jobItemParams.putAll(opts);

    jobItem.put('params', JSON.serializePretty(jobItemParams));

    Map<String,String> m = new Map<String,String>();

    for (String key : jobItem.keySet()) {
        m.put(key, (String)jobItem.get(key));
    }

    return m;
  }

    public static Map<String,Object> createExportToAttachmentJobGroup(Map<String,String> opts) {

        List<Map<String,String>> jobItemList = new List<Map<String,String>>();
        jobItemList.add( createExportToAttachmentJobItem(opts) );

        Map<String,Object> jobGroup = new Map<String,Object>();
        jobGroup.put('name', 'Export to Attachment');
        jobGroup.put('jobItemList', jobItemList);

        return jobGroup;
    }

public static Map<String,String> asyncExportToAttachment(Map<String,String> opts) {

    MSD_CORE_JobQueueService.addJobGroup(createExportToAttachmentJobGroup(opts));
    MSD_CORE_JobQueueService.run();

    return new Map<String,String>();
  }

  global static Map<String,String> exportToAttachment(Map<String, String> opts) {


      MSD_CORE_Logger.loggingEnabled = true;

      MSD_CORE_Logger.debug('MSD_CORE_ExportToAttachmentServices.exportToAttachment: start ' + JSON.serializePretty(opts));

      Map<String, String> result = new Map<String,String>();

      try {
          String op = (String)opts.get('op');

        String totalRecordsExportedString = opts.get('totalRecordsExported');
        Integer totalRecordsExported;
        if (totalRecordsExportedString == null) {
            totalRecordsExported = 0;
        }

        String lastExportedId = opts.get('lastExportedId');

        String batchSize = opts.get('batchSize');
        String selectFields = opts.get('selectFields');
        String objectName = opts.get('objectName');
        String whereClauseTemplate = opts.get('whereClauseTemplate');
        String type = opts.get('type');
        whereClauseTemplate = whereClauseTemplate.replace('{matched}', (type == 'matched' ? 'true' : 'false'));
        String whereClause = whereClauseTemplate.replace('{listAttachmentId}', opts.get('listAttachmentId'));
        if (lastExportedId != null) {
            whereClause += (' and Id > \'' + lastExportedId + '\'');
        }
        String orderByClause = opts.get('orderByClause');
        String soql = 'select ' + selectFields + ' from ' + objectName + ' where ' + whereClause + ' ' + orderByClause;
        String soqlWithLimit = soql + ' limit ' + batchSize;
        String countSoql = 'select count() from ' + objectName + ' where ' + whereClause;

        opts.put('soqlWithLimit', soqlWithLimit);

          if (op == 'createNewAttachment') {

            // ***
            MSD_CORE_Export_To_Attachment_Task__c eta = new MSD_CORE_Export_To_Attachment_Task__c(
                MSD_CORE_Query__c = soql,
                MSD_CORE_Status__c = 'exporting',
                MSD_CORE_Country_Code__c = MSD_CORE_Setting.getString('LIST_MANAGER', 'countryCode'),
                MSD_CORE_Related_Record_ID__c = opts.get('listAttachmentId')
            );
            Database.SaveResult etaSr = Database.insert(eta);

            // TODO: handle error
            if (!etaSr.isSuccess()) {
                // return MSD_CORE_BaseServices.halt(opts);
            }


            String exportToAttachmentTaskId = etaSr.getId();
            result.put('exportToAttachmentTaskId',  exportToAttachmentTaskId);
            // ***

            result.putAll(getDataFromQuery(opts));

            Attachment a = new Attachment();
            a.ContentType = opts.get('contentType');
            a.Body = Blob.valueOf(result.get('data'));
            a.Name = opts.get('attachmentName');
            a.parentId = exportToAttachmentTaskId;

            MSD_CORE_Logger.debug('MSD_CORE_ExportToAttachmentServices.exportToAttachment: before attachment insert');
            Database.SaveResult sr = Database.insert(a);
            MSD_CORE_Logger.debug('MSD_CORE_ExportToAttachmentServices.exportToAttachment: after attachment insert');


            if (sr.isSuccess()) {
                result.put('attachmentId', sr.getId() + '');
            } else {
                String errStr = '';
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');
                    errStr = errStr + err.getStatusCode() + ': ' + err.getMessage() + '\n';
                    errStr = errStr + 'fields that affected this error: ' + err.getFields();
                }
                result.put('error', errStr);
                result.put('done', 'true');
            }

          }

          if (op == 'appendToAttachment') {

            MSD_CORE_Logger.debug('MSD_CORE_ExportToAttachmentServices.exportToAttachment: begin appendToAttachment');
            result.putAll(getDataFromQuery(opts));

            Id attachmentId = (Id)opts.get('attachmentId');
            result.put('attachmentId', attachmentId + '');
            Attachment a = [select Name, Description, Body from Attachment where Id = :attachmentId][0];
            Blob b = a.Body;
            String contents = b.toString();
            a.Body = Blob.valueOf(contents + '\n' + result.get('data'));
            Database.SaveResult sr = Database.update(a);

            if (sr.isSuccess()) {
                result.put('attachmentId', sr.getId() + '');
            } else {
                String errStr = '';
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');
                    errStr = errStr + err.getStatusCode() + ': ' + err.getMessage() + '\n';
                    errStr = errStr + 'fields that affected this error: ' + err.getFields();
                }
                result.put('error', errStr);
            }

          }

        // remove data so we don't log it.  can be very large
        result.remove('data');

        //totalRecordsExported += Integer.valueOf(batchSize);
        //Integer totalRecordsToExport = Database.countQuery(countSoql);
        //result.put('done', (totalRecordsToExport == totalRecordsExported) ? 'true' : 'false');

        if (result.get('done') == 'false') {
            result.put('op', 'appendToAttachment');
        } else {
            // TODO: update MSD_CORE_Status__c to complete
        }

          MSD_CORE_Logger.debug('MSD_CORE_ExportToAttachmentServices.exportToAttachment: before return ' + JSON.serializePretty(result));


      } catch (Exception e) {
          String errString = e + ', line #:' + e.getLineNumber() + '\nStack Trace:\n' + e.getStackTraceString();
          MSD_CORE_Logger.error(errString);
          result.put('error', errString);
      } finally {
          MSD_CORE_Logger.flush();
      }

      return result;

  }

  global static Map<String,String> getDataFromQuery(Map<String, String> opts) {
    List<sObject> objList = Database.query(opts.get('soqlWithLimit'));
    String exportFieldName = opts.get('exportFieldName');
    List<String> itemList = new List<String>();
    for(sObject obj : objList) {
        itemList.add((String)obj.get(exportFieldName));
    }

    String data = string.join(itemList, '\n');
    opts.put('data', data);

    if (objList.size() > 0) {
        opts.put('lastExportedId', objList[objList.size()-1].Id + '');
    }

    Integer batchSize = Integer.valueOf(opts.get('batchSize'));
    opts.put('done', (objList.size() < batchSize) ? 'true' : 'false');

    return opts;
  }



}