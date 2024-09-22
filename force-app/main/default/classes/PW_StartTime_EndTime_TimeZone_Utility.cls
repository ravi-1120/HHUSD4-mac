// Veeva has come with a new feature of Local date and Time. Based on whether the new 
// feature is on or off it would return diffrent values for
// 1. Start_Time
// 2. End_Time
// 3. Time Zone  
public class PW_StartTime_EndTime_TimeZone_Utility
{
   
    PW_PermisionForEMLocalDateTimeFeature permission {get;set;}
    EM_Event_vod__c event {get;set;}
    
    
    public PW_StartTime_EndTime_TimeZone_Utility(Boolean autoInitialize, EM_Event_vod__c evt )
    {
        if(autoInitialize)
        {
        
            permission = new PW_PermisionForEMLocalDateTimeFeature(autoInitialize, evt.OwnerID);
            event = evt;  
                
        }
        
    }
       
    
    
    
    
    
    public String GetStartTime()
    {
        String Start_Time='';
        
        if(permission.IsNewFeatureOn)
        {
            datetime combineStartDateAndTime=DateTime.newInstance(event.Start_Date_vod__c, event.Start_Time_Local_vod__c);
            Start_Time = string.valueof(combineStartDateAndTime); 
        
        }
        else
        {
             datetime combineStartDateAndTime=datetime.parse(event.PW_Local_Start_Date__c.format()+' '+event.PW_Local_Start_Time__c);
             
             Start_Time = string.valueof(combineStartDateAndTime); 
        
        
        }
        
        return Start_Time;
    
    }
    
    public String GetEndTime()
    {
        String End_Time = '';
        if(permission.IsNewFeatureOn)
        {
            datetime combineEndDateAndTime=DateTime.newInstance(event.End_Date_vod__c, event.End_Time_Local_vod__c);
            End_Time = string.valueof(combineEndDateAndTime); 
        
        }
        else
        {
             datetime combineStartDateAndTime=datetime.parse(event.PW_Local_Start_Date__c.format()+' '+event.PW_Local_Start_Time__c);
        
            End_Time= GetEndDateOld(event.PW_Duration__c,combineStartDateAndTime);
        
        }
        
        return End_Time;
    
    }
    
    private string GetEndDateOld(decimal duration, datetime startDateTime){              
         System.debug(' duration  ' +duration); 
        integer durationInMinutes= (integer)math.round(duration*60);
        System.debug(' duration  ' +durationInMinutes); 
        datetime endDateLocal =startDateTime.addMinutes(durationInMinutes);
        System.debug(' duration after addition  ' +endDateLocal); 
         return string.valueOf(endDateLocal);
       
    }
    
    public String GetTimeZone()
    {
        String Time_Zone = '';
        
        if(permission.IsNewFeatureOn)
        {
            
            Time_Zone=event.Time_Zone_vod__c;
        
        }
        else
        {
        
             Time_Zone=event.PW_Time_Zone__c;
        
        }
        
        return Time_Zone;
    
    }
    
    public Date GetDateFromMWString(string payloadDateTime )
    {
        DateTime localtime = datetime.valueOf(payloadDateTime.replaceAll('/','-'));
        
        return date.parse(localtime.format('MM/dd/yyyy'));
    }
    
    public Time GetTimeFromMWString(string payloadDateTime) 
    {
        DateTime localtime = datetime.valueOf(payloadDateTime.replaceAll('/','-'));
        
        Time myTime = Time.newInstance(localtime.hour(), localtime.minute(), localtime.second(), localtime.millisecond());
        
        return  myTime;
        
    }
    Datetime convertToUTCBasedOnUserTimezone(string dt,Id eventOwnerId){
            Datetime res = datetime.valueOfGMT(dt.replaceAll('/','-'));
            User user = [SELECT TimeZoneSidKey,Username FROM User WHERE id =: eventOwnerId];
            //EM_Event_vod__c event  = [Select Id,Name,start_time_vod__c from EM_Event_vod__c where id='a2v4C0000003aQN'];
            string dateTimeStr = event.Start_time_vod__c.format('yyyy-MM-dd HH:mm:ss',  user.TimeZoneSidKey);
            string dateGmtStr  = event.Start_time_vod__c.formatGMT('yyyy-MM-dd HH:mm:ss');
            Datetime localDateTime = DateTime.valueOf(dateTimeStr);
            Datetime baseGMTTime = DateTime.valueOf(dateGMTStr);
            Long milliSecDiff =  baseGMTTime.getTime() - localDateTime.getTime();
            Long minDiff = milliSecDiff / 1000 / 60;
            Datetime outDateTime = res.addMinutes(minDiff.intValue());
            return outDateTime;
        }
        
    public void SetStartTimeEndTimeAndTimeZone(PW_Event_Model eventOfTp)
    {
        if(permission.IsNewFeatureOn)
        {
        
            //New Code 
            event.Time_Zone_vod__c = eventOfTp.Time_Zone;
            event.End_Time_Local_vod__c = GetTimeFromMWString (eventOfTp.End_Time);
            event.Start_Time_Local_vod__c = GetTimeFromMWString (eventOfTp.Start_Time);
            event.Start_Date_vod__c = GetDateFromMWString(eventOfTp.Start_Time);
            event.End_Date_vod__c = GetDateFromMWString(eventOfTp.End_Time);           
        
        }
        else
        {
        
        // Retaining the existing code  
                event.Start_Time_vod__c=convertToUTCBasedOnUserTimezone(eventOfTp.Start_Time,event.OwnerId);
                event.End_Time_vod__c=convertToUTCBasedOnUserTimezone(eventOfTp.End_Time,event.OwnerId);
                
                DateTime localtime = datetime.valueOf(eventOfTp.Start_Time.replaceAll('/','-'));
                event.PW_Local_Start_Date__c=date.parse(localtime.format('MM/dd/yyyy'));
                    //date.newinstance(event.Start_Time_vod__c.year(), event.Start_Time_vod__c.month(), event.Start_Time_vod__c.day());
                event.PW_Local_Start_Time__c = localtime.format('h:mm a');

                event.PW_Time_Zone__c=eventOfTp.Time_Zone;
             
        
        }
    
    }
    
    
    
     // For Email Functionality
    public Date GetLocalStartDate()
    {
        if(permission.IsNewFeatureOn)
        {
            return event.Start_Date_vod__c;
        }
        else
        {
            return event.PW_Local_Start_Date__c;
        
        }
    
    }
    
    // For Email Functionality
    public String GetLocalStartTime()
    {
        if(permission.IsNewFeatureOn)
        {
            datetime combineStartDateAndTime=DateTime.newInstance(event.Start_Date_vod__c, event.Start_Time_Local_vod__c);
            
            return combineStartDateAndTime.format('h:mm a');
        }
        else
        {
            return event.PW_Local_Start_Time__c;
        
        }
    
    }
    
    // For Email Functionality
    public String GetTimeZoneValue()
    {
        if(permission.IsNewFeatureOn)
        {
            
            
            return (String )event.get('NewTimeZoneLabel');
        }
        else
        {
            return (String)event.get('OldTimeZoneLabel');
        
        }
    
    }
    


}