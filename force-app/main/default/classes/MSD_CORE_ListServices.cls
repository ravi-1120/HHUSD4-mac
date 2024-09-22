@RestResource(urlMapping='/msdcore/list/*')
global without sharing class MSD_CORE_ListServices {


  @HttpPost
  global static Map<String,String> doPost(Map<String, String> data) {
    Map<String,String> result = new Map<String,String>();

    String method = (String)data.get('method');

    if (method == 'getList') {
        result = getList(data);
    }

    if (method == 'saveList') {
        result = saveList(data);
    }

    if (method == 'deleteList') {
        result = deleteList(data);
    }

    if (method == 'getSelectableListProducts') {
        result = getSelectableListProducts(data);
    }

    if (method == 'saveListProduct') {
        result = saveListProduct(data);
    }

    if (method == 'saveListSalesTeam') {
        result = saveListSalesTeam(data);
    }

    if (method == 'saveListAttribute') {
        result = saveListAttribute(data);
    }


    if (method == 'getSelectableListSalesTeams') {
        result = getSelectableListSalesTeams(data);
    }

    if (method == 'getSelectableListMarkets') {
        result = getSelectableListMarkets(data);
    }


    if (method == 'getSelectableListAttributes') {
        result = getSelectableListAttributes(data);
    }

    if (method == 'deleteListAttribute') {
        result = deleteListAttribute(data);
    }

    if (method == 'getListAttachments') {
        result = getListAttachments(data);
    }

    if (method == 'saveListAttachment') {
        result = saveListAttachment(data);
    }

    if (method == 'unpackListAttachment') {
        result = unpackListAttachment(data);
    }

    if (method == 'activateListAttachment') {
        result = activateListAttachment(data);
    }

    if (method == 'scheduleListAttachmentForActivation') {
        result = scheduleListAttachmentForActivation(data);
    }

    if (method == 'inactivateListAttachment') {
        result = inactivateListAttachment(data);
    }

    if (method == 'deleteListAttachment') {
        result = deleteListAttachment(data);
    }

    if (method == 'getListApplications') {
        result = getListApplications(data);
    }

    if (method == 'saveListApplication') {
        result = saveListApplication(data);
    }

    if (method == 'activateListApplication') {
        result = activateListApplication(data);
    }

    if (method == 'scheduleListApplicationForActivation') {
        result = scheduleListApplicationForActivation(data);
    }

    if (method == 'inactivateListApplication') {
        result = inactivateListApplication(data);
    }

    if (method == 'deleteListApplication') {
        result = deleteListApplication(data);
    }

    if (method == 'getSelectableSurveys') {
        result = getSelectableSurveys(data);
    }



    if (method == 'asyncUnpackListAttachment') {
        //KRB REL 8.0 8/4/2016
        //result = asyncUnpackListAttachment(data.get('listAttachmentId'));
    }

    if (method == 'asyncAccountMatch') {
        result = asyncAccountMatch(data.get('listAttachmentId'));
    }

    if (method == 'asyncCreateCampaignFromListApplication') {
        result = asyncCreateCampaignFromListApplication(data.get('listApplicationId'));
    }

    if (method == 'asyncCreateSurveyTargetsFromListApplication') {
        result = asyncCreateSurveyTargetsFromListApplication(data.get('listApplicationId'));
    }

    if (method == 'asyncCreateProductMetricCampaignFromListApplication') {
        result = asyncCreateProductMetricCampaignFromListApplication(data.get('listApplicationId'));
    }


    return result;
  }


    public static Map<String,String> saveList(Map<String,String> opts) {

        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('list'));

        Map<String,String> validateListResult = validateList(opts);

        String validationError = validateListResult.get('error');
        if ((validationError != null) && (validationError != '')) {
            opts.putAll(validateListResult);
            opts.put('success', 'false');
            return opts;
        }

        String listId = (String)fieldNameToValueMap.get('Id');
        MSD_CORE_List__c l;
        if (listId == null) {
            l = new MSD_CORE_List__c();
        } else {
            l = Database.query(MSD_CORE_Setting.getString('LIST_MANAGER', 'listsSOQL') + ' where Id = \'' + listId + '\'');
        }

        String ignoreOnUpdateFieldListString = MSD_CORE_Setting.getString('LIST_MANAGER', 'ignoreOnUpdateFieldList');
        List<String> ignoreOnUpdateFieldList = ignoreOnUpdateFieldListString.split(',');

        for (String fieldName : ignoreOnUpdateFieldList) {
            fieldNameToValueMap.remove(fieldName);
        }

       for (String fieldName : fieldNameToValueMap.keySet()) {
        if ((fieldName == 'MSD_CORE_Start_Date__c') || (fieldName == 'MSD_CORE_End_Date__c')) {
            l.put(fieldName, Date.valueOf(fieldNameToValueMap.get(fieldName) + ' 00:00:00'));
        } else {
            l.put(fieldName, fieldNameToValueMap.get(fieldName));
        }

       }

       l.put('MSD_CORE_Country_Code__c', MSD_CORE_Setting.getString('LIST_MANAGER', 'countryCode'));

        // MSD_CORE_Description__c, MSD_CORE_Start_Date__c, MSD_CORE_End_Date__c, MSD_CORE_Requested_By__c, MSD_CORE_Request_Type__c, MSD_CORE_Business_Rationale__c, MSD_CORE_Business_Use__c, MSD_CORE_Country_Code__c]: [MSD_CORE_Description__c, MSD_CORE_Start_Date__c, MSD_CORE_End_Date__c, MSD_CORE_Requested_By__c, MSD_CORE_Request_Type__c, MSD_CORE_Business_Rationale__c, MSD_CORE_Business_Use__c, MSD_CORE_Country_Code__c

       Database.SaveResult sr;

       if (listId == null) {
        sr = Database.insert(l);
       } else {
        sr = Database.update(l);
       }

       opts.put('success', sr.isSuccess() ? 'true' : 'false');
       opts.put('Id', sr.getId() + '');

        return opts;
    }

    public static Map<String,String> validateList(Map<String,String> opts) {
        Map<String,String> result = new Map<String,String>();

        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('list'));

        String idString = (String)fieldNameToValueMap.get('Id');

        if ((idString == null) || (idString == '')) {

            String name = (String)fieldNameToValueMap.get('MSD_CORE_Name__c');

            String activeStatusValue = 'active';

            List<MSD_CORE_List__c> listList = [select Id from MSD_CORE_List__c where MSD_CORE_Name__c = :name and MSD_CORE_Status__c = :activeStatusValue];
            if (listList.size() > 0) {
                result.put('error', 'An active list with Name of "' + name + '" exists.  Please rename.');
            }

            String shortName = (String)fieldNameToValueMap.get('MSD_CORE_Short_Name__c');
            listList = [select Id from MSD_CORE_List__c where MSD_CORE_Short_Name__c = :name and MSD_CORE_Status__c = :activeStatusValue];
            if (listList.size() > 0) {
                result.put('error', 'An active list with Short Name of "' + shortName + '" exists.  Please rename.');
            }
        }

        return result;
    }

    public static Map<String,String> saveListProduct(Map<String,String> opts) {

        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('listProduct'));

        String listId = (String)fieldNameToValueMap.get('MSD_CORE_List__c');
        List<MSD_CORE_List_Product__c> listProductList = [select Id, MSD_CORE_List__c, MSD_CORE_Product__c from MSD_CORE_List_Product__c where MSD_CORE_List__c = :listId];

        MSD_CORE_List_Product__c lp;
        if (listProductList.size() == 0) {
            lp = new MSD_CORE_List_Product__c(
                MSD_CORE_List__c = listId
            );
        } else {
            lp = listProductList[0];
        }

        String ignoreOnUpdateFieldListString = MSD_CORE_Setting.getString('LIST_MANAGER', 'ignoreOnUpdateFieldList');
        List<String> ignoreOnUpdateFieldList = ignoreOnUpdateFieldListString.split(',');

        for (String fieldName : ignoreOnUpdateFieldList) {
            fieldNameToValueMap.remove(fieldName);
        }

        fieldNameToValueMap.remove('MSD_CORE_List__c');

       for (String fieldName : fieldNameToValueMap.keySet()) {
            lp.put(fieldName, fieldNameToValueMap.get(fieldName));
       }

       lp.put('MSD_CORE_Country_Code__c', MSD_CORE_Setting.getString('LIST_MANAGER', 'countryCode'));

        // MSD_CORE_Description__c, MSD_CORE_Start_Date__c, MSD_CORE_End_Date__c, MSD_CORE_Requested_By__c, MSD_CORE_Request_Type__c, MSD_CORE_Business_Rationale__c, MSD_CORE_Business_Use__c, MSD_CORE_Country_Code__c]: [MSD_CORE_Description__c, MSD_CORE_Start_Date__c, MSD_CORE_End_Date__c, MSD_CORE_Requested_By__c, MSD_CORE_Request_Type__c, MSD_CORE_Business_Rationale__c, MSD_CORE_Business_Use__c, MSD_CORE_Country_Code__c

       Database.SaveResult sr;

       if (listProductList.size() == 0) {
        sr = Database.insert(lp);
       } else {
        sr = Database.update(lp);
       }

       opts.put('success', sr.isSuccess() ? 'true' : 'false');
       opts.put('Id', sr.getId() + '');

        return opts;
    }


    public static Map<String,String> saveListSalesTeam(Map<String,String> opts) {

        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('listSalesTeam'));

        String listId = (String)fieldNameToValueMap.get('MSD_CORE_List__c');
        List<MSD_CORE_List_Sales_Team__c> listSalesTeamList = [select Id,  MSD_CORE_Country_Code__c, MSD_CORE_List__c, MSD_CORE_Sales_Team__c, Name, RecordTypeId from MSD_CORE_List_Sales_Team__c where MSD_CORE_List__c = :listId];

        MSD_CORE_List_Sales_Team__c lst;
        if (listSalesTeamList.size() == 0) {
            lst = new MSD_CORE_List_Sales_Team__c(
                MSD_CORE_List__c = listId
            );
        } else {
            lst = listSalesTeamList[0];
        }

        String ignoreOnUpdateFieldListString = MSD_CORE_Setting.getString('LIST_MANAGER', 'ignoreOnUpdateFieldList');
        List<String> ignoreOnUpdateFieldList = ignoreOnUpdateFieldListString.split(',');

        for (String fieldName : ignoreOnUpdateFieldList) {
            fieldNameToValueMap.remove(fieldName);
        }

        fieldNameToValueMap.remove('MSD_CORE_List__c');

       for (String fieldName : fieldNameToValueMap.keySet()) {
            lst.put(fieldName, fieldNameToValueMap.get(fieldName));
       }

       lst.put('MSD_CORE_Country_Code__c', MSD_CORE_Setting.getString('LIST_MANAGER', 'countryCode'));

        // MSD_CORE_Description__c, MSD_CORE_Start_Date__c, MSD_CORE_End_Date__c, MSD_CORE_Requested_By__c, MSD_CORE_Request_Type__c, MSD_CORE_Business_Rationale__c, MSD_CORE_Business_Use__c, MSD_CORE_Country_Code__c]: [MSD_CORE_Description__c, MSD_CORE_Start_Date__c, MSD_CORE_End_Date__c, MSD_CORE_Requested_By__c, MSD_CORE_Request_Type__c, MSD_CORE_Business_Rationale__c, MSD_CORE_Business_Use__c, MSD_CORE_Country_Code__c

       Database.SaveResult sr;

       if (listSalesTeamList.size() == 0) {
        sr = Database.insert(lst);
       } else {
        sr = Database.update(lst);
       }

       opts.put('success', sr.isSuccess() ? 'true' : 'false');
       opts.put('Id', sr.getId() + '');

        return opts;
    }

    public static Map<String,String> saveListAttribute(Map<String,String> opts) {

        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('listAttribute'));

        String listId = (String)fieldNameToValueMap.get('MSD_CORE_List__c');
        String attributeName = (String)fieldNameToValueMap.get('MSD_CORE_Name__c');
        String attributeValue = (String)fieldNameToValueMap.get('MSD_CORE_Value__c');
        List<MSD_CORE_List_Attribute__c> listAttributeList = [select Id, MSD_CORE_List__c, MSD_CORE_Name__c, MSD_CORE_Value__c from MSD_CORE_List_Attribute__c where MSD_CORE_List__c = :listId and MSD_CORE_Name__c = :attributeName and MSD_CORE_Value__c = :attributeValue];

        MSD_CORE_List_Attribute__c la;
        if (listAttributeList.size() == 0) {
            la = new MSD_CORE_List_Attribute__c(
                MSD_CORE_List__c = listId
            );
        } else {
            la = listAttributeList[0];
        }

        String ignoreOnUpdateFieldListString = MSD_CORE_Setting.getString('LIST_MANAGER', 'ignoreOnUpdateFieldList');
        List<String> ignoreOnUpdateFieldList = ignoreOnUpdateFieldListString.split(',');

        for (String fieldName : ignoreOnUpdateFieldList) {
            fieldNameToValueMap.remove(fieldName);
        }

        fieldNameToValueMap.remove('MSD_CORE_List__c');

       for (String fieldName : fieldNameToValueMap.keySet()) {
            la.put(fieldName, fieldNameToValueMap.get(fieldName));
       }

       la.put('MSD_CORE_Country_Code__c', MSD_CORE_Setting.getString('LIST_MANAGER', 'countryCode'));

       Database.SaveResult sr;

       if (listAttributeList.size() == 0) {
        sr = Database.insert(la);
       } else {
        sr = Database.update(la);
       }

       opts.put('success', sr.isSuccess() ? 'true' : 'false');
       opts.put('Id', sr.getId() + '');

        return opts;
    }

    public static Map<String,String> deleteListAttribute(Map<String,String> opts) {

        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('listAttribute'));
        String listAttributeId = (String)fieldNameToValueMap.get('Id');
        Database.DeleteResult sr = Database.delete(listAttributeId);
        if (!sr.isSuccess()) {
            String errString = 'Failed to delete List Attribute having Id "' + listAttributeId + '".\n';

            for(Database.Error err : sr.getErrors()) {
                System.debug('The following error has occurred.');
                errString += (err.getStatusCode() + ': ' + err.getMessage() + '\n');
                errString += ('fields that affected this error: ' + err.getFields() + '\n\n');
            }

            opts.put('error', errString);
        }
        return opts;
    }

    public static Map<String,String> deleteList(Map<String,String> opts) {
        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('list'));
        String listId = (String)fieldNameToValueMap.get('Id');

        Database.DeleteResult dr = Database.delete(listId);

        opts.put('success', dr.isSuccess() ? 'true' : 'false');

        return opts;
    }

    public static Map<String,String> getList(Map<String,String> opts) {
        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('list'));
        String listId = (String)fieldNameToValueMap.get('Id');

        MSD_CORE_List__c l = (MSD_CORE_List__c)Database.query(MSD_CORE_Setting.getString('LIST_MANAGER', 'listsSOQL') + ' where Id = \'' + listId + '\'');
        opts.put('list', JSON.serializePretty(l));

        String listProductSOQL = string.format(MSD_CORE_Setting.getString('LIST_MANAGER', 'listProductSOQL'), new List<String>{'\'' + listId + '\''});
        List<MSD_CORE_List_Product__c> lpList = (List<MSD_CORE_List_Product__c>)Database.query(listProductSOQL);

        if (lpList.size() > 0) {
            opts.put('listProduct', JSON.serializePretty(lpList[0]));
        } else {
            opts.put('listProduct', '{}');
        }

        String listSalesTeamSOQL = string.format(MSD_CORE_Setting.getString('LIST_MANAGER', 'listSalesTeamSOQL'), new List<String>{'\'' + listId + '\''});
        List<MSD_CORE_List_Sales_Team__c> lstList = (List<MSD_CORE_List_Sales_Team__c>)Database.query(listSalesTeamSOQL);

        if (lstList.size() > 0) {
            opts.put('listSalesTeam', JSON.serializePretty(lstList[0]));
        } else {
            opts.put('listSalesTeam', '{}');
        }

        String listAttributesSOQL = string.format(MSD_CORE_Setting.getString('LIST_MANAGER', 'listAttributesSOQL'), new List<String>{'\'' + listId + '\''});
        List<MSD_CORE_List_Attribute__c> listAttributeList = (List<MSD_CORE_List_Attribute__c>)Database.query(listAttributesSOQL);

        if (listAttributeList.size() > 0) {
            opts.put('listAttributes', JSON.serializePretty(listAttributeList));
        } else {
            opts.put('listAttributes', '[]');
        }

        return opts;
    }

    public static Map<String,String> getSelectableListProducts(Map<String,String> opts) {
        List<sObject> objectList = (List<sObject>)Database.query(MSD_CORE_Setting.getString('LIST_MANAGER', 'selectableListProductsSOQL'));
        opts.put('products', JSON.serializePretty(objectList));
        return opts;
    }

    public static Map<String,String> getSelectableListSalesTeams(Map<String,String> opts) {
        List<sObject> objectList = (List<sObject>)Database.query(MSD_CORE_Setting.getString('LIST_MANAGER', 'selectableListSalesTeamsSOQL'));
        opts.put('salesTeams', JSON.serializePretty(objectList));
        return opts;
    }

    public static Map<String,String> getSelectableListMarkets(Map<String,String> opts) {
        List<sObject> objectList = (List<sObject>)Database.query(MSD_CORE_Setting.getString('LIST_MANAGER', 'selectableMarketsSOQL'));
        opts.put('markets', JSON.serializePretty(objectList));
        return opts;
    }

    public static Map<String,String> getSelectableListAttributes(Map<String,String> opts) {
        List<sObject> objectList = (List<sObject>)Database.query(MSD_CORE_Setting.getString('LIST_MANAGER', 'selectableListAttributesSOQL'));
        opts.put('listAttributes', JSON.serializePretty(objectList));
        return opts;
    }


    public static Map<String,String> getSelectableSurveys(Map<String,String> opts) {
        // TODO: limit results by list.start_date and list.end_date
        String soqlTemplate = MSD_CORE_Setting.getString('LIST_MANAGER', 'selectableSurveysSOQLTemplate');
        String soql = soqlTemplate;
        //String productId = opts.get('productId');
        //String soql = string.format(soqlTemplate, new List<String>{'\'' + productId + '\''});
        List<sObject> objectList = (List<sObject>)Database.query(soql);
        opts.put('surveys', JSON.serializePretty(objectList));

        return opts;
    }


    public static Map<String,String> getListAttachments(Map<String,String> opts) {
        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('list'));
        String listId = (String)fieldNameToValueMap.get('Id');

        List<MSD_CORE_List_Attachment__c> laList = (List<MSD_CORE_List_Attachment__c>)Database.query(MSD_CORE_Setting.getString('LIST_MANAGER', 'listAttachmentsSOQL') + ' where MSD_CORE_List__c = \'' + listId + '\' order by MSD_CORE_Version__c desc');

        Set<Id> attachmentIdSet = new Set<Id>();
        for (MSD_CORE_List_Attachment__c la : laList) {
            attachmentIdSet.add(la.Id);
        }

        List<Attachment> attachmentList = [select BodyLength, ContentType, CreatedById, CreatedDate, Description, Id, IsDeleted, IsPrivate, LastModifiedById, LastModifiedDate, Name, OwnerId, ParentId, SystemModstamp from Attachment where ParentId in :attachmentIdSet];

        List<MSD_CORE_Export_To_Attachment_Task__c> exportToAttachmentTaskList = [select Id, MSD_CORE_Query__c, MSD_CORE_Related_Record_ID__c, MSD_CORE_Status__c, Name from MSD_CORE_Export_To_Attachment_Task__c where MSD_CORE_Related_Record_ID__c in :attachmentIdSet];
        Set<Id> exportToAttachmentTaskIdSet = new Set<Id>();

        for (MSD_CORE_Export_To_Attachment_Task__c exportToAttachmentTask : exportToAttachmentTaskList) {
            exportToAttachmentTaskIdSet.add(exportToAttachmentTask.Id);
        }

        List<Attachment> exportToAttachmentTaskAttachmentList = [select Id, Name, ParentId from Attachment where ParentId in :exportToAttachmentTaskIdSet];

        opts.put('listAttachments', JSON.serializePretty(laList));
        opts.put('attachmentList', JSON.serializePretty(attachmentList));
        opts.put('exportToAttachmentTaskList', JSON.serializePretty(exportToAttachmentTaskList));
        opts.put('exportToAttachmentTaskAttachmentList', JSON.serializePretty(exportToAttachmentTaskAttachmentList));

        return opts;
    }

    public static Map<String,String> getListApplications(Map<String,String> opts) {
        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('list'));
        String listId = (String)fieldNameToValueMap.get('Id');

        List<MSD_CORE_List_Application__c> listApplicationList = (List<MSD_CORE_List_Application__c>)Database.query(MSD_CORE_Setting.getString('LIST_MANAGER', 'listApplicationsSOQL') + ' where MSD_CORE_List__c = \'' + listId + '\' order by LastModifiedDate  desc');
        opts.put('listApplications', JSON.serializePretty(listApplicationList));

        List<sObject> listApplicationRelatedRecordList = new List<sObject>();
        for (MSD_CORE_List_Application__c listApplication : listApplicationList) {
            if (listApplication.MSD_CORE_Related_Record_ID__c != null) {
                String objectName = ((Id)listApplication.MSD_CORE_Related_Record_ID__c).getSObjectType().getDescribe().getName();

                sObject record = Database.query('select Id, Name from ' + objectName + ' where Id = \'' + listApplication.MSD_CORE_Related_Record_ID__c + '\'');
                listApplicationRelatedRecordList.add(record);
            }
        }

        opts.put('listApplicationRelatedRecordList', JSON.serializePretty(listApplicationRelatedRecordList));

        return opts;
    }


    public static Map<String,String> saveListAttachment(Map<String,String> opts) {
        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('listAttachment'));

        String listAttachmentId = (String)fieldNameToValueMap.get('Id');
        MSD_CORE_List_Attachment__c la;
        if (listAttachmentId == null) {
            la = new MSD_CORE_List_Attachment__c();
            la.put('MSD_CORE_Status__c', 'pending');
        } else {
            la = Database.query(MSD_CORE_Setting.getString('LIST_MANAGER', 'listAttachmentsSOQL') + ' where Id = \'' + listAttachmentId + '\'');
        }

        String ignoreOnUpdateFieldListString = MSD_CORE_Setting.getString('LIST_MANAGER', 'ignoreOnUpdateFieldList');
        List<String> ignoreOnUpdateFieldList = ignoreOnUpdateFieldListString.split(',');

        for (String fieldName : ignoreOnUpdateFieldList) {
            fieldNameToValueMap.remove(fieldName);
        }

       for (String fieldName : fieldNameToValueMap.keySet()) {
        if ((fieldName == 'MSD_CORE_Start_Date__c') || (fieldName == 'MSD_CORE_End_Date__c')) {
            la.put(fieldName, Date.valueOf(fieldNameToValueMap.get(fieldName) + ' 00:00:00'));
        } else {
            la.put(fieldName, fieldNameToValueMap.get(fieldName));
        }

       }

       la.put('MSD_CORE_Country_Code__c', MSD_CORE_Setting.getString('LIST_MANAGER', 'countryCode'));

       Database.SaveResult sr;

       if (listAttachmentId == null) {
        sr = Database.insert(la);
       } else {
        sr = Database.update(la);
       }

       opts.put('success', sr.isSuccess() ? 'true' : 'false');
       opts.put('Id', sr.getId() + '');

        return opts;
    }

    public static Map<String,String> createActivateListAttachmentParams(Map<String,String> opts) {
        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('listAttachment'));

        String listAttachmentId = (String)fieldNameToValueMap.get('Id');

        opts.put('jobItemTemplate', 'listItemsUpdate');
        opts.put('listAttachmentId', listAttachmentId);
        opts.put('fieldValue', 'active');
        opts.put('parentId', listAttachmentId);
        opts.put('parentFieldValue', 'active');

        return opts;
    }

    public static Map<String,String> scheduleListAttachmentForActivation(Map<String,String> opts) {
        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('listAttachment'));

        String listAttachmentId = (String)fieldNameToValueMap.get('Id');

        MSD_CORE_List_Attachment__c la = [select Id, MSD_CORE_Status__c from MSD_CORE_List_Attachment__c where Id = :listAttachmentId];
        la.MSD_CORE_Status__c = 'pending activation';
        Database.SaveResult sr = Database.update(la);
        // TODO: handle error
        if (!sr.isSuccess()) {

        }

        return opts;
    }

    public static Map<String,String> scheduleListApplicationForActivation(Map<String,String> opts) {
        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('listApplication'));

        String listAttachmentId = (String)fieldNameToValueMap.get('Id');

        MSD_CORE_List_Application__c la = [select Id, MSD_CORE_Status__c from MSD_CORE_List_Application__c where Id = :listAttachmentId];
        la.MSD_CORE_Status__c = 'pending activation';
        Database.SaveResult sr = Database.update(la);
        // TODO: handle error
        if (!sr.isSuccess()) {

        }

        return opts;
    }

    public static Map<String,String> activateListAttachment(Map<String,String> opts) {
        return MSD_CORE_RecordsOperationServices.asyncExecute( createActivateListAttachmentParams(opts));
    }

    public static Map<String,String> createInactivateListAttachmentParams(Map<String,String> opts) {
        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('listAttachment'));

        String listAttachmentId = (String)fieldNameToValueMap.get('Id');

        opts.put('jobItemTemplate', 'listItemsUpdate');
        opts.put('listAttachmentId', listAttachmentId);
        opts.put('fieldValue', 'inactive');
        opts.put('parentId', listAttachmentId);
        opts.put('parentFieldValue', 'inactive');

        return opts;
    }

    public static Map<String,String> inactivateListAttachment(Map<String,String> opts) {
        return MSD_CORE_RecordsOperationServices.asyncExecute( createInactivateListAttachmentParams(opts) );
    }

    public static Map<String,String> deleteListAttachment(Map<String,String> opts) {
        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('listAttachment'));

        String listAttachmentId = (String)fieldNameToValueMap.get('Id');

        opts.put('jobItemTemplate', 'listItemsDelete');
        opts.put('listAttachmentId', listAttachmentId);
        //opts.put('fieldValue', 'inactive');
        opts.put('parentId', listAttachmentId);
        //opts.put('parentFieldValue', 'inactive');

        return MSD_CORE_RecordsOperationServices.asyncExecute(opts);
    }

    public static Map<String,String> saveListApplication(Map<String,String> opts) {
        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('listApplication'));

        String listApplicationtId = (String)fieldNameToValueMap.get('Id');
        MSD_CORE_List_Application__c la;
        if (listApplicationtId == null) {
            la = new MSD_CORE_List_Application__c();
            la.put('MSD_CORE_Status__c', 'pending');
        } else {
            la = Database.query(MSD_CORE_Setting.getString('LIST_MANAGER', 'listApplicationsSOQL') + ' where Id = \'' + listApplicationtId + '\'');
            fieldNameToValueMap.remove('MSD_CORE_List__c');
        }

        String ignoreOnUpdateFieldListString = MSD_CORE_Setting.getString('LIST_MANAGER', 'ignoreOnUpdateFieldList');
        List<String> ignoreOnUpdateFieldList = ignoreOnUpdateFieldListString.split(',');

        for (String fieldName : ignoreOnUpdateFieldList) {
            fieldNameToValueMap.remove(fieldName);
        }

       for (String fieldName : fieldNameToValueMap.keySet()) {
        if ((fieldName == 'MSD_CORE_Start_Date__c') || (fieldName == 'MSD_CORE_End_Date__c')) {
            la.put(fieldName, Date.valueOf(fieldNameToValueMap.get(fieldName) + ' 00:00:00'));
        } else {
            la.put(fieldName, fieldNameToValueMap.get(fieldName));
        }

       }

       la.put('MSD_CORE_Country_Code__c', MSD_CORE_Setting.getString('LIST_MANAGER', 'countryCode'));

       Database.SaveResult sr;

       if (listApplicationtId == null) {
        sr = Database.insert(la);
       } else {
        sr = Database.update(la);
       }

       opts.put('success', sr.isSuccess() ? 'true' : 'false');
       opts.put('Id', sr.getId() + '');

        return opts;
    }

    public static Map<String,Object> createInactivateListApplicationJobGroup(Map<String,String> opts) {
        Map<String, Object> result = new Map<String, String>();
        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('listApplication'));

        String listApplicationId = (String)fieldNameToValueMap.get('Id');
        String type = (String)fieldNameToValueMap.get('MSD_CORE_Type__c');


        if (type == 'campaign') {
            result = createInactivateCampaignFromListApplicationJobGroup(listApplicationId);
        }

        if (type == 'product metric') {
            // TODO: implement
            result = null;
            result = createInactivateProductMetricCampaignFromListApplicationJobGroup(listApplicationId);
        }

        if (type == 'product metric campaign') {
            // TODO: implement
            result = null;
            result = createInactivateProductMetricCampaignFromListApplicationJobGroup(listApplicationId);
        }


        if (type == 'survey') {
            // TODO: implement
            result = null;
            //result = createInactivateSurveyTargetsFromListApplicationJobGroup(listApplicationId);
        }


        return result;

    }


    public static Map<String,Object> createActivateListApplicationJobGroup(Map<String,String> opts) {
        Map<String, Object> result = new Map<String, String>();
        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('listApplication'));

        String listApplicationId = (String)fieldNameToValueMap.get('Id');
        String type = (String)fieldNameToValueMap.get('MSD_CORE_Type__c');


        if (type == 'campaign') {
            result = createCreateCampaignFromListApplicationJobGroup(listApplicationId);
        }

        if (type == 'product metric') {
            // TODO: fix this so the naming makes sense
            result = createCreateProductMetricCampaignFromListApplicationJobGroup(listApplicationId);
        }

        if (type == 'product metric campaign') {
            result = createCreateProductMetricCampaignFromListApplicationJobGroup(listApplicationId);
        }


        if (type == 'survey') {
            result = createCreateSurveyTargetsFromListApplicationJobGroup(listApplicationId);
        }

        return result;

    }

    public static Map<String,String> activateListApplication(Map<String,String> opts) {
        Map<String, String> result = new Map<String, String>();
        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('listApplication'));

        String listApplicationId = (String)fieldNameToValueMap.get('Id');
        String type = (String)fieldNameToValueMap.get('MSD_CORE_Type__c');


        if (type == 'campaign') {
            result = asyncCreateCampaignFromListApplication(listApplicationId);
        }

        if (type == 'product metric') {
            // TODO: fix this so the naming makes sense
            result = asyncCreateProductMetricCampaignFromListApplication(listApplicationId);
        }

        if (type == 'product metric campaign') {
            result = asyncCreateProductMetricCampaignFromListApplication(listApplicationId);
        }


        if (type == 'survey') {
            result = asyncCreateSurveyTargetsFromListApplication(listApplicationId);
        }

        return result;

    }

    public static Map<String,String> createCampaignFromListApplication(Map<String,String> opts) {
        Map<String, String> result = opts.clone();

        String op = opts.get('op');
        String listId = opts.get('listId');
        String listApplicationId = opts.get('listApplicationId');
        Integer batchSize = Integer.valueOf(opts.get('batchSize'));
        Integer recordsProcessed = Integer.valueOf(opts.get('recordsProcessed'));

        MSD_CORE_List_Application__c listApplication = [select Id,  MSD_CORE_List__c, MSD_CORE_List_Attachment__c, MSD_CORE_Status__c, MSD_CORE_Type__c, Name from MSD_CORE_List_Application__c where Id = :listApplicationId];

        MSD_CORE_List__c l = (MSD_CORE_List__c)Database.query(MSD_CORE_Setting.getString('LIST_MANAGER', 'listsSOQL') + ' where Id = \'' + listId + '\'');

        List<MSD_CORE_List_Attachment__c> listAttachmentList = [select Id, MSD_CORE_List__c, MSD_CORE_Status__c, MSD_CORE_Item_Count__c from MSD_CORE_List_Attachment__c where Id = :listApplication.MSD_CORE_List_Attachment__c];

        if (listAttachmentList.size() == 0) {
            // TODO: translate
            opts.put('error', 'no active list attachments exist for List with Id = ' + listId);
            return opts;
        }

        if (listAttachmentList.size() > 1) {
            // TODO: translate
            opts.put('error', 'more than one active list attachment exist for List with Id = ' + listId);
            return opts;
        }

        MSD_CORE_List_Attachment__c la = listAttachmentList[0];
        String listAttachmentId = la.Id;

        if (op == 'createCampaign') {

            /*
            if (listApplication.MSD_CORE_Status__c == 'active') {
                listApplication.MSD_CORE_Status__c = 'syncing';
            } else {
                listApplication.MSD_CORE_Status__c = 'activating';
            }
            */

            listApplication.MSD_CORE_Status__c = 'activating';
            Database.SaveResult listApplicationSaveResult = Database.update(listApplication);

            // TODO: handle error
            if (!listApplicationSaveResult.isSuccess()) {
                opts.put('error', 'failed to update Status to "activating" for list application with ID ' + listApplicationId);
                opts.put('done', 'true');
            }


            List<MSD_CORE_List_Product__c> listProductList = [select Id, MSD_CORE_List__c, MSD_CORE_Product__c, MSD_CORE_Product__r.Name from MSD_CORE_List_Product__c where MSD_CORE_List__c = :listId];
            if (listProductList.size() == 0) {
                // TODO: translate
                opts.put('error', 'no active list products exist for List with Id = ' + listId);
                return opts;
            }

            if (listProductList.size() > 1) {
                // TODO: translate
                opts.put('error', 'more than one active list product exist for List with Id = ' + listId);
                return opts;
            }

            MSD_CORE_List_Product__c listProduct = listProductList[0];

            List<Campaign_vod__c> campaignList = [select Id, Name, Description_vod__c, Campaign_Short_Description_MRK__c, Product_MRK__c, Sharing_Groups_MRK__c, Start_Date_vod__c, End_Date_vod__c, Active_MRK__c, External_ID_MRK__c from Campaign_vod__c where Name = :l.MSD_CORE_Name__c];

            if (campaignList.size() > 1) {
                // TODO: translate
                opts.put('error', 'more than 1 Campaign exists with the name = ' + l.MSD_CORE_Name__c);
                return opts;
            }

            Campaign_vod__c campaign;
            Database.SaveResult campaignSaveResult;
            if (campaignList.size() == 1) {
                campaign = campaignList[0];
            } else {
                campaign = new Campaign_vod__c();
            }

            campaign.Name = l.MSD_CORE_Name__c;
            campaign.Description_vod__c = l.MSD_CORE_Description__c;
            campaign.Campaign_Short_Description_MRK__c = l.MSD_CORE_Short_Name__c;
            campaign.Product_MRK__c = listProduct.MSD_CORE_Product__c;
            campaign.Sharing_Groups_MRK__c = listProduct.MSD_CORE_Product__r.Name;
            campaign.Start_Date_vod__c = l.MSD_CORE_Start_Date__c;
            campaign.End_Date_vod__c = l.MSD_CORE_End_Date__c;
            campaign.Active_MRK__c = false;
            campaign.External_ID_MRK__c = l.Name;

            // overrides for General and Headquarters
            Boolean isGeneralProduct = (listProduct.MSD_CORE_Product__r.Name .toLowerCase() == 'general');
            Boolean isHeadquarters = (l.MSD_CORE_Requested_By__c.toLowerCase() == 'headquarters');

            if (isGeneralProduct && !isHeadquarters) {
                campaign.Product_MRK__c = null;
                campaign.Sharing_Groups_MRK__c = '00000000';
            }

            if (isGeneralProduct && isHeadquarters) {
                campaign.Product_MRK__c = null;
                campaign.Sharing_Groups_MRK__c = null; // no visibility to end users
            }

            if (campaignList.size() == 1) {
                campaignSaveResult = Database.update(campaign);
            } else {
                campaignSaveResult = Database.insert(campaign);
            }

            if (!campaignSaveResult.isSuccess()) {
                // TODO: translate
                String errorString = 'failed to create or update campaign for List with Id = ' + listId + '.\nErrors:\n';

                for(Database.Error err : campaignSaveResult.getErrors()) {
                    errorString += (err.getStatusCode() + ': ' + err.getMessage() + '\n');
                    errorString += ('Fields that affected this error: ' + err.getFields() + '\n\n');
                }

                opts.put('error',  + errorString);
                return opts;
            }


            String campaignId = campaignSaveResult.getId();
            opts.put('campaignId', campaignId + '');

            opts.put('done', 'false');
            opts.put('op', 'createCampaignTargets');

        }

        if (op == 'createCampaignTargets') {

            //Id hqCampaignRecordType = [select Id from RecordType where DeveloperName = 'Headquarters' and sObjectType = 'Campaign_vod__c'].Id;

            String campaignId = opts.get('campaignId');
            String lastListItemIdProcessed = opts.get('lastListItemIdProcessed');

            List<Campaign_Target_vod__c> campaignTargetList = new List<Campaign_Target_vod__c>();

            String listItemSOQL;
            if (lastListItemIdProcessed != null && lastListItemIdProcessed != '') {
                listItemSOQL = 'select Id, MSD_CORE_Account__c from MSD_CORE_List_Item__c where MSD_CORE_List_Attachment__c = \'' + listAttachmentId + '\' and Id > \'' + lastListItemIdProcessed + '\' order by Id limit ' + batchSize;
            } else {
                listItemSOQL = 'select Id, MSD_CORE_Account__c from MSD_CORE_List_Item__c where MSD_CORE_List_Attachment__c = \'' + listAttachmentId + '\' order by Id limit ' + batchSize;
            }

            List<MSD_CORE_List_Item__c> listItemList = Database.query(listItemSOQL);

            List<String> externalIdList = new List<String>();

            for (MSD_CORE_List_Item__c li : listItemList) {
                String externalId = campaignId + '__' + li.MSD_CORE_Account__c;
                externalIdList.add(externalId);
                Campaign_Target_vod__c campaignTarget = new Campaign_Target_vod__c(
                    Campaign_vod__c = campaignId,
                    Target_Account_vod__c = li.MSD_CORE_Account__c,
                    Effective_Date_MRK__c = l.MSD_CORE_Start_Date__c,
                    Expiration_Date_MRK__c = l.MSD_CORE_End_Date__c,
                    // Associated_Campaign_Record_Type_MRK__c = hqCampaignRecordType,
                    External_Id_vod__c = externalId
                );

                campaignTargetList.add(campaignTarget);
            }

            // remove existing campaign targets from our insert list
            List<Campaign_Target_vod__c> finalCampaignTargetInsertList = new List<Campaign_Target_vod__c>();
            List<Campaign_Target_vod__c> existingCampaignTargetList = (List<Campaign_Target_vod__c>)[select Id, External_Id_vod__c from Campaign_Target_vod__c where Campaign_vod__c = :campaignId and External_Id_vod__c in :externalIdList];
            for (Campaign_Target_vod__c campaignTarget : campaignTargetList) {
                Boolean campaignTargetExists = false;
                for (Campaign_Target_vod__c existingCampaignTarget : existingCampaignTargetList) {

                    if (campaignTarget.External_Id_vod__c == existingCampaignTarget.External_Id_vod__c) {
                        campaignTargetExists = true;
                    }
                }

                if (!campaignTargetExists) {
                    finalCampaignTargetInsertList.add(campaignTarget);
                }
            }

            // TODO: error handling
            Database.SaveResult[] srList = Database.insert(finalCampaignTargetInsertList);

            if (listItemList.size() > 0) {
                opts.put('lastListItemIdProcessed', listItemList[listItemList.size() - 1].Id + '');
            }

            recordsProcessed += listItemList.size();
            opts.put('recordsProcessed', recordsProcessed + '');

            if (la.MSD_CORE_Item_Count__c == recordsProcessed) {

                Campaign_vod__c campaign = [select Id, Active_MRK__c from Campaign_vod__c where Id = :campaignId];
                campaign.Active_MRK__c = true;
                Database.SaveResult campaignSaveResult = Database.update(campaign);

                if (!campaignSaveResult.isSuccess()) {
                    opts.put('error', 'failed to update Active to tue for campaign with ID ' + campaignId);
                    opts.put('done', 'true');
                }

                listApplication.MSD_CORE_Status__c = 'active';
                listApplication.MSD_CORE_Related_Record_ID__c = campaignId;
                Database.SaveResult listApplicationSaveResult = Database.update(listApplication);

                // TODO: handle error
                if (!listApplicationSaveResult.isSuccess()) {
                    opts.put('error', 'failed to update Status to "active" for list application with ID ' + listApplicationId);
                    opts.put('done', 'true');
                }
            }

            opts.put('done', (la.MSD_CORE_Item_Count__c == recordsProcessed) ? 'true' : 'false');


        }

        if (op == 'inactivateCampaign') {

            List<Campaign_vod__c> campaignList = [select Id, Name, Description_vod__c, Campaign_Short_Description_MRK__c, Product_MRK__c, Sharing_Groups_MRK__c, Start_Date_vod__c, End_Date_vod__c, Active_MRK__c, External_ID_MRK__c from Campaign_vod__c where Name = :l.MSD_CORE_Name__c];

            if (campaignList.size() > 1) {
                // TODO: translate
                opts.put('error', 'more than 1 Campaign exists with the name = ' + l.MSD_CORE_Name__c);
                return opts;
            }

            Campaign_vod__c campaign = campaignList[0];

            opts.put('campaignId', campaign.Id + '');

            String campaignId = opts.get('campaignId');
            String lastListItemIdProcessed = opts.get('lastListItemIdProcessed');

            String listItemSOQL;
            if (lastListItemIdProcessed != null && lastListItemIdProcessed != '') {
                listItemSOQL = 'select Id, MSD_CORE_Account__c from MSD_CORE_List_Item__c where MSD_CORE_List_Attachment__c = \'' + listAttachmentId + '\' and Id > \'' + lastListItemIdProcessed + '\' order by Id limit ' + batchSize;
            } else {
                listItemSOQL = 'select Id, MSD_CORE_Account__c from MSD_CORE_List_Item__c where MSD_CORE_List_Attachment__c = \'' + listAttachmentId + '\' order by Id limit ' + batchSize;
            }


            List<MSD_CORE_List_Item__c> listItemList = Database.query(listItemSOQL);

            List<String> externalIdList = new List<String>();

            for (MSD_CORE_List_Item__c li : listItemList) {
                String externalId = campaignId + '__' + li.MSD_CORE_Account__c;
                externalIdList.add(externalId);
            }

            List<Campaign_Target_vod__c> campaignTargetList = [select Id from Campaign_Target_vod__c where External_Id_vod__c IN :externalIdList];


            // TODO: error handling
            Database.DeleteResult[] drList = Database.delete(campaignTargetList);

            if (listItemList.size() > 0) {
                opts.put('lastListItemIdProcessed', listItemList[listItemList.size() - 1].Id + '');
            }

            recordsProcessed += listItemList.size();
            opts.put('recordsProcessed', recordsProcessed + '');

            if (la.MSD_CORE_Item_Count__c == recordsProcessed) {

                //Campaign_vod__c campaign = [select Id, Active_MRK__c from Campaign_vod__c where Id = :campaignId];
                campaign.Active_MRK__c = false;
                Database.SaveResult campaignSaveResult = Database.update(campaign);

                if (!campaignSaveResult.isSuccess()) {
                    opts.put('error', 'failed to update Active to tue for campaign with ID ' + campaignId);
                    opts.put('done', 'true');
                }

                listApplication.MSD_CORE_Status__c = 'inactive';
                Database.SaveResult listApplicationSaveResult = Database.update(listApplication);

                // TODO: handle error
                if (!listApplicationSaveResult.isSuccess()) {
                    opts.put('error', 'failed to update Status to "inactive" for list application with ID ' + listApplicationId);
                    opts.put('done', 'true');
                }
            }

            opts.put('done', (la.MSD_CORE_Item_Count__c == recordsProcessed) ? 'true' : 'false');

        }


        return opts;
    }


  public static Map<String,String> createCreateCampaignFromListApplicationJobItem(String listApplicationId) {
    MSD_CORE_List_Application__c listApplication = [select Id, MSD_CORE_List__c, MSD_CORE_List_Attachment__c from MSD_CORE_List_Application__c where Id = :listApplicationId];

    MSD_CORE_List_Attachment__c la = [select Id, MSD_CORE_List__c, MSD_CORE_Status__c, MSD_CORE_Version__c from MSD_CORE_List_Attachment__c where Id = :listApplication.MSD_CORE_List_Attachment__c];

    Map<String,Object> jobItem = MSD_CORE_JobQueueService.getJobItemTemplate('createCampaignFromListApplication');
    Map<String,String> jobItemParams = MSD_CORE_JobQueueService.getJobItemParamsTemplate('createCampaignFromListApplication');

    jobItemParams.put('listId', listApplication.MSD_CORE_List__c + '');
    jobItemParams.put('listApplicationId', listApplicationId);
    jobItemParams.put('listAttachmentId', la.Id + '');
    jobItem.put('params', JSON.serializePretty(jobItemParams));

    Map<String,String> m = new Map<String,String>();

    for (String key : jobItem.keySet()) {
        m.put(key, (String)jobItem.get(key));
    }

    return m;
  }

    public static Map<String,Object> createCreateCampaignFromListApplicationJobGroup(String listApplicationId) {

        List<Map<String,String>> jobItemList = new List<Map<String,String>>();
        jobItemList.add( createCreateCampaignFromListApplicationJobItem(listApplicationId) );

        Map<String,Object> jobGroup = new Map<String,Object>();
        jobGroup.put('name', 'create campaign from list application');
        jobGroup.put('jobItemList', jobItemList);

        return jobGroup;
    }

  public static Map<String,String> asyncCreateCampaignFromListApplication(String listApplicationId) {

    Map<String,Object> result = MSD_CORE_JobQueueService.addJobGroup(createCreateCampaignFromListApplicationJobGroup(listApplicationId));
    MSD_CORE_JobQueueService.run();

    return new Map<String,String>();
  }


    public static Map<String,String> createSurveyTargetsFromListApplication(Map<String,String> opts) {
        Map<String, String> result = opts.clone();

        String op = opts.get('op');
        String listId = opts.get('listId');
        String listApplicationId = opts.get('listApplicationId');
        Integer batchSize = Integer.valueOf(opts.get('batchSize'));
        Integer recordsProcessed = Integer.valueOf(opts.get('recordsProcessed'));

        MSD_CORE_List_Application__c listApplication = [select Id,  MSD_CORE_List__c, MSD_CORE_List_Attachment__c, MSD_CORE_Related_Record_ID__c, MSD_CORE_Status__c, MSD_CORE_Type__c, Name from MSD_CORE_List_Application__c where Id = :listApplicationId];
        String surveyId = listApplication.MSD_CORE_Related_Record_ID__c;

        Survey_vod__c survey = [select Assignment_Type_vod__c, Channels_vod__c, CreatedById, CreatedDate, End_Date_vod__c, Expired_vod__c, External_ID_vod__c, Id, IsLocked, Language_vod__c, LastModifiedById, LastModifiedDate, Lock_vod__c, Max_Score_vod__c, Min_Score_vod__c, Name, Open_vod__c, OwnerId, Product_vod__c, RecordTypeId, Region_vod__c, Segment_vod__c, Start_Date_vod__c, Status_vod__c, Territory_vod__c from Survey_vod__c where Id = :surveyId];

        MSD_CORE_List__c l = (MSD_CORE_List__c)Database.query(MSD_CORE_Setting.getString('LIST_MANAGER', 'listsSOQL') + ' where Id = \'' + listId + '\'');

        List<MSD_CORE_List_Attachment__c> listAttachmentList = [select Id, MSD_CORE_List__c, MSD_CORE_Status__c, MSD_CORE_Item_Count__c from MSD_CORE_List_Attachment__c where Id = :listApplication.MSD_CORE_List_Attachment__c];

        if (listAttachmentList.size() == 0) {
            // TODO: translate
            opts.put('error', 'no active list attachments exist for List with Id = ' + listId);
            return opts;
        }

        if (listAttachmentList.size() > 1) {
            // TODO: translate
            opts.put('error', 'more than one active list attachment exist for List with Id = ' + listId);
            return opts;
        }

        MSD_CORE_List_Attachment__c la = listAttachmentList[0];
        String listAttachmentId = la.Id;

        if (op == 'createSurveyTargets') {

            listApplication.MSD_CORE_Status__c = 'activating';
            Database.SaveResult listApplicationSaveResult = Database.update(listApplication);

            // TODO: handle error
            if (!listApplicationSaveResult.isSuccess()) {
                opts.put('error', 'failed to update Status to "activing" for list application with ID ' + listApplicationId);
                opts.put('done', 'true');
            }



            List<MSD_CORE_List_Product__c> listProductList = [select Id, MSD_CORE_List__c, MSD_CORE_Product__c, MSD_CORE_Product__r.Name from MSD_CORE_List_Product__c where MSD_CORE_List__c = :listId];
            if (listProductList.size() == 0) {
                // TODO: translate
                opts.put('error', 'no active list products exist for List with Id = ' + listId);
                return opts;
            }

            if (listProductList.size() > 1) {
                // TODO: translate
                opts.put('error', 'more than one active list product exist for List with Id = ' + listId);
                return opts;
            }

            MSD_CORE_List_Product__c listProduct = listProductList[0];

            String lastListItemIdProcessed = opts.get('lastListItemIdProcessed');

            List<Survey_Target_vod__c> surveyTargetList = new List<Survey_Target_vod__c>();

            String listItemSOQL;
            if (lastListItemIdProcessed != null && lastListItemIdProcessed != '') {
                listItemSOQL = 'select Id, MSD_CORE_Account__c from MSD_CORE_List_Item__c where MSD_CORE_List_Attachment__c = \'' + listAttachmentId + '\' and Id > \'' + lastListItemIdProcessed + '\' order by Id limit ' + batchSize;
            } else {
                listItemSOQL = 'select Id, MSD_CORE_Account__c from MSD_CORE_List_Item__c where MSD_CORE_List_Attachment__c = \'' + listAttachmentId + '\' order by Id limit ' + batchSize;
            }

            List<MSD_CORE_List_Item__c> listItemList = Database.query(listItemSOQL);

            for (MSD_CORE_List_Item__c li : listItemList) {
                Survey_Target_vod__c surveyTarget = new Survey_Target_vod__c(
                    Survey_vod__c = surveyId,
                    Account_vod__c = li.MSD_CORE_Account__c,
                    Survey_Product__c = listProduct.MSD_CORE_Product__c,
                    Start_Date_vod__c = survey.Start_Date_vod__c,
                    End_Date_vod__c = survey.End_Date_vod__c,
                    MRK_Most_Recent__c = true
                );

                surveyTargetList.add(surveyTarget);
            }

            // TODO: push this into settings and remove dependency on MRKSurveyUTLCls to make it global
            MRKSurveyUTLCls.BypasssMRKSurveyTgttoActiveTrigger = true;

            // TODO: error handling
            Database.SaveResult[] srList = Database.insert(surveyTargetList);

            if (listItemList.size() > 0) {
                opts.put('lastListItemIdProcessed', listItemList[listItemList.size() - 1].Id + '');
            }

            recordsProcessed += listItemList.size();
            opts.put('recordsProcessed', recordsProcessed + '');

            if (la.MSD_CORE_Item_Count__c == recordsProcessed) {

                /*
                Campaign_vod__c campaign = [select Id, Active_MRK__c from Campaign_vod__c where Id = :campaignId];
                campaign.Active_MRK__c = true;
                Database.SaveResult campaignSaveResult = Database.update(campaign);

                if (!campaignSaveResult.isSuccess()) {
                    opts.put('error', 'failed to update Active to tue for campaign with ID ' + campaignId);
                    opts.put('done', 'true');
                }
                */

                listApplication.MSD_CORE_Status__c = 'active';
                listApplicationSaveResult = Database.update(listApplication);

                // TODO: handle error
                if (!listApplicationSaveResult.isSuccess()) {
                    opts.put('error', 'failed to update Status to "active" for list application with ID ' + listApplicationId);
                    opts.put('done', 'true');
                }
            }

            opts.put('done', (la.MSD_CORE_Item_Count__c == recordsProcessed) ? 'true' : 'false');
            opts.put('op', 'createSurveyTargets');

        }


        return opts;
    }


  public static Map<String,String> createCreateSurveyTargetsFromListApplicationJobItem(String listApplicationId) {
    MSD_CORE_List_Application__c listApplication = [select Id, MSD_CORE_List__c, MSD_CORE_List_Attachment__c from MSD_CORE_List_Application__c where Id = :listApplicationId];

    MSD_CORE_List_Attachment__c la = [select Id, MSD_CORE_List__c, MSD_CORE_Status__c, MSD_CORE_Version__c from MSD_CORE_List_Attachment__c where Id = :listApplication.MSD_CORE_List_Attachment__c];

    Map<String,Object> jobItem = MSD_CORE_JobQueueService.getJobItemTemplate('createSurveyTargetsFromListApplication');
    Map<String,String> jobItemParams = MSD_CORE_JobQueueService.getJobItemParamsTemplate('createSurveyTargetsFromListApplication');

    jobItemParams.put('listId', listApplication.MSD_CORE_List__c + '');
    jobItemParams.put('listApplicationId', listApplicationId);
    jobItemParams.put('listAttachmentId', la.Id + '');
    jobItem.put('params', JSON.serializePretty(jobItemParams));

    Map<String,String> m = new Map<String,String>();

    for (String key : jobItem.keySet()) {
        m.put(key, (String)jobItem.get(key));
    }

    return m;
  }

    public static Map<String,Object> createCreateSurveyTargetsFromListApplicationJobGroup(String listApplicationId) {

        List<Map<String,String>> jobItemList = new List<Map<String,String>>();
        jobItemList.add( createCreateSurveyTargetsFromListApplicationJobItem(listApplicationId) );

        Map<String,Object> jobGroup = new Map<String,Object>();
        jobGroup.put('name', 'create survey targets from list application');
        jobGroup.put('jobItemList', jobItemList);

        return jobGroup;
    }


public static Map<String,String> asyncCreateSurveyTargetsFromListApplication(String listApplicationId) {

    Map<String,Object> result = MSD_CORE_JobQueueService.addJobGroup(createCreateSurveyTargetsFromListApplicationJobGroup(listApplicationId));
    MSD_CORE_JobQueueService.run();

    return new Map<String,String>();
  }

    public static Map<String,String> createProductMetricCampaignFromListApplication(Map<String,String> opts) {
        Map<String, String> result = opts.clone();

        String op = opts.get('op');
        String listId = opts.get('listId');
        String listApplicationId = opts.get('listApplicationId');
        Integer batchSize = Integer.valueOf(opts.get('batchSize'));
        Integer recordsProcessed = Integer.valueOf(opts.get('recordsProcessed'));

        MSD_CORE_List_Application__c listApplication = [select Id,  MSD_CORE_List__c, MSD_CORE_List_Attachment__c, MSD_CORE_Related_Record_ID__c, MSD_CORE_Status__c, MSD_CORE_Type__c, Name from MSD_CORE_List_Application__c where Id = :listApplicationId];

        MSD_CORE_List__c l = (MSD_CORE_List__c)Database.query(MSD_CORE_Setting.getString('LIST_MANAGER', 'listsSOQL') + ' where Id = \'' + listId + '\'');

        List<MSD_CORE_List_Attachment__c> listAttachmentList = [select Id, MSD_CORE_List__c, MSD_CORE_Status__c, MSD_CORE_Type__c, MSD_CORE_Item_Count__c from MSD_CORE_List_Attachment__c where Id = :listApplication.MSD_CORE_List_Attachment__c];

        if (listAttachmentList.size() == 0) {
            // TODO: translate
            opts.put('error', 'no active list attachments exist for List with Id = ' + listId);
            return opts;
        }

        if (listAttachmentList.size() > 1) {
            // TODO: translate
            opts.put('error', 'more than one active list attachment exist for List with Id = ' + listId);
            return opts;
        }

        MSD_CORE_List_Attachment__c la = listAttachmentList[0];
        String listAttachmentId = la.Id;

        if ( (op == 'createProductMetricCampaign') || (op == 'createProductMetricCampaignDeleteProductMetricRecordsPhase') ) {

            listApplication.MSD_CORE_Status__c = 'activating';
            Database.SaveResult listApplicationSaveResult = Database.update(listApplication);

            // TODO: handle error
            if (!listApplicationSaveResult.isSuccess()) {
                opts.put('error', 'failed to update Status to "activing" for list application with ID ' + listApplicationId);
                opts.put('done', 'true');
            }


            List<MSD_CORE_List_Product__c> listProductList = [select Id, MSD_CORE_List__c, MSD_CORE_Product__c, MSD_CORE_Product__r.Name from MSD_CORE_List_Product__c where MSD_CORE_List__c = :listId];
            if (listProductList.size() == 0) {
                // TODO: translate
                opts.put('error', 'no active list products exist for List with Id = ' + listId);
                return opts;
            }

            if (listProductList.size() > 1) {
                // TODO: translate
                opts.put('error', 'more than one active list product exist for List with Id = ' + listId);
                return opts;
            }

            MSD_CORE_List_Product__c listProduct = listProductList[0];

            String lastListItemIdProcessed = opts.get('lastListItemIdProcessed');

            Product_vod__c campaignsRootProduct = (Product_vod__c)Database.query(MSD_CORE_Setting.getString('LIST_MANAGER', 'campaignsRootProductSOQL'));
            String campaignsRootProductId = campaignsRootProduct.Id;

            String campaignProductSOQLTemplate = MSD_CORE_Setting.getString('LIST_MANAGER', 'campaignProductSOQLTemplate');
            String campaignProductSOQL = string.format(campaignProductSOQLTemplate, new List<String>{ '\'' + l.MSD_CORE_Name__c + '\'',  '\'Detail\'',  '\'Campaign\'' });
            MSD_CORE_Logger.debug('campaignProductSOQL = ' + campaignProductSOQL);

            List<Product_vod__c> campaignProductList = (List<Product_vod__c>)Database.query(campaignProductSOQL);
            Product_vod__c campaignProduct;
            String campaignProductId;
            if (campaignProductList.size() == 0) {

                campaignProduct = new Product_vod__c(
                    Name = l.MSD_CORE_Name__c,
                    External_ID_vod__c = l.Name,
                    Product_Type_vod__c = 'Detail',
                    External_Product_Type_MRK__c = 'Campaign',
                    Active_MRK__c = true,
                    No_Details_vod__c = true,
                    No_Cycle_Plans_vod__c = true
                    // TODO: does display order need to be populated?
                    // Display_Order_vod__c
                );

                Database.SaveResult campaignProductSaveResult = Database.insert(campaignProduct);
                if (!campaignProductSaveResult.isSuccess()) {
                    opts.put('error', 'failed to create campaign product for List with name ' + l.MSD_CORE_Name__c + ' and ID ' + l.Id);
                    return opts;
                }
                campaignProductId = campaignProductSaveResult.getId();

            } else {
                campaignProduct = campaignProductList[0];
                campaignProductId = campaignProduct.Id;
            }

            String detailGroupProductId = [select Id from Product_vod__c where External_ID_vod__c = 'Customer_Potential'].Id;

            String campaignProductGroupSOQLTemplate = MSD_CORE_Setting.getString('LIST_MANAGER', 'campaignProductGroupSOQLTemplate');
            String campaignProductGroupSOQL = string.format(campaignProductGroupSOQLTemplate, new List<String>{ '\'Campaigns\'', '\'' + campaignsRootProductId + '\'', '\'' + campaignProductId + '\'' });
            List<Product_Group_vod__c> campaignProductGroupList = (List<Product_Group_vod__c>)Database.query(campaignProductGroupSOQL);
            Product_Group_vod__c campaignProductGroup;
            String campaignProductGroupId;
            if (campaignProductGroupList.size() == 0) {

                campaignProductGroup = new Product_Group_vod__c(
                    Name = 'Campaigns',
                    Product_Catalog_vod__c = campaignsRootProductId,
                    Product_vod__c = campaignProductId,
                    Description_vod__c = 'Holder for all campaigns that are products'
                );

                Database.SaveResult campaignProductGroupSaveResult = Database.insert(campaignProductGroup);
                if (!campaignProductGroupSaveResult.isSuccess()) {
                    opts.put('error', 'failed to create campaign product group for List with name ' + l.MSD_CORE_Name__c + ' and ID ' + l.Id);
                    return opts;
                }
                campaignProductGroupId = campaignProductGroupSaveResult.getId();

            } else {
                campaignProductGroup = campaignProductGroupList[0];
                campaignProductGroupId = campaignProductGroup.Id;
            }

            if (op == 'createProductMetricCampaign') {

                List<Product_Metrics_vod__c> productMetricsList = new List<Product_Metrics_vod__c>();

                String listItemSOQL;
                if (lastListItemIdProcessed != null && lastListItemIdProcessed != '') {
                    listItemSOQL = 'select Id, MSD_CORE_Value__c, MSD_CORE_Account__c, MSD_CORE_Field_Name_0__c, MSD_CORE_Field_Value_0__c, MSD_CORE_Field_Name_1__c, MSD_CORE_Field_Value_1__c, MSD_CORE_Field_Name_2__c, MSD_CORE_Field_Value_2__c, MSD_CORE_Field_Name_3__c, MSD_CORE_Field_Value_3__c,MSD_CORE_Field_Name_4__c, MSD_CORE_Field_Value_4__c,MSD_CORE_Field_Name_5__c, MSD_CORE_Field_Value_5__c,MSD_CORE_Field_Name_6__c, MSD_CORE_Field_Value_6__c,MSD_CORE_Field_Name_7__c, MSD_CORE_Field_Value_7__c,MSD_CORE_Field_Name_8__c, MSD_CORE_Field_Value_8__c,MSD_CORE_Field_Name_9__c, MSD_CORE_Field_Value_9__c from MSD_CORE_List_Item__c where MSD_CORE_List_Attachment__c = \'' + listAttachmentId + '\' and Id > \'' + lastListItemIdProcessed + '\' order by Id limit ' + batchSize;
                } else {
                    listItemSOQL = 'select Id, MSD_CORE_Value__c, MSD_CORE_Account__c, MSD_CORE_Field_Name_0__c, MSD_CORE_Field_Value_0__c, MSD_CORE_Field_Name_1__c, MSD_CORE_Field_Value_1__c, MSD_CORE_Field_Name_2__c, MSD_CORE_Field_Value_2__c, MSD_CORE_Field_Name_3__c, MSD_CORE_Field_Value_3__c,MSD_CORE_Field_Name_4__c, MSD_CORE_Field_Value_4__c,MSD_CORE_Field_Name_5__c, MSD_CORE_Field_Value_5__c,MSD_CORE_Field_Name_6__c, MSD_CORE_Field_Value_6__c,MSD_CORE_Field_Name_7__c, MSD_CORE_Field_Value_7__c,MSD_CORE_Field_Name_8__c, MSD_CORE_Field_Value_8__c,MSD_CORE_Field_Name_9__c, MSD_CORE_Field_Value_9__c from MSD_CORE_List_Item__c where MSD_CORE_List_Attachment__c = \'' + listAttachmentId + '\' order by Id limit ' + batchSize;
                }

                List<MSD_CORE_List_Item__c> listItemList = Database.query(listItemSOQL);

                String dateFormatString = MSD_CORE_Setting.getString('LIST_MANAGER', 'dateFormatString');

                for (MSD_CORE_List_Item__c li : listItemList) {

                    Product_Metrics_vod__c productMetricForProductGroup = null;
                    if (la.MSD_CORE_Type__c == 'account ids') {
                        productMetricForProductGroup = new Product_Metrics_vod__c(
                            Account_vod__c = li.MSD_CORE_Account__c,
                            Detail_Group_vod__c = campaignsRootProductId,
                            Products_vod__c = campaignProductId,
                            Start_Date_MRK__c = Datetime.newInstance(l.MSD_CORE_Start_Date__c, Time.newInstance(0,0,0,0)).format(dateFormatString),
                            End_Date__c = Datetime.newInstance(l.MSD_CORE_End_Date__c, Time.newInstance(0,0,0,0)).format(dateFormatString),
                            Active_MRK__c = true,
                            External_ID_vod__c = li.MSD_CORE_Value__c + '_' + l.Name,
                            Member_MRK__c = 'YES',
                            Description_MRK__c = l.MSD_CORE_Description__c,
                            MRK_Campaign_Product__c = listProduct.MSD_CORE_Product__r.Name,
                            Modified_Date__c = Datetime.now().format(dateFormatString)
                        );
                    }


                    Product_Metrics_vod__c productMetricForProduct = new Product_Metrics_vod__c(
                        Account_vod__c = li.MSD_CORE_Account__c,
                        //Products_vod__c = campaignProductId,
                        Products_vod__c = campaignsRootProductId,
                        Start_Date_MRK__c = Datetime.newInstance(l.MSD_CORE_Start_Date__c, Time.newInstance(0,0,0,0)).format(dateFormatString),
                        End_Date__c = Datetime.newInstance(l.MSD_CORE_End_Date__c, Time.newInstance(0,0,0,0)).format(dateFormatString),
                        Active_MRK__c = true,
                        Member_MRK__c = 'YES',
                        Description_MRK__c = l.MSD_CORE_Description__c,
                        External_ID_vod__c = li.MSD_CORE_Value__c + '_' + l.Name + '_CP',
                        MRK_Campaign_Product__c = listProduct.MSD_CORE_Product__r.Name,
                        Modified_Date__c = Datetime.now().format(dateFormatString)
                    );


                    if (la.MSD_CORE_Type__c == 'product metric values') {

                        productMetricForProductGroup = new Product_Metrics_vod__c(
                            Account_vod__c = li.MSD_CORE_Account__c,
                            //Detail_Group_vod__c = campaignsRootProductId,
                            Products_vod__c = detailGroupProductId,
                            //Start_Date_MRK__c = Datetime.newInstance(l.MSD_CORE_Start_Date__c, Time.newInstance(0,0,0,0)).format(dateFormatString),
                            //End_Date__c = Datetime.newInstance(l.MSD_CORE_End_Date__c, Time.newInstance(0,0,0,0)).format(dateFormatString),
                            Active_MRK__c = true,
                            External_ID_vod__c = li.MSD_CORE_Value__c + '_CP'
                            //Member_MRK__c = 'YES',
                            //Description_MRK__c = l.MSD_CORE_Description__c,
                            //MRK_Campaign_Product__c = listProduct.MSD_CORE_Product__r.Name,
                            //Modified_Date__c = Datetime.now().format(dateFormatString)
                        );

                        // clear out product metric campaign values
                        productMetricForProduct.put('Detail_Group_vod__c', detailGroupProductId);
                        productMetricForProduct.Products_vod__c = listProduct.MSD_CORE_Product__c;
                        productMetricForProduct.put('Start_Date_MRK__c', '');
                        productMetricForProduct.put('End_Date__c', '');
                        productMetricForProduct.put('Member_MRK__c', '');
                        productMetricForProduct.put('Description_MRK__c', '');
                        productMetricForProduct.put('MRK_Campaign_Product__c', '');
                        productMetricForProduct.put('External_ID_vod__c', li.MSD_CORE_Value__c + '_' + l.Name + '_LPM');

                        Boolean hasMoreValues = true;
                        Integer idx = 0;
                        while (hasMoreValues) {
                            String listItemFieldName = 'MSD_CORE_Field_Name_' + idx + '__c';
                            String listItemFieldValueName = 'MSD_CORE_Field_Value_' + idx + '__c';
                            String productMetricFieldName = (String)li.get(listItemFieldName);
                            if ((productMetricFieldName != null) && (productMetricFieldName != '')) {
                                String productMetricFieldValue = (String)li.get(listItemFieldValueName);
                                productMetricForProduct.put(productMetricFieldName, productMetricFieldValue);
                            } else {
                                hasMoreValues = false;
                            }
                            idx++;
                        }
                    }

                    if (productMetricForProductGroup != null) {
                        productMetricsList.add(productMetricForProductGroup);
                    }

                    productMetricsList.add(productMetricForProduct);

                }

                // TODO: error handling
                Database.SaveResult[] productMetricsSaveResultList = Database.insert(productMetricsList, false);
                String errorsString = '';
                for (Database.SaveResult productMetricsSaveResult : productMetricsSaveResultList) {
                    if (!productMetricsSaveResult.isSuccess()) {
                        for(Database.Error err : productMetricsSaveResult.getErrors()) {
                            errorsString += (err.getStatusCode() + ': ' + err.getMessage() + '\n');
                            errorsString += ('fields that affected this error: ' + err.getFields() + '\n\n');
                        }
                    }
                }

                if (errorsString != '') {
                    Integer maxStringLength = 15000;
                    if (errorsString.length() > maxStringLength) {
                        errorsString = errorsString.substring(0, maxStringLength);
                    }
                    opts.put('errors', 'Failed to create batch of product metric records for List with name' + l.MSD_CORE_Name__c + ' and Id ' + l.Id + '\n\n' + errorsString);

                    // TODO: should we fail hard here and return?
                    //return opts;
                }

                recordsProcessed += listItemList.size();
                opts.put('recordsProcessed', recordsProcessed + '');

                if (listItemList.size() > 0) {
                    opts.put('lastListItemIdProcessed', listItemList[listItemList.size() - 1].Id + '');
                    opts.put('done', 'false');
                    opts.put('op', 'createProductMetricCampaign');
                } else {
                    opts.put('done', 'false');
                    opts.put('op', 'createProductMetricCampaignDeleteProductMetricRecordsPhase');                                        
                    opts.put('lastListItemIdProcessed', '');
                }

            }

            if (op == 'createProductMetricCampaignDeleteProductMetricRecordsPhase') {
                MSD_CORE_Logger.loggingEnabled = true;
                
                String productMetricsSOQL;

                // TODO: blank out lastListItemIdProcessed at the end of 'createProductMetricCampaign' op

                if (lastListItemIdProcessed != null && lastListItemIdProcessed != '') {
                    productMetricsSOQL = 'select Id, Account_vod__c, Products_vod__c from Product_Metrics_vod__c where Products_vod__c = \'' + campaignProductId + '\' and Id > \'' + lastListItemIdProcessed + '\' order by Id limit ' + batchSize;
                } else {
                    productMetricsSOQL = 'select Id, Account_vod__c, Products_vod__c from Product_Metrics_vod__c where Products_vod__c = \'' + campaignProductId + '\' order by Id limit ' + batchSize;
                }

                Set<String> productMetricAccountIdSet = new Set<String>();
                Map<String,Set<String>> accountIdToProductMetricIdSetMap = new Map<String,Set<String>>();

                MSD_CORE_Logger.debug('productMetricsSOQL = ' + productMetricsSOQL);

                List<Product_Metrics_vod__c> productMetricsList = Database.query(productMetricsSOQL);
                for (Product_Metrics_vod__c productMetric : productMetricsList) {
                    Set<String> productMetricIdSet = accountIdToProductMetricIdSetMap.get(productMetric.Account_vod__c);
                    if (productMetricIdSet == null) {
                        productMetricIdSet = new Set<String>();
                        accountIdToProductMetricIdSetMap.put(productMetric.Account_vod__c, productMetricIdSet);
                    }

                    productMetricIdSet.add(productMetric.Id);
                    productMetricAccountIdSet.add(productMetric.Account_vod__c);
                }

                MSD_CORE_Logger.debug('productMetricAccountIdSet=\n' + JSON.serializePretty(productMetricAccountIdSet));
                MSD_CORE_Logger.debug('accountIdToProductMetricIdSetMap=\n' + JSON.serializePretty(accountIdToProductMetricIdSetMap));

                String listItemSOQL = 'select Id, MSD_CORE_Account__c from MSD_CORE_List_Item__c where MSD_CORE_List_Attachment__c = :listAttachmentId and MSD_CORE_Account__c IN :productMetricAccountIdSet';
                MSD_CORE_Logger.debug('listItemSOQL = ' + listItemSOQL);
                List<MSD_CORE_List_Item__c> listItemList = Database.query(listItemSOQL);
                MSD_CORE_Logger.debug('listItemList=\n' + JSON.serializePretty(listItemList));
                
                Set<String> listItemAccountIdSet = new Set<String>();
                Set<String> productMetricIdsToDeleteSet = new Set<String>();
                for (MSD_CORE_List_Item__c listItem : listItemList) {
                    listItemAccountIdSet.add(listItem.MSD_CORE_Account__c);  
                }

                for (String productMetricAccountId : productMetricAccountIdSet) {
                    if (!listItemAccountIdSet.contains(productMetricAccountId)) {
                        productMetricIdsToDeleteSet.addAll(
                            accountIdToProductMetricIdSetMap.get(productMetricAccountId)
                        );                        
                    }
                }

                MSD_CORE_Logger.debug('productMetricIdsToDeleteSet=\n' + JSON.serializePretty(productMetricIdsToDeleteSet));

                List<Product_Metrics_vod__c> productMetricsToDeleteList = [select Id from Product_Metrics_vod__c where Id IN :productMetricIdsToDeleteSet];

                MSD_CORE_Logger.debug('productMetricsToDeleteList=\n' + JSON.serializePretty(productMetricsToDeleteList));
                MSD_CORE_Logger.flush();

                if (productMetricsToDeleteList.size() > 0) {

                    // TODO: error handling
                    Database.DeleteResult[] productMetricsDeleteResultList = Database.delete(productMetricsToDeleteList, false);
                    String errorsString = '';
                    for (Database.DeleteResult productMetricsDeleteResult : productMetricsDeleteResultList) {
                        if (!productMetricsDeleteResult.isSuccess()) {
                            for(Database.Error err : productMetricsDeleteResult.getErrors()) {
                                errorsString += (err.getStatusCode() + ': ' + err.getMessage() + '\n');
                                errorsString += ('fields that affected this error: ' + err.getFields() + '\n\n');
                            }
                        }
                    }

                    if (errorsString != '') {
                        Integer maxStringLength = 15000;
                        if (errorsString.length() > maxStringLength) {
                            errorsString = errorsString.substring(0, maxStringLength);
                        }
                        opts.put('errors', 'Failed to delete batch of product metric records for List with name' + l.MSD_CORE_Name__c + ' and Id ' + l.Id + '\n\n' + errorsString);

                        // TODO: should we fail hard here and return?
                        //return opts;
                    }

                }

                if (productMetricsList.size() > 0) {
                    opts.put('lastProductMetricsIdProcessed', productMetricsList[productMetricsList.size() - 1].Id + '');
                    opts.put('lastListItemIdProcessed', productMetricsList[productMetricsList.size() - 1].Id + '');
                    opts.put('done', 'false');
                    opts.put('op', 'createProductMetricCampaignDeleteProductMetricRecordsPhase');                                        

                } else {

                    listApplication.MSD_CORE_Status__c = 'active';
                    listApplication.MSD_CORE_Related_Record_ID__c = campaignProductId;
                    listApplicationSaveResult = Database.update(listApplication);

                    opts.put('done', 'true');
                    opts.put('op', 'createProductMetricCampaignDeleteProductMetricRecordsPhase');                                        
                }

            }

    

        }

        if (op == 'inactivateProductMetricCampaign') {
            listApplication.MSD_CORE_Status__c = 'inactivating';
            Database.SaveResult listApplicationSaveResult = Database.update(listApplication);

            // TODO: handle error
            if (!listApplicationSaveResult.isSuccess()) {
                opts.put('error', 'failed to update Status to "inactivating" for list application with ID ' + listApplicationId);
                opts.put('done', 'true');
            }

            String soql = 'select Id from Product_Metrics_vod__c where Products_vod__c = \'' + listApplication.MSD_CORE_Related_Record_ID__c + '\' limit ' + batchSize;

            List<Product_Metrics_vod__c> productMetricList = Database.query(soql);

            if (productMetricList.size() > 0) {
                Database.DeleteResult[] dr = Database.delete(productMetricList);

                // TODO: handle error
            }

            opts.put('op', 'inactivateProductMetricCampaign');

            if (productMetricList.size() >= batchSize) {
                opts.put('done', 'false');
            } else {

                // inactivate product metric campaign product
                Product_vod__c p = [select Id, Active_MRK__c from Product_vod__c where Id = :listApplication.MSD_CORE_Related_Record_ID__c];
                p.Active_MRK__c = false;
                Database.update(p);

                listApplication.MSD_CORE_Status__c = 'inactive';
                listApplicationSaveResult = Database.update(listApplication);

                // TODO: handle error
                if (!listApplicationSaveResult.isSuccess()) {
                    opts.put('error', 'failed to update Status to "inactive" for list application with ID ' + listApplicationId);
                }

                opts.put('done', 'true');
            }
        }
        return opts;
    }


  public static Map<String,String> createCreateProductMetricCampaignFromListApplicationJobItem(String listApplicationId) {
    MSD_CORE_List_Application__c listApplication = [select Id, MSD_CORE_List__c, MSD_CORE_List_Attachment__c from MSD_CORE_List_Application__c where Id = :listApplicationId];

    MSD_CORE_List_Attachment__c la = [select Id, MSD_CORE_List__c, MSD_CORE_Status__c, MSD_CORE_Version__c from MSD_CORE_List_Attachment__c where Id = :listApplication.MSD_CORE_List_Attachment__c];

    Map<String,Object> jobItem = MSD_CORE_JobQueueService.getJobItemTemplate('createProductMetricCampaignFromListApplication');
    Map<String,String> jobItemParams = MSD_CORE_JobQueueService.getJobItemParamsTemplate('createProductMetricCampaignFromListApplication');

    jobItemParams.put('listId', listApplication.MSD_CORE_List__c + '');
    jobItemParams.put('listApplicationId', listApplicationId);
    jobItemParams.put('listAttachmentId', la.Id + '');
    jobItem.put('params', JSON.serializePretty(jobItemParams));

    Map<String,String> m = new Map<String,String>();

    for (String key : jobItem.keySet()) {
        m.put(key, (String)jobItem.get(key));
    }

    return m;
  }

    public static Map<String,Object> createCreateProductMetricCampaignFromListApplicationJobGroup(String listApplicationId) {

        List<Map<String,String>> jobItemList = new List<Map<String,String>>();
        jobItemList.add( createCreateProductMetricCampaignFromListApplicationJobItem(listApplicationId) );

        Map<String,Object> jobGroup = new Map<String,Object>();
        jobGroup.put('name', 'create product metric campaign from list application');
        jobGroup.put('jobItemList', jobItemList);

        return jobGroup;
    }


public static Map<String,String> asyncCreateProductMetricCampaignFromListApplication(String listApplicationId) {

    Map<String,Object> result = MSD_CORE_JobQueueService.addJobGroup(createCreateProductMetricCampaignFromListApplicationJobGroup(listApplicationId));
    MSD_CORE_JobQueueService.run();

    return new Map<String,String>();
  }


    public static Map<String,String> inactivateListApplication(Map<String,String> opts) {
        Map<String,String> result = new Map<String,String>();

        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('listApplication'));

        String listApplicationtId = (String)fieldNameToValueMap.get('Id');
        String type = (String)fieldNameToValueMap.get('MSD_CORE_Type__c');

        // route to corresponding application type handler
        if (type == 'campaign') {
            result = asyncInactivateCampaignFromListApplication(listApplicationtId);
        }

        if (type == 'product metric') {
            result = asyncInactivateProductMetricCampaignFromListApplication(listApplicationtId);
        }

        if (type == 'product metric campaign') {
            result = asyncInactivateProductMetricCampaignFromListApplication(listApplicationtId);
        }

        if (type == 'survey') {
            result = inactivateSurveyTargetsFromListApplication(opts);
        }


        /*
        String listAttachmentId = (String)fieldNameToValueMap.get('Id');

        opts.put('jobItemTemplate', 'listItemsUpdate');
        opts.put('listAttachmentId', listAttachmentId);
        opts.put('fieldValue', 'inactive');
        opts.put('parentId', listAttachmentId);
        opts.put('parentFieldValue', 'inactive');

        return MSD_CORE_RecordsOperationServices.asyncExecute(opts);
        */

        return result;
    }

    public static Map<String,String> inactivateProductMetricCampaignFromListApplication(Map<String,String> opts) {
            Map<String, String> result = opts.clone();
            return result;
    }

    public static Map<String,String> inactivateSurveyTargetsFromListApplication(Map<String,String> opts) {
            Map<String, String> result = opts.clone();
            return result;
    }

    public static Map<String,String> createInactivateCampaignFromListApplicationJobItem(String listApplicationId) {

        MSD_CORE_List_Application__c listApplication = [select Id, MSD_CORE_List__c, MSD_CORE_List_Attachment__c from MSD_CORE_List_Application__c where Id = :listApplicationId];
        MSD_CORE_List_Attachment__c la = [select Id, MSD_CORE_List__c, MSD_CORE_Status__c, MSD_CORE_Version__c from MSD_CORE_List_Attachment__c where Id = :listApplication.MSD_CORE_List_Attachment__c];

        Map<String,Object> jobItem = MSD_CORE_JobQueueService.getJobItemTemplate('inactivateCampaignFromListApplication');
        Map<String,String> jobItemParams = MSD_CORE_JobQueueService.getJobItemParamsTemplate('inactivateCampaignFromListApplication');

        jobItemParams.put('listId', listApplication.MSD_CORE_List__c + '');
        jobItemParams.put('listApplicationId', listApplicationId);
        jobItemParams.put('listAttachmentId', la.Id + '');
        jobItem.put('params', JSON.serializePretty(jobItemParams));

        Map<String,String> m = new Map<String,String>();

        for (String key : jobItem.keySet()) {
            m.put(key, (String)jobItem.get(key));
        }

        return m;
      }

        public static Map<String,Object> createInactivateCampaignFromListApplicationJobGroup(String listApplicationId) {

            List<Map<String,String>> jobItemList = new List<Map<String,String>>();
            jobItemList.add( createInactivateCampaignFromListApplicationJobItem(listApplicationId) );

            Map<String,Object> jobGroup = new Map<String,Object>();
            jobGroup.put('name', 'inactivate campaign from list application');
            jobGroup.put('jobItemList', jobItemList);

            return jobGroup;
        }

  public static Map<String,String> asyncInactivateCampaignFromListApplication(String listApplicationId) {

    Map<String,Object> result = MSD_CORE_JobQueueService.addJobGroup(createInactivateCampaignFromListApplicationJobGroup(listApplicationId));
    MSD_CORE_JobQueueService.run();

    return new Map<String,String>();
  }

    public static Map<String,String> asyncInactivateProductMetricCampaignFromListApplication(String listApplicationId) {

        Map<String,Object> result = MSD_CORE_JobQueueService.addJobGroup(createInactivateProductMetricCampaignFromListApplicationJobGroup(listApplicationId));
        MSD_CORE_JobQueueService.run();

        return new Map<String,String>();
    }

    public static Map<String,String> createInactivateProductMetricCampaignFromListApplicationJobItem(String listApplicationId) {
        MSD_CORE_List_Application__c listApplication = [select Id, MSD_CORE_List__c, MSD_CORE_List_Attachment__c from MSD_CORE_List_Application__c where Id = :listApplicationId];

        //MSD_CORE_List_Attachment__c la = [select Id, MSD_CORE_List__c, MSD_CORE_Status__c, MSD_CORE_Version__c from MSD_CORE_List_Attachment__c where MSD_CORE_List__c = :listApplication.MSD_CORE_List__c and MSD_CORE_Status__c = 'active' limit 1];

        Map<String,Object> jobItem = MSD_CORE_JobQueueService.getJobItemTemplate('inactivateProductMetricCampaignFromListApplication');
        Map<String,String> jobItemParams = MSD_CORE_JobQueueService.getJobItemParamsTemplate('inactivateProductMetricCampaignFromListApplication');

        jobItemParams.put('listId', listApplication.MSD_CORE_List__c + '');
        jobItemParams.put('listApplicationId', listApplicationId);
        jobItemParams.put('listAttachmentId', listApplication.MSD_CORE_List_Attachment__c + '');
        jobItem.put('params', JSON.serializePretty(jobItemParams));

        Map<String,String> m = new Map<String,String>();

        for (String key : jobItem.keySet()) {
            m.put(key, (String)jobItem.get(key));
        }

        return m;
      }


  public static Map<String,Object> createInactivateProductMetricCampaignFromListApplicationJobGroup(String listApplicationId) {

      List<Map<String,String>> jobItemList = new List<Map<String,String>>();
      jobItemList.add( createInactivateProductMetricCampaignFromListApplicationJobItem(listApplicationId) );

      Map<String,Object> jobGroup = new Map<String,Object>();
      jobGroup.put('name', 'inactivate product metric campaign from list application');
      jobGroup.put('jobItemList', jobItemList);


      return jobGroup;
  }

    public static Map<String,String> createProcessUpdatesToListAttachmentJobItem(String listAttachmentId) {

        MSD_CORE_List_Attachment__c la = [select Id, MSD_CORE_List__c, MSD_CORE_Status__c, MSD_CORE_Version__c from MSD_CORE_List_Attachment__c where Id = :listAttachmentId];

        Map<String,Object> jobItem = MSD_CORE_JobQueueService.getJobItemTemplate('processUpdatesToListAttachment');
        Map<String,String> jobItemParams = MSD_CORE_JobQueueService.getJobItemParamsTemplate('processUpdatesToListAttachment');

        jobItemParams.put('listId', la.MSD_CORE_List__c + '');
        jobItemParams.put('listAttachmentId', la.Id + '');
        jobItem.put('params', JSON.serializePretty(jobItemParams));

        Map<String,String> m = new Map<String,String>();

        for (String key : jobItem.keySet()) {
            m.put(key, (String)jobItem.get(key));
        }

        return m;
      }

  public static Map<String,Object> createProcessUpdatesToListAttachmentJobGroup(String listAttachmentId) {

            List<Map<String,String>> jobItemList = new List<Map<String,String>>();
            jobItemList.add( createProcessUpdatesToListAttachmentJobItem(listAttachmentId) );

            Map<String,Object> jobGroup = new Map<String,Object>();
            jobGroup.put('name', 'process updates to list attachment');
            jobGroup.put('jobItemList', jobItemList);

            return jobGroup;
        }



  public static Map<String,String> asyncProcessUpdatesToListAttachment(String listAttachmentId) {

    Map<String,Object> result = MSD_CORE_JobQueueService.addJobGroup(createProcessUpdatesToListAttachmentJobGroup(listAttachmentId));
    MSD_CORE_JobQueueService.run();

    return new Map<String,String>();
  }

  public static Map<String,String> identifyAndActivateLists(Map<String,String> opts) {
    Map<String,String> result = new Map<String,String>();

    String identifyActivateListsSOQL = MSD_CORE_Setting.getString('LIST_MANAGER', 'identifyActivateListsSOQL');

    List<MSD_CORE_List__c> listList = Database.query(identifyActivateListsSOQL);
    for (MSD_CORE_List__c l : listList) {
        activateList(new Map<String,String>{'listId' => l.Id});
    }
    return result;
  }

    public static Map<String,String> activateList(Map<String,String> opts) {
    List<Map<String,Object>> jobGroupList = new List<Map<String,Object>>();

    String listId = opts.get('listId');

    MSD_CORE_List__c l = [select Id, MSD_CORE_Status__c from MSD_CORE_List__c where Id = :listId];
    l.MSD_CORE_Status__c = 'activating';
    Database.SaveResult listSaveResult = Database.update(l);
    // TODO: handle error
    if (!listSaveResult.isSuccess()) {

    }

    Map<String,String> data = new Map<String,String>();
    Map<String,String> listAttachmentRecordMap = new Map<String,String>();

    List<MSD_CORE_List_Attachment__c> activeListAttachmentList = [select Id, MSD_CORE_Country_Code__c, MSD_CORE_Error__c, MSD_CORE_Item_Count__c, MSD_CORE_List__c, MSD_CORE_Match_Status__c, MSD_CORE_Status__c, MSD_CORE_Type__c, MSD_CORE_Version__c, Name, RecordTypeId from MSD_CORE_List_Attachment__c where MSD_CORE_List__c = :listId and MSD_CORE_Status__c = 'pending activation'];
    for (MSD_CORE_List_Attachment__c listAttachment : activeListAttachmentList) {
        listAttachmentRecordMap.put('Id', listAttachment.Id + '');
        data.put('listAttachment', JSON.serialize(listAttachmentRecordMap));
        activateListAttachment(data);
    }

    List<MSD_CORE_List_Application__c> activeListApplicationList = [select Id, MSD_CORE_Country_Code__c, MSD_CORE_List__c, MSD_CORE_List_Attachment__c, MSD_CORE_Related_Record_ID__c, MSD_CORE_Status__c, MSD_CORE_Type__c, RecordTypeId from MSD_CORE_List_Application__c where MSD_CORE_List__c = :listId and MSD_CORE_Status__c = 'pending activation'];
    for (MSD_CORE_List_Application__c listApplication : activeListApplicationList) {
        String listApplicationAsJSON = JSON.serialize(listApplication);
        activateListApplication(new Map<String,String>{'listApplication' => listApplicationAsJSON});
    }

    for (Map<String,Object> jobGroup : jobGroupList) {
        MSD_CORE_JobQueueService.addJobGroup(jobGroup);
    }

    MSD_CORE_JobQueueService.run();

    return opts;

}


  public static Map<String,String> identifyAndExpireLists(Map<String,String> opts) {
    Map<String,String> result = new Map<String,String>();

    String identifyExpiredListsSOQL = MSD_CORE_Setting.getString('LIST_MANAGER', 'identifyExpiredListsSOQL');

    List<MSD_CORE_List__c> listList = Database.query(identifyExpiredListsSOQL);
    for (MSD_CORE_List__c l : listList) {
        expireList(new Map<String,String>{'listId' => l.Id});
    }
    return result;
  }

public static Map<String,String> expireList(Map<String,String> opts) {
    List<Map<String,Object>> jobGroupList = new List<Map<String,Object>>();

    String listId = opts.get('listId');

    MSD_CORE_List__c l = [select Id, MSD_CORE_Status__c from MSD_CORE_List__c where Id = :listId];
    l.MSD_CORE_Status__c = 'expired';
    Database.SaveResult listSaveResult = Database.update(l);
    // TODO: handle error
    if (!listSaveResult.isSuccess()) {

    }


    Map<String,String> data = new Map<String,String>();
    Map<String,String> listAttachmentRecordMap = new Map<String,String>();

    List<MSD_CORE_List_Attachment__c> activeListAttachmentList = [select Id, MSD_CORE_Country_Code__c, MSD_CORE_Error__c, MSD_CORE_Item_Count__c, MSD_CORE_List__c, MSD_CORE_Match_Status__c, MSD_CORE_Status__c, MSD_CORE_Type__c, MSD_CORE_Version__c, Name, RecordTypeId from MSD_CORE_List_Attachment__c where MSD_CORE_List__c = :listId and MSD_CORE_Status__c = 'active'];
    for (MSD_CORE_List_Attachment__c listAttachment : activeListAttachmentList) {
        listAttachmentRecordMap.put('Id', listAttachment.Id + '');
        data.put('listAttachment', JSON.serialize(listAttachmentRecordMap));
        jobGroupList.add( MSD_CORE_RecordsOperationServices.createRecordsOperationJobGroup( createInactivateListAttachmentParams(data) ) );
    }

    List<MSD_CORE_List_Application__c> activeListApplicationList = [select Id, MSD_CORE_Country_Code__c, MSD_CORE_List__c, MSD_CORE_List_Attachment__c, MSD_CORE_Related_Record_ID__c, MSD_CORE_Status__c, MSD_CORE_Type__c, RecordTypeId from MSD_CORE_List_Application__c where MSD_CORE_List__c = :listId and MSD_CORE_Status__c = 'active'];
    for (MSD_CORE_List_Application__c listApplication : activeListApplicationList) {
        String listApplicationAsJSON = JSON.serialize(listApplication);
        Map<String,Object> jobGroup = createInactivateListApplicationJobGroup(new Map<String,String>{'listApplication' => listApplicationAsJSON});
        if (jobGroup != null) {
            jobGroupList.add( jobGroup );
        }

    }

    for (Map<String,Object> jobGroup : jobGroupList) {
        MSD_CORE_JobQueueService.addJobGroup(jobGroup);
    }

    MSD_CORE_JobQueueService.run();

    return opts;

}

public static Map<String,String> processUpdatesToListAttachment(Map<String,String> opts) {
    String listAttachmentId = opts.get('listAttachmentId');

    List<Map<String,String>> jobItemList = new List<Map<String,String>>();
    List<Map<String,Object>> jobGroupList = new List<Map<String,Object>>();

    MSD_CORE_List_Attachment__c listAttachment = [select Id, MSD_CORE_Country_Code__c, MSD_CORE_Error__c, MSD_CORE_Item_Count__c, MSD_CORE_List__c, MSD_CORE_Match_Status__c, MSD_CORE_Status__c, MSD_CORE_Type__c, MSD_CORE_Version__c, Name, RecordTypeId from MSD_CORE_List_Attachment__c where Id = :listAttachmentId];

    List<MSD_CORE_List_Attachment__c> activeListAttachmentList = [select Id, MSD_CORE_Country_Code__c, MSD_CORE_Error__c, MSD_CORE_Item_Count__c, MSD_CORE_List__c, MSD_CORE_Match_Status__c, MSD_CORE_Status__c, MSD_CORE_Type__c, MSD_CORE_Version__c, Name, RecordTypeId from MSD_CORE_List_Attachment__c where MSD_CORE_List__c = :listAttachment.MSD_CORE_List__c and MSD_CORE_Status__c = 'active'];

    MSD_CORE_List_Attachment__c activeListAttachment = null;
    if (activeListAttachmentList.size() > 0) {
       activeListAttachment = activeListAttachmentList[0];
    }

    Map<String,String> data = new Map<String,String>();

    Map<String,String> listAttachmentRecordMap = new Map<String,String>();

    // inactivate the active list attachment
    if (activeListAttachment != null) {
        listAttachmentRecordMap.put('Id', activeListAttachment.Id + '');
        data.put('listAttachment', JSON.serialize(listAttachmentRecordMap));

        jobGroupList.add( MSD_CORE_RecordsOperationServices.createRecordsOperationJobGroup( createInactivateListAttachmentParams(data) ) );
    }

    listAttachmentRecordMap.put('Id', listAttachmentId);
    data.put('listAttachment', JSON.serialize(listAttachmentRecordMap));

    jobGroupList.add( createUnpackListAttachmentJobGroup(listAttachmentId) );
    jobGroupList.add( createAccountMatchJobGroup(listAttachmentId) );
    jobGroupList.add( MSD_CORE_RecordsOperationServices.createRecordsOperationJobGroup( createActivateListAttachmentParams(data) ) );

    // sync any list applications below
    List<MSD_CORE_List_Application__c> activeListApplicationList = [select Id, MSD_CORE_Country_Code__c, MSD_CORE_List__c, MSD_CORE_List_Attachment__c, MSD_CORE_Related_Record_ID__c, MSD_CORE_Status__c, MSD_CORE_Type__c, RecordTypeId from MSD_CORE_List_Application__c where MSD_CORE_List__c = :listAttachment.MSD_CORE_List__c and MSD_CORE_Status__c = 'active'];

    List<MSD_CORE_List_Application__c> newListApplicationList = new List<MSD_CORE_List_Application__c>();

    for (MSD_CORE_List_Application__c activeListApplication : activeListApplicationList) {
        MSD_CORE_List_Application__c la = activeListApplication.clone();
        la.MSD_CORE_List_Attachment__c = listAttachmentId;
        Database.SaveResult sr = Database.insert(la);
        // TODO: handle error
        if (!sr.isSuccess()) {
        }

        //la.Id = sr.getId();


        activeListApplication.MSD_CORE_Status__c = 'superseded';
        Database.SaveResult activeListApplicationSaveResult = Database.update(activeListApplication);

        // TODO: handle error
        if (!activeListApplicationSaveResult.isSuccess()) {
        }

        String listApplicationAsJSON = JSON.serialize(la);

        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped(listApplicationAsJSON);
        fieldNameToValueMap.put('Id', sr.getId() + '');
        listApplicationAsJSON = JSON.serialize(fieldNameToValueMap);

        jobGroupList.add( createActivateListApplicationJobGroup(new Map<String,String>{'listApplication' => listApplicationAsJSON}) );
    }


    for (Map<String,Object> jobGroup : jobGroupList) {
        MSD_CORE_JobQueueService.addJobGroup(jobGroup);
    }

    MSD_CORE_JobQueueService.run();

    return opts;
}


    public static Map<String,String> deleteListApplication(Map<String,String> opts) {
        Map<String, Object> fieldNameToValueMap = (Map<String, Object>)JSON.deserializeUntyped((String)opts.get('listApplication'));

        String listAttachmentId = (String)fieldNameToValueMap.get('Id');

        opts.put('jobItemTemplate', 'listItemsDelete');
        opts.put('listAttachmentId', listAttachmentId);
        //opts.put('fieldValue', 'inactive');
        opts.put('parentId', listAttachmentId);
        //opts.put('parentFieldValue', 'inactive');

        return MSD_CORE_RecordsOperationServices.asyncExecute(opts);
    }


  public static void handleListAttachmentTriggerOperation(Map<String,String> opts) {


        String listAttachmentId = opts.get('listAttachmentId');
        MSD_CORE_List_Attachment__c la = [select Id, MSD_CORE_List__c, MSD_CORE_Status__c, MSD_CORE_Version__c from MSD_CORE_List_Attachment__c where Id = :listAttachmentId limit 1];

        // integration created the list attachment for account merges.
        // in this case we don't want to automatically unpack
        // the ListAttachment_Handler will trigger the unpack and other operations
        if (la.MSD_CORE_Status__c == 'ready for processing') {
            return;
        }

        Boolean disableAttachmentAutoUnpack = false;
        List<Object> usernameList = MSD_CORE_Setting.getObjectList('LIST_MANAGER', 'disableAttachmentAutoUnpackForUsernamesContaining');

        String currentUsername = UserInfo.getUserName();
        if (usernameList != null) {
            for (Object username : usernameList) {
                if (currentUsername.containsIgnoreCase((String)username)) {
                    disableAttachmentAutoUnpack = true;
                }
            }
        }

        if (disableAttachmentAutoUnpack) {
            return;
        }

        sObject obj = [select max(MSD_CORE_Version__c) from MSD_CORE_List_Attachment__c where MSD_CORE_List__c = :la.MSD_CORE_List__c];
        Integer maxVersion = Integer.valueOf(obj.get('expr0'));

        // mark as "uploaded"
        la.MSD_CORE_Status__c = 'uploaded';
        la.MSD_CORE_Version__c = maxVersion + 1;
        Database.SaveResult sr = Database.update(la);

        // TODO: handle errors
        if (sr.isSuccess()) {
        } else {
        }
        
        //KRB REL 8.0 8/4/2016 - integration will now handle.
        //asyncUnpackListAttachment(opts.get('listAttachmentId'));
  }

  public static Map<String,String> createUnpackListAttachmentJobItem(String listAttachmentId) {

    MSD_CORE_List_Attachment__c la = [select Id, MSD_CORE_List__c, MSD_CORE_Status__c, MSD_CORE_Version__c from MSD_CORE_List_Attachment__c where Id = :listAttachmentId limit 1];
    Attachment att = [select Id from Attachment where ParentId = :listAttachmentId limit 1];

    Map<String,Object> jobItem = MSD_CORE_JobQueueService.getJobItemTemplate('unpackListAttachment');
    Map<String,String> jobItemParams = MSD_CORE_JobQueueService.getJobItemParamsTemplate('unpackListAttachment');
    jobItemParams.put('listId', la.MSD_CORE_List__c);
    jobItemParams.put('listAttachmentId', listAttachmentId);
    jobItemParams.put('attachmentId', att.Id);
    jobItem.put('params', JSON.serializePretty(jobItemParams));

    Map<String,String> m = new Map<String,String>();

    for (String key : jobItem.keySet()) {
        m.put(key, (String)jobItem.get(key));
    }

    return m;
  }

    public static Map<String,Object> createUnpackListAttachmentJobGroup(String listAttachmentId) {

        List<Map<String,String>> jobItemList = new List<Map<String,String>>();
        jobItemList.add( createUnpackListAttachmentJobItem(listAttachmentId) );

        Map<String,Object> jobGroup = new Map<String,Object>();
        jobGroup.put('name', 'Unpack List Attachment');
        jobGroup.put('jobItemList', jobItemList);

        return jobGroup;
    }

  public static Map<String,String> asyncUnpackListAttachment(String listAttachmentId) {

    Map<String,Object> result = MSD_CORE_JobQueueService.addJobGroup(createUnpackListAttachmentJobGroup(listAttachmentId));
    MSD_CORE_JobQueueService.run();

    return new Map<String,String>();
  }

    public static Map<String,String> unpackListAttachment(Map<String,String> opts) {
        MSD_CORE_Logger.loggingEnabled = true;

        MSD_CORE_Logger.debug('ListServices.unpackListAttachment: start ' + JSON.serializePretty(opts));

        Map<String, String> result = new Map<String,String>();

        Id listAttachmentId = (Id)opts.get('listAttachmentId');
        MSD_CORE_List_Attachment__c la = [select Id, MSD_CORE_Error__c, MSD_CORE_Item_Count__c, MSD_CORE_List__c, MSD_CORE_Status__c, MSD_CORE_Type__c, MSD_CORE_Version__c, Name from MSD_CORE_List_Attachment__c where Id = :listAttachmentId];

        try {

            String op = (String)opts.get('op');

            Id attachmentId = (Id)opts.get('attachmentId');
            Id listId =(Id)opts.get('listId');


            String offset = (String)opts.get('offset');
            Integer maxElements = Integer.valueOf((String)opts.get('maxElements'));
            List<String> productMetricFieldNamesList;

            String productMetricFieldNamesListJsonString = opts.get('productMetricFieldNamesList');
            if (productMetricFieldNamesListJsonString != null) {
                productMetricFieldNamesList = (List<String>)JSON.deserialize(productMetricFieldNamesListJsonString, List<String>.class);
            }

            // always pass these  along
            result.put('attachmentId', attachmentId);
            result.put('listId', listId + '');
            result.put('listAttachmentId', listAttachmentId + '');
            result.put('maxElements', maxElements + '');

            Attachment a = [select Name, Description, Body, BodyLength from Attachment where Id = :attachmentId][0];
            Blob b = a.Body;
            String contents = b.toString();

            Integer maxAttachmentSizeInBytes = Integer.valueOf(opts.get('maxAttachmentSizeInBytes'));
            if (a.BodyLength > maxAttachmentSizeInBytes) {
                result.put('error', 'List Attachment file size exceeds the limit of ' + maxAttachmentSizeInBytes);
                result.put('done', 'true');
                return result;
            }

            // identify delimiter
            List<Integer> delimiterChars = new List<Integer>();
            Integer characterScanCount = 0;
            Integer characterScanCountMax = 4000;
            Boolean canNotFindDelimiter = false;
            for (Integer c : contents.getChars()) {
                // non-alphanumeric
                if (c < 33) {
                    delimiterChars.add(c);
                } else {
                    if (delimiterChars.size() > 0) {
                        break;
                    }
                }
                characterScanCount += 1;

                if (characterScanCount > characterScanCountMax) {
                    canNotFindDelimiter = true;
                    break;
                }
            }

            if (canNotFindDelimiter == true) {
                String errString = 'File contents do not match expected format.  Cannot identify delimiter within the first ' + characterScanCountMax + ' characters of the file.';
                la.MSD_CORE_Status__c = 'unpacking error(s)';
                la.MSD_CORE_Error__c = errString;
                // TODO: handle failure case
                Database.SaveResult sr = Database.update(la);

                result.put('error', errString);
                result.put('done', 'true');
                return result;
            }

            String delimiterString = String.fromCharArray(delimiterChars);

            // file format validation
            if ( (delimiterString.length() == 0) || (delimiterString == '') ) {
                String errString = 'File contents do not match expected format.  Delimiter string is "' + delimiterString + '".';
                la.MSD_CORE_Status__c = 'unpacking error(s)';
                la.MSD_CORE_Error__c = errString;
                // TODO: handle failure case
                Database.SaveResult sr = Database.update(la);

                result.put('error', errString);
                result.put('done', 'true');
                return result;
            }

            Integer counter = 0;
            //LineReader lineReader = new LineReader(contents, '\r', Integer.valueOf(offset));
            LineReader lineReader = new LineReader(contents, delimiterString, Integer.valueOf(offset));
            List<String> lineList = new List<String>();

            if (op == 'calculateOffsets') {

                la.MSD_CORE_Status__c = 'unpacking';
                // TODO: handle failure case
                Database.SaveResult sr = Database.update(la);

                List<Integer> offsetList = lineReader.generateOffsetsForMaxLines(maxElements);
                result.put('offsetList', JSON.serialize(offsetList));
                result.put('offset', offsetList[0] + '');
                result.put('op', 'unpack');
                result.put('done', 'false');
            }

            if (op == 'unpack') {
                MSD_CORE_Logger.debug('ListServices.unpackListAttachment - unpack. offset=' + offset);
                List<MSD_CORE_List_Item__c> laiList = new List<MSD_CORE_List_Item__c>();
                while(lineReader.hasNext() && (counter < maxElements)) {
                    // Read line
                    String line = lineReader.next();

                    if (line.trim() != '') {

                        MSD_CORE_List_Item__c lai = new MSD_CORE_List_Item__c(
                            MSD_CORE_Type__c='cm',
                            MSD_CORE_List__c=listId,
                            MSD_CORE_List_Attachment__c=listAttachmentId,
                            MSD_CORE_Country_Code__c = 'USA'
                        );


                        if (la.MSD_CORE_Type__c == 'account ids') {
                            lai.MSD_CORE_Value__c = line;
                            laiList.add(lai);
                        }

                        if (la.MSD_CORE_Type__c == 'product metric values') {

                            // header row
                            if ((counter == 0) && (offset == '0')) {

                                productMetricFieldNamesList = line.trim().replace('"', '').split(',');
                                result.put('productMetricFieldNamesList', JSON.serializePretty(productMetricFieldNamesList));

                            } else { // value row
                                Integer idx = 0;
                                List<String> productMetricFieldValuesList = line.trim().replace('"', '').split(',');
                                for (String productMetricFieldName : productMetricFieldNamesList) {

                                    // first field value is the id
                                    if (idx == 0) {
                                        lai.MSD_CORE_Value__c = productMetricFieldValuesList.get(idx);
                                    } else {
                                        lai.put('MSD_CORE_Field_Name_' + (idx - 1) + '__c', productMetricFieldName);
                                        lai.put('MSD_CORE_Field_Value_' + (idx - 1) + '__c', productMetricFieldValuesList.get(idx));
                                    }
                                    idx++;
                                }


                                laiList.add(lai);
                            }
                        }

                        counter++;

                    }


                }

                if ((la.MSD_CORE_Type__c == 'product metric values') && (offset == '0')) {
                    // decrement counter so header row isn't counted
                    counter--;
                }

                Database.SaveResult[] saveResults = Database.insert(laiList, true);
                Integer successfulInserts = 0;
                Integer failedInserts = 0;
                for (Database.SaveResult saveResult : saveResults) {
                    if (saveResult.isSuccess()) {
                        successfulInserts++;
                    } else {
                        failedInserts++;
                    }
                }

                result.put('successfulInserts', successfulInserts + '');
                result.put('failedInserts', failedInserts + '');
                result.put('counter', counter + '');

                String totalSuccessfulInserts = (String)opts.get('totalSuccessfulInserts');
                if (totalSuccessfulInserts != null) {
                    result.put('totalSuccessfulInserts', (Integer.valueOf(totalSuccessfulInserts) + successfulInserts) + '');
                } else {
                    result.put('totalSuccessfulInserts', successfulInserts + '');
                }


                List<Integer> offsetList = (List<Integer>)JSON.deserialize((String)opts.get('offsetList'), List<Integer>.class);
                MSD_CORE_Logger.debug('offsetList=' + JSON.serializePretty(offsetList));
                if (offsetList.size() > 0) {

                    offsetList.remove(0);
                    /*
                    List<Integer> offsetMinusFirstElementList = new List<Integer>();
                    if (offsetList.size() > 1) {
                        for (Integer i = 1; i < offsetList.size(); i++) {
                            offsetMinusFirstElementList.add((Integer)offsetList.get(i));
                        }
                    }
                    */

                    // no more offsets to process
                    if (offsetList.size() == 0) {
                        // update list attachment metadata (Status, Count)
                        Boolean success = updateListAttachmentMetadata(result);

                        // TODO: handle error case
                        if (success) {

                        } else {
                        }

                        result.put('done', 'true');
                    } else {
                        result.put('offset', (Integer)offsetList.get(0) + '');
                         MSD_CORE_Logger.debug('offsetList=' + JSON.serializePretty(offsetList));
                        result.put('offsetList', JSON.serialize(offsetList));
                        result.put('op', 'unpack');
                        result.put('done', 'false');
                    }
                } else {
                    result.put('done', 'true');
                }

                //result.put('done', !(lineReader.hasNext()) + '' );
                //result.put('ids', String.join(lineList, ','));
                //result.put('ids.size()', lineList.size() + '');
                //result.put('offset', lineReader.offset + '');
            }

            MSD_CORE_Logger.debug('ListServices.unpackListAttachment: before return' + JSON.serializePretty(result));
        } catch (Exception e) {
            String errString = 'File unpacking error.\n';
            errString += (e + ', line #:' + e.getLineNumber() + '\nStack Trace:\n' + e.getStackTraceString());
            MSD_CORE_Logger.error(errString);
            result.put('error', errString);
            result.put('done', 'true');
            la.MSD_CORE_Status__c = 'unpacking error(s)';
            la.MSD_CORE_Error__c = errString;
            // TODO: handle failure case
            Database.SaveResult sr = Database.update(la);
        } finally {
            MSD_CORE_Logger.flush();
        }


        return result;
    }

    public static Boolean updateListAttachmentMetadata(Map<String,String> opts) {

        String listAttachmentId = (String)opts.get('listAttachmentId');
        String listId = (String)opts.get('listId');

        // TODO: put into settings
        //String countQuery = 'select count() from MSD_CORE_List_Item__c where MSD_CORE_List_Attachment__c = \'' + listAttachmentId + '\' and MSD_CORE_Status__c = \'unpacked\'';
        //Integer count = Database.countQuery(countQuery);
        String totalSuccessfulInserts = opts.get('totalSuccessfulInserts');
        Integer count = Integer.valueOf(totalSuccessfulInserts);

        // TODO: put soql in settings
        MSD_CORE_List_Attachment__c la = [select Id, MSD_CORE_Item_Count__c, MSD_CORE_List__c, MSD_CORE_Status__c, MSD_CORE_Version__c, Name from MSD_CORE_List_Attachment__c where Id = :listAttachmentId and MSD_CORE_List__c = :listId limit 1];
        la.MSD_CORE_Status__c = 'unpacked';
        la.MSD_CORE_Item_Count__c = count;


        // TODO: handle failure case
        Database.SaveResult sr = Database.update(la);

        return sr.isSuccess();
    }

  public static Map<String,String> createAccountMatchJobItem(String listAttachmentId) {

    MSD_CORE_List_Attachment__c la = [select Id, MSD_CORE_List__c, MSD_CORE_Status__c, MSD_CORE_Version__c from MSD_CORE_List_Attachment__c where Id = :listAttachmentId limit 1];
    Attachment att = [select Id from Attachment where ParentId = :listAttachmentId limit 1];

    Map<String,Object> jobItem = MSD_CORE_JobQueueService.getJobItemTemplate('accountMatch');
    Map<String,String> jobItemParams = MSD_CORE_JobQueueService.getJobItemParamsTemplate('accountMatch');
    //jobItemParams.put('listId', la.MSD_CORE_List__c);
    jobItemParams.put('listAttachmentId', listAttachmentId);
    //jobItemParams.put('attachmentId', att.Id);
    jobItem.put('params', JSON.serializePretty(jobItemParams));

    Map<String,String> m = new Map<String,String>();

    for (String key : jobItem.keySet()) {
        m.put(key, (String)jobItem.get(key));
    }

    return m;
  }

    public static Map<String,Object> createAccountMatchJobGroup(String listAttachmentId) {

        List<Map<String,String>> jobItemList = new List<Map<String,String>>();
        jobItemList.add( createAccountMatchJobItem(listAttachmentId) );

        Map<String,Object> jobGroup = new Map<String,Object>();
        jobGroup.put('name', 'Account Match');
        jobGroup.put('jobItemList', jobItemList);

        return jobGroup;
    }

  public static Map<String,String> asyncAccountMatch(String listAttachmentId) {

    List<Map<String,String>> jobItemList = new List<Map<String,String>>();
    jobItemList.add( createAccountMatchJobItem(listAttachmentId) );

    Map<String,Object> jobGroup = new Map<String,Object>();
    jobGroup.put('name', 'Account Match');
    jobGroup.put('jobItemList', jobItemList);

    MSD_CORE_JobQueueService.addJobGroup(jobGroup);
    MSD_CORE_JobQueueService.run();

    return new Map<String,String>();
  }

    public static Map<String,String> accountMatch(Map<String,String> opts) {

        Map<String, String> result = new Map<String,String>();

        try {

            String listAttachmentId = opts.get('listAttachmentId');

            MSD_CORE_List_Attachment__c listAttachment = [select Id, MSD_CORE_Status__c from MSD_CORE_List_Attachment__c where Id = :listAttachmentId];

            if (listAttachment.MSD_CORE_Status__c != 'matching') {
                listAttachment.MSD_CORE_Status__c = 'matching';

                Database.SaveResult sr = Database.update(listAttachment);
                if (!sr.isSuccess()) {
                    result.put('error', 'failed to update MSD_CORE_List_Attachment__c.MSD_CORE_Status__c to "matching" for List Attachment with Id = ' + listAttachmentId);
                    return result;
                }
            }

            String selectFields = 'Id, MSD_CORE_List__c, MSD_CORE_List_Attachment__c, MSD_CORE_Matched__c, MSD_CORE_Processed__c, MSD_CORE_Processed_DateTime__c, MSD_CORE_Status__c, MSD_CORE_Type__c, MSD_CORE_Value__c';

            String batchSize = opts.get('batchSize');
            String whereClause = ' where MSD_CORE_List_Attachment__c = \'' + listAttachmentId + '\' and MSD_CORE_Type__c=\'cm\' and MSD_CORE_Processed__c = false limit ' + batchSize;
            //String countOfMatchedQuery = 'select count() from MSD_CORE_List_Item__c where MSD_CORE_List_Attachment__c = \'' + listAttachmentId + '\' and MSD_CORE_Type__c=\'cm\' and MSD_CORE_Processed__c = true and MSD_CORE_Matched__c = true';
            String itemsToProcessSoql = 'select ' + selectFields + ' from MSD_CORE_List_Item__c ' + whereClause;
            String itemsLeftToProcessCountSoql = 'select count() from MSD_CORE_List_Item__c ' + whereClause;

            List<MSD_CORE_List_Item__c> itemList = (List<MSD_CORE_List_Item__c>)Database.query(itemsToProcessSoql);
            Set<String> values = new Set<String>();
            for (MSD_CORE_List_Item__c i : itemList) {
                values.add(i.MSD_CORE_Value__c);
            }

            String accountIdMatchFieldApiName = MSD_CORE_Setting.getString('LIST_MANAGER', 'accountIdMatchFieldApiName');

            List<String> valueList = new List<String>();
            valueList.addAll(values);
            List<Account> acctlist = Database.query('select Id, ' + accountIdMatchFieldApiName + ' from Account where ' + accountIdMatchFieldApiName + ' IN :valueList');
            //List<Account> acctlist = [select Id, Merck_ID_MRK__c from Account where Merck_ID_MRK__c IN :values];
            Map<String,String> matchedValuesMap = new Map<String,String>();
            for (Account acct : acctlist) {
                matchedValuesMap.put((String)acct.get(accountIdMatchFieldApiName), acct.Id);
            }

            // TODO: put in settings
            String matchingCompleteStatus = 'matching complete';

            Integer matchedCount = 0;

            for (MSD_CORE_List_Item__c i : itemList) {
                String sfId = matchedValuesMap.get(i.MSD_CORE_Value__c);
                if (sfId != null) {
                    i.MSD_CORE_Matched__c = true;
                    i.MSD_CORE_Account__c = sfId;
                    matchedCount++;
                } else {
                    i.MSD_CORE_Matched__c = false;
                }
                i.MSD_CORE_Processed__c = true;
                i.MSD_CORE_Processed_DateTime__c = DateTime.now();
                i.MSD_CORE_Status__c = matchingCompleteStatus;
            }

                String totalMatchedCount = (String)opts.get('totalMatchedCount');
                if (totalMatchedCount != null) {
                    result.put('totalMatchedCount', (Integer.valueOf(totalMatchedCount) + matchedCount) + '');
                } else {
                    result.put('totalMatchedCount', matchedCount + '');
                }



            Database.SaveResult[] srList = Database.update(itemList);

            // TODO: handle errors

            Integer itemsLeftToProcessCount = Database.countQuery(itemsLeftToProcessCountSoql);

            if (itemsLeftToProcessCount == 0) {
                MSD_CORE_List_Attachment__c la = [select Id, MSD_CORE_Status__c, MSD_CORE_Match_Status__c, MSD_CORE_Item_Count__c, MSD_CORE_List__r.MSD_CORE_Name__c, MSD_CORE_Version__c from MSD_CORE_List_Attachment__c where Id = :listAttachmentId];
                la.MSD_CORE_Status__c = matchingCompleteStatus;
                Integer countOfMatched = Integer.valueOf(result.get('totalMatchedCount'));
                la.MSD_CORE_Match_Status__c = (countOfMatched == la.MSD_CORE_Item_Count__c) ? 'all matched' : 'not all matched';
                Database.SaveResult sr = Database.update(la);

                // TODO: handle error
                if (!sr.isSuccess()) {
                }


                if (countOfMatched != la.MSD_CORE_Item_Count__c) {
                    Map<String,String> nonMatchedAccountsExportToAttachmentOpts = new Map<String,String>();
                    nonMatchedAccountsExportToAttachmentOpts.put('type', 'non-matched');
                    nonMatchedAccountsExportToAttachmentOpts.put('listAttachmentId', la.Id);
                    nonMatchedAccountsExportToAttachmentOpts.put('attachmentName', la.MSD_CORE_List__r.MSD_CORE_Name__c + '-version-' + String.valueOf(la.MSD_CORE_Version__c) + '-non-matched-ids.csv');
                    MSD_CORE_JobQueueService.addJobGroup(MSD_CORE_ExportToAttachmentServices.createExportToAttachmentJobGroup(nonMatchedAccountsExportToAttachmentOpts));

                    Map<String,String> matchedAccountsExportToAttachmentOpts = new Map<String,String>();
                    matchedAccountsExportToAttachmentOpts.put('type', 'matched');
                    matchedAccountsExportToAttachmentOpts.put('listAttachmentId', la.Id);
                    matchedAccountsExportToAttachmentOpts.put('attachmentName', la.MSD_CORE_List__r.MSD_CORE_Name__c + '-version-' + String.valueOf(la.MSD_CORE_Version__c) + '-matched-ids.csv');
                    MSD_CORE_JobQueueService.addJobGroup(MSD_CORE_ExportToAttachmentServices.createExportToAttachmentJobGroup(matchedAccountsExportToAttachmentOpts));

                }
            }

            result.put('done', (itemsLeftToProcessCount == 0) ? 'true' : 'false');

        } catch (Exception e) {
            String errString = e + ', line #:' + e.getLineNumber() + '\nStack Trace:\n' + e.getStackTraceString();
            MSD_CORE_Logger.error(errString);
            result.put('error', errString);
        } finally {
            MSD_CORE_Logger.flush();
        }

        return result;
    }

    public static void segmentationTaskTest() {

        // d6
        // Id attachmentId = '00PJ0000002NEveMAG';
        // Id listId ='a2QJ0000000XcVNMA0';
        // Id listAttachmentId = 'a3eJ00000004Wft';

        // f3
        // Id attachmentId = '00PJ0000002NHT1MAO';
        // Id listId ='a3nJ0000000DjazIAC';
        // Id listAttachmentId = 'a3mJ0000000CtpqIAC';

        // f3
        // 400K IDs
        Id attachmentId = '00PJ0000002Nls1';
        Id listId ='a3nJ0000000DjazIAC';
        Id listAttachmentId = 'a3mJ0000000CtpqIAC';

        Map<String, String> opts = new Map<String,String>{
            'op' => 'calculateOffsets',
            'offset' => '0',
            'maxElements' => '9000',
            'attachmentId' => attachmentId,
            'listId' => listId,
            'listAttachmentId' => listAttachmentId
        };
        ListTask task = new ListTask(opts);
        ID jobId = System.enqueueJob(task);
        MSD_CORE_Logger.loggingEnabled = true;
        MSD_CORE_Logger.debug('ListServices.ListTaskTest(): opts' + JSON.serializePretty(opts));
        MSD_CORE_Logger.flush();
    }

    public class ListTask implements Queueable {
        private Map<String,String> opts;
        public ListTask(Map<String,String> opts) {
            this.opts = opts;
        }

        public void execute(QueueableContext context) {
            MSD_CORE_Logger.loggingEnabled = true;
            try {
                MSD_CORE_Logger.debug('ListTask.execute: opts' + JSON.serializePretty(this.opts));

                Map<String, String> res = MSD_CORE_ListServices.unpackListAttachment(opts);
                MSD_CORE_Logger.debug('ListTask.execute: res' + JSON.serializePretty(res));

                String done = (String)res.get('done');
                if (done == 'true') {
                    MSD_CORE_Logger.debug('ListTask.execute: res' + JSON.serializePretty(res));
                    MSD_CORE_Logger.debug('ListTask.execute: done');
                } else {
                    ListTask task = new ListTask(res);
                    ID jobId = System.enqueueJob(task);
                }

            } catch (Exception e) {
                MSD_CORE_Logger.error(e + '1, line #:' + e.getLineNumber() + '\nStack Trace:\n' + e.getStackTraceString());
            } finally {
                MSD_CORE_Logger.flush();
            }

        }
    }


    /**
     * Utility class to iterate over lines
     **/
    public class LineReader implements Iterator<string>, Iterable<string> {
        private String lineDelimiter;
        private Integer lineDelimiterLength;
        private String textData;
        public Integer offset = 0;

        public LineReader(String textData) {
            this.textData = textData;
            this.lineDelimiter = '\r';
            this.lineDelimiterLength = this.lineDelimiter.length();
        }


        public LineReader(String textData, String lineDelimiter) {
            this.textData = textData;
            this.lineDelimiter = lineDelimiter;
            this.lineDelimiterLength = this.lineDelimiter.length();
        }

        public LineReader(String textData, String lineDelimiter, Integer offset) {
            this.offset = offset;
          this.textData = (offset > 0) ? textData.substring(offset) : textData;
          this.lineDelimiter = lineDelimiter;
          this.lineDelimiterLength = this.lineDelimiter.length();
        }

        public List<Integer> generateOffsetsForMaxLines(Integer maxLines) {
            List<Integer> offsetList = new List<Integer>();

            Integer offset = 0;
            Integer lineCounter = 0;

            offsetList.add(offset);

            while (offset != -1) {
                    offset = textData.indexOf(lineDelimiter, offset);
                    if (offset == -1) { break; }
                    offset += lineDelimiterLength;
                    lineCounter++;
                    if (lineCounter == maxLines) {
                        offsetList.add(offset);
                        lineCounter = 0;
                    }
            }
            return offsetList;
        }


        public Boolean hasNext() {
            return textData.length() > 0 ? true : false;
        }

        public String next() {
            String row = null;
            Integer endPos = textData.indexOf(lineDelimiter);
            if(endPos == -1) {
                row = textData;
                textData = '';
            } else {
                row = textData.subString(0, endPos);
                textData = textData.subString(endPos + lineDelimiterLength, textData.length());
            }
            offset += (row.length() + lineDelimiterLength);

            return row;
        }

        public Iterator<String> Iterator() {
            return this;
        }
    }


}