/*
 *  MSD_CORE_DeliveryTrackingNumber
 *  Created By:     Samuel Rosen
 *  Created Date:   5/18/2015
 *  Description:    This is a generic MSD_CORE_Delivery_Tracking_Number__c trigger used for calling any DeliveryTrackingNumber logic
 */
trigger MSD_CORE_DeliveryTrackingNumber on MSD_CORE_Delivery_Tracking_Number__c (before insert, before update, before delete, after delete) {
    new TriggersMVN()
        .bind(TriggersMVN.Evt.beforeinsert, new LockRelatedRecordsMVN('MSD_CORE_Case__c', 'Case', 'IsClosed', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforeinsert, new LockRelatedRecordsMVN('MSD_CORE_Case__c', 'Case', 'MSD_CORE_Is_Submitted__c', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforeupdate, new LockRelatedRecordsMVN('MSD_CORE_Case__c', 'Case', 'IsClosed', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforeupdate, new LockRelatedRecordsMVN('MSD_CORE_Case__c', 'Case', 'MSD_CORE_Is_Submitted__c', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforedelete, new LockRelatedRecordsMVN('MSD_CORE_Case__c', 'Case', 'IsClosed', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.beforedelete, new LockRelatedRecordsMVN('MSD_CORE_Case__c', 'Case', 'MSD_CORE_Is_Submitted__c', Schema.SobjectType.Case.getKeyPrefix(), Label.Cannot_Modify_Record_on_Closed_Case))
        .bind(TriggersMVN.Evt.afterdelete, new MSD_CORE_RollupRelatedListTrigger('MSD_CORE_PQC_Delivery_Tracking_Numbers__c', 'MSD_CORE_Case__c'))
        .bind(TriggersMVN.Evt.afterdelete, new MSD_CORE_DeleteTrackingTrigger()) 
        .manage();
}