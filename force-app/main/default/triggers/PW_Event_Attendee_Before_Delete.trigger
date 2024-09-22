///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Trigger on object:          Event_Attendee_vod__c
///   Description:    This trigger  is  called when event attendee is deleted in salesforce
///   Author:         Nitesh Kodle                   
///   
///    Date: 24-12-2016
///   Revision History:
///-----------------------------------------------------------------


trigger PW_Event_Attendee_Before_Delete on Event_Attendee_vod__c (before delete) {
    System.Debug(' Event Attendee After Delete trigger');
   
     if (Trigger.isDelete)
    {
        
        PW_Robot_User__c robotUserCustomSetting=PW_Robot_User__c.getValues('RobotUserSetting');
        if(robotUserCustomSetting.Robot_User__c==UserInfo.getUserName())
        {
        
        
            System.Debug('Event Attendee deleted with robot user :'+UserInfo.getUserName());
            return;
        }
        
        Set<Id> allEventAttendeeIds = trigger.oldMap.keySet();
        Map<Id,Event_Attendee_vod__c > eventAttendeeMap =  new Map<Id,Event_Attendee_vod__c >([Select Id,Medical_Event_vod__r.EM_Event_vod__c from Event_Attendee_vod__c where Id in :allEventAttendeeIds ]);
        Set<Id> eventIds = new Set<Id>();
        for(Event_Attendee_vod__c eventAttendee : eventAttendeeMap.values())
        {
            if(eventAttendee!=null)
                eventIds.add(eventAttendee.Medical_Event_vod__r.EM_Event_vod__c);
        }
        PW_Filter_On_Event_Record_Types pwFilterRT = new PW_Filter_On_Event_Record_Types();
        pwFilterRT.filterEventRecordTypes(eventIds);
        
        
        List<Id> EventAttendeeIdList=new List<Id>();
		try{
                       for (Event_Attendee_vod__c eventAttendee : Trigger.Old) 
                       {
                           if(eventAttendeeMap.get(eventAttendee.Id)!=null)
                           {
                            if(!pwFilterRT.checkRecordTypeForEvent(eventAttendeeMap.get(eventAttendee.Id).Medical_Event_vod__r.EM_Event_vod__c))
                               continue ;
                           }
                           
                            system.debug('Event Status :'+ eventAttendee.Medical_Event_vod__r.EM_Event_vod__r.Status_vod__c);
                         
                           
                           
                               System.Debug('Event Attendee Insert after trigger called for id ='+eventAttendee .id);
                               EventAttendeeIdList.add(eventAttendee.id);
                               //Pw_Call_Service_Bus_API.MakeCalloutAddAttendee(eventAttendee.id);
                               System.Debug('Event Attendee Insert after trigger ');
                         
                           
                       }
		                  System.Debug('Before Calling MakeCalloutDeleteAttendeeBulk:: '+EventAttendeeIdList);
		               Pw_Call_Service_Bus_API.MakeCalloutDeleteAttendeeBulk(EventAttendeeIdList);
					    System.Debug('After Calling MakeCalloutDeleteAttendeeBulk:: ');
		
		}catch(Exception e){
                
                PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
                
                System.Debug(' Event Attendee Delete after trigger exception');  
                System.Debug('exception'+e);  
         
				        for (Event_Attendee_vod__c eventAttendee : Trigger.old) 
						{
						   eventAttendee.addError('An error has occurred upon submitting this event.Please contact support for further assistance.');
						}
             
                system.debug('An error has occurred upon submitting this event.Please contact support for further assistance.');
            }
        
    }
}