trigger PW_Event_Team_Member_After_Delete on EM_Event_Team_Member_vod__c (after delete) {
    
    
    System.Debug('Event Team Member after delete trigger');
    String triggerEvent ='';
    if (Trigger.isDelete)
    {
        triggerEvent ='DELETE';
        PW_Robot_User__c robotUserCustomSetting=PW_Robot_User__c.getValues('RobotUserSetting');
        if(robotUserCustomSetting.Robot_User__c==UserInfo.getUserName())
        {       
            System.Debug('Event Team Member created with robot user :'+UserInfo.getUserName());
            return;
        }
        
        Set<Id> allEventTeamMemberIds = trigger.oldMap.keySet();
        Map<Id,EM_Event_Team_Member_vod__c > eventTeamMemberMap =  new Map<Id,EM_Event_Team_Member_vod__c >([Select Id,Event_vod__c from EM_Event_Team_Member_vod__c where Id in :allEventTeamMemberIds ALL ROWS]);
        Set<Id> eventIds = new Set<Id>();
        for(EM_Event_Team_Member_vod__c eventTeamMember : eventTeamMemberMap.values())
        {
            if(eventTeamMember!=null)
                eventIds.add(eventTeamMember.Event_vod__c);
        }
        PW_Filter_On_Event_Record_Types pwFilterRT = new PW_Filter_On_Event_Record_Types();
        pwFilterRT.filterEventRecordTypes(eventIds);
        
      //  PW_Identify_Cohost_Organiser_Role pw_team_member_role=new PW_Identify_Cohost_Organiser_Role();  //---New
        
        
        for (EM_Event_Team_Member_vod__c eventTeamMember : Trigger.old) 
        {
            if(eventTeamMemberMap.get(eventTeamMember.Id)!=null)
            {
                if(!pwFilterRT.checkRecordTypeForEvent(eventTeamMemberMap.get(eventTeamMember.Id).Event_vod__c))
                    continue ;
            }
            
            system.debug('Event Status :'+ eventTeamMember.Event_vod__c);
            try{           
                System.Debug('Event Team Member Delete after trigger called for id ='+eventTeamMember .id); 
                if(eventTeamMember.Role_vod__c.containsIgnoreCase('cohost') )
                {				
                    Pw_Call_Service_Bus_API.MakeCalloutDeleteTeamMember(eventTeamMember.id ,eventTeamMember);
                }
                System.Debug('Team Member Delete after trigger');
            }
            catch(Exception e){
                
                PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
                
                System.Debug(' Event Team member delete after trigger exception');  
                System.Debug('exception'+e);  
                
              //  eventTeamMember.addError('An error has occurred upon submitting this event.Please contact support for further assistance.');
                system.debug('An error has occurred upon inserting Event Team Member.Please contact Support for further assistance.');
            }
        }
        
    }
}