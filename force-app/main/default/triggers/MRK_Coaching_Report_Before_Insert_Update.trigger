/*
   BMP - 8/1/2013

	 * automatically sets the manager as record creator
   * enforces validation rules
*/
trigger MRK_Coaching_Report_Before_Insert_Update on Coaching_Report_vod__c (before insert, before update) {

  for (Integer i = 0; i < Trigger.new.size(); i++) {
    MRK_CoachingReportServices.getInstance().beforeInsertUpdateTriggerHandler(Trigger.new[i]);
  }

}