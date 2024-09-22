trigger PW_Event_Speaker_Before_Update on EM_Event_Speaker_vod__c (before update) {
    PW_Robot_User__c robotUserCustomSetting=PW_Robot_User__c.getValues('RobotUserSetting');
    if(robotUserCustomSetting.Robot_User__c==UserInfo.getUserName())
    {                
        System.Debug('Event Updated with robot user :'+UserInfo.getUserName());
        return;
    }
    
    if(Trigger.isUpdate)
    {
        Set<Id> allEventSpeakerIds = trigger.newMap.keySet();
        Map<ID, EM_Event_Speaker_vod__c > mapOdIdsOfEventSpeaker = new Map<ID, EM_Event_Speaker_vod__c >([Select id,Event_vod__r.Status_vod__c from EM_Event_Speaker_vod__c where id in : allEventSpeakerIds ]);
        for (EM_Event_Speaker_vod__c eventSpeaker : Trigger.new) 
        {
            Set<Id> eventIdSet= new Set<Id>();
            eventIdSet.add(eventSpeaker.Event_vod__c);
            
            PW_Filter_On_Event_Record_Types pwFilterRT = new PW_Filter_On_Event_Record_Types();
            pwFilterRT.filterEventRecordTypes(eventIdSet);
            
            if(!pwFilterRT.checkRecordTypeForEvent(eventSpeaker.Event_vod__c))
                continue ;
            
            PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
            if (regSettings.PW_Allow_Speaker_Upd__c)
            {
                if(!string.isEMpty(regSettings.PW_Allow_Speaker_Update_Event_Status__c))
                {
                    List<String> eventSpeakerUpdateStatus = regSettings.PW_Allow_Speaker_Update_Event_Status__c.split(';');
                    string status= mapOdIdsOfEventSpeaker.get(eventSpeaker.id).Event_vod__r.Status_vod__c;
                    if (!eventSpeakerUpdateStatus.contains(status)) 
                    {
                           string errorMessage ='Speaker cannot be updated as the Event is not in ';
                           string eventStatus = regSettings.PW_Allow_Speaker_Update_Event_Status__c;
                           eventStatus = eventStatus.replace(';',' / ');
                           errorMessage = errorMessage + eventStatus + ' status. \n';
                           eventSpeaker.addError(errorMessage );
                           return;
                    } 
                }
            }
         }
    }
}