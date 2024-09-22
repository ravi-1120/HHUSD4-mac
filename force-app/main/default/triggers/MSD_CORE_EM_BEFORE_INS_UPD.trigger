/*
 * Trigger: Updates Attendee's address to the address selected by the user on update.
 * Also, updated Attendee's email address to Account's email address
 * Author: Ramesh Elapakurthi
*/
trigger MSD_CORE_EM_BEFORE_INS_UPD on EM_Attendee_vod__c (before insert, before update) {

    List<Id> addressIds=new List<Id>();
    List<Id> accountIds = new List<Id>();
    List<Id> eventIds = new List<Id>();
    
    if(Trigger.IsUpdate){
        for(EM_Attendee_vod__c emAtt:trigger.new){
            if(emAtt.MSD_CORE_Selected_Address__c!=null) addressIds.add(emAtt.MSD_CORE_Selected_Address__c);
        }
        Map<Id,Address_vod__c> addressMap=new Map<Id,Address_vod__c>([Select Id,Name,Address_Line_2_vod__c,City_vod__c,State_vod__c,Zip_vod__c, License_vod__c, License_Status_vod__c from Address_vod__c where Id in:addressIds]);
        
        for(EM_Attendee_vod__c emAtt: trigger.new){
            
            if(emAtt.Account_vod__c == null) continue;
            
            EM_Attendee_vod__c oldEmAtt = Trigger.oldMap.get(emAtt.Id);
            
            if(oldEmAtt.MSD_CORE_Selected_Address__c != emAtt.MSD_CORE_Selected_Address__c){
                Address_vod__c address =addressMap.get(emAtt.MSD_CORE_Selected_Address__c);
                emAtt.Address_Line_1_vod__c = address.Name;
                emAtt.Address_Line_2_vod__c = address.Address_line_2_vod__c;
                emAtt.City_vod__c = address.City_vod__c;
                emAtt.PW_State__c = address.State_vod__c;
                emAtt.Zip_vod__c = address.Zip_vod__c;
                emAtt.PW_SL_State__c = address.State_vod__c;
                if(address.License_Status_vod__c == 'Valid_vod') 
                    emAtt.PW_SL__c = address.License_vod__c;
            }
        }
    
    }
        
    if(Trigger.IsInsert){
        for(EM_Attendee_vod__c emAtt:trigger.new){
            if(emAtt.Account_vod__c!=null) accountIds.add(emAtt.Account_vod__c);
            if(emAtt.Event_vod__c != null) eventIds.add(emAtt.Event_vod__c);
        }
        Map<Id,Account> accountMap=new Map<Id,Account>([Select Id,PersonEmail,NPI_vod__c from Account where Id in:accountIds]); 
        Map<Id, EM_Event_vod__c> eventMap = new Map<Id, EM_Event_vod__c>([SELECT Id, RecordTypeId FROM EM_Event_vod__c WHERE Id in: eventIds]);
        Map<ID, Schema.RecordTypeInfo> eventRtMap = Schema.SObjectType.EM_Event_vod__c.getRecordTypeInfosById();
        
        for(EM_Attendee_vod__c emAtt: trigger.new){
            
            if(emAtt.Account_vod__c != null) {
                Account acc =accountMap.get(emAtt.Account_vod__c);
                emAtt.Email_vod__c = acc.PersonEmail;
                emAtt.PW_NPI__c = acc.NPI_vod__c;
            }
            EM_Event_vod__c emEvent = eventMap.get(emAtt.Event_vod__c);
            if(emEvent!= null && eventRtMap != null){
                String eventRtDevName =eventRtMap.get(emEvent.RecordtypeId).getDeveloperName();
                
                if(eventRtDevName == 'MSD_CORE_Events_Without_Speakers'){
                    emAtt.Status_vod__c = 'Attended_vod';
                }
            }
        }
    }

}