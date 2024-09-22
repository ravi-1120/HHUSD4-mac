trigger PW_Attendee_Before_Insert on EM_Attendee_vod__c (before insert) {
           PW_Robot_User__c robotUserCustomSetting=PW_Robot_User__c.getValues('RobotUserSetting');
        if(robotUserCustomSetting.Robot_User__c==UserInfo.getUserName())
            {                
                System.Debug('Event Updated with robot user :'+UserInfo.getUserName());
                return;
            }
            if(Trigger.isInsert)
            {
                   System.Debug('Inside insert :');
					Set<Id> eventIdSet=new Set<Id>();
                    for(EM_Attendee_vod__c c: Trigger.new)
                    {
                        eventIdSet.add(c.Event_vod__c);
                    }
	                PW_Filter_On_Event_Record_Types pwFilterRT = new PW_Filter_On_Event_Record_Types();
					pwFilterRT.filterEventRecordTypes(eventIdSet);
					Map<Id,EM_Event_Team_Member_vod__c> eventTeamMap=new Map<Id,EM_Event_Team_Member_vod__c>([SELECT Id,Name,Event_vod__c,Role_vod__c,Team_Member_vod__c FROM EM_Event_Team_Member_vod__c where Event_vod__c  in :eventIdSet and  (Role_vod__c  like  '%Organizer%' OR Role_vod__c  like  '%Cohost%' )]);	
	                Map<Id,EM_Event_Speaker_vod__c> eventSpeakerMap=new Map<Id,EM_Event_Speaker_vod__c>([SELECT Id,Name, Account_vod__c,Event_vod__c,PW_Client_ID__c,PW_Speaker_ID__c FROM EM_Event_Speaker_vod__c where Event_vod__c  in :eventIdSet ]);
					List<Id> errorEventIdList = new List<Id>();
              	for(EM_Attendee_vod__c attendee: Trigger.new)
                {
                    if(!pwFilterRT.checkRecordTypeForEvent(attendee.Event_vod__c))
                    continue ;
                    PW_Attendee_Validation attendeeValidation = new PW_Attendee_Validation();
					try{
					       //if(!errorEventIdList.contains(attendee.Event_vod__c))
					       					   
						      if(!attendeeValidation.validateAttendee(attendee,eventTeamMap,eventSpeakerMap))
						      {
                                  
                                  attendee.addError(attendeeValidation.errorMessage);
						         
						    	  
						      }
						     
						  
						}
						 catch(Exception e){
                                
                            PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
                                
                            System.Debug(' Event is in trigger exception'); 
                            System.Debug('exception'+e);    
                            attendee.addError('An error has occurred upon submitting this event.Please contact support for further assistance.');                    
                            }
					
                    
                   
                    
                }   
            } 
}