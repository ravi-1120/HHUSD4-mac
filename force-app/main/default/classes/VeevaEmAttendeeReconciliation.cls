/******************************************************************************
 *
 *               Confidentiality Information:
 *
 * This module is the confidential and proprietary information of
 * Veeva Systems, Inc.; it is not to be copied, reproduced, or transmitted
 * in any form, by any means, in whole or in part, nor is it to be used
 * for any purpose other than that for which it is expressly provided
 * without the written permission of Veeva Systems, Inc.
 *
 * Copyright (c) 2022 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/
public class VeevaEmAttendeeReconciliation {
    
    private static final String EM_ATTENDEE = 'EM_Attendee_vod__c';
    private static final String TO_LABEL_WALK_IN_STATUS = 'toLabel(Walk_In_Status_vod__c)';
    private static final String WALK_IN_STATUS = 'Walk_In_Status_vod__c';
    private static final String TO_LABEL_ONLINE_REGISTRATION_STATUS = 'toLabel(Online_Registration_Status_vod__c)';
    private static final String ONLINE_REGISTRATION_STATUS = 'Online_Registration_Status_vod__c';
    private static final String TO_LABEL_WALK_IN_TYPE = 'toLabel(Walk_In_Type_vod__c)';
    private static final String WALK_IN_TYPE = 'Walk_In_Type_vod__c';
    private static final Integer TABLE_ROW_LIMIT = 2001;
    
    @AuraEnabled
    public static WalkInCounts getWalkInCounts(Id eventId) {
        Integer total = 0;
        Integer reconciled = 0;
        Integer dismissed = 0;
        Integer pendingVerification = 0;
        Integer needsReconciliation = 0;
        for (AggregateResult result : [SELECT Walk_In_Status_vod__c, Online_Registration_Status_vod__c, COUNT(Id) num FROM EM_Attendee_vod__c WHERE Event_vod__c = :eventId AND (Walk_In_Status_vod__c != null OR Online_Registration_Status_vod__c != null) GROUP BY Walk_In_Status_vod__c,Online_Registration_Status_vod__c]) {
            Integer countForStatus = (Integer) result.get('num');
            String status = (String) result.get(WALK_IN_STATUS);
            if (String.isBlank(status)) {
                status = (String) result.get(ONLINE_REGISTRATION_STATUS);
            }
            if (String.isBlank(status)) {
                continue;
            }
            
            total += countForStatus;
            if ('Dismissed_vod'.equals(status)) {
                dismissed += countForStatus;
            } else if ('Needs_Reconciliation_vod'.equals(status) || 'Reconciliation_Rejected_vod'.equals(status)) {
                needsReconciliation += countForStatus;
            } else if (status.contains('Reconciled')) {
                reconciled += countForStatus;
            } else if ('Pending_Verification_vod'.equals(status)) {
                pendingVerification += countForStatus;
            }
        }
        return new WalkInCounts(total, reconciled, dismissed, pendingVerification, needsReconciliation);
    }

    @TestVisible
    private class WalkInCounts {
        @AuraEnabled
        public Integer total {get;set;}
        @AuraEnabled
        public Integer reconciled {get;set;}
        @AuraEnabled
        public Integer dismissed {get;set;}
        @AuraEnabled
        public Integer pendingVerification {get;set;}
        @AuraEnabled
        public Integer needsReconciliation {get;set;}
        
        public WalkInCounts(Integer total, Integer reconciled, Integer dismissed, Integer pendingVerification, Integer needsReconciliation) {
            this.total = total;
            this.reconciled = reconciled;
            this.dismissed = dismissed;
            this.pendingVerification = pendingVerification;
            this.needsReconciliation = needsReconciliation;
        }
    }
    
    @AuraEnabled
    public static List<EM_Attendee_vod__c> getWalkInAttendees(Id eventId, List<String> fields, List<String> walkInStatuses, List<String> walkInTypes, String sortBy, String sortDirection) {
        VeevaBaseObject vbo = VeevaBaseObject.create(EM_ATTENDEE);
        Set<String> accessibleFields = vbo.getAccessibleFields(new Set<String>(fields), true, false);
        addLabelAndApiname(accessibleFields, WALK_IN_STATUS);
        addLabelAndApiname(accessibleFields, ONLINE_REGISTRATION_STATUS);
        addLabelAndApiname(accessibleFields, WALK_IN_TYPE);

        String filterClause = '';
        if (!walkInStatuses?.isEmpty()) {
            filterClause += ' AND (Walk_In_Status_vod__c IN :walkInStatuses OR Online_Registration_Status_vod__c IN :walkInStatuses)';
        }
        if (!walkInTypes?.isEmpty()) {
            filterClause += ' AND (Walk_In_Type_vod__c IN :walkInTypes OR Online_Registration_Status_vod__c IN :walkInTypes)';
        }
        
        String orderBy = '';
        if (String.isNotBlank(sortBy) && String.isNotBlank(sortDirection)) {
            orderBy += EmAttendeeSelection.orderBy(vbo, sortBy, sortDirection);
        }
        
        String soqlTemplate = 'SELECT {0} FROM EM_Attendee_vod__c WHERE Event_vod__c = :eventId AND (Walk_In_Status_vod__c != null OR Online_Registration_Status_vod__c != null) {1} {2} LIMIT :TABLE_ROW_LIMIT';
        List<Object> parameters = new List<Object>{String.join(new List<String>(accessibleFields), ','), filterClause, orderBy};
        List<EM_Attendee_vod__c> walkIns = Database.query(String.format(soqlTemplate, parameters));
        return walkIns;
    }
    
    private static void addLabelAndApiname(Set<String> accessibleFields, String field) {
        String toLabelField = String.format('toLabel({0})', new List<Object>{field});
        if (accessibleFields.contains(toLabelField)) { // need both label and api name
            accessibleFields.remove(toLabelField);
            accessibleFields.add(field);
            accessibleFields.add(toLabelField+' toLabel_'+field);
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ReconciliationFilterGroup> getFilters() {
        VeevaBaseObject vbo = VeevaBaseObject.create(EM_ATTENDEE);
        
        List<ReconciliationFilterGroup> filters = new List<ReconciliationFilterGroup>();
        DescribeFieldResult walkInStatusDescribe = vbo.getFieldDescribe(WALK_IN_STATUS);
        if (walkInStatusDescribe?.isAccessible()) {
            ReconciliationFilterGroup walkInStatusFilters = new ReconciliationFilterGroup(walkInStatusDescribe);
            filters.add(walkInStatusFilters);
        }
        DescribeFieldResult walkInTypeDescribe = vbo.getFieldDescribe(WALK_IN_TYPE);
        if (walkInTypeDescribe?.isAccessible()) {
            ReconciliationFilterGroup walkInTypeFilters = new ReconciliationFilterGroup(walkInTypeDescribe);
            filters.add(walkInTypeFilters);
        }
        return filters;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getWalkInAttendeeStatuses(Id eventCountryId, Id eventConfigId) {
        List<String> walkInFieldsStatuses = new List<String>();
        VeevaBaseObject attendeeObj = VeevaBaseObject.create('EM_Event_Rule_vod__c');
        Set<String> accessibleFields = attendeeObj.getAccessibleFields(new Set<String>{'Country_Override_vod__c','Walk_In_Attendee_Statuses_vod__c', 'Event_Configuration_vod__c'});
        if (accessibleFields.size() == 3) {
            List<EM_Event_Rule_vod__c> walkInFieldsRules = [SELECT Country_Override_vod__c, Walk_In_Attendee_Statuses_vod__c 
                                                            FROM EM_Event_Rule_vod__c 
                                                            WHERE Event_Configuration_vod__c = :eventConfigId 
                                                            AND RecordType.DeveloperName = 'Walk_In_Fields_vod' 
                                                            AND (Country_Override_vod__c = null OR Country_Override_vod__r.Country_vod__c = :eventCountryId)
                                                            ORDER BY Country_Override_vod__c NULLS LAST];
            EM_Event_Rule_vod__c walkInFieldsRule = walkInFieldsRules.size() > 0 ? walkInFieldsRules.get(0) : null;
            if (String.isNotBlank(walkInFieldsRule?.Walk_In_Attendee_Statuses_vod__c)) {
                walkInFieldsStatuses.addAll(walkInFieldsRule.Walk_In_Attendee_Statuses_vod__c.split(';'));
            }
        }
        return walkInFieldsStatuses;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCustomSettingsForNewButtonConfig() {
        return VeevaGlobalAccountSearchController.getCustomSettingsForNewButtonConfig();
    }
    
    @TestVisible
    private class ReconciliationFilterGroup {
        @AuraEnabled
        public String fieldName {get;set;}
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public List<ReconciliationFilter> options {get;set;}
        private Map<String, List<String>> ORDER = new Map<String, List<String>>{
            'Walk_In_Type_vod__c' => new List<String>{'Prescriber_vod', 'Non_Prescriber_vod','Other_vod'},
            'Walk_In_Status_vod__c' => new List<String>{'Needs_Reconciliation_vod','Reconciled_To_Existing_Account_vod','Reconciled_To_Existing_User_vod','Reconciled_To_Customer_Master_vod','Reconciled_To_New_Account_vod','Dismissed_vod'}
        };

        public ReconciliationFilterGroup(DescribeFieldResult field) {
            this.fieldName = field.getName();
            this.label = field.getLabel();
            this.options = new List<ReconciliationFilter>();
            Map<String, Schema.PicklistEntry> picklistValuesMap = new Map<String, Schema.PicklistEntry>();
            for (Schema.PicklistEntry option : field.getPicklistValues()) {
                picklistValuesMap.put(option.getValue(), option);
            }
            if (ORDER.containsKey(this.fieldName)) {
                for (String value : ORDER.get(this.fieldName)) {
                    Schema.PicklistEntry option = picklistValuesMap.remove(value);
                    if (option != null) {
                        this.options.add(new ReconciliationFilter(option.getValue(), option.getLabel()));
                    }
                }
                if (!picklistValuesMap.isEmpty()) {
                    for (Schema.PicklistEntry option : picklistValuesMap.values()) {
                        this.options.add(new ReconciliationFilter(option.getValue(), option.getLabel()));
                    }
                }
                
            }
        }
    }

    private class ReconciliationFilter {
        @AuraEnabled
        public String value {get;set;}
        @AuraEnabled
        public String label {get;set;}

        public ReconciliationFilter(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}