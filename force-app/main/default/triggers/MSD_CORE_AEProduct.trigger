/*
 *  MSD_CORE_AEProduct
 *  Created By:     Samuel Rosen
 *  Created Date:   5/18/2015
 *  Description:    This is a generic MSD_CORE_AEProduct trigger used for calling any AE Product logic
 */
trigger MSD_CORE_AEProduct on MSD_CORE_AE_Product__c (before insert, before update, before delete, after delete, after insert, after update) {
    new TriggersMVN()
        .bind(TriggersMVN.Evt.beforeinsert, new LockRelatedRecordsMVN('MSD_CORE_Adverse_Event__c', 'Case', 'IsClosed', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforeinsert, new LockRelatedRecordsMVN('MSD_CORE_Adverse_Event__c', 'Case', 'MSD_CORE_Is_Submitted__c', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforeupdate, new LockRelatedRecordsMVN('MSD_CORE_Adverse_Event__c', 'Case', 'IsClosed', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforeupdate, new LockRelatedRecordsMVN('MSD_CORE_Adverse_Event__c', 'Case', 'MSD_CORE_Is_Submitted__c', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforedelete, new LockRelatedRecordsMVN('MSD_CORE_Adverse_Event__c', 'Case', 'IsClosed', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforedelete, new LockRelatedRecordsMVN('MSD_CORE_Adverse_Event__c', 'Case', 'MSD_CORE_Is_Submitted__c', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.afterdelete, new MSD_CORE_RollupRelatedListTrigger('MSD_CORE_PQC_Lot_Numbers__c', 'MSD_CORE_Adverse_Event__c'))
        .bind(TriggersMVN.Evt.afterdelete, new MSD_CORE_RollupRelatedListTrigger('MSD_CORE_Product_Name__c', 'MSD_CORE_Adverse_Event__c'))
        .bind(TriggersMVN.Evt.afterdelete, new MSD_CORE_DeleteTrackingTrigger()) 
        .manage();
        
        if(trigger.isAfter && trigger.isDelete == false)
            MSD_CORE_RollupRelatedListTrigger.updateCaseLotNumber(trigger.new);
}