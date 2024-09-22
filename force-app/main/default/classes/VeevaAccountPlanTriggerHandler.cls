public without sharing class VeevaAccountPlanTriggerHandler extends VeevaTriggerHandler {

    private List<Account_Plan_vod__c> newAccountPlans;
    private List<Account_Plan_vod__c> oldAccountPlans;
    private Map<ID, Account_Plan_vod__c> newAccountPlansMap;
    private Map<ID, Account_Plan_vod__c> oldAccountPlansMap;

        
    protected override String sObjectType() {
        return 'Account_Plan_vod__c ';
    }

    protected override void preTrigger(
        List<SObject> triggerNew,
        List<SObject> triggerOld,
        Map<ID, SObject> triggerNewMap,
        Map<ID, SObject> triggerOldMap
    ) {
        newAccountPlans = (List<Account_Plan_vod__c>) triggerNew;
        oldAccountPlans = (List<Account_Plan_vod__c>) triggerOld;
        newAccountPlansMap = (Map<ID, Account_Plan_vod__c>) triggerNewMap;
        oldAccountPlansMap = (Map<ID, Account_Plan_vod__c>) triggerOldMap;
    }

    protected override void beforeInsert() {
        validateAccountPlans();
    }

    protected override void beforeUpdate() {
        validateAccountPlans();
    }

    protected override void beforeDelete() {
        checkForAssociatedCalls();
    }

    private void validateAccountPlans() {
        for (Account_Plan_vod__c newAccountPlan : newAccountPlans) {
            validateStartDateAndEndDate(newAccountPlan);
        }
    }

    private void validateStartDateAndEndDate(Account_Plan_vod__c accountPlan) {
        Date startDate = accountPlan.Start_Date_vod__c;
        Date endDate = accountPlan.End_Date_vod__c;

        if (!VeevaDateValidationHelper.areStartDateAndEndDatePopulatedOrNull(startDate, endDate)) {
            // We do not allow just one of the two fields to be set
            accountPlan.addError(
                VeevaMessageController.getMsgWithDefault('ACCOUNT_PLAN_DATES_REQUIRED', 'Common', 'Start Date and End Date are required.')
            );
        } else if (!VeevaDateValidationHelper.areStartDateAndEndDateValid(startDate, endDate)) {
            // If both are populated, then start date cannot be on or after the end date
            accountPlan.addError(
                VeevaMessageController.getMsgWithDefault(
                    'ACCOUNT_PLAN_START_DATE_CANNOT_BE_GREATER',
                    'Common',
                    'Start Date cannot be greater than or equal to the End Date.'
                )
            );
        }
    }

    private void checkForAssociatedCalls() {
        List<Call2_vod__c> headers = [SELECT Id, Account_Plan_vod__c FROM Call2_vod__c WHERE Account_Plan_vod__c IN :oldAccountPlans];

        for (Call2_vod__c header : headers) {
            oldAccountPlansMap.get(header.Account_Plan_vod__c).addError(VOD_GET_ERROR_MSG.getErrorMsg('DEL_PROD_STRAT', 'TriggerError'), false);
        }
    }
}