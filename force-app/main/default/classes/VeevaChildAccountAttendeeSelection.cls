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
 * Copyright (c) 2023 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/
public class VeevaChildAccountAttendeeSelection {
    private static final String ALL_LOCATIONS = 'all_loc'; // Veeva Message for Label - ALL_LOCATIONS;;Common;;All Locations
    private static final String ALL_USERS = 'user';
    private static final String ALL_CONTACTS = 'contact';
    private static final String CHILD_ACCOUNT = 'Child_Account_vod__c';
    private static final List<String> DEFAULT_CHILD_ACCOUNT_QUERY_FIELDS = new List<String>{'Id', 'Parent_Child_Name_vod__c', 'Parent_Account_vod__c', 'Child_Account_vod__c', 'Child_Account_vod__r.LastName', 'Child_Account_vod__r.FirstName'};
    private static final List<String> DEFAULT_VIEWS_MESSAGES = new List<String>{'ALL_LOCATIONS;;Common;;All Locations', 'ALL_USERS;;Manage_Attendees;;All Users', 'ALL_CONTACTS;;Manage_Attendees;;All Contacts' };
    private static final Map<String, String> VEEVA_MESSAGE_TO_VIEW_ID = new Map<String, String>{'ALL_LOCATIONS' => ALL_LOCATIONS, 'ALL_USERS' => ALL_USERS, 'ALL_CONTACTS' => ALL_CONTACTS};
    private static final String CHILD_ACCOUNT_RELATIONSHIP_NAME = Child_Account_vod__c.Child_Account_vod__c.getDescribe().getRelationshipName();
    public static final String RECORD_TYPE_PREDICATE_TEMPLATE = '((Child_Account_vod__r.RecordType.DeveloperName IN ({0})) OR (Parent_Account_vod__r.RecordType.DeveloperName IN ({0})))';
    public static final String COUNTRY_PREDICATE_TEMPLATE = '((Child_Account_vod__r.Country_vod__r.Alpha_2_Code_vod__c IN ({0})) OR (Parent_Account_vod__r.Country_vod__r.Alpha_2_Code_vod__c IN ({0})))';

    @AuraEnabled
    public static List<ChildAccountResult> getChildAccounts(String termString, List<String> fields, String viewId, List<String> viewAccountIds, String orderBy, String orderDirection, Integer qLimit, Integer offset, boolean includeOutsideTerritoryAccounts, EmAttendeeSelection.Filters filters, boolean useCustomFieldFormatting) {
        String joinClause = includeOutsideTerritoryAccounts == true ?
            'Child_Account_vod__c != null AND Parent_Account_vod__c != null ' :
            'Child_Account_vod__c IN (SELECT Id FROM Account) AND Parent_Account_vod__c IN (SELECT Id FROM Account)';
               
        if (viewId != ALL_LOCATIONS) {
            joinClause = 'Id IN :childAccountIds';
        }
        Set<Id> accountIds = null;
        if (String.isNotBlank(termString)) {
            accountIds = searchWithTerm(termString);
            joinClause += ' AND (Child_Account_vod__c IN :accountIds OR Parent_Account_vod__c IN :accountIds)';
        }

        return queryChildAccounts(accountIds, viewAccountIds, fields, joinClause, orderBy, orderDirection, qLimit, offset, filters, useCustomFieldFormatting);
    }
    
    @TestVisible
    static Set<Id> searchWithTerm(String termString) {
        // Check FLS prior to SOSL search
        VeevaBaseObject addressVbo = VeevaBaseObject.create('Address_vod__c');
        Set<String> addressQueryFields = new Set<String>{'Account_vod__c', 'Inactive_vod__c'};
        Set<String> addressAccessibleFields = addressVbo.getAccessibleFields(addressQueryFields);

        if (addressAccessibleFields == null || addressAccessibleFields.size() != addressQueryFields.size()) {
            return new Set<Id>();
        }

        SOSLQueryHelper helper = new SOSLQueryHelper();
        termString = helper.escapeSpecialCharacters(termString);
        List<String> terms = termString.split('\\s+');
        terms = helper.addWildcardToTerms(terms);
        String term = String.join(terms, ' AND ');
        
        List<List<SObject>> searchResults = [
            FIND :term
                IN ALL FIELDS
                RETURNING
                    Address_vod__c(
                        Account_vod__c WHERE Inactive_vod__c = false AND Account_vod__c IN (SELECT Parent_Account_vod__c FROM Child_Account_vod__c)),
                    Account(Id)
        ];
                
        Set<Id> accountIds = new Set<Id>();
        for (List<SObject> results : searchResults) {
            for (SObject record : results) {
                if (SObjectType.Address_vod__c.getSObjectType() == record.getSObjectType()) {
                    accountIds.add((Id) record.get('Account_vod__c'));
                } else { // Account
                    accountIds.add((Id) record.get('Id'));
                }
            }
        }
    
        return accountIds;
    }
    
    static List<ChildAccountResult> queryChildAccounts(Set<Id> accountIds, List<Id> childAccountIds, List<String> fields, String joinClause, String orderBy, String orderDirection, Integer qLimit, Integer offset, EmAttendeeSelection.Filters filters, boolean useCustomFieldFormatting) {
        List<ChildAccountResult> records = new List<ChildAccountResult>();
        String soql = buildQuery(fields, joinClause, orderBy, orderDirection, qLimit, offset, filters, useCustomFieldFormatting);
        List<Child_Account_vod__c> childAccounts = Database.query(soql);
        
        Set<Id> parentAccountIds = new Set<Id>();
        for (Child_Account_vod__c childAccount : childAccounts) {
            if (childAccount.Parent_Account_vod__c != null) {
                parentAccountIds.add(childAccount.Parent_Account_vod__c);
            }
        }

        Map<Id, Address_vod__c> addressMap = getParentAccountAddresses(parentAccountIds);
        for (Child_Account_vod__c childAccount : childAccounts) {
            Address_vod__c addr = addressMap.get(childAccount.Parent_Account_vod__c);
            records.add(new ChildAccountResult(childAccount, addr));
        }
        return records;
    }

    @TestVisible
    static String buildQuery(List<String> fields, String joinClause, String orderBy, String orderDirection, Integer qLimit, Integer offset, EmAttendeeSelection.Filters filters, boolean useCustomFieldFormatting) {
        VeevaBaseObject childAccountVbo = VeevaBaseObject.create('Child_Account_vod__c');
        childAccountVbo?.addRelationship(CHILD_ACCOUNT_RELATIONSHIP_NAME, VeevaBaseObject.create('Account'));
        childAccountVbo?.mapRelationships(getChildAccountFieldsForQuery(fields));
        Set<String> fieldsToQuery = useCustomFieldFormatting ? childAccountVbo.getAccessibleFieldsWithCustomFormatting(new Set<String>(getChildAccountFieldsForQuery(fields))) :
            childAccountVbo.getAccessibleFields(new Set<String>(getChildAccountFieldsForQuery(fields)), true, false);

        // Ensuring fields are safe to use
        List<String> escapedFields = new List<String>();
        for(String field : fieldsToQuery) {
            escapedFields.add(String.escapeSingleQuotes(field));
        }

        List<String> filterConditions = new List<String>();
        if (filters != null && filters.hasFilters())  {
            filterConditions.addAll(filters.getFilterClauses());
            joinClause += 'AND ' + String.join(filterConditions, ' AND ');
        }
        
        List<Object> parameters = new List<Object>{String.join(escapedFields, ','), joinClause};
        String soqlTemplate = 'SELECT {0} FROM Child_Account_vod__c WHERE {1}';
        String soql = String.format(soqlTemplate, parameters);
        soql += orderByLimit(childAccountVbo, orderBy, orderDirection, qLimit, offset);
        return soql;
    }

    static List<String> getChildAccountFieldsForQuery(List<String> fields) {
        List<String> fieldsToQuery = new List<String>();
        fieldsToQuery.addAll(DEFAULT_CHILD_ACCOUNT_QUERY_FIELDS);
        for (String field : fields) {
            fieldsToQuery.add(CHILD_ACCOUNT_RELATIONSHIP_NAME + '.' + field);
        }
        return fieldsToQuery;
    }
    
    static String orderByLimit(VeevaBaseObject vbo, String orderBy, String orderDirection, Integer qLimit, Integer offset) {
        String clause = '';
        
        if (String.isNotBlank(orderBy) && String.isNotBlank(orderDirection)) {
            clause += EmAttendeeSelection.orderBy(vbo, orderBy, orderDirection);
        }
        if (qLimit != null && offset != null) {
            clause += ' LIMIT ';
            clause += qLimit;
            clause += ' OFFSET ';
            clause += offset;
        }
        return clause;
    }

    static Map<Id, Address_vod__c> getParentAccountAddresses(Set<Id> parentAccountIds) {
        Map<Id, Address_vod__c> addressMap = new Map<Id, Address_vod__c>();
        for (Address_vod__c address : [SELECT Account_vod__c, Name, City_vod__c, State_vod__c, Zip_vod__c, toLabel(Country_vod__c) FROM Address_vod__c WHERE Account_vod__c IN :parentAccountIds AND Inactive_vod__c = false ORDER BY Primary_vod__c DESC]) {
            if (!addressMap.containsKey(address.Account_vod__c)) {
                addressMap.put(address.Account_vod__c, address);
            }
        }
        return addressMap;
    }
    
    @TestVisible
    public class ChildAccountResult {
        @AuraEnabled
        public String childAccountId {get;set;}
        @AuraEnabled
        public String parentId {get;set;}
        @AuraEnabled
        public String childId {get;set;}
        @AuraEnabled
        public Map<String, Object> fields {get;set;}
        
        ChildAccountResult(Child_Account_vod__c childAccount, Address_vod__c address) {
            this.childAccountId = childAccount.Id;
            this.childId = childAccount.Child_Account_vod__c;
            this.parentId = childAccount.Parent_Account_vod__c;
            this.fields = new Map<String,Object>(childAccount.getSObject('Child_Account_vod__r').getPopulatedFieldsAsMap());
            this.fields.put('type', 'Child_Account_vod__c');
            this.fields.put('Name', childAccount.get('Parent_Child_Name_vod__c'));
            this.fields.put('Address_vod__r', constructAddress(address));
        }
        
        String constructAddress(Address_vod__c address) {
            String fullAddress = '';
            if (address != null) {
                List<String> addressFields = new List<String> {'Name', 'City_vod__c', 'State_vod__c','Zip_vod__c','Country_vod__c'};
                for (String addressField : addressFields) {
                    String addressPart = (String) address.get(addressField);
                    if (String.isNotBlank(addressPart)) {
                        if (String.isNotBlank(fullAddress)) {
                            fullAddress += ', ';
                        }
                        fullAddress += addressPart;
                    }
                }
            }
            return fullAddress;
        }
    }

    @AuraEnabled
    public static List<EmAttendeeSelection.AttendeeSelectionView> getViews() {
        List<EmAttendeeSelection.AttendeeSelectionView> views = new List<EmAttendeeSelection.AttendeeSelectionView>();
        Id userId = UserInfo.getUserId();
        Id userProfile = UserInfo.getProfileId();

        for (String veevaMessage : DEFAULT_VIEWS_MESSAGES) {
            List<String> messageParts = veevaMessage.split(';;');
            String messageName = messageParts[0];
            String filterLabel = VeevaMessageController.getMsgWithDefault(messageName, messageParts[1], messageParts[2]);
            views.add(new EmAttendeeSelection.AttendeeSelectionView(VEEVA_MESSAGE_TO_VIEW_ID.get(messageName), filterLabel, false));
        }
        
        //My Accounts views
        List<VeevaMyAccountsViewItem> customViews = VeevaMyAccountsController.getViews();
        for (VeevaMyAccountsViewItem customView : customViews) {
            if ('LOCATION'.equals(customView.source)) {
                views.add(new EmAttendeeSelection.AttendeeSelectionView(customView));
            }
        }
        return views;
    }
}