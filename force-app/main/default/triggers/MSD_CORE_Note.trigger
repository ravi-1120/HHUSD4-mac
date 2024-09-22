/*
 *  MSD_CORE_Note
 *  Created By:     Samuel Rosen
 *  Created Date:   5/18/2015
 *  Description:    This is a generic MSD_CORE_Note trigger used for calling any MSD_CORE_Note__c logic
 */
trigger MSD_CORE_Note on MSD_CORE_Note__c (before update, before delete, after delete) {

    new TriggersMVN()
        .bind(TriggersMVN.Evt.beforeupdate, new LockRelatedRecordsMVN('MSD_CORE_Case__c', 'Case', 'IsClosed', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforeupdate, new LockRelatedRecordsMVN('MSD_CORE_Case__c', 'Case', 'MSD_CORE_Is_Submitted__c', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforeupdate, new LockRelatedRecordsMVN('MSD_CORE_Case__c', 'Case', 'MSD_CORE_Case_Was_Closed__c', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_edit_Note_on_a_previously_Closed_Case))
        .bind(TriggersMVN.Evt.beforedelete, new LockRelatedRecordsMVN('MSD_CORE_Case__c', 'Case', 'IsClosed', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforedelete, new LockRelatedRecordsMVN('MSD_CORE_Case__c', 'Case', 'MSD_CORE_Is_Submitted__c', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforedelete, new LockRelatedRecordsMVN('MSD_CORE_Case__c', 'Case', 'MSD_CORE_Case_Was_Closed__c', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_edit_Note_on_a_previously_Closed_Case))
        .bind(TriggersMVN.Evt.afterdelete, new MSD_CORE_DeleteTrackingTrigger()) 
        .manage();
        
}