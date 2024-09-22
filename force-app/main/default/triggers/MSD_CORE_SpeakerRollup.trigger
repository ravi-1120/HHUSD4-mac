/*
 * Trigger: MSD_CORE_SpeakerRollup
 * Description: Updated Speaker count, Attended Speaker count and No Show Speaker Count on Event record when there is an insert/update/delete happens.
 * Author: Kalyan Vuppalapati
 * Change: Updated the Attended / No Show Speaker Count as part of Sprint 1
*/

trigger MSD_CORE_SpeakerRollup on EM_Event_Speaker_vod__c (after delete, after insert, after update) {
Set<id> EventIds = new Set<id>();
    List<EM_Event_vod__c> EventToUpdate = new List<EM_Event_vod__c>();
if (Trigger.isInsert) {
for (EM_Event_Speaker_vod__c item : Trigger.new)
        EventIds.add(item.Event_vod__c);
    }        
if (Trigger.isUpdate || Trigger.isDelete) {
        for (EM_Event_Speaker_vod__c item : Trigger.old)
            EventIds.add(item.Event_vod__c);
    }

   if(EventIds.size() > 0){
        EventToUpdate = [select Id, Name, MSD_CORE_Speaker_Count__c,(select id,status_vod__C from EM_Event_Speaker_vod__r) from EM_Event_vod__c where Id IN :EventIds];
    }
    for(EM_Event_vod__c EMEvent : EventToUpdate){
        integer valAll = 0;
        integer valAttnd = 0;
        integer valNoShow = 0;
        for(EM_Event_Speaker_vod__c SPK : EMEvent.EM_Event_Speaker_vod__r){

        valAll += 1;
        
         if (SPK.Status_vod__c == 'Attended_vod') { valAttnd += 1;}    
         
         if (SPK.Status_vod__c == 'MSD_CORE_No_Show') { valNoShow += 1;}    
         
        }

        EMEvent.MSD_CORE_Speaker_Count__c = valAll;
        EMEvent.MSD_CORE_Attended_Speaker_Count__c = valAttnd;
        EMEvent.MSD_CORE_No_Show_Speaker_Count__c = valNoShow;

    }
update EventToUpdate;
}