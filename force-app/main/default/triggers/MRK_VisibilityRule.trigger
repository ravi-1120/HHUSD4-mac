trigger MRK_VisibilityRule on Visibility_Rule_MRK__c (after delete, after insert, after update, before delete, before insert, before update) {
   MSD_CORE_VE_Trigger_Factory.process(Visibility_Rule_MRK__c.sObjectType);
}