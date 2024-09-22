public without sharing class VeevaCustomerJourneyTriggerHandler extends VeevaTriggerHandler {
    private List<Customer_Journey_vod__c> newCustomerJourneys = new List<Customer_Journey_vod__c>();
    private List<Customer_Journey_vod__c> oldCustomerJourneys = new List<Customer_Journey_vod__c>();
    private Map<Id, Customer_Journey_vod__c> newCustomerJourneysMap = new Map<Id, Customer_Journey_vod__c>();
    private Map<Id, Customer_Journey_vod__c> olderCustomerJourneysMap = new Map<Id, Customer_Journey_vod__c>();

    @TestVisible
    protected override void preTrigger(List<SObject> triggerNew, List<SObject>  triggerOld, Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        this.newCustomerJourneys = (List<Customer_Journey_vod__c>) triggerNew;
        this.oldCustomerJourneys = (List<Customer_Journey_vod__c>) triggerOld;
        this.newCustomerJourneysMap = (Map<Id, Customer_Journey_vod__c>) triggerNewMap;
        this.olderCustomerJourneysMap = (Map<Id, Customer_Journey_vod__c>) triggerOldMap;

    }

    protected override String sObjectType() {
        return 'Customer_Journey_vod__c';
    }

    @TestVisible
    protected override void beforeInsert() {
        handleBeforeInsUpd(false, this.newCustomerJourneys, this.oldCustomerJourneys);
    }

    @TestVisible
    protected override void beforeUpdate() {
        handleBeforeInsUpd(true, this.newCustomerJourneys, this.oldCustomerJourneys);
    }

    private void handleBeforeInsUpd(boolean isUpdate,  List<Customer_Journey_vod__c> newCustomerJourneys,  List<Customer_Journey_vod__c> oldCustomerJourneys) {
        VeevaCountryHelper.updateCountryFields(Customer_Journey_vod__c.getSObjectType(), Customer_Journey_vod__c.OwnerId, null, isUpdate, newCustomerJourneys, oldCustomerJourneys);
    }


}