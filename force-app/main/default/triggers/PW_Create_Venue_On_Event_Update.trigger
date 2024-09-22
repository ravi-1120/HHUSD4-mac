trigger PW_Create_Venue_On_Event_Update on EM_Event_vod__c (before update,before insert) {
    
        PW_Robot_User__c robotUserCustomSetting=PW_Robot_User__c.getValues('RobotUserSetting');
        if(robotUserCustomSetting.Robot_User__c==UserInfo.getUserName())
            {                
                System.Debug('Event Updated with robot user :'+UserInfo.getUserName());
                return;
            }
            
            //April 2020 start
            Set<String> venueSet = new Set<String>();
   
  
            for (EM_Event_vod__c event : Trigger.new) {
                if (event.Venue_vod__c != null) {
                    
                    venueSet.add(event.Venue_vod__c);
                }
                
            }
    
            Map<ID, EM_Venue_vod__c > mapOfIdsOfVenue = new Map<ID, EM_Venue_vod__c >([SELECT Id, PW_Venue_Category__c
                                             FROM EM_Venue_vod__c
                                              WHERE Id IN :venueSet]);
    
            //April 2020 
            
            if(Trigger.isInsert)
            {
                for (EM_Event_vod__c event : Trigger.new) 
                {
                   
                    PW_Event_Validation eventVaidation = new PW_Event_Validation();
                    
                    if( !eventVaidation.validateAV(event, event))
                    {
                        event.addError(eventVaidation.errorMessage);
                        return;
                    }
                    //April 2020
                    if(event.Venue_vod__c!=null)
                    {
                        if(mapOfIdsOfVenue.get(event.Venue_vod__c)!=null)
                        {
                            event.PW_Venue_Category__c = mapOfIdsOfVenue.get(event.Venue_vod__c).PW_Venue_Category__c;
                        }
                    }
                    //April 2020
                    
                }   
            }
            if(Trigger.isUpdate)
            {
                     Set<Id> allEventIds = trigger.newMap.keySet();
                     PW_Filter_On_Event_Record_Types pwFilterRT = new PW_Filter_On_Event_Record_Types();
                     pwFilterRT.filterEventRecordTypes(allEventIds);
                   
                    for (EM_Event_vod__c event : Trigger.new) 
                    {   
                        if(!pwFilterRT.checkRecordTypeForEvent(event.Id))
                            continue ;
                     
                        EM_Event_vod__c oldEvent= Trigger.oldMap.get(event.id);                        
               
                            try{
                            PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
                            system.debug('Event Start time '+event.Start_Time_vod__c.date());
                            if(regSettings.Always_copy_Local_Date_from_Veeva_Date__c)
                            {
                                event.PW_Local_Start_Date__c = event.Start_Time_vod__c.date();
                            }
                            else
                            {
                                if(event.PW_Local_Start_Date__c==null)
                                {
                                    event.PW_Local_Start_Date__c = event.Start_Time_vod__c.date();
                                }
                            }
                                
                           
                            String[] venueTriggerStatus = new string[]{};
                            boolean venueFlag=false;
                            
                            
                            PW_Event_Validation eventVaidation = new PW_Event_Validation();
                            if( !eventVaidation.validateSpeakerPresentInEvent(event))
                            {
                                event.addError(eventVaidation.errorMessage);
                                return;
                            }
               if( !eventVaidation.validateTopicNotChangeInEvent(event,oldEVent))
                            {
                                event.addError(eventVaidation.errorMessage);
                                return;
                            }                            
                            if(! eventVaidation.validateEventEndTimeForCompletion(event,oldEVent))
                            {
                                event.addError(eventVaidation.errorMessage);
                                return;
                            }
                           
                            if(! eventVaidation.validateAttendeeAndSpeakerAttendanceForCompletion(event,oldEVent))
                            {
                                event.addError(eventVaidation.errorMessage);
                                return;
                            }
                            //April 2020
                            if(event.Venue_vod__c != oldEvent.Venue_vod__c) 
                            {
                                if(event.Venue_vod__c!=null)
                                    {
                                        if(mapOfIdsOfVenue.get(event.Venue_vod__c)!=null)
                                        {
                                            event.PW_Venue_Category__c = mapOfIdsOfVenue.get(event.Venue_vod__c).PW_Venue_Category__c;
                                        }
                                    }
                            }
                            //April 2020
                            if(!string.isEMpty(regSettings.PW_Venue_Creation_Statuses__c))
                            {
                                venueTriggerStatus = regSettings.PW_Venue_Creation_Statuses__c.split(';');
                                
                                for(string status : venueTriggerStatus)
                                {
                                    if(event.Status_vod__c==status && oldEvent.Status_vod__c!=status )
                                    {
                                        venueFlag=true;
                                    }
                                
                                }
                                if(venueFlag)
                                {
                                    System.Debug('venue creation trigger called for id ='+event.id);
                                    EM_Venue_vod__c createdVenue = Pw_Generate_Venue_On_Fly.GenerateVenue(event); 
                                    if(createdVenue!=null){
                                        event.Venue_vod__c = createdVenue.id;
                                    }
                                    System.Debug('venue is created');
                                }
                            }
                            else
                            {
                                system.debug('Venue trigger status in PW General Settings is empty : ' +regSettings.PW_Venue_Creation_Statuses__c);
                                event.addError('An error has occurred upon submitting this event.Please contact support for further assistance.');
                            }
                            
                            //OCT 2020 Patient integration
                            
                            String[] eventTriggerStatus = new string[]{};
                                 
                                 if(!string.isEmpty(regSettings.PW_Event_trigger_Statuses__c))
                                 {
                                    eventTriggerStatus = regSettings.PW_Event_trigger_Statuses__c.split(';');
                                    for(string status : eventTriggerStatus)
                                        {
                                            if(event.Status_vod__c==status)
                                            {
                                                        event.PW_Is_EventApproved__c=true;
                                            }
                                                
                                        }
                                 }
                                                            
                               
                            }
                            catch(Exception e){
                                
                            PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
                                
                            System.Debug(' Event is in trigger exception'); 
                            System.Debug('exception'+e);    
                            event.addError('An error has occurred upon submitting this event.Please contact support for further assistance.');                    
                            }
                    
                    }    
        }
}