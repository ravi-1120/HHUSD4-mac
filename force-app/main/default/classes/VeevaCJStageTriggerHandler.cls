public without sharing class VeevaCJStageTriggerHandler extends VeevaTriggerHandler {
    private List<Customer_Journey_Stage_vod__c> newCustomerJourneyStages = new List<Customer_Journey_Stage_vod__c>();
    private List<Customer_Journey_Stage_vod__c> oldCustomerJourneyStages = new List<Customer_Journey_Stage_vod__c>();
    private Map<Id, Customer_Journey_Stage_vod__c> newCustomerJourneyStagesMap = new Map<Id, Customer_Journey_Stage_vod__c>();
    private Map<Id, Customer_Journey_Stage_vod__c> oldCustomerJourneyStagesMap = new Map<Id, Customer_Journey_Stage_vod__c>();

    protected override void preTrigger(List<SObject> triggerNew, List<SObject>  triggerOld, Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        this.newCustomerJourneyStages = (List<Customer_Journey_Stage_vod__c>) triggerNew;
        this.oldCustomerJourneyStages = (List<Customer_Journey_Stage_vod__c>) triggerOld;
        this.newCustomerJourneyStagesMap = (Map<Id, Customer_Journey_Stage_vod__c>) triggerNewMap;
        this.oldCustomerJourneyStagesMap = (Map<Id, Customer_Journey_Stage_vod__c>) triggerOldMap;
    }

    protected override String sObjectType() {
        return 'Customer_Journey_Stage_vod__c';
    }

    protected override void beforeInsert() {
        handleBeforeInsUpd();
    }

    protected override void beforeUpdate() {
        handleBeforeInsUpd();
    }

    private void handleBeforeInsUpd() {

        final String CUSTOMER_JOURNEY_STAGE_REQUIRED = VOD_GET_ERROR_MSG.getErrorMsg('CUSTOMER_JOURNEY_STAGE_REQUIRED', 'JOURNEYS');

        for (Customer_Journey_Stage_vod__c customerJourneyStage: this.newCustomerJourneyStages) {
            if (String.isBlank(customerJourneyStage.Stage_vod__c)) {
                customerJourneyStage.addError(CUSTOMER_JOURNEY_STAGE_REQUIRED);
            } else {
                customerJourneyStage.VExternal_ID_vod__c = String.valueof(customerJourneyStage.Customer_Journey_vod__c) + String.valueof(customerJourneyStage.Stage_vod__c);
            }
        }
    }

}