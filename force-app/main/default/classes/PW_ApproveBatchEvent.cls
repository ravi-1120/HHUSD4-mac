public class PW_ApproveBatchEvent
{
    
    public EM_Event_vod__c local_event{get;set;}
    public PW_Batch_Processing_PerRecType_Settings__c PW_RecTypeSetting{get;set;}
    public PW_Batch_Processing_Global_Settings__c PW_globalSetting{get;set;}
    public String ErrorDescription {get;set;}    
    public String Current_Event_Status {get;Set;}
    public String SchedulerName{get;Set;}
    public String SchedulerID{get;Set;}
    public String JobType{get;Set;}
    public String QueuableJobID {get;set;}
    
    public void execute(QueueableContext context){
    
        QueuableJobID = String.ValueOf(context.getJobId());
    
        if(ValidateNullValuesForRequiredFields())
        {
            try
            {
                Set<String> statuses =  new Set<String>(); 
                
                statuses = GetListOfStatuses();
                if (statuses==null)
                {
                    return; //Already logged and hence return
                }
                if(statuses.Size()>0)
                {
                
                    UpdateEventStatuses(statuses);
                }
                else
                {                   
                    ErrorDescription = 'No Statuses, to process, were found in the setting.  RecordType: ' + PW_RecTypeSetting.Name + ' Event Statuses: ' + PW_RecTypeSetting.PW_Event_Statuses__c ; 
                    PW_Log_Into_BatchLogger.LogBatch('', ErrorDescription, Pw_Batch_Logger_Constants.BATCH_INCORRECT_SETTING, UserInfo.getUserName(), local_event.id, SchedulerName, SchedulerID, QueuableJobID);
                    
                    return;
                }
            
                    ErrorDescription = 'Event update succeeded, event status: ' + Current_Event_Status;
               
                    PW_Log_Into_BatchLogger.LogBatch('', ErrorDescription, Pw_Batch_Logger_Constants.BATCH_SUCCESS, UserInfo.getUserName(), local_event.id, SchedulerName, SchedulerID, QueuableJobID);
            }
            catch (Exception Ex)
            {

               ErrorDescription = 'Event update failed for the status: ' + Current_Event_Status + ' Error Message: ' + ex.getMessage(); 
                    PW_Log_Into_BatchLogger.LogBatch(ex.getStackTraceString(), ErrorDescription, Pw_Batch_Logger_Constants.BATCH_FAILURE, UserInfo.getUserName(), local_event.id, SchedulerName, SchedulerID, QueuableJobID);
                    
                    try
                    {
                        local_event.Status_vod__c = PW_globalSetting.Batch_Failed_Event_Status__c;          
                        update local_event;
                    }
                    catch (Exception e)
                    {
                            ErrorDescription = 'Event update failed for the status: ' + PW_globalSetting.Batch_Failed_Event_Status__c + ' Error Message: ' + e.getMessage(); 
                        PW_Log_Into_BatchLogger.LogBatch(e.getStackTraceString(), ErrorDescription, Pw_Batch_Logger_Constants.BATCH_FAILURE, UserInfo.getUserName(), local_event.id, SchedulerName, SchedulerID, QueuableJobID);
                    }
             
            }
            
        }
        
    }
    
    void UpdateEventStatuses(Set<String> statuses)
    {
        for( String status :  statuses)
        {
            local_event.Status_vod__c = status;
            Current_Event_Status = status;      
            update local_event;
                
        }
    }
    
    Set<String> GetListOfStatuses()
    {
        Set<String> statuses =  new Set<String>(); 
        try
        {
            statuses = new Set<String>(PW_RecTypeSetting.PW_Event_Statuses__c.split(';'));
            
        }
        Catch(Exception ex) 
        {
            ErrorDescription = ' Error while getting a list of statuses. Event Statuses: ' + PW_RecTypeSetting.PW_Event_Statuses__c ; 
                    PW_Log_Into_BatchLogger.LogBatch('', ErrorDescription, Pw_Batch_Logger_Constants.BATCH_INCORRECT_SETTING, UserInfo.getUserName(), local_event.id, SchedulerName, SchedulerID, QueuableJobID);
                    
            return null;
        }
        return statuses;
        
    }
    
    Boolean ValidateNullValuesForRequiredFields() 
    {
        try
        {
            Set<String> requiredfields= GetAllUniqueRequiredFields();
            Set<String> requiredfieldswithnovalue = new Set<String>();
            Boolean requiredfieldvalidationfailed= false;
            if(requiredfields.Size()>0)
            {
                for(String field : requiredfields)
                {
                    String fieldValue = String.ValueOf(local_event.get(field));
                    
                    if(String.IsEmpty(fieldValue))
                    {
                        requiredfieldswithnovalue.add(field);
                        requiredfieldvalidationfailed = true;
                    }
                    
                }
                
                if(requiredfieldvalidationfailed == true)
                {
                    ErrorDescription = 'Required field validation failed for the fields: ' + GenerateRequiredFieldsString(requiredfieldswithnovalue); 
                            PW_Log_Into_BatchLogger.LogBatch('', ErrorDescription, Pw_Batch_Logger_Constants.BATCH_FAILURE, UserInfo.getUserName(), local_event.id, SchedulerName, SchedulerID, QueuableJobID);
                     local_event.Status_vod__c = PW_globalSetting.Batch_Failed_Event_Status__c;          
                     update local_event;
                    return false;
                }
                else
                {

                    return true;    
                }
                                
            
            }
            else
            {
                return true;
            }
        }
        catch(Exception ex)
        {
        
            ErrorDescription = 'Required field validation failed as there was an exception while validating, ' + ex.getMessage(); 
            
            PW_Log_Into_BatchLogger.LogBatch('', ErrorDescription, Pw_Batch_Logger_Constants.BATCH_FAILURE, UserInfo.getUserName(), local_event.id, SchedulerName, SchedulerID, QueuableJobID);
            
            return false;
        
        }
    
    }
    String GenerateRequiredFieldsString(Set<string> requiredfields )
    {
        
            String requiredFieldsString = '';
            Boolean firstfield = true;
            for(String s:requiredfields) {
            
                if(firstfield == true)
                {
                    requiredFieldsString += s;
                    firstfield = false;
                }
                else
                {
                   requiredFieldsString +=  ',' + s ;
                }
            }
         return requiredFieldsString;
    }
    
    
    Set<String> GetAllUniqueRequiredFields()
    {
            Set<string> requiredfields = new Set<string>();
            try
            {
                if(!String.IsEmpty(PW_RecTypeSetting.PW_Required_Fields_1__c))
                {
                    Set<String> requiredfields1 =  new Set<String>(PW_RecTypeSetting.PW_Required_Fields_1__c.split(';'));
                    requiredfields.addAll (requiredfields1);
                }

                if(!String.IsEmpty(PW_RecTypeSetting.PW_Required_Fields_2__c))
                {
                    Set<String> requiredfields2 =  new Set<String>(PW_RecTypeSetting.PW_Required_Fields_2__c.split(';'));
                    requiredfields.addAll (requiredfields2);
                }

                if(!String.IsEmpty(PW_RecTypeSetting.PW_Required_Fields_3__c))
                {
                    Set<String> requiredfields3 =  new Set<String>(PW_RecTypeSetting.PW_Required_Fields_3__c.split(';'));
                    requiredfields.addAll (requiredfields3);
                }

                if(!String.IsEmpty(PW_RecTypeSetting.PW_Required_Fields_4__c))
                {
                    Set<String> requiredfields4 =  new Set<String>(PW_RecTypeSetting.PW_Required_Fields_4__c.split(';'));
                    requiredfields.addAll (requiredfields4);
                }
            }
            catch(Exception ex)
            {
            }
            
            return requiredfields;
    
    }
}