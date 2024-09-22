/*
 *  EventMVN
 *  Created By:     Roman Lerman
 *  Created Date:   4/8/2013
 *  Description:    This is a generic Event trigger used for calling any Case logic
 */
trigger EventMVN on Event (before delete, before insert, before update, after insert) {
	String parentIdFieldName = 'WhatId';
	String objectName = 'Case';
	String lockedFieldName = 'IsClosed';
	String parentKeyPrefix = Schema.SobjectType.Case.getKeyPrefix();
	String error = Label.Cannot_Modify_Record_on_Closed_Case;
	
	new TriggersMVN()
		.bind(TriggersMVN.Evt.beforeinsert, new LockRelatedRecordsMVN(parentIdFieldName, objectName, lockedFieldName, parentKeyPrefix, error))
        .bind(TriggersMVN.Evt.beforeupdate, new LockRelatedRecordsMVN(parentIdFieldName, objectName, lockedFieldName, parentKeyPrefix, error))
        .bind(TriggersMVN.Evt.beforedelete, new LockRelatedRecordsMVN(parentIdFieldName, objectName, lockedFieldName, parentKeyPrefix, error))
        .bind(TriggersMVN.Evt.afterinsert, new MSD_CORE_CreateCaseChatPDFFromEventDesc())
        .manage();
}