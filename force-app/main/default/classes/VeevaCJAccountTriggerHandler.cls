public without sharing class VeevaCJAccountTriggerHandler extends VeevaTriggerHandler {
    private List<Customer_Journey_Account_vod__c> newCustomerJourneyAccounts = new List<Customer_Journey_Account_vod__c>();
    private List<Customer_Journey_Account_vod__c> oldCustomerJourneyAccounts = new List<Customer_Journey_Account_vod__c>();
    private Map<Id, Customer_Journey_Account_vod__c> newCustomerJourneyAccountsMap = new Map<Id, Customer_Journey_Account_vod__c>();
    private Map<Id, Customer_Journey_Account_vod__c> oldCustomerJourneyAccountsMap = new Map<Id, Customer_Journey_Account_vod__c>();

    protected override void preTrigger(List<SObject> triggerNew, List<SObject>  triggerOld, Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        this.newCustomerJourneyAccounts = (List<Customer_Journey_Account_vod__c>) triggerNew;
        this.oldCustomerJourneyAccounts = (List<Customer_Journey_Account_vod__c>) triggerOld;
        this.newCustomerJourneyAccountsMap = (Map<Id, Customer_Journey_Account_vod__c>) triggerNewMap;
        this.oldCustomerJourneyAccountsMap = (Map<Id, Customer_Journey_Account_vod__c>) triggerOldMap;

    }

    protected override String sObjectType() {
        return 'Customer_Journey_Account_vod__c';
    }

    protected override void beforeInsert() {
        handleBeforeInsUpd();
    }

    protected override void beforeUpdate() {
        handleBeforeInsUpd();
    }

    private void handleBeforeInsUpd() {

        final String CUSTOMER_JOURNEY_ACCOUNT_REQUIRED = VOD_GET_ERROR_MSG.getErrorMsg('CUSTOMER_JOURNEY_ACCOUNT_REQUIRED', 'JOURNEYS');

        for (Customer_Journey_Account_vod__c customerJourneyAccount: this.newCustomerJourneyAccounts) {
            if (String.isBlank(customerJourneyAccount.Account_vod__c)) {
                customerJourneyAccount.addError(CUSTOMER_JOURNEY_ACCOUNT_REQUIRED);
            } else {
                customerJourneyAccount.VExternal_ID_vod__c = String.valueof(customerJourneyAccount.Customer_Journey_vod__c) + String.valueof(customerJourneyAccount.Account_vod__c);
            }
        }
    }
}