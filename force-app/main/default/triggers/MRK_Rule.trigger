trigger MRK_Rule on Rule_MRK__c (after delete, after insert, after update, before delete, before insert, before update) {
    MRK_TriggerFactory.process(Rule_MRK__c.sObjectType);
}