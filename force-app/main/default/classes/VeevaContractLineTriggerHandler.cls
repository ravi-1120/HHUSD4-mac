public without sharing class VeevaContractLineTriggerHandler extends VeevaTriggerHandler{
    private List<Contract_Line_vod__c> newContractLines;
    private List<Contract_Line_vod__c> oldContractLines;
    private Map<ID, Contract_Line_vod__c> newContractLinesMap;
    private Map<ID, Contract_Line_vod__c> oldContractLinesMap;
    private VeevaContractLineBeforeHdl contractLineBeforeHdl;
    private VeevaContractLineAfterInsUpdHdl contractLineAfterInsUpdHdl;

    protected override boolean doRecursionCheck() {
        return true;
    }

    protected override String sObjectType() {
        return 'Contract_Line_vod__c';
    }

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        newContractLines = (List<Contract_Line_vod__c>) triggerNew;
        oldContractLines = (List<Contract_Line_vod__c>) triggerOld;
        newContractLinesMap = (Map<ID, Contract_Line_vod__c>) triggerNewMap;
        oldContractLinesMap = (Map<ID, Contract_Line_vod__c>) triggerOldMap;

        // BeforeHandler
        contractLineBeforeHdl = new VeevaContractLineBeforeHdl(newContractLines, oldContractLines, newContractLinesMap, oldContractLinesMap);
        // AfterInsertUpdateHandler
        contractLineAfterInsUpdHdl = new VeevaContractLineAfterInsUpdHdl(newContractLines, oldContractLines, newContractLinesMap, oldContractLinesMap);
    }

    protected override void beforeInsert() {
        contractLineBeforeHdl.contractLineBeforeInsertUpdateDelete();
    }

    protected override void beforeUpdate() {
        contractLineBeforeHdl.contractLineBeforeInsertUpdateDelete();
    }

    protected override void beforeDelete() {
        contractLineBeforeHdl.contractLineBeforeDelete();
    }

    protected override void afterInsert() {
        contractLineAfterInsUpdHdl.contractLineAfterInsertUpdate();
    }
    protected override void afterUpdate() {
        contractLineAfterInsUpdHdl.contractLineAfterInsertUpdate();
    }
}