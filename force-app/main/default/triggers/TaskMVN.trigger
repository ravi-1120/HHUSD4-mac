/*
 *  TaskMVN
 *  Created By:     Roman Lerman
 *  Created Date:   4/8/2013
 *  Description:    This is a generic Task trigger used for calling any Task logic
 */
trigger TaskMVN on Task (before delete, before insert, before update, after delete) {
  String parentIdFieldName = 'WhatId';
  String objectName = 'Case';
  String lockedFieldName = 'IsClosed';
  String parentKeyPrefix = Schema.SobjectType.Case.getKeyPrefix();
  String error = Label.MSD_CORE_Cannot_Delete_Tasks;
  
  new TriggersMVN()
        .bind(TriggersMVN.Evt.beforedelete, new LockRelatedRecordsMVN(Label.MSD_CORE_Cannot_Delete_Tasks))
        .manage();
}