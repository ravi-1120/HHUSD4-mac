///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_Filter_On_Event_Record_Types 
///   Description:    This class will filter the event record type for integration
///   Author:         Khushbu Khetan                   
///   Notes:          Conatins methods which will will filter the event record type for integration
///   Date: 1-10-2018
///-----------------------------------------------------------------
public class PW_Filter_On_Event_Record_Types {

    public Map<Id,EM_Event_vod__c > eventMap{get;set;}
    
    public void filterEventRecordTypes(Set<Id> eventIdSet)
    {
        system.debug('filterEventRecordTypes method eventIdSet---'+eventIdSet);
        eventMap = new Map<Id,EM_Event_vod__c >();
        if(eventIdSet!=null)
        {
            eventMap = new Map<Id,EM_Event_vod__c >([Select Id,Recordtype.DeveloperName from EM_Event_vod__c where Id in : eventIdSet]);           
        }
        system.debug('filterEventRecordTypes method ---'+eventMap );
    }
    
    public boolean checkRecordTypeForEvent(Id eventId)
    {
        system.debug('checkRecordTypeForEvent Id ---'+eventId);
        boolean passRecordType = false;
        PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
        
        if(!regSettings.PW_Filter_Event_Record_Types__c)
        {
            passRecordType =true;
            return passRecordType;
        }
        
        if(regSettings.PW_Event_Record_Types_For_Integration__c == '')
        {
            passRecordType =true;
        }
        else
        {               
            if(eventMap!=null && eventMap.containsKey(eventId))
            {
                if(eventMap.get(eventId)!=null)
                {
                    if(regSettings.PW_Event_Record_Types_For_Integration__c.contains(eventMap.get(eventId).Recordtype.DeveloperName))
                    {
                       passRecordType =true; 
                    }
                    else
                    {
                        passRecordType =false; 
                    }
                }
            }
        }
        system.debug('checkRecordTypeForEventmethod ---'+eventMap );
        system.debug('checkRecordTypeForEvent passRecordType ---'+passRecordType);
        return passRecordType;
    }

}