/*
 *  CaseDocumentMVN
 *  Created By:     Roman Lerman
 *  Created Date:   4/18/2013
 *  Description:    This is a generic Case Document trigger used for calling any Case Document logic
 */
trigger CaseDocumentMVN on Case_Document_MVN__c (before insert, after insert, before update, before delete, after delete) {
    new TriggersMVN()
		.bind(TriggersMVN.Evt.beforeinsert, new CaseArticleCopyTriggerMVN())
        .bind(TriggersMVN.Evt.beforeinsert, new LockRelatedRecordsMVN('Case_MVN__c', 'Case', 'IsClosed', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforeinsert, new LockRelatedRecordsMVN('Case_MVN__c', 'Case', 'MSD_CORE_Is_Submitted__c', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.afterinsert, new MSD_CORE_CaseDocumentAddNoteTrigger())
        .bind(TriggersMVN.Evt.beforeupdate, new LockRelatedRecordsMVN('Case_MVN__c', 'Case', 'IsClosed', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforeupdate, new LockRelatedRecordsMVN('Case_MVN__c', 'Case', 'MSD_CORE_Is_Submitted__c', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforedelete, new LockRelatedRecordsMVN('Case_MVN__c', 'Case', 'IsClosed', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforedelete, new LockRelatedRecordsMVN('Case_MVN__c', 'Case', 'MSD_CORE_Is_Submitted__c', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforedelete, new CaseArticleDeleteTriggerMVN())
        .bind(TriggersMVN.Evt.afterdelete, new MSD_CORE_RollupRelatedListTrigger('MSD_CORE_Case_Document_Title__c', 'Case_MVN__c'))
        .bind(TriggersMVN.Evt.afterdelete, new MSD_CORE_RollupRelatedListTrigger('MSD_CORE_Related_Articles__c', 'Case_MVN__c'))
        .bind(TriggersMVN.Evt.afterdelete, new MSD_CORE_DeleteTrackingTrigger()) 
        .manage();
}