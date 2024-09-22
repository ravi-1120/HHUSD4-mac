@RestResource(urlMapping='/msdcore/database/*')
global without sharing class MSD_CORE_DatabaseServices {


  @HttpPost
  global static Map<String,String> doPost(Map<String, String> data) {
    Map<String,String> result = new Map<String,String>();

    String method = (String)data.get('method');

    /*
    if (method == 'getList') {
        result = getList(data);
    }
    */

    return result;
  }

  global static Map<String,String> insertRecord(sObject rec) {
    Map<String,String> result = new Map<String,String>();
    return result;
  }

  global static Map<String,String> updateRecord(String objectTypeName, String recordId, Map<String,Object> values) {
    Map<String,String> result = new Map<String,String>();
    return result;
  }


}