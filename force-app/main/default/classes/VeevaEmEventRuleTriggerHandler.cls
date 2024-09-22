public without sharing class VeevaEmEventRuleTriggerHandler  extends VeevaTriggerHandler {

    private List<EM_Event_Rule_vod__c> newEventRules;

    protected override boolean doRecursionCheck() {
        return true;
    }
    
    protected override String sObjectType() {
        return 'EM_Event_Rule_vod__c';
    }
    
    @TestVisible protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        newEventRules = (List<EM_Event_Rule_vod__c>) triggerNew;
    }
    
    protected override void beforeInsert() {
        checkEmEventRuleBeforeInsertUpdate();
    }
    
    protected override void beforeUpdate() {
        checkEmEventRuleBeforeInsertUpdate();
    }

    /*
        This method verify uniqueness of the Event Management Rules.
        We implemented the following logic:
        1. Get all EM_Event_Rule_vod__c records that has the same Event_Configuration_vod__c, Country_Override_vod__c and RecordTypeId but the EM_Event_Rule_vod__c.Id not in the set with the new Ids.
        2. Then we check the RecordTypeId. There are 3 different cases:
            Case 1: The RecordTypeId of the new rule equals to 'Material_vod'.
                The error will be set in the rules that have duplicated  Material_vod__c or Email_Template_vod__c  withthe already existing rule(s).
            Case 2: The RecordTypeId of the new rule equals to the 'Speaker_Qualification_vod'.
                The error will be set for all rules that have duplicated these RecordTypeIds.
            Case 3: The error will be set for all rules with any other record types.
        3. The query to populate 'List<EM_Event_Rule_vod__c> currentRules' will eliminate all not related records.          
    */
    public void checkEmEventRuleBeforeInsertUpdate() {
        Set<String> eventConfigurationSet = new Set<String>();
        Set<String> countryOverrideSet = new Set<String>();
        Set<String> recordTypeSet = new Set<String>();

        Id qualificationRecordType;
        Id materialRecordType;

        String errMessage = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('DUPLICATE_CONFIG_ERROR', 'TriggerError', 'Duplicate Configuration Error');

        List<Schema.RecordTypeInfo> ruleRecordTypes = EM_Event_Rule_vod__c.SObjectType.getDescribe().getRecordTypeInfos();
        for (Schema.RecordTypeInfo rt: ruleRecordTypes) {
            String devName = rt.getDeveloperName();
            if (devName == 'Speaker_Qualification_vod') {
                qualificationRecordType = rt.getRecordTypeId();
            } else if (devName == 'Material_vod') {
                materialRecordType = rt.getRecordTypeId();
            }
        }


        // Create WHERE clause 
        for (EM_Event_Rule_vod__c rule : newEventRules) {
            eventConfigurationSet.add(rule.Event_Configuration_vod__c);
            recordTypeSet.add(rule.RecordTypeId);
            if (rule.Country_Override_vod__c == null){
                countryOverrideSet.add('');
            } else {
                countryOverrideSet.add(rule.Country_Override_vod__c);
            }
        }

        List<EM_Event_Rule_vod__c> currentRules = [ SELECT Id, RecordTypeId, Event_Configuration_vod__c, Qualification_vod__c, Country_Override_vod__c, Material_vod__c, Email_Template_vod__c 
                                             FROM EM_Event_Rule_vod__c
                                             WHERE Id NOT IN :newEventRules AND Event_Configuration_vod__c IN :eventConfigurationSet
                                             AND Country_Override_vod__c IN :countryOverrideSet AND RecordTypeId IN :recordTypeSet ];


        Set<String> currentRuleSet = new Set<String>();

        for (EM_Event_Rule_vod__c rule : currentRules) {
            String key = createKey(rule, materialRecordType, qualificationRecordType);
            if(key != null) {
                currentRuleSet.add(key);
            }
        }
        
        for (EM_Event_Rule_vod__c rule : newEventRules) {
            String key = createKey(rule, materialRecordType, qualificationRecordType);
            if (key != null && currentRuleSet.contains(key)) {
                rule.addError(errMessage);
            }
        }
    }

    String createKey(EM_Event_Rule_vod__c rule,  Id materialRecordType, Id qualificationRecordType) {
        String country = '*';
        if (String.isNotBlank(rule.Country_Override_vod__c)) {
            country = rule.Country_Override_vod__c;
        }
        String tmp = '*';

        if (materialRecordType != null && materialRecordType.equals(rule.RecordTypeId)) {
            if (rule.Material_vod__c != null) {
                tmp = rule.Material_vod__c;
            } else if (rule.Email_Template_vod__c != null) {
                tmp = rule.Email_Template_vod__c;
            } else {
                tmp = null;
            }
        } else if (qualificationRecordType != null && qualificationRecordType.equals(rule.RecordTypeId)) {
            tmp = wrapEmpty(rule.Qualification_vod__c);
        }

        return (tmp == null ) ? tmp : rule.Event_Configuration_vod__c + '-' + rule.RecordTypeId + '-' + country + '-' + tmp;
    }

    String wrapEmpty(String str) {
        return (str == null) ? 'NULL' : str;
    }
}