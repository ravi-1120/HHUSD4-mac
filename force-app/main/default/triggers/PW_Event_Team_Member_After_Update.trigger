trigger PW_Event_Team_Member_After_Update on EM_Event_Team_Member_vod__c (after update) {
    System.Debug('Event Team Member after update trigger');
    String triggerEvent ='';
    if (Trigger.isUpdate)
    {
        triggerEvent ='UPDATE';
        PW_Robot_User__c robotUserCustomSetting=PW_Robot_User__c.getValues('RobotUserSetting');
        if(robotUserCustomSetting.Robot_User__c==UserInfo.getUserName())
        {       
            System.Debug('Event Team Member created with robot user :'+UserInfo.getUserName());
            return;
        }
        
        Set<Id> allEventTeamMemberIds = trigger.newMap.keySet();
        Map<Id,EM_Event_Team_Member_vod__c > eventTeamMemberMap =  new Map<Id,EM_Event_Team_Member_vod__c >([Select Id,Event_vod__c from EM_Event_Team_Member_vod__c where Id in :allEventTeamMemberIds ]);
        Set<Id> eventIds = new Set<Id>();
        for(EM_Event_Team_Member_vod__c eventTeamMember : eventTeamMemberMap.values())
        {
            if(eventTeamMember!=null)
                eventIds.add(eventTeamMember.Event_vod__c);
        }
        PW_Filter_On_Event_Record_Types pwFilterRT = new PW_Filter_On_Event_Record_Types();
        pwFilterRT.filterEventRecordTypes(eventIds);
        
       // PW_Identify_Cohost_Organiser_Role  pw_event_teamcohost_orgniser=new PW_Identify_Cohost_Organiser_Role();
        
        
        for (EM_Event_Team_Member_vod__c eventTeamMember : Trigger.new ) 
        {
            if(eventTeamMemberMap.get(eventTeamMember.Id)!=null)
            {
                if(!pwFilterRT.checkRecordTypeForEvent(eventTeamMemberMap.get(eventTeamMember.Id).Event_vod__c))
                    continue ;
            }
            
            system.debug('Event Status :'+ eventTeamMember.Event_vod__c);
            try{           
                System.Debug('Event Team Member Update after trigger called for id ='+eventTeamMember .id);      
                //---------New---------------------
                EM_Event_Team_Member_vod__c oldEventTeamMember= Trigger.oldMap.get(eventTeamMember.id);  
                
                if(oldEventTeamMember.Team_Member_vod__c != null && eventTeamMember.Team_Member_vod__c != null )
                {
                    if(oldEventTeamMember.Team_Member_vod__c != eventTeamMember.Team_Member_vod__c)
                    {
                        if( oldEventTeamMember.Role_vod__c.containsIgnoreCase('cohost'))
                        {
                            /// send Delete for Old
                            Pw_Call_Service_Bus_API.MakeCalloutDeleteTeamMember(eventTeamMember.id ,oldEventTeamMember);
                            
                        }
                        if(eventTeamMember.Role_vod__c.containsIgnoreCase('cohost'))
                        {
                            /// send Insert for New
                            Pw_Call_Service_Bus_API.MakeCalloutInsertTeamMember(eventTeamMember.id ,eventTeamMember);
                        }
                        
                    }else if(oldEventTeamMember.Team_Member_vod__c == eventTeamMember.Team_Member_vod__c)
                    {
                        if(eventTeamMember.Role_vod__c.containsIgnoreCase('cohost'))
                        {
                            if(eventTeamMember.Role_vod__c !=  oldEventTeamMember.Role_vod__c)
                            {
                                /// send Insert for New  (doubt)
                                Pw_Call_Service_Bus_API.MakeCalloutInsertTeamMember(eventTeamMember.id ,eventTeamMember);
                            }
                            
                            
                            
                        }
                        else if(eventTeamMember.Role_vod__c.containsIgnoreCase('organizer'))
                        {
                            
                        }
                        else
                        {
                            if(eventTeamMember.Role_vod__c !=  oldEventTeamMember.Role_vod__c)
                            {
                                if(oldEventTeamMember.Role_vod__c.containsIgnoreCase('cohost'))
                                { /// send Insert for New  (doubt)
                                Pw_Call_Service_Bus_API.MakeCalloutDeleteTeamMember(eventTeamMember.id ,oldEventTeamMember);
                                }
                            } 
                        }
                        
                    }
                    
                }  else if(oldEventTeamMember.Team_Member_vod__c == null && eventTeamMember.Team_Member_vod__c == null)    
                {
                    
                } else if(oldEventTeamMember.Team_Member_vod__c == null && eventTeamMember.Team_Member_vod__c != null)  
                {
                    if(eventTeamMember.Role_vod__c.containsIgnoreCase('cohost'))
                    {
                        
                        /// send Insert for New         
                        Pw_Call_Service_Bus_API.MakeCalloutInsertTeamMember(eventTeamMember.id ,eventTeamMember);
                        
                        
                    }
                    
                }  else if(oldEventTeamMember.Team_Member_vod__c != null && eventTeamMember.Team_Member_vod__c == null)  
                {
                    if(oldEventTeamMember.Role_vod__c.containsIgnoreCase('cohost'))
                    {
                        
                        /// send Delete for old         
                        Pw_Call_Service_Bus_API.MakeCalloutDeleteTeamMember(eventTeamMember.id ,oldEventTeamMember);
                        
                        
                    }
                    
                }  
                //----------New End---------------------
                //  Pw_Call_Service_Bus_API.MakeCalloutAddTeamMember(eventTeamMember.id ,triggerEvent);
                System.Debug('Event Team Member Update after trigger ');
            }
            catch(Exception e){
                
                PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
                
                System.Debug(' Event Team member update after trigger exception');  
                System.Debug('exception'+e);  
                
                // eventTeamMember.addError('An error has occurred upon submitting this event.Please contact support for further assistance.');
                system.debug('An error has occurred upon inserting Event Team Member.Please contact Support for further assistance.');
            }
        }
        
    }
}