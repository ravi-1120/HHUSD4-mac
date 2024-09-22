public class PW_Proccess_Event_Update {

public static void  proccessEventUpdate(List<EM_Event_vod__c> newEvents,List<EM_Event_vod__c> oldEvents,
Map<Id,EM_Event_vod__c> newMap,Map<Id,EM_Event_vod__c> oldMap)
{
   
        Set<Id> allEventIds = newMap.keySet();
        PW_Filter_On_Event_Record_Types pwFilterRT = new PW_Filter_On_Event_Record_Types();
        pwFilterRT.filterEventRecordTypes(allEventIds);
    
     System.Debug(' Event With Submitted Status');
        for (EM_Event_vod__c event : newEvents) 
        {
             system.debug('Filter checkRecordtypeForEvent -----'+pwFilterRT.checkRecordTypeForEvent(event.Id));
             if(!pwFilterRT.checkRecordTypeForEvent(event.Id))                
                continue ;
        
             EM_Event_vod__c oldEvent= oldMap.get(event.id);
         
                try{
                
                PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
                String[] eventTriggerStatus = new string[]{};
                String[] emailTriggerStatus = new string[]{};
                
                if(!string.isEMpty(regSettings.PW_Event_trigger_Statuses__c))
                {
                    eventTriggerStatus = regSettings.PW_Event_trigger_Statuses__c.split(';');
                }
                else
                {
                    system.debug('Event trigger status in PW General Settings is empty : ' +regSettings.PW_Event_trigger_Statuses__c);
                    event.addError('An error has occurred upon submitting this event.Please contact support for further assistance.');                    
                }
                 
                 if(!string.isEMpty(regSettings.PW_Email_Trigger_Statuses__c))
                    emailTriggerStatus = regSettings.PW_Email_Trigger_Statuses__c.split(';');
                    
                boolean eventFlag=false;
                boolean emailFlag=false;
                for(string status : eventTriggerStatus)
                {
                    if(event.Status_vod__c==status && oldEvent.Status_vod__c!=status )
                    {
                        eventFlag=true;
                    }
                
                }
                
                for(string status : emailTriggerStatus)
                {
                    if(event.Status_vod__c==status && oldEvent.Status_vod__c!=status )
                    {
                        emailFlag=true;
                    }
                
                }
                                
                if(regSettings.PW_Auto_Select_Budget__c)
                {
                    boolean validateBudget = false;
                    system.debug(event.Status_vod__c+'---- Event Status validateBudget');
                    if(regSettings.PW_Validate_Budget_Statuses__c.contains(event.Status_vod__c))
                    {
                        Pw_AutoSelect_Budget_To_Event pwBudgetEvent = new Pw_AutoSelect_Budget_To_Event();
                        validateBudget = pwBudgetEvent.ValidateBudgetForEvent(event.Id);
                        if(!validateBudget)
                        {
                            event.addError(pwBudgetEvent.errorMessage);
                            return;
                        }
                    }
                
                    boolean isbudgetSelected = false;
                    system.debug(event.Status_vod__c+'---- Event Status');
                    system.debug(oldEvent.Status_vod__c+'---- Event old Status');
                    if(event.Status_vod__c==regSettings.PW_Budget_Auto_Selection_Status__c && oldEvent.Status_vod__c!=regSettings.PW_Budget_Auto_Selection_Status__c )
                    {
                        Pw_AutoSelect_Budget_To_Event pwBudgetEvent = new Pw_AutoSelect_Budget_To_Event();
                        isbudgetSelected = pwBudgetEvent.AutoSelectBudgetToEvent(event.Id);
                        if(!isbudgetSelected)
                        {
                            event.addError(pwBudgetEvent.errorMessage);
                            return;
                        }
                    }
                }
                
                if(emailFlag)
                {
                    Pw_Send_Email_On_Submission.CreateAndSendEmail(event.id);
                }
                
                System.Debug('trigger called for id ='+event.id);
                if(eventFlag)   
                { 
                    Pw_Call_Service_Bus_API.MakeCallout(event.id);
                }
                
                    
                System.Debug(' Event With Submitted Status');
                }
                catch(Exception e){
                
                PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
                    
                System.Debug(' Event is in trigger exception'); 
                System.Debug('exception'+e);    
                event.addError('An error has occurred upon submitting this event.Please contact support for further assistance.');                    
                }
        
        }


}
public static void proccessEventStatusUpdate(List<EM_Event_vod__c> newEvents,List<EM_Event_vod__c> oldEvents,
Map<Id,EM_Event_vod__c> newMap,Map<Id,EM_Event_vod__c> oldMap)
{
        Set<Id> allEventIds = newMap.keySet();
        PW_Filter_On_Event_Record_Types pwFilterRT = new PW_Filter_On_Event_Record_Types();
        pwFilterRT.filterEventRecordTypes(allEventIds);
         for (EM_Event_vod__c event : newEvents) 
        {
            system.debug('Filter checkRecordtypeForEvent -----'+pwFilterRT.checkRecordTypeForEvent(event.Id));
             if(!pwFilterRT.checkRecordTypeForEvent(event.Id))                
                continue ;
        
             EM_Event_vod__c oldEvent= oldMap.get(event.id);
             try{
                    PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
                    String[] eventStatusAfterApproved = new string[]{};
                    
                
                    if(!string.isEMpty(regSettings.PW_Event_Statuses_After_Approved__c))
                    {
                        eventStatusAfterApproved = regSettings.PW_Event_Statuses_After_Approved__c.split(';');
                    }
                    else
                    {
                        system.debug('Event trigger status in PW General Settings is empty : ' +regSettings.PW_Event_Statuses_After_Approved__c);
                                           
                    }
                     boolean sendEventStatusFlag=false;                    
                      for(string status : eventStatusAfterApproved)
                      {
                          if(event.Status_vod__c==status && oldEvent.Status_vod__c!=event.Status_vod__c )
                          {
                              sendEventStatusFlag=true;
                          }
                      
                      }
                      if(sendEventStatusFlag)   
                      { 
                          System.Debug('Sending Event Status sendEventStatusFlag ::'+sendEventStatusFlag);
                         Pw_Call_Service_Bus_API.MakeCalloutEventStatus(event.id);
                      }                
                    
                      System.Debug(' Event With Submitted Status');

                }   //end of try
                  catch(Exception e){
                
                PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
                    
                System.Debug(' Event is in trigger exception'); 
                System.Debug('exception'+e);    
                               
                }


        }//end of for


}

public static void proccessEventUpdMsg(List<EM_Event_vod__c> newEvents,List<EM_Event_vod__c> oldEvents,
Map<Id,EM_Event_vod__c> newMap,Map<Id,EM_Event_vod__c> oldMap)
{
    try
    {
        PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
                    String[] eventStatusAfterApproved = new string[]{};
                    
        if(regSettings.PW_Send_Event_UPD_Msg__c== false)
            {
                return;
            }
        Set<Id> allEventIds = newMap.keySet();
        PW_Filter_On_Event_Record_Types pwFilterRT = new PW_Filter_On_Event_Record_Types();
        pwFilterRT.filterEventRecordTypes(allEventIds);
         for (EM_Event_vod__c event : newEvents) 
        {
        
             if(event.PW_Is_EventApproved__c==false)
                continue;
             
            system.debug('Filter checkRecordtypeForEvent -----'+pwFilterRT.checkRecordTypeForEvent(event.Id));
             if(!pwFilterRT.checkRecordTypeForEvent(event.Id))                
                continue ;
        
             EM_Event_vod__c oldEvent= oldMap.get(event.id);
             try{
                    
                     boolean sendEventUpdMsgFlag=true; 
                    if(!string.isEmpty(regSettings.PW_Event_trigger_Statuses__c))
                    {
                        List<string> eventTriggerStatus = regSettings.PW_Event_trigger_Statuses__c.split(';');
                        for(string status : eventTriggerStatus)
                        {
                            if(event.Status_vod__c==status && oldEvent.Status_vod__c!=status )
                            {
                                sendEventUpdMsgFlag=false;
                                
                            }
                    
                        }
                    }
                      if(sendEventUpdMsgFlag)   
                      { 
                          System.Debug('Sending Event upd msg  sendEventUpdMsgFlag::'+sendEventUpdMsgFlag);
                         Pw_Call_Service_Bus_API.MakeCalloutEventUpdMsg(event.id);
                      }                
                    
                      System.Debug(' Event With Submitted Status');

                }   //end of try
                 catch(Exception e)
                {
                
                PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
                    
                System.Debug(' Event is in trigger exception'); 
                System.Debug('exception'+e);    
                               
                }


        }//end of for
    }//end of try
    catch(Exception e)
    {
                
                PW_Log_Into_CustomLogger.Log(e.getStackTraceString(),e.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
                    
                System.Debug(' Event is in trigger exception'); 
                System.Debug('exception'+e);    
                               
    }

}
}