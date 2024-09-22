/*
 * Trigger: MSD_CORE_AttendeeRollup
 * Description: Calculates Requester count and Attendee count who are missing Placebo Info on Event record when there is an insert/update/delete operation.
 * Author: Kalyan Vuppalapati
 * Release:Sprint 1
*/

trigger MSD_CORE_AttendeeRollup on EM_Attendee_vod__c (after delete, after insert, after update) {
Set<id> EventIds = new Set<id>();
    List<EM_Event_vod__c> EventToUpdate = new List<EM_Event_vod__c>();
if (Trigger.isInsert) {
for (EM_Attendee_vod__c item : Trigger.new)
        EventIds.add(item.Event_vod__c);
    }        
if (Trigger.isUpdate || Trigger.isDelete) {
        for (EM_Attendee_vod__c item : Trigger.old)
            EventIds.add(item.Event_vod__c);
    }

   if(EventIds.size() > 0){
        EventToUpdate = [select Id,MSD_CORE_Attendee_No_Address_Email_Count__c,MSD_CORE_Customer_Requested__c,MSD_CORE_Requester_Count__c,Attendee_s_Missing_Placebo_info_Count__c,(select id,PW_SKit__c ,PW_SLotNo__c,PW_Samples__c,MSD_CORE_Requested_Event__c, Account_vod__c,Address_Line_1_vod__c,  Status_vod__c, Email_vod__c from EM_Attendee_Event_vod__r) from EM_Event_vod__c where Id IN :EventIds];
    }
    for(EM_Event_vod__c EMEvent : EventToUpdate){
        integer valRequesters = 0;
        integer valPlaceboInfoMissing = 0;
        integer valAddressEmailMissing = 0;
        
        for(EM_Attendee_vod__c SPK : EMEvent.EM_Attendee_Event_vod__r){
        
          if (SPK.PW_SKit__c == TRUE && (SPK.PW_SLotNo__c == '' || SPK.PW_Samples__c == NULL)) { valPlaceboInfoMissing += 1;}    
          if (EMEvent.MSD_CORE_Customer_Requested__c == TRUE && SPK.MSD_CORE_Requested_Event__c == TRUE) { valRequesters += 1;}              
 //         if (SPK.Account_vod__c <> NULL && (SPK.Status_vod__c == 'Attended_vod' || SPK.Status_vod__c == 'MSD_CORE_Attended_Trained') && (string.ISBLANK(SPK.Address_Line_1_vod__c)|| string.ISBLANK(SPK.Email_vod__c))) { valAddressEmailMissing += 1;}            
 //         if (SPK.Account_vod__c <> NULL && (string.ISBLANK(SPK.Address_Line_1_vod__c)|| string.ISBLANK(SPK.Email_vod__c))) { valAddressEmailMissing += 1;}  
          if (SPK.Account_vod__c <> NULL && (SPK.Status_vod__c == 'MSD_CORE_Attended_Trained') && (string.ISBLANK(SPK.Address_Line_1_vod__c)|| string.ISBLANK(SPK.Email_vod__c))) { valAddressEmailMissing += 1;}            
           
        }
        
        

        EMEvent.Attendee_s_Missing_Placebo_info_Count__c = valPlaceboInfoMissing;
        EMEvent.MSD_CORE_Requester_Count__c = valRequesters;
        EMEvent.MSD_CORE_Attendee_No_Address_Email_Count__c = valAddressEmailMissing;
    }
update EventToUpdate;
}