/* Company       : Merck Co.
* Date          : 04/03/2022   
* Author        : Koushik Majumder
* Description   : trigger to create and update event speaker from GWET
* History       : First version
* History       : CEF2F-14304
*/

trigger MSD_CORE_Create_Event_Speaker on MSD_Event_Speaker_GWET__e (after insert) {
    Set<Id> relatedEventSet = new Set<Id>();
    map<id,EM_Event_Speaker_vod__c> spkrIdWithSpkr = new map<id,EM_Event_Speaker_vod__c>();
    map<String,id> spkrIdWithExternalId = new map<String,id>();
    
    Id recTypeId = [Select Id from RecordType Where sObjectType = 'EM_Event_Speaker_vod__c' and DeveloperName = 'MSD_CORE_Event_Speaker'].Id;
    List<EM_Event_Speaker_vod__c> toUpdateList = new List<EM_Event_Speaker_vod__c>();
    
    for(MSD_Event_Speaker_GWET__e event : Trigger.New){
        relatedEventSet.add(event.Event_Id__c);
    }
    
    for(EM_Event_Speaker_vod__c each:[SELECT id,MSD_CORE_MSD_External_Id__c FROM EM_Event_Speaker_vod__c WHERE Event_vod__c IN: relatedEventSet]){
        spkrIdWithSpkr.put(each.Id, each);
        spkrIdWithExternalId.put(each.MSD_CORE_MSD_External_Id__c,each.Id);
    }
    
    for(MSD_Event_Speaker_GWET__e event : Trigger.New){
        if(!event.Is_Response__c){
            if(event.Speaker_VVA_ID__c != NULL){
                EM_Event_Speaker_vod__c toUpdateRec = spkrIdWithSpkr.get(event.Speaker_VVA_ID__c);
                
                toUpdateRec.MSD_CORE_Attended_Live__c = event.Attended_Live__c;
                toUpdateRec.MSD_CORE_Attended_Replay__c = event.Attended_Replay__c;
                toUpdateRec.MSD_CORE_Join_Time__c = event.Join_Time__c;
                toUpdateRec.MSD_CORE_Leave_Time__c = event.Leave_Time__c;
                toUpdateRec.MSD_CORE_Call_Duration__c = event.Call_Duration__c;
                toUpdateList.add(toUpdateRec);
            }
            
            if(spkrIdWithExternalId.keyset().contains(event.JzeroId__c)){
                Id temp = spkrIdWithExternalId.get(event.JzeroId__c);
                EM_Event_Speaker_vod__c toUpdateRec = spkrIdWithSpkr.get(temp);
                
                toUpdateRec.MSD_CORE_Attended_Live__c = event.Attended_Live__c;
                toUpdateRec.MSD_CORE_Attended_Replay__c = event.Attended_Replay__c;
                toUpdateRec.MSD_CORE_Join_Time__c = event.Join_Time__c;
                toUpdateRec.MSD_CORE_Leave_Time__c = event.Leave_Time__c;
                toUpdateRec.MSD_CORE_Call_Duration__c = event.Call_Duration__c;
                toUpdateList.add(toUpdateRec);
            }
        }
    }
    
    if(toUpdateList.size()>0){
        try{      
            database.saveresult[] ds =  Database.update(toUpdateList,false);
            for(database.SaveResult d : ds){
                if(d.issuccess()){
                    System.debug('Successfully inserted record: ' + d.getId());
                }                   
            }
        }
        catch(exception e){
            system.debug('update failed');
        }
    }
}