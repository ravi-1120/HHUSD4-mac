public class PW_BatchEventProcessingAdv
 {
    
    
    PW_Batch_Processing_Global_Settings__c globalCustomSetting {get;set;}
    Map<String, PW_Batch_Processing_PerRecType_Settings__c> mapRecordTypeCustomSetting {get;set;}
    
    public Boolean batchprocessorsettingserror {get;set;}
    public String ErrorDescription; 
    public String SchedulerName {get;set;}
    public String SchedulerID {get;set;}
    public String JobType {get;set;}
    public String SqlLimit {get;set;}
    public Integer NoOfEventsPerQueuable {get;set;}
    
    public void InitializeBatchProcessing(SchedulableContext sc)
    {
    
        try
        {
            SqlLimit = '100';
            NoOfEventsPerQueuable = 2;
            
            SetSchedulerNameAndID(sc);
            Batchprocessorsettingserror = false;
            List<PW_Batch_Processing_Global_Settings__c> globalCustomSettings =  PW_Batch_Processing_Global_Settings__c.getAll().values(); //Note .getAll() returns an empty map if there are no records

            globalCustomSetting = new PW_Batch_Processing_Global_Settings__c();

            if(globalCustomSettings.Size()>0)
            {
                globalCustomSetting = globalCustomSettings [0];
                
                if((globalCustomSetting.No_Of_Events_Processed_Per_Queuable__c==null) || (globalCustomSetting.No_Of_Events_Processed_Per_Queuable__c== 0) || (globalCustomSetting.Max_Events_Per_Schedule__c ==null) || (globalCustomSetting.Max_Events_Per_Schedule__c ==0) )
                {
                    System.Debug('Settings not propper ');
                
                    ErrorDescription = 'BATCH ABORTED: Global Batch Custom Setting -> PW_Batch_Processing_Global_Settings__c.No_Of_Events_Processed_Per_Queuable__c or PW_Batch_Processing_Global_Settings__c.Max_Events_Per_Schedule__c value missing';
                    batchprocessorsettingserror = true;
                    PW_Log_Into_BatchLogger.LogBatch('', ErrorDescription, Pw_Batch_Logger_Constants.BATCH_INCORRECT_SETTING, UserInfo.getUserName(), null, SchedulerName, SchedulerID, '');
                    
                   
                }
                else
                {
                     NoOfEventsPerQueuable = Integer.ValueOf(globalCustomSetting.No_Of_Events_Processed_Per_Queuable__c);
                     SqlLimit  =  String.valueOf(Integer.ValueOf(globalCustomSetting.Max_Events_Per_Schedule__c));
                
                }
                
                if(String.IsEmpty(globalCustomSetting.Batch_Pending_Event_Status__c)&& String.IsEmpty(globalCustomSetting.Batch_Failed_Event_Status__c))
                {
                    System.Debug('Settings ot propper ');
                
                    ErrorDescription = 'BATCH ABORTED: Global Batch Custom Setting -> PW_Batch_Processing_Global_Settings__c.Batch_Pending_Event_Status__c and PW_Batch_Processing_Global_Settings__c.Batch_Failed_Event_Status__c value missing';
                    batchprocessorsettingserror = true;
                    PW_Log_Into_BatchLogger.LogBatch('', ErrorDescription, Pw_Batch_Logger_Constants.BATCH_INCORRECT_SETTING, UserInfo.getUserName(), null, SchedulerName, SchedulerID, '');
                    
                
                }
                else if(String.IsEmpty(globalCustomSetting.Batch_Pending_Event_Status__c))
                {
                    System.Debug('Settings ot propper ');
                
                    ErrorDescription = 'BATCH ABORTED: Global Batch Custom Setting -> PW_Batch_Processing_Global_Settings__c.Batch_Pending_Event_Status__c value missing';
                    batchprocessorsettingserror = true;
                    PW_Log_Into_BatchLogger.LogBatch('', ErrorDescription, Pw_Batch_Logger_Constants.BATCH_INCORRECT_SETTING, UserInfo.getUserName(), null, SchedulerName, SchedulerID, '');
                
                
                }
                else if(String.IsEmpty(globalCustomSetting.Batch_Failed_Event_Status__c))
                {
                    System.Debug('Settings not propper ');
                
                    ErrorDescription = 'BATCH ABORTED: Global Batch Custom Setting -> PW_Batch_Processing_Global_Settings__c.Batch_Failed_Event_Status__c value missing';
                    batchprocessorsettingserror = true;
                    PW_Log_Into_BatchLogger.LogBatch('', ErrorDescription, Pw_Batch_Logger_Constants.BATCH_INCORRECT_SETTING, UserInfo.getUserName(), null, SchedulerName, SchedulerID, '');
                
                
                }
            }
            else
            {
                System.Debug('Settings ot propper ');
                
                ErrorDescription = 'BATCH ABORTED: Global Batch Custom Setting record missing';
                batchprocessorsettingserror = true;
                PW_Log_Into_BatchLogger.LogBatch('', ErrorDescription, Pw_Batch_Logger_Constants.BATCH_INCORRECT_SETTING, UserInfo.getUserName(), null, SchedulerName, SchedulerID, '');
                        
                return;
            }
            
            mapRecordTypeCustomSetting = PW_Batch_Processing_PerRecType_Settings__c.getAll();
            if(mapRecordTypeCustomSetting.Size()<=0)
            {
            
                ErrorDescription = 'BATCH ABORTED: Batch processiong RecordType Setting records missing';
                batchprocessorsettingserror = true;
                PW_Log_Into_BatchLogger.LogBatch('', ErrorDescription, Pw_Batch_Logger_Constants.BATCH_INCORRECT_SETTING, UserInfo.getUserName(), null, SchedulerName, SchedulerID, '');
            
            }
        }
        catch (Exception ex)
        {
            ErrorDescription = ex.getMessage();
            batchprocessorsettingserror = true;
            PW_Log_Into_BatchLogger.LogBatch(ex.getStackTraceString(), ErrorDescription, Pw_Batch_Logger_Constants.BATCH_INCORRECT_SETTING, UserInfo.getUserName(), null, SchedulerName, SchedulerID, '');
        }
    }
    
    public void processBatchOfEvents(SchedulableContext sc)
    {
        InitializeBatchProcessing(sc);
        
        if(batchprocessorsettingserror==true)
        {
            return;
        }
        
        List <EM_Event_vod__c> events= DBExecuteEventQueryForProcessing();
        
        if(events==null)
        {
            return;
        }
        
        if(events.Size()>0)
        {
            EnqueEventsForProcessing (events);
        }
        else
        {
            ErrorDescription = 'No Events found for processing in this run';
            batchprocessorsettingserror = true;
            PW_Log_Into_BatchLogger.LogBatch('', ErrorDescription, Pw_Batch_Logger_Constants.BATCH_NOEVENTS, UserInfo.getUserName(), null, SchedulerName, SchedulerID, '');
            
        }
    
    }
    void SetSchedulerNameAndID(SchedulableContext sc)
    {

        Id myId= sc.getTriggerId();
    
        CronTrigger ct = [SELECT CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger WHERE Id = :myId];
        SchedulerName = ct.CronJobDetail.Name;
        SchedulerID = String.ValueOf(myId);
        JobType = ct.CronJobDetail.JobType;
    }
    
    public Set<String> GetAllUniqueRequiredFieldsAcrossRecTypes()
    {
        Set<string> requiredfield_acrossrecordtypes = new Set<string>();
        
        try
        {
        
            for(PW_Batch_Processing_PerRecType_Settings__c recordTypeSetting : mapRecordTypeCustomSetting.values()){

                    if(!String.IsEmpty(recordTypeSetting.PW_Required_Fields_1__c))
                    {
                        Set<String> requiredfields1 =  new Set<String>(recordTypeSetting.PW_Required_Fields_1__c.split(';'));
                        requiredfield_acrossrecordtypes.addAll (requiredfields1);
                    }

                    if(!String.IsEmpty(recordTypeSetting.PW_Required_Fields_2__c))
                    {
                        Set<String> requiredfields2 =  new Set<String>(recordTypeSetting.PW_Required_Fields_2__c.split(';'));
                        requiredfield_acrossrecordtypes.addAll (requiredfields2);
                    }

                    if(!String.IsEmpty(recordTypeSetting.PW_Required_Fields_3__c))
                    {
                        Set<String> requiredfields3 =  new Set<String>(recordTypeSetting.PW_Required_Fields_3__c.split(';'));
                        requiredfield_acrossrecordtypes.addAll (requiredfields3);
                    }

                    if(!String.IsEmpty(recordTypeSetting.PW_Required_Fields_4__c))
                    {
                        Set<String> requiredfields4 =  new Set<String>(recordTypeSetting.PW_Required_Fields_4__c.split(';'));
                        requiredfield_acrossrecordtypes.addAll (requiredfields4);
                    }

            }
        }
        catch(Exception ex)
        {
            batchprocessorsettingserror = true;
            ErrorDescription = 'GetAllUniqueRequiredFieldsAcrossRecTypes : ' + ex.getMessage();
            PW_Log_Into_BatchLogger.LogBatch(ex.getStackTraceString(), ErrorDescription, Pw_Batch_Logger_Constants.BATCH_INCORRECT_SETTING, UserInfo.getUserName(), null, SchedulerName, SchedulerID, '');
            
        }
        
        return requiredfield_acrossrecordtypes;
        
    }
    String GenerateRequiredFieldsString()
    {
        if(batchprocessorsettingserror == true)
        {
            return null;
        }
        
        Set<string> requiredfield_acrossrecordtypes = new Set<string>();
        
        try
        {
            requiredfield_acrossrecordtypes=GetAllUniqueRequiredFieldsAcrossRecTypes();
            String requiredFieldsString = '';
            for(String s:requiredfield_acrossrecordtypes) {
               requiredFieldsString +=  ',' + s ;
            }
         return requiredFieldsString;
        }
        catch(Exception ex)
        {
            batchprocessorsettingserror = true;
            ErrorDescription = 'GenerateRequiredFieldsString : ' + ex.getMessage();
            PW_Log_Into_BatchLogger.LogBatch(ex.getStackTraceString(), ErrorDescription, Pw_Batch_Logger_Constants.BATCH_INCORRECT_SETTING, UserInfo.getUserName(), null, SchedulerName, SchedulerID, '');
        }
        return null;
    
    }
    
    String GenerateEventQueryForBatchProcessing(String requiredFieldsString)
    {
        if(batchprocessorsettingserror == true)
        {
            return null;
        }
        try
        {
            
            
            String query = 'SELECT Id, Status_vod__c, RecordType.DeveloperName' +  requiredFieldsString + ' FROM EM_Event_vod__c WHERE Status_vod__c = \'' + globalCustomSetting.Batch_Pending_Event_Status__c + '\' and RecordType.DeveloperName IN' ;

            query += ':keys LIMIT ' + SqlLimit;
            return query;
        }
        catch (Exception ex)
        {
            batchprocessorsettingserror = true;
            ErrorDescription = 'GenerateEventQueryForBatchProcessing : ' + ex.getMessage();
            PW_Log_Into_BatchLogger.LogBatch(ex.getStackTraceString(), ErrorDescription, Pw_Batch_Logger_Constants.BATCH_INCORRECT_SETTING, UserInfo.getUserName(), null, SchedulerName, SchedulerID, '');
        }
        return null;
    }
    List <EM_Event_vod__c> DBExecuteEventQueryForProcessing()
    {   
        String requiredFieldsString='';
        String query ='';
        
        if(batchprocessorsettingserror == true)
        {
            return null;
        }
    
        try
        {
             SET<string> keys = mapRecordTypeCustomSetting.keyset();
            requiredFieldsString= GenerateRequiredFieldsString();
            query= GenerateEventQueryForBatchProcessing(requiredFieldsString);
            if(query==null || requiredFieldsString == null)
            {
                return null;
            }
            List <EM_Event_vod__c> events=Database.query(query);
            return events;
        }
        catch(Exception ex)
        {
            batchprocessorsettingserror= true;
            ErrorDescription = 'Query Execution Failed : ' + query + ' Required fields: ' + requiredFieldsString + ' Message : ' + ex.getMessage();
            PW_Log_Into_BatchLogger.LogBatch(ex.getStackTraceString(), ErrorDescription, Pw_Batch_Logger_Constants.BATCH_INCORRECT_SETTING, UserInfo.getUserName(), null, SchedulerName, SchedulerID, '');
        }
        return null;
    }
    void EnqueEventsForProcessing(List <EM_Event_vod__c> events)
    {
        try
        {
            
            PW_QueueableApproveBatchEvents eventsQueue = new PW_QueueableApproveBatchEvents();
            
            for(EM_Event_vod__c event: events)
            {
                
                
                
                PW_ApproveBatchEvent enqueEvent = new PW_ApproveBatchEvent();
                            enqueEvent.local_event =  event;
                            enqueEvent.PW_RecTypeSetting = mapRecordTypeCustomSetting.get(event.RecordType.DeveloperName);
                            enqueEvent.PW_globalSetting = globalCustomSetting;
                            enqueEvent.SchedulerName = SchedulerName;
                            enqueEvent.SchedulerID = SchedulerID;
                            enqueEvent.JobType= JobType;    
                
                
                eventsQueue.events.Add(enqueEvent);

                if(eventsQueue.events.Size()== NoOfEventsPerQueuable)
                {
                             
                    ID jobID = System.enqueueJob(eventsQueue);
                    
                    eventsQueue= new PW_QueueableApproveBatchEvents();
                }
             
            }
            if(eventsQueue.events.Size()>0)
            {
                ID jobID = System.enqueueJob(eventsQueue);
            }
        }
        catch (Exception ex)
        {
            ErrorDescription = 'Enqueue events failed: ' +  ex.getMessage();
            PW_Log_Into_BatchLogger.LogBatch(ex.getStackTraceString(), ErrorDescription, Pw_Batch_Logger_Constants.BATCH_GENERAL_EXCEPTION, UserInfo.getUserName(), null, SchedulerName, SchedulerID, '');
        }
        
    }
 }