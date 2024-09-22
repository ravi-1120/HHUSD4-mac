public with sharing class VeevaAccountTriggerHandler extends VeevaTriggerHandler {

    private List<Account> newAccounts = new List<Account>();
    private List<Account> oldAccounts = new List<Account>();
    private Map<ID, Account> newAccountsMap = new Map<ID, Account>();
    private Map<ID, Account> oldAccountsMap = new Map<ID, Account>();
    VOD_ERROR_MSG_BUNDLE bundle;

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newAccounts = (List<Account>) triggerNew;
        this.oldAccounts = (List<Account>) triggerOld;
        this.newAccountsMap = (Map<ID, Account>) triggerNewMap;
        this.oldAccountsMap = (Map<ID, Account>) triggerOldMap;
        this.bundle = new VOD_ERROR_MSG_BUNDLE();
    }

    protected override String sObjectType() {
        return 'Account';
    }

    protected override void beforeInsert() {
        VeevaAccountTriggerActions.newAcccountTerritoryCleanup(newAccounts);
        VeevaAccountTriggerActions.newAccountRestrictedProductCleanup(newAccounts);
        VeevaCountryHelper.updateCountryFields(Account.getSObjectType(), Account.OwnerId, null, false, newAccounts, oldAccounts);
    }
    
    protected override void beforeUpdate() {
        VeevaAccountTriggerActions.newAcccountTerritoryCleanup(newAccounts);
        VeevaCountryHelper.updateCountryFields(Account.getSObjectType(), Account.OwnerId, null, true, newAccounts, oldAccounts);
    }
    
    protected override void beforeDelete() {
        VeevaAccountTriggerActions.createSetDeleteMap(oldAccounts);
    }
    
    protected override void afterInsert() {
        VeevaAccountTriggerActions.accountInsertCreateChildren(newAccounts);
    }
    
    protected override void afterUpdate() {
        VeevaAccountTriggerActions.accountUpdateRecordTypeChanges(oldAccounts, newAccounts);
        VeevaAccountTriggerActions.accountUpdatePrimaryParentChanges(oldAccounts, newAccounts);
        VeevaAccountWeChatTriggerActions.accountWeChatUpdate(oldAccounts, newAccounts);
    }

    protected override void afterDelete() {
        VeevaAccountTriggerActions.accountMergeProcessing(bundle, oldAccountsMap);
        VeevaAccountTriggerActions.accountMergeHistoryCreation(oldAccounts);
    }
}