global class MSD_CORE_Update_Virtual_Attendee_Status implements Database.Batchable<sObject>, Database.Stateful{
    public integer count = 0;
    public integer processed = 0;
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT ID,MSD_CORE_Attended_Live__c,MSD_CORE_Attended_Replay__c,Status_vod__c,Event_vod__r.MSD_CORE_Country_Code__c, Event_vod__r.MSD_CORE_Remote_Access_Platform__c FROM EM_Attendee_vod__c WHERE MSD_CORE_Source_System__c = \'GWET\' AND Event_vod__c IN(SELECT ID FROM EM_Event_vod__c WHERE MSD_Core_Published__c = true AND End_Time_vod__c < LAST_N_DAYS:2 AND Status_vod__c = \'Approved_vod\')';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<EM_Attendee_vod__c> relAttendees){
        System.debug('This is attendee list size===>'+relAttendees.size());
        System.debug('This is attendee list===>'+relAttendees);
        
        Id rapRecTypeId = Schema.SObjectType.Common_KPI__c.getRecordTypeInfosByName().get('Remote Access Platform').getRecordTypeId();
        List<Common_KPI__c> commonKPIList = new List<Common_KPI__c>();
        map<Id,String> cKPIIdWithName = new map<Id,String>();
        commonKPIList = [SELECT id, Name FROM Common_KPI__c WHERE recordTypeId =: rapRecTypeId];
        
        for(Common_KPI__c each:commonKPIList){
            cKPIIdWithName.put(each.Id, each.Name);
        }
        
        List<EM_Attendee_vod__c> listAttendees = new List<EM_Attendee_vod__c>();
        
        for (EM_Attendee_vod__c att : relAttendees){
          
          //String countryCode = att.Event_vod__r.MSD_CORE_Country_Code__c; //Comment out not used in the US
          MSD_Core_RTI_Switch_Utility gwetUtility = new MSD_Core_RTI_Switch_Utility();
          String switchStatus = gwetUtility.getSwitchValue('US','GWET'); //This call now returns a hard coded value for the US.
          
          //String contextKPI = cKPIIdWithName.get(att.Event_vod__r.MSD_CORE_Remote_Access_Platform__c);
          String contextKPI = 'ON24';
          
          system.debug('This is KPI Name  ====> '+ contextKPI);
          system.debug('This is switch status  ====> '+ switchStatus);
          
            if(switchStatus == 'ON' && (contextKPI == 'ON24' || contextKPI == 'Webex' || contextKPI == 'MSD Live' || contextKPI == 'MS Teams' )){
                count++;
                system.debug('This is attendee status  ====> '+ att.Status_vod__c);
                
                if(att.Status_vod__c != 'Attended_vod'){
                    
                    system.debug('Inside If  ====> ');
                    if(att.MSD_CORE_Attended_Live__c != FALSE || att.MSD_CORE_Attended_Replay__c != FALSE){
                        att.Status_vod__c = 'Attended_vod';
                    }else{
                        att.Status_vod__c = 'No Show';
                    }
                    
                    listAttendees.add(att);
                }
            }
        }
        
        system.debug('This is attlist size ====> '+ listAttendees.size());
        
        try{      
            database.saveresult[] ds =  Database.update(listAttendees,false);
            system.debug('This is DML size ====> '+ ds.size());
            for(database.SaveResult d : ds){
                if(d.issuccess()){
                    processed++;
                }                   
            }
        }
        catch(exception e){
            system.debug('update failed');
        }
    } 
    
    global void finish(Database.BatchableContext bc){

        system.debug('+++++ Total scope record count +++++'+count);
        system.debug('+++++ Total processed record count +++++'+processed);
    }
}