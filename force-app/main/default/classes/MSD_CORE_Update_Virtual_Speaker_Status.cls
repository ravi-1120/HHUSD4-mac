/* Company       : Merck Co.
* Date          : 04/03/2022   
* Author        : Koushik Majumder
* Description   : This batch updated Virtual Event Speaker status based on Attended Live or Attended Replay
* History       : First version
* History       : CEF2F-14304
* History       : Revised for the US ORG by G.Schneible 10/3/22 CEF2F-18496
*/
global class MSD_CORE_Update_Virtual_Speaker_Status implements Database.Batchable<sObject>, Database.Stateful{
  public integer count = 0;
    public integer processed = 0;
  
  global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT ID,Name,MSD_CORE_Attended_Live__c,MSD_CORE_Attended_Replay__c,Status_vod__c,Event_vod__r.MSD_CORE_Country_Code__c, Event_vod__r.MSD_CORE_Remote_Access_Platform__c FROM EM_Event_Speaker_vod__c WHERE Event_vod__c IN(SELECT ID FROM EM_Event_vod__c WHERE MSD_Core_Published__c = true AND End_Time_vod__c < LAST_N_DAYS:2)';
        return Database.getQueryLocator(query);
    }
  
  global void execute(Database.BatchableContext bc, List<EM_Event_Speaker_vod__c> relEvntSpeakers){
    System.debug('This is speakr id ==> '+relEvntSpeakers[0].Id);
    System.debug('This is speakr Name ==> '+relEvntSpeakers[0].Name);
    Id rapRecTypeId = Schema.SObjectType.Common_KPI__c.getRecordTypeInfosByName().get('Remote Access Platform').getRecordTypeId();
        List<Common_KPI__c> commonKPIList = new List<Common_KPI__c>();
        map<Id,String> cKPIIdWithName = new map<Id,String>();
        commonKPIList = [SELECT id, Name FROM Common_KPI__c WHERE recordTypeId =: rapRecTypeId];
    
    for(Common_KPI__c each:commonKPIList){
            cKPIIdWithName.put(each.Id, each.Name);
        }
    
    List<EM_Event_Speaker_vod__c> listEvntSpeakers = new List<EM_Event_Speaker_vod__c>();
    
    for (EM_Event_Speaker_vod__c spkr : relEvntSpeakers){
      //String countryCode = spkr.Event_vod__r.MSD_CORE_Country_Code__c; //Comment out not used in the US
      MSD_Core_RTI_Switch_Utility gwetUtility = new MSD_Core_RTI_Switch_Utility();
      String switchStatus = gwetUtility.getSwitchValue('US','GWET'); //This call now returns a hard coded value for the US.
      
      //String contextKPI = cKPIIdWithName.get(spkr.Event_vod__r.MSD_CORE_Remote_Access_Platform__c);  // field not used in the US
      String contextKPI = 'ON24';  //Hardcoded values for the US where we only use ON24
      
      if(switchStatus == 'ON' && (contextKPI == 'ON24' || contextKPI == 'Webex' || contextKPI == 'MS Teams' )){
        count++;
        if(spkr.Status_vod__c != 'Attended_vod' && spkr.Status_vod__c != 'No Show'){
          if(spkr.MSD_CORE_Attended_Live__c != FALSE || spkr.MSD_CORE_Attended_Replay__c != FALSE){
            spkr.Status_vod__c = 'Attended_vod';
          }else{
            spkr.Status_vod__c = 'No Show';
          }
          
          listEvntSpeakers.add(spkr);
        }
      }
    }
    
    try{      
            database.saveresult[] ds =  Database.update(listEvntSpeakers,false);
            system.debug('This is DML size ====> '+ ds.size());
            for(database.SaveResult d : ds){
                if(d.issuccess()){
                    processed++;
                }                   
            }
        }
        catch(exception e){
            system.debug('update failed');
        }
  }
  
  global void finish(Database.BatchableContext bc){

        system.debug('+++++ Total scope record count +++++'+count);
        system.debug('+++++ Total processed record count +++++'+processed);
    }
}