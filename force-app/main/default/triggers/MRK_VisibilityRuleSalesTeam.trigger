trigger MRK_VisibilityRuleSalesTeam on Visibility_Rule_Sales_Team_MRK__c (after delete, after insert, after update, before delete, before insert, before update) {
   MSD_CORE_VE_Trigger_Factory.process(Visibility_Rule_Sales_Team_MRK__c.sObjectType);
}