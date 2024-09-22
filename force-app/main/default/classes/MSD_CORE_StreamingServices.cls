@RestResource(urlMapping='/msdcore/streaming/*')
global without sharing class MSD_CORE_StreamingServices {

  @HttpPost
  global static Map<String,String> doPost(Map<String, String> data) {
    Map<String,String> result = new Map<String,String>();

    String method = (String)data.get('method');

    if (method == 'createPushTopic') {
        result = createPushTopic(data);
    }

    if (method == 'createPushTopics') {
        result = createPushTopics(data);
    }

    return result;
  }

  public static Map<String,String> createPushTopics(Map<String, String> opts) {
    List<Map<String,String>> pushTopicList = (List<Map<String,String>>)JSON.deserialize(opts.get('pushTopicList'), List<Map<String,String>>.class);

    List<Map<String,String>> resultList = new List<Map<String,String>>();
    for (Map<String,String> pushTopic : pushTopicList) {
        Map<String,String> result = createPushTopic(pushTopic);
        resultList.add(result);
    }
    opts.put('result', JSON.serializePretty(resultList));
    return opts;
  }

  public static Map<String,String> createPushTopic(Map<String, String> opts) {
    String name = opts.get('name');
    List<PushTopic> pushTopicList = [select ApiVersion, CreatedById, CreatedDate, Description, Id, IsActive, IsDeleted, LastModifiedById, LastModifiedDate, Name, NotifyForFields, NotifyForOperationCreate, NotifyForOperationDelete, NotifyForOperations, NotifyForOperationUndelete, NotifyForOperationUpdate, Query, SystemModstamp from PushTopic where Name = :name];
    if (pushTopicList.size() > 0) {
        opts.put('success', 'true');
        opts.put('message', 'PushTopic with name ' + name + ' already exists.');
        opts.put('result', JSON.serializePretty(pushTopicList[0]));
        return opts;
    }
    PushTopic pushTopic = new PushTopic();
    pushTopic.Name = name; // 'MSD_CORE_LogItems';
    pushTopic.Query = opts.get('soql'); // 'SELECT Id, Name FROM MSD_CORE_Log_Item__c';
    pushTopic.ApiVersion = Integer.valueOf(opts.get('apiVersion')); // 33.0;
    pushTopic.NotifyForOperationCreate = true;
    pushTopic.NotifyForOperationUpdate = true;
    pushTopic.NotifyForOperationUndelete = true;
    pushTopic.NotifyForOperationDelete = true;
    pushTopic.NotifyForFields = 'Referenced';

    Database.SaveResult sr = Database.insert(pushTopic);

    // TODO: handle error
    if (!sr.isSuccess()) {
    } else {
        opts.put('success', 'true');
        opts.put('result', JSON.serializePretty(pushTopic));
    }

    return opts;
  }

}