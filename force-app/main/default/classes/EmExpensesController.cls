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

public with sharing class EmExpensesController {
    /**
     * Wrapper to pass to LWC, containg parent and children Expense Types
     * Reason for the wrapper is that regular Map does not preserve order, when reading in LWC
     */
    public class ExpenseLineExpenseTypeWrapper {
        @AuraEnabled
        public Id parentId;
        @AuraEnabled
        public String parentName;
        @AuraEnabled
        public List<Expense_Type_vod__c> subTypes;

        ExpenseLineExpenseTypeWrapper(Id parentId, String parentName, List<Expense_Type_vod__c> subTypes) {
            this.parentId = parentId;
            this.parentName = parentName;
            this.subTypes = subTypes;
        }
    }

    /**
     * Gets Event Budgets for a given Event
     * @param String eventId to
     * @return List of Event Budgets
     */
    @AuraEnabled
    public static List<EM_Event_Budget_vod__c> getEventBudgets(String eventId) {
        try {
            List<EM_Event_Budget_vod__c> eventBudgets = [
                SELECT Budget_Name_vod__c, Id
                FROM EM_Event_Budget_vod__c
                WHERE Event_vod__c = :eventId
                ORDER BY Budget_Name_vod__c ASC
            ];
            return eventBudgets;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Gets unused parent Expense Types
     * @param String eventId
     * @param String selectedTypeId to exclude selected Type from the query
     * @return List of Event Budgets
     */
    @AuraEnabled
    public static List<Expense_Type_vod__c> getEstimateExpenseTypes(String eventId, String selectedTypeId) {
        try {
            List<Expense_Type_vod__c> estimateTypes = [
                SELECT Id, Name, Country_vod__c, toLabel(Country_vod__r.Country_Name_vod__c), Expense_Code_vod__c
                FROM Expense_Type_vod__c
                WHERE
                    Active_vod__c = true
                    AND Parent_Expense_Type_vod__c = null
                    AND Id NOT IN (
                        SELECT Expense_Type_vod__c
                        FROM EM_Expense_Estimate_vod__c
                        WHERE Event_vod__c = :eventId AND Expense_Type_vod__c != :selectedTypeId
                    )
                ORDER BY Name ASC
            ];

            return estimateTypes;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Gets sorted and grouped Expense Types
     * Parent is its own child
     * Max depth of inheritance is 1, no grand children allowed
     * @return Sorted and LWC readable List of ExpenseLineExpenseTypeWrapper
     */
    @AuraEnabled
    public static List<ExpenseLineExpenseTypeWrapper> getExpenseLineExpenseTypes() {
        try {
            List<Expense_Type_vod__c> estimateTypes = [
                SELECT
                    Id,
                    Name,
                    Country_vod__c,
                    toLabel(Country_vod__r.Country_Name_vod__c),
                    Expense_Type_Identifier_vod__c,
                    Parent_Expense_Type_vod__c
                FROM Expense_Type_vod__c
                WHERE Active_vod__c = true
                ORDER BY Name ASC
            ];

            // List used to preserve lwc readable order of parent to child expense types
            List<ExpenseLineExpenseTypeWrapper> parentToChildContainer = new List<ExpenseLineExpenseTypeWrapper>();

            Map<Id, Expense_Type_vod__c> parentIdToParentMap = new Map<Id, Expense_Type_vod__c>();
            Map<Id, List<Expense_Type_vod__c>> parentIdToChildrenMap = new Map<Id, List<Expense_Type_vod__c>>();

            for (Expense_Type_vod__c eT : estimateTypes) {
                Id parentId = eT.Parent_Expense_Type_vod__c;
                if (parentId != null) {
                    if (parentIdToChildrenMap.containsKey(parentId)) {
                        List<Expense_Type_vod__c> childList = parentIdToChildrenMap.get(parentId);
                        childList.add(eT);
                        parentIdToChildrenMap.put(parentId, childList);
                    } else {
                        parentIdToChildrenMap.put(parentId, new List<Expense_Type_vod__c>{ eT });
                    }
                } else {
                    if (parentIdToChildrenMap.containsKey(eT.Id)) {
                        List<Expense_Type_vod__c> childList = parentIdToChildrenMap.get(eT.Id);
                        List<Expense_Type_vod__c> listWithParentPrepended = new List<Expense_Type_vod__c>();
                        listWithParentPrepended.add(eT);
                        listWithParentPrepended.addAll(childList);
                        parentIdToChildrenMap.put(eT.Id, listWithParentPrepended);
                    } else {
                        parentIdToChildrenMap.put(eT.Id, new List<Expense_Type_vod__c>{ eT });
                    }
                    parentIdToParentMap.put(eT.Id, eT);
                }
            }

            for (Id parentId : parentIdToParentMap.keySet()) {
                Expense_Type_vod__c parent = parentIdToParentMap.get(parentId);
                if (parentIdToChildrenMap.containsKey(parentId)) {
                    List<Expense_Type_vod__c> childList = parentIdToChildrenMap.get(parentId);
                    ExpenseLineExpenseTypeWrapper wrapper = new ExpenseLineExpenseTypeWrapper(parentId, parent.Name, childList);
                    parentToChildContainer.add(wrapper);
                }
            }

            return parentToChildContainer;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Method to associate Expense Types to Expense Estimates for a given Event
     * @param String eventId to find related Expense Estimates for.
     * @return Map of expenseTypeIds to Expense Estimates
     */
    @AuraEnabled
    public static Map<Id, EM_Expense_Estimate_vod__c> getExpenseTypeToExpenseEstimateMapping(String eventId) {
        try {
            Map<Id, EM_Expense_Estimate_vod__c> expenseTypeToExpenseEstimateMap = new Map<Id, EM_Expense_Estimate_vod__c>();
            List<EM_Expense_Estimate_vod__c> expenseEstimates = [
                SELECT Id, Name, Event_Budget_vod__c, Expense_Type_vod__c, Expense_Type_Name_vod__c
                FROM EM_Expense_Estimate_vod__c
                WHERE Event_vod__c = :eventId AND Event_Budget_vod__c != null AND Expense_Type_vod__c != null
            ];

            for (EM_Expense_Estimate_vod__c estimate : expenseEstimates) {
                expenseTypeToExpenseEstimateMap.put(estimate.Expense_Type_vod__c, estimate);
            }

            return expenseTypeToExpenseEstimateMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Method to determine if a current user is a system admin or not.
     * @return Boolean of if user is a system admin.
     */
    @AuraEnabled
    public static Boolean isSystemAdmin(){
        try {
            String userId = UserInfo.getUserId();
            List<User> users = [
                SELECT User.Id 
                FROM User 
                WHERE Profile.PermissionsModifyAllData = true AND Profile.PermissionsCustomizeApplication = true AND User.Id =: userId
            ];
            return users != null && users.size() > 0;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Expense_Line_vod__c> getExpenseLines(Id expenseHeaderId) {
        try {
            VeevaBaseObject expenseLineObj = VeevaBaseObject.create('Expense_Line_vod__c');
            if (expenseLineObj == null) {
                return new List<Expense_Line_vod__c>();
            }
            Set<String> expenseLineQueryParams = new Set<String>{
                'RecordType.DeveloperName',
                'Expense_Estimate_vod__r.Expense_Type_Name_vod__c',
                'Event_Budget_vod__r.Budget_Name_vod__c'
            };
            for (SObjectField field : expenseLineObj.getDescribe().fields.getMap().values()) {
                expenseLineQueryParams.add(field.getDescribe().getName());
            }

            expenseLineObj.mapRelationships(new List<String>(expenseLineQueryParams));

            Set<String> formattedExpenseLineQueryParams = expenseLineObj.getAccessibleFields(expenseLineQueryParams, true, true);

            Set<String> accessibleExpenseAttributionQueryParams = new Set<String>();
            VeevaBaseObject expenseAttributionObj = VeevaBaseObject.create('Expense_Attribution_vod__c');
            if (expenseAttributionObj != null) {
                Set<String> expenseAttributionQueryParams = new Set<String>{
                    'Actual_vod__c',
                    'Expense_Line_vod__c',
                    'Incurred_Expense_Account_vod__c',
                    'Incurred_Expense_Attendee_vod__c',
                    'Incurred_Expense_Attendee_vod__r.Account_vod__c',
                    'Incurred_Expense_Attendee_vod__r.Account_vod__r.IsPersonAccount',
                    'Incurred_Expense_Attendee_vod__r.Contact_vod__c',
                    'Incurred_Expense_Attendee_vod__r.Meal_Opt_In_vod__c',
                    'Incurred_Expense_Attendee_vod__r.Status_vod__c',
                    'Incurred_Expense_Attendee_vod__r.User_vod__c',
                    'Incurred_Expense_Speaker_vod__c',
                    'Incurred_Expense_Speaker_vod__r.Meal_Opt_In_vod__c',
                    'Incurred_Expense_Speaker_vod__r.Status_vod__c',
                    'Incurred_Expense_Team_Member_vod__c',
                    'Incurred_Expense_Type_vod__c',
                    'Incurred_Expense_Vendor_vod__c',
                    'Incurred_Expense_Venue_vod__c',
                    'Incurred_Expense_vod__c'
                };
                expenseAttributionObj.mapRelationships(new List<String>(expenseAttributionQueryParams));
                accessibleExpenseAttributionQueryParams = expenseAttributionObj.getAccessibleFields(expenseAttributionQueryParams, true, true);
            }

            String query = 'SELECT ' + String.join(new List<String>(formattedExpenseLineQueryParams), ',');
            if (!accessibleExpenseAttributionQueryParams.isEmpty()) {
                query += ', (SELECT ' + String.join(new List<String>(accessibleExpenseAttributionQueryParams), ',');
                query += ' FROM Expense_Attributions_vod__r)';
            }
            query += ' FROM Expense_Line_vod__c';
            query += ' WHERE Expense_Header_vod__c = :expenseHeaderId';
            query += ' ORDER BY CreatedDate ASC';

            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static string getExpenseLineRecordTypeId(String expenseHeaderRecordType){
        try {
            Schema.RecordTypeInfo expenseLineRecordType = Schema.SObjectType.Expense_Line_vod__c.getRecordTypeInfosByDeveloperName().get(expenseHeaderRecordType);
            if (expenseLineRecordType == null || !expenseLineRecordType.isAvailable()) {
                return null;
            }
            return expenseLineRecordType.getRecordTypeId();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<ParticipantGroup> getParticipantGroups(Id eventId, Id expenseLineId) {
        try {
            List<ParticipantGroup> groups = new List<ParticipantGroup>();
            VeevaBaseObject expenseAttributionObj = VeevaBaseObject.create('Expense_Attribution_vod__c');
            if (expenseAttributionObj == null) {
                return groups;
            }
            Map<String, String> typeToField = new Map<String, String>{
                'Attendee_vod' => 'Incurred_Expense_Attendee_vod__c',
                'Event_Speaker_vod' => 'Incurred_Expense_Speaker_vod__c',
                'Event_Team_Member_vod' => 'Incurred_Expense_Team_Member_vod__c',
                'Vendor_vod' => 'Incurred_Expense_Vendor_vod__c',
                'Venue_vod' => 'Incurred_Expense_Venue_vod__c'
            };
            Set<String> allowedTypes = new Set<String>();
            for (String type : typeToField.keySet()) {
                if (expenseAttributionObj.getAccessibleField(typeToField.get(type), false, false) != null) {
                    allowedTypes.add(type);
                }
            }

            List<EM_Attendee_vod__c> mealOptInAttendees = [
                SELECT Id, toLabel(Status_vod__c), Attendee_Name_vod__c, Account_vod__c, Account_vod__r.IsPersonAccount, Contact_vod__c, User_vod__c, Meal_Opt_In_vod__c
                FROM EM_Attendee_vod__c
                WHERE Event_vod__c = :eventId AND Meal_Opt_In_vod__c = true
            ];
            mealOptInAttendees = Security.stripInaccessible(AccessType.READABLE, mealOptInAttendees).getRecords();
            List<EM_Event_Speaker_vod__c> mealOptInSpeakers = [
                SELECT Id, toLabel(Status_vod__c), Speaker_Name_vod__c, Meal_Opt_In_vod__c
                FROM EM_Event_Speaker_vod__c
                WHERE Event_vod__c = :eventId AND Meal_Opt_In_vod__c = true
            ];
            mealOptInSpeakers = Security.stripInaccessible(AccessType.READABLE, mealOptInSpeakers).getRecords();
            ParticipantGroup mealOptIns = new ParticipantGroup('mealOptIn');
            mealOptIns.label = VeevaMessageController.getMsgWithDefault('MEAL_OPT_IN_LABEL', 'EVENT_MANAGEMENT', 'Meal Opt In');
            if (mealOptInAttendees.size() > 0 && allowedTypes.contains('Attendee_vod')) {
                for (EM_Attendee_vod__c attendee : mealOptInAttendees) {
                    mealOptIns.participants.add(new Participant(attendee));
                }
            }
            if (mealOptInSpeakers.size() > 0 && allowedTypes.contains('Event_Speaker_vod')) {
                for (EM_Event_Speaker_vod__c speaker : mealOptInSpeakers) {
                    mealOptIns.participants.add(new Participant(speaker));
                }
            }
            if (mealOptIns.participants.size() > 0) {
                groups.add(mealOptIns);
            }
            Set<Id> recentLines = new Map<Id,Expense_Line_vod__c>([
                SELECT Id FROM Expense_Line_vod__c
                WHERE Event_vod__c = :eventId AND Id != :expenseLineId AND Number_Of_People_vod__c > 0
                    AND Expense_Header_vod__r.Split_Lines_vod__c = 'Yes_vod'
                ORDER BY LastModifiedDate DESC
                LIMIT 5
            ]).keySet();
            List<Expense_Line_vod__c> previousGroups = [
                SELECT Id, Expense_Header_vod__r.Transaction_Date_vod__c, Expense_Type_Name_vod__c, (
                    SELECT Incurred_Expense_vod__c,
                        Incurred_Expense_Account_vod__c,
                        Incurred_Expense_Attendee_vod__c,
                        Incurred_Expense_Attendee_vod__r.Attendee_Name_vod__c,
                        Incurred_Expense_Attendee_vod__r.Account_vod__c,
                        Incurred_Expense_Attendee_vod__r.Account_vod__r.IsPersonAccount,
                        Incurred_Expense_Attendee_vod__r.Contact_vod__c,
                        Incurred_Expense_Attendee_vod__r.Meal_Opt_In_vod__c,
                        toLabel(Incurred_Expense_Attendee_vod__r.Status_vod__c),
                        Incurred_Expense_Attendee_vod__r.User_vod__c,
                        Incurred_Expense_Speaker_vod__c,
                        Incurred_Expense_Speaker_vod__r.Speaker_Name_vod__c,
                        Incurred_Expense_Speaker_vod__r.Meal_Opt_In_vod__c,
                        toLabel(Incurred_Expense_Speaker_vod__r.Status_vod__c),
                        Incurred_Expense_Team_Member_vod__c,
                        Incurred_Expense_Type_vod__c,
                        Incurred_Expense_Vendor_vod__c,
                        Incurred_Expense_Venue_vod__c
                    FROM Expense_Attributions_vod__r
                    WHERE Incurred_Expense_Type_vod__c IN :allowedTypes AND (
                        Incurred_Expense_Attendee_vod__c != null OR Incurred_Expense_Speaker_vod__c != null OR 
                        Incurred_Expense_Team_Member_vod__c != null OR Incurred_Expense_Vendor_vod__c != null OR 
                        Incurred_Expense_Venue_vod__c != null
                    )
                )
                FROM Expense_Line_vod__c
                WHERE Id IN :recentLines
                ORDER BY Expense_Header_vod__r.Transaction_Date_vod__c DESC NULLS LAST,
                    Expense_Type_Name_vod__c ASC NULLS LAST
            ];
            previousGroups = Security.stripInaccessible(AccessType.READABLE, previousGroups).getRecords();
            for (Expense_Line_vod__c line : previousGroups) {
                ParticipantGroup grouping = new ParticipantGroup(line.Id);
                List<String> labelComponents = new List<String>();
                if (line.Expense_Header_vod__r?.Transaction_Date_vod__c != null) {
                    labelComponents.add(line.Expense_Header_vod__r.Transaction_Date_vod__c.format());
                }
                if (line.Expense_Type_Name_vod__c != null) {
                    labelComponents.add(line.Expense_Type_Name_vod__c);
                }
                grouping.label = String.join(labelComponents, ', ');
                for (Expense_Attribution_vod__c attribution : line.Expense_Attributions_vod__r) {
                    grouping.participants.add(new Participant(attribution));
                }
                if (grouping.participants.size() > 0) {
                    groups.add(grouping);
                }
            }
            return groups;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @TestVisible
    private class ParticipantGroup {
        private String privateLabel;
        @AuraEnabled public String id;
        @AuraEnabled public String label {
            get { return privateLabel + ' (' + participants.size() + ')'; }
            set { privateLabel = value; }
        }
        @AuraEnabled public List<Participant> participants;

        ParticipantGroup(String id) {
            this.id = id;
            participants = new List<Participant>();
        }
    }

    private class Participant {
        @AuraEnabled public Id participantId;
        @AuraEnabled public String name;
        @AuraEnabled public String type;
        @AuraEnabled public String icon;
        @AuraEnabled public String status;
        @AuraEnabled public boolean mealOptIn;

        Participant(EM_Attendee_vod__c attendee) {
            participantId = attendee.Id;
            name = attendee.Attendee_Name_vod__c;
            type = 'Attendee_vod';
            status = attendee.Status_vod__c;
            mealOptIn = attendee.Meal_Opt_In_vod__c;
            if (attendee.Contact_vod__c != null) {
                icon = 'standard:contact';
            } else if (attendee.User_vod__c != null) {
                icon = 'standard:user';
            } else if (attendee.Account_vod__c != null && attendee.Account_vod__r.IsPersonAccount == false) {
                icon = 'standard:account';
            } else {
                icon = 'standard:person_account';
            }
        }

        Participant(EM_Event_Speaker_vod__c speaker) {
            participantId = speaker.Id;
            name = speaker.Speaker_Name_vod__c;
            type = 'Event_Speaker_vod';
            status = speaker.Status_vod__c;
            mealOptIn = speaker.Meal_Opt_In_vod__c;
            icon = 'custom:custom84';
        }

        Participant(Expense_Attribution_vod__c attribution) {
            name = attribution.Incurred_Expense_vod__c;
            type = attribution.Incurred_Expense_Type_vod__c;
            switch on attribution.Incurred_Expense_Type_vod__c {
                when 'Attendee_vod' {
                    this(attribution.Incurred_Expense_Attendee_vod__r);
                }
                when 'Event_Speaker_vod' {
                    this(attribution.Incurred_Expense_Speaker_vod__r);
                }
                when 'Event_Team_Member_vod' {
                    participantId = attribution.Incurred_Expense_Team_Member_vod__c;
                    icon = 'standard:user';
                }
                when 'Vendor_vod' {
                    participantId = attribution.Incurred_Expense_Vendor_vod__c;
                    icon = 'custom:custom16';
                }
                when 'Venue_vod' {
                    participantId = attribution.Incurred_Expense_Venue_vod__c;
                    icon = 'custom:custom16';
                }
            }
        }
    }

    @AuraEnabled
    public static List<Expense_Header_vod__c> getRelatedExpenseHeaders(
        String fields,
        String id,
        String relationField,
        Map<String, List<String>> filters
    ) {
        try {
            FieldStrings fieldStrings = getHeaderAndLineFields(fields);
            String stmt = 'SELECT ' + fieldStrings.headerFields;
            stmt += ', (SELECT ' + fieldStrings.lineFields;
            stmt += ' FROM Expense_Lines_vod__r ORDER BY Name) FROM Expense_Header_vod__c';
            stmt += ' WHERE ' + relationField + '=\'' + String.escapeSingleQuotes(id) + '\'';
            stmt += getFiltersString(filters) + ' ORDER BY Name';
            return Database.query(stmt);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Expense_Header_vod__c> searchRelatedExpenseHeaders(
        String fields,
        String id,
        String relationField,
        String searchTerm,
        Map<String, List<String>> filters
    ) {
        try {
            SOSLQueryHelper helper = new SOSLQueryHelper();
            FieldStrings fieldStrings = getHeaderAndLineFields(fields);

            searchTerm = helper.escapeSpecialCharacters(searchTerm);
            List<String> terms = searchTerm.split('\\s+');
            terms = helper.addWildcardToTerms(terms);
            String term = String.join(terms, ' AND ');

            String sosl = 'FIND {' + term + '} IN ALL FIELDS RETURNING';
            sosl += ' Expense_Header_vod__c(Id';
            sosl += ' WHERE ' + relationField + '=\'' + String.escapeSingleQuotes(id) + '\'';
            sosl += getFiltersString(filters) + ' ORDER BY Name),';
            sosl += ' Expense_Line_vod__c(Id,Expense_Header_vod__c';
            sosl += ' WHERE ' + relationField + '=\'' + String.escapeSingleQuotes(id) + '\' ORDER BY Name)';
            
            List<List<SObject>> soslResult = Search.query(sosl);

            if (soslResult.get(0).size() == 0 && soslResult.get(1).size() == 0 ) {
                return new List<Expense_Header_vod__c>();
            }

            List<Id> headerIds = new List<Id>();
            List<Id> lineIds = new List<Id>();

            for (SObject header: soslResult.get(0)) {
                headerIds.add((Id)header.get('Id'));
            }

            Set<Id> allHeaderIds = new Set<Id>(headerIds);

            for (SObject line: soslResult.get(1)) {
                lineIds.add((Id)line.get('Id'));
                allHeaderIds.add((Id)line.get('Expense_Header_vod__c'));
            }

            List<Expense_Header_vod__c> relatedExpenseHeaders;

            String soql = 'SELECT ' + fieldStrings.headerFields;
            soql += ', (SELECT ' + fieldStrings.lineFields + ' FROM Expense_Lines_vod__r';
            soql += ' WHERE Expense_Header_vod__c IN :headerIds OR Id IN :lineIds';
            soql += ' ORDER BY Name) FROM Expense_Header_vod__c WHERE Id IN :allHeaderIds';
            soql += getFiltersString(filters) + ' ORDER BY Name';

            return Database.query(soql);
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<VeevaRelatedListFilterController.FilterGroup> getFilters(
        String referenceFieldName,
        String recordId
    ) {
        try {
            List<String> filterFields = new List<String>{'recordTypeId', 'Split_Lines_vod__c'};
            List<VeevaRelatedListFilterController.FilterGroup> filters = VeevaRelatedListFilterController.getFilters(
                'Expense_Header_vod__c', 
                referenceFieldName, 
                recordId, 
                filterFields, 
                null
            );
            
            VeevaBaseObject headerObj = VeevaBaseObject.create('Expense_Header_vod__c');
            DescribeFieldResult fieldDescribe = headerObj.getFieldDescribe('Split_Lines_vod__c');

            if (!fieldDescribe.isAccessible()) {
                return filters;
            }
            
            Boolean noNoValues = true;
            VeevaRelatedListFilterController.FilterGroup splitLineFilterGroup;

            for (VeevaRelatedListFilterController.FilterGroup filterGroup: filters) {
                if (filterGroup.fieldName == 'Split_Lines_vod__c') {
                    splitLineFilterGroup = filterGroup;
                    for (VeevaRelatedListFilterController.Filter filter: splitLineFilterGroup.options) {
                        if (filter.value == 'No_vod') {
                            noNoValues = false;
                            break;
                        }
                    }
                    break;
                }
            }

            if (noNoValues) {
                String soql = 'SELECT Split_Lines_vod__c FROM Expense_Header_vod__c'; 
                soql += ' WHERE ' + referenceFieldName + ' = :recordId AND Split_Lines_vod__c=NULL';

                Boolean hasNullSplitLines = Database.query(soql).size() > 0;
                if (hasNullSplitLines) {
                    if (splitLineFilterGroup == null) {
                        splitLineFilterGroup = new VeevaRelatedListFilterController.FilterGroup(fieldDescribe);
                        filters.add(splitLineFilterGroup);
                    }
                    for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                        if (entry.getValue() == 'No_vod') {
                            VeevaRelatedListFilterController.Filter option = new VeevaRelatedListFilterController.Filter(
                                entry.getValue(), 
                                entry.getLabel()
                            );
                            splitLineFilterGroup.options.add(option);
                        }
                    }
                }
            }
            return filters;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private class FieldStrings {
        public String headerFields { get; set; }
        public String lineFields { get; set; }
    }

    private static FieldStrings getHeaderAndLineFields(String fields) {
        List<String> fieldsList = fields.split(',');
        Set<String> fieldsSet = new Set<String>(fieldsList);

        VeevaBaseObject headerObj = VeevaBaseObject.create('Expense_Header_vod__c');
        headerObj.mapRelationships(fieldsList);
        fieldsSet.remove('Concur_Status_vod__c');
        Set<String> headerFields = headerObj.getAccessibleFields(fieldsSet, true, false);
        String concurField = headerObj.getAccessibleField('Concur_Status_vod__c', true, true);
        if (!String.isEmpty(concurField)) {
            headerFields.add(concurField);
        }

        VeevaBaseObject lineObj = VeevaBaseObject.create('Expense_Line_vod__c');
        lineObj.mapRelationships(fieldsList);
        Set<String> lineFields = lineObj.getAccessibleFields(fieldsSet, true, false);

        FieldStrings headerAndLineFields = new FieldStrings();
        headerAndLineFields.headerFields = String.join(new List<String>(headerFields), ',');
        headerAndLineFields.lineFields = String.join(new List<String>(lineFields), ',');

        return headerAndLineFields;
    }

    private static String getFiltersString(Map<String, List<String>> filters) {
        VeevaBaseObject headerObj = VeevaBaseObject.create('Expense_Header_vod__c');

        String clause = '';
        for (String fieldName : filters.keySet()) {
            DescribeFieldResult fieldDescribe = headerObj.getFieldDescribe(fieldName);
            List<String> fieldValues = filters.get(fieldName);
            if (fieldDescribe != null && fieldValues != null && !fieldValues.isEmpty()) {
                List<String> escapedFieldValues = escapeStringList(fieldValues);
                clause += ' AND ' + String.escapeSingleQuotes(fieldName) + ' IN (';
                clause += '\'' + String.join(escapedFieldValues, '\',\'') + '\'';
                if (fieldName == 'Split_Lines_vod__c' && fieldValues.contains('No_vod')) {
                    clause += ',NULL';
                }
                clause += ')';
            }
        }
        return clause;
    }

    private static List<String> escapeStringList(List<String> stringList) {
        list<String> escapedList = new List<String>();
        for (String s : stringList) {
            escapedList.add(String.escapeSingleQuotes(s));
        }
        return escapedList;
    }

    @AuraEnabled
    public static Map<Id, String> getAttendeeIcons(List<Id> attendeeIds) {
        try {
            Map<Id, String> attendeeIcons = new Map<Id, String>();
            List<EM_Attendee_vod__c> attendees = [
                SELECT Id, Account_vod__c, Account_vod__r.IsPersonAccount, Contact_vod__c, User_vod__c
                FROM EM_Attendee_vod__c
                WHERE Id IN :attendeeIds
            ];
            for (EM_Attendee_vod__c attendee : attendees) {
                String icon = 'standard:person_account';
                if (attendee.Contact_vod__c != null) {
                    icon = 'standard:contact';
                } else if (attendee.User_vod__c != null) {
                    icon = 'standard:user';
                } else if (attendee.Account_vod__c != null && attendee.Account_vod__r.IsPersonAccount == false) {
                    icon = 'standard:account';
                }
                attendeeIcons.put(attendee.Id, icon);
            }
            return attendeeIcons;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}