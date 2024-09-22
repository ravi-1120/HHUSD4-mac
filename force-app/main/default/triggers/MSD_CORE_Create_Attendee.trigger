trigger MSD_CORE_Create_Attendee on MSD_Event_Attendee_GWET__e (after insert) {
    
    Set<Id> relatedEventSet = new Set<Id>();
    map<id,EM_Attendee_vod__c> attIdWithAttendee = new map<id,EM_Attendee_vod__c>();
    map<String,id> attIdWithExternalId = new map<String,id>();
   // Id recTypeId = Schema.SObjectType.EM_Attendee_vod__c.getRecordTypeInfosByName().get('EM Attendee').getRecordTypeId();
   
    Id recTypeId = [Select Id from RecordType Where sObjectType = 'EM_Attendee_vod__c' and DeveloperName = 'Attendee_vod'].Id;
    List<EM_Attendee_vod__c> toInsertList = new List<EM_Attendee_vod__c>();
    List<EM_Attendee_vod__c> toUpdateList = new List<EM_Attendee_vod__c>();
    
    for(MSD_Event_Attendee_GWET__e event : Trigger.New){
        relatedEventSet.add(event.Event_Id__c);
    }
    
    for(EM_Attendee_vod__c each:[SELECT id,MSD_CORE_MSD_External_Id__c FROM EM_Attendee_vod__c WHERE Event_vod__c IN: relatedEventSet]){
        attIdWithAttendee.put(each.Id, each);
        attIdWithExternalId.put(each.MSD_CORE_MSD_External_Id__c,each.Id);
    }

    for(MSD_Event_Attendee_GWET__e event : Trigger.New){
        if(!event.Is_Response__c){
            if(event.Attendee_VVA_ID__c!=NULL){
                EM_Attendee_vod__c toUpdateRec = attIdWithAttendee.get(event.Attendee_VVA_ID__c);
                
                //toUpdateRec.Email_vod__c = event.Email_Address__c;
                //toUpdateRec.Event_vod__c = event.Event_Id__c;
                //toUpdateRec.First_Name_vod__c = event.First_Name__c;
                //toUpdateRec.Last_Name_vod__c = event.Last_Name__c;
                toUpdateRec.MSD_CORE_Attended_Live__c = event.Attended_Live__c;
                toUpdateRec.MSD_CORE_Attended_Replay__c = event.Attended_Replay__c;
                //toUpdateRec.MSD_CORE_MCID__c = event.MCID__c;
                //toUpdateRec.MSD_CORE_MDM_ID_GWET__c = event.MDM__c;
                toUpdateRec.MSD_CORE_On24_Engagement_Link__c = event.On24_Engagement_Link__c;
                //toUpdateRec.Organization_vod__c = event.Business__c;
                //toUpdateRec.MSD_CORE_Source_System__c = 'GWET';
                //toUpdateRec.MSD_CORE_Specialty__c = event.Specialty__c;
                //toUpdateRec.MSD_Core_Virtual_Attendee__c = true;
                toUpdateRec.RecordTypeId = recTypeId;
                toUpdateRec.Status_vod__c = 'Attended_vod';
                //toUpdateRec.Walk_In_Status_vod__c = 'Needs_Reconciliation_vod';
                toUpdateRec.MSD_CORE_Join_Time__c = event.MSD_CORE_Join_Time__c;
                toUpdateRec.MSD_CORE_Leave_Time__c = event.MSD_CORE_Leave_Time__c;
                toUpdateRec.MSD_CORE_Call_Duration__c = event.MSD_CORE_Call_Duration__c;
                            
                toUpdateList.add(toUpdateRec);
                
                } 
                else if(attIdWithExternalId.keyset().contains(event.JzeroId__c)){
                Id temp = attIdWithExternalId.get(event.JzeroId__c);
                EM_Attendee_vod__c toUpdateRec = attIdWithAttendee.get(temp);
                
                /* toUpdateRec.Email_vod__c = event.Email_Address__c;
                toUpdateRec.Event_vod__c = event.Event_Id__c;
                toUpdateRec.First_Name_vod__c = event.First_Name__c;
                toUpdateRec.Last_Name_vod__c = event.Last_Name__c;                
                toUpdateRec.MSD_CORE_MCID__c = event.MCID__c;
                toUpdateRec.MSD_CORE_MDM_ID_GWET__c = event.MDM__c;
                toUpdateRec.MSD_CORE_On24_Engagement_Link__c = event.On24_Engagement_Link__c;
                toUpdateRec.Organization_vod__c = event.Business__c;
                toUpdateRec.MSD_CORE_Source_System__c = 'GWET';
                toUpdateRec.MSD_CORE_Specialty__c = event.Specialty__c;
                toUpdateRec.MSD_Core_Virtual_Attendee__c = true;
                toUpdateRec.RecordTypeId = recTypeId;
                toUpdateRec.Status_vod__c = 'Attended_vod';
                toUpdateRec.Walk_In_Status_vod__c = 'Needs_Reconciliation_vod'; */
                toUpdateRec.MSD_CORE_Attended_Live__c = event.Attended_Live__c;
                toUpdateRec.MSD_CORE_Attended_Replay__c = event.Attended_Replay__c;
                toUpdateRec.MSD_CORE_Join_Time__c = event.MSD_CORE_Join_Time__c;
                toUpdateRec.MSD_CORE_Leave_Time__c = event.MSD_CORE_Leave_Time__c;
                toUpdateRec.MSD_CORE_Call_Duration__c = event.MSD_CORE_Call_Duration__c;
                
                toUpdateList.add(toUpdateRec);
                
            }else{
                EM_Attendee_vod__c toInsertRec = new EM_Attendee_vod__c();
                
                toInsertRec.MSD_CORE_MSD_External_Id__c = event.JzeroId__c;
                toInsertRec.Email_vod__c = event.Email_Address__c;
                toInsertRec.Event_vod__c = event.Event_Id__c;
                toInsertRec.First_Name_vod__c = event.First_Name__c;
                toInsertRec.Last_Name_vod__c = event.Last_Name__c;
                toInsertRec.MSD_CORE_Attended_Live__c = event.Attended_Live__c;
                toInsertRec.MSD_CORE_Attended_Replay__c = event.Attended_Replay__c;
                //toInsertRec.MSD_CORE_MCID__c = event.MCID__c;
                //toInsertRec.MSD_CORE_MDM_ID_GWET__c = event.MDM__c;
                toInsertRec.MSD_CORE_On24_Engagement_Link__c = event.On24_Engagement_Link__c;
                toInsertRec.Organization_vod__c = event.Business__c;
                //toInsertRec.MSD_CORE_Source_System__c = 'GWET';
                //toInsertRec.MSD_CORE_Specialty__c = event.Specialty__c;
                //toInsertRec.MSD_Core_Virtual_Attendee__c = true;
                toInsertRec.RecordTypeId = recTypeId;
                toInsertRec.Status_vod__c = 'Attended_vod';
                toInsertRec.Walk_In_Status_vod__c = 'Needs_Reconciliation_vod';
                toInsertRec.MSD_CORE_Join_Time__c = event.MSD_CORE_Join_Time__c;
                toInsertRec.MSD_CORE_Leave_Time__c = event.MSD_CORE_Leave_Time__c;
                toInsertRec.MSD_CORE_Call_Duration__c = event.MSD_CORE_Call_Duration__c;
                
                toInsertList.add(toInsertRec);
            }
        }
    }
    
    /* if(toUpdateList.size()>0){
        update toUpdateList;
    }
    
    if(toInsertList.size()>0){
        insert toInsertList;
    } */
    
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
    
    if(toInsertList.size()>0){
        try{      
            database.saveresult[] ds =  Database.insert(toInsertList,false);
            for(database.SaveResult d : ds){
                if(d.issuccess()){
                    System.debug('Successfully updated record: ' + d.getId());
                }                   
            }
        }
        catch(exception e){
            system.debug('insert failed');
        }
    }
}