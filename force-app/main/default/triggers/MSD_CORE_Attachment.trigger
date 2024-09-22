/*
 *  MSD_CORE_Attachment
 *  Created By:     Samuel Rosen
 *  Created Date:   5/18/2015
 *  Description:    This is a generic MSD_CORE_Attachment trigger used for calling any Attachment logic
 */
trigger MSD_CORE_Attachment on Attachment (before insert, after insert, before update,  before delete, after delete) {
    new TriggersMVN()
        .bind(TriggersMVN.Evt.afterinsert, new MSD_CORE_AddNoteToAEPQCTrigger())
        .bind(TriggersMVN.Evt.afterinsert, new MSD_CORE_UpdateAttachmentIdOnCaseTrigger())
        .bind(TriggersMVN.Evt.beforeupdate, new LockRelatedRecordsMVN('ParentId', 'Case', 'IsClosed', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforeupdate, new LockRelatedRecordsMVN('ParentId', 'Case', 'MSD_CORE_Is_Submitted__c', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforedelete, new LockRelatedRecordsMVN('ParentId', 'Case', 'IsClosed', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforedelete, new LockRelatedRecordsMVN('ParentId', 'Case', 'MSD_CORE_Is_Submitted__c', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.afterdelete, new MSD_CORE_UpdateAttachmentIdOnCaseTrigger())   
        .bind(TriggersMVN.Evt.afterdelete, new MSD_CORE_DeleteTrackingTrigger())  
        .manage();

        
}