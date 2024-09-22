trigger MSD_CORE_ListSalesTeamTriggerHandler on MSD_CORE_List_Sales_Team__c (after delete, after insert, after update, before delete, before insert, before update) {
    MSD_CORE_TriggerFactory.process(MSD_CORE_List_Sales_Team__c.sObjectType);
}