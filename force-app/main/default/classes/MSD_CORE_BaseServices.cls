@RestResource(urlMapping='/msdcore/base/*')
global without sharing class MSD_CORE_BaseServices {

  @HttpPost
  global static Map<String,String> doPost(Map<String, String> data) {
    Map<String,String> res = new Map<String,String>();
    String method = (String)data.get('method');
    return res;
  }

  global static Map<String,String> halt(Map<String, String> opts) {
    return null;
  }

}