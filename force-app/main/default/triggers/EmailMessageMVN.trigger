/*
 *  EmailMessageMVN
 *  Created By:     Roman Lerman
 *  Created Date:   6/24/2013
 *  Description:    This is a generic EmailMessage trigger used for calling any EmailMessage logic
 *  Change Log:
 *  Updated Date: 8/19/2021
 *  Updated By : VKB
 *  Description:Created a new method class on after insert
 * 				MSD_CORE_FollowupEmail
 */
trigger EmailMessageMVN on EmailMessage (before insert, after insert, before update, before delete) {
	String parentId = 'ParentId';
	String objectName = 'Case';
	String lockedFieldName = 'IsClosed';
	String parentKeyPrefix = Schema.SobjectType.Case.getKeyPrefix();
	String error = Label.Cannot_Modify_Record_on_Closed_Case;

	new TriggersMVN()
        .bind(TriggersMVN.Evt.afterinsert, new MSD_CORE_UpdateInteractionSourceTrigger())
        .bind(TriggersMVN.Evt.afterinsert, new MSD_CORE_FollowupEmail())
        .bind(TriggersMVN.Evt.afterinsert, new MSD_CORE_EmailMessageAsAtt())
        .bind(TriggersMVN.Evt.afterinsert, new MSD_Core_CaseWitEmailTemp_Usage_Report())
        .bind(TriggersMVN.Evt.beforeupdate, new LockRelatedRecordsMVN(parentId, objectName, lockedFieldName, parentKeyPrefix, error))
        .bind(TriggersMVN.Evt.beforedelete, new LockRelatedRecordsMVN(Label.MSD_CORE_Cannot_Delete_Email_Messages))
        .manage();
}