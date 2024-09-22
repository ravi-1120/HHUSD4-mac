/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_BatchCommunicationEventPublish.cls
* @description - Batch class for publishing communication events
* @createdate - August 26th, 2013
*
*/

global class MRK_BatchCommunicationEventPublish implements Database.Batchable<sObject>, Database.Stateful {

   global final String query;
   global final String emailTo;
   global String output = '';
   global Map<String, MRK_UserInfo> useridToUserInfoMap = new Map<String, MRK_UserInfo>();
   
   final MRK_UserInfo userInfoTemplate;

   global MRK_BatchCommunicationEventPublish(String q, String et) {
       query = q;
       emailTo = et;

       // DEBUG: hold
       //userInfoTemplate = MRK_UserInfo.getByUserid([select id from user where username = 'commrep01@merck.com.hhusc3'][0].Id);
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope) {
   	MRK_CommunicationServices.communicationEventPublishForUserList(scope);
   }

   global void finish(Database.BatchableContext BC) {
  	//MRK_CommunicationServices.assignEventsToTargets(useridToUserInfoMap);

 		//output += 'useridToUserInfoMap.values().size() = ' + useridToUserInfoMap.values().size() + '\n\n';
 		//output += JSON.serializePretty(useridToUserInfoMap);
   }
}