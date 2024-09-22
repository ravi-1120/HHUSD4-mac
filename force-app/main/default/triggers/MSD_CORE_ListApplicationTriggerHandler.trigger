trigger MSD_CORE_ListApplicationTriggerHandler on MSD_CORE_List_Application__c (after delete, after insert, after update, before delete, before insert, before update) {
    MSD_CORE_TriggerFactory.process(MSD_CORE_List_Application__c.sObjectType);
}