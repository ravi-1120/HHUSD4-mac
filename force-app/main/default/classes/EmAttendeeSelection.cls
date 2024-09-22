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
public inherited sharing class EmAttendeeSelection {
    
    @TestVisible private class InvalidViewException extends Exception {}
    
    private static final String ACCOUNT = 'Account';
    private static final String PRIMARY_PARENT_RELATIONSHIP = 'Primary_Parent_vod__r';
    private static final String FORMATTED_NAME = 'Formatted_Name_vod__c';
    private static final String PRIMARY_PARENT_FORMATTED_NAME = 'Primary_Parent_vod__r.Formatted_Name_vod__c';
    private static final String ALL_ACCOUNTS = 'all';
    private static final String ALL_PERSON_ACCOUNTS = 'per';
    private static final String ALL_BUSINESS_ACCOUNTS = 'bus';
    private static final String ALL_USERS = 'user';
    private static final String ALL_CONTACTS = 'contact';
    private static final List<String> DEFAULT_VIEWS_MESSAGES = new List<String>{'ALL_ACCOUNTS;;MyAccounts;;All Accounts', 'ALL_PERSON_ACCOUNTS;;iPad;;All Person Accounts', 'ALL_BUSINESS_ACCOUNTS;;iPad;;All Business Accounts', 'ALL_USERS;;Manage_Attendees;;All Users', 'ALL_CONTACTS;;Manage_Attendees;;All Contacts' };
    private static final Map<String, String> VEEVA_MESSAGE_TO_VIEW_ID = new Map<String, String>{ 'ALL_ACCOUNTS' => ALL_ACCOUNTS, 'ALL_PERSON_ACCOUNTS' => ALL_PERSON_ACCOUNTS, 'ALL_BUSINESS_ACCOUNTS' => ALL_BUSINESS_ACCOUNTS, 'ALL_USERS' => ALL_USERS, 'ALL_CONTACTS' => ALL_CONTACTS};
    private static final Map<String, String> DEFAULT_VIEWS_CLAUSES = new Map<String, String>{ ALL_PERSON_ACCOUNTS => 'IsPersonAccount = true', ALL_BUSINESS_ACCOUNTS => 'IsPersonAccount = false', ALL_USERS => 'IsActive = true', ALL_CONTACTS => 'IsPersonAccount = false' };
    private static final Set<String> ATTENDEE_FIELD_KEYWORDS = new Set<String>{'Address','LastTopic', 'RecentEvents', 'MCCP'};
    private static final String DEFAULT_ATTENDEE_RECORD_TYPE_MESSAGE = 'DEFAULT_ATTENDEE_RECORD_TYPE;;MEDICAL_EVENTS';
    private static final String DEFAULT_ATTENDEE_ROLLUP_STATUS_FILTER = 'Signed_vod,Attended_vod';
    private static final String OOT_EVENT_COUNTRY_FILTER = 'Event_Country_vod';
    private static final String OOT_USER_COUNTRY_FILTER = 'User_Country_vod';
    private static final String VEEVA_SETTING_CHILD_ACCOUNT = 'Enable_Child_Account_vod__c';
    public static final String RECORD_TYPE_PREDICATE_TEMPLATE = 'RecordType.DeveloperName IN ({0})';
    public static final String COUNTRY_PREDICATE_TEMPLATE = 'Country_vod__r.Alpha_2_Code_vod__c IN ({0})';
    public static final Integer ATTENDEE_SOQL_QUERY_VIEW_LIMIT = 5000;
    private static final String ADDRESS_INNER_QUERY = '(SELECT Id,Name,Address_line_2_vod__c,City_vod__c,toLabel(State_vod__c),toLabel(Country_vod__c),Zip_vod__c,Primary_vod__c FROM Address_vod__r WHERE Primary_vod__c = true)';
    
    @AuraEnabled(cacheable=true)
    public static Boolean isChildAccountEnabled() {
        Object enableChildAccount = VeevaCustomSettingsService.getVeevaSettings(new List<String> {VEEVA_SETTING_CHILD_ACCOUNT}).get(VEEVA_SETTING_CHILD_ACCOUNT);
        return Schema.sObjectType.EM_Attendee_vod__c.fields.Child_Account_vod__c.isUpdateable() && enableChildAccount != null && Boolean.valueOf(enableChildAccount);
    }

    @AuraEnabled
    public static List<AttendeeResult> getAttendees(String termString, List<String> fields, String viewId, List<String> viewAccountIds, Filters filters, String orderBy, String orderDirection, Integer qLimit, Integer offset, boolean includeAddress, boolean useCustomFieldFormatting) {
        String targetObj = getViewObject(viewId);
        Boolean isSoslSearch = String.isNotBlank(termString);
        List<SObject> attendees = getAttendeesBase(termString, fields, viewId, viewAccountIds, filters, orderBy, orderDirection, qLimit, offset, includeAddress, useCustomFieldFormatting);    
        
        return wrapAttendees(attendees, targetObj, isSoslSearch, includeAddress);
    }

    private static List<SObject> getAttendeesBase(String termString, List<String> fields, String viewId, List<String> viewAccountIds, Filters filters, String orderBy, String orderDirection, Integer qLimit, Integer offset, boolean includeAddress, boolean useCustomFieldFormatting) {
        String targetObj = getViewObject(viewId);
        VeevaBaseObject vbo = VeevaBaseObject.create(targetObj);
        boolean parentAccountDisplayEnabled = getEnableParentAccountDisplaySetting();
        
        fields = useCustomFieldFormatting ? new List<String>(vbo.getAccessibleFieldsWithCustomFormatting(new Set<String>(fields))) :
            new List<String>(vbo.getAccessibleFields(new Set<String>(fields), true, false));

        if (ACCOUNT.equals(targetObj) && parentAccountDisplayEnabled && !fields.contains(PRIMARY_PARENT_FORMATTED_NAME)) {
            fields.add(PRIMARY_PARENT_FORMATTED_NAME);
        }
        List<SObject> results = new List<SObject>();
        if (String.isNotBlank(termString)) {
            String sosl = buildSearch(vbo, termString, fields, viewId, viewAccountIds, filters, orderBy, orderDirection, qLimit, offset);
            results = Search.query(sosl).get(0);
        } else {
            List<String> recordIds = queryViewRecordIds(vbo, viewId, viewAccountIds, filters); // Get the unsorted ids up to ATTENDEE_SOQL_QUERY_VIEW_LIMIT + 1
            List<String> queryFields = new List<String>(fields);
            if (includeAddress) {
                queryFields.add(ADDRESS_INNER_QUERY);
            }
            String soql = buildQuery(vbo, queryFields, viewId, viewAccountIds, filters, orderBy, orderDirection, qLimit, offset, recordIds);
            results = Database.query(soql);
        }
        if (ACCOUNT.equals(targetObj)) {
            stampAccountName(results, parentAccountDisplayEnabled);
        }
        return results;
    }

    private static List<AttendeeResult> wrapAttendees(List<SObject> attendees, String targetObj, boolean isSoslSearch, boolean includeAddress) {
        List<AttendeeResult> attendeeResults = new List<AttendeeResult>();

        if (ACCOUNT.equals(targetObj) && includeAddress) {
            attendeeResults.addAll(getAttendeeAccountResults((List<Account>)attendees, isSoslSearch));
        } else {
            attendeeResults.addAll(getAttendeeResults(attendees));
        }
        return attendeeResults;
    }

    /**
     * Get the record ids for the given view.
     * The point of the query is to avoid long-running ORDER BY clause for large datasets.
     * By querying the records up to a ATTENDEE_SOQL_QUERY_VIEW_LIMIT + 1, avoid timeouts on SOQL queries with ORDER BY clause.
     * 
     * For example, [SELECT Name FROM Account WHERE Id IN (SELECT Id FROM Account LIMIT 5001) ORDER BY Name ASC] is not allowed.
     * Instead, queryViewRecordIds() helps do the following, [SELECT Name FROM Account WHERE Id IN :{queryViewRecordIds()} ORDER BY Name ASC]
     */
    public static List<Id> queryViewRecordIds(VeevaBaseObject vbo, String viewId, List<String> viewAccountIds, Filters filters) {
        List<SObject> objectResults = new List<SObject>();
        List<Id> idResults = new List<Id>();
        String soql = buildQuery(vbo, new List<String> {'Id'}, viewId, viewAccountIds, filters, 'Id', 'ASC', ATTENDEE_SOQL_QUERY_VIEW_LIMIT + 1, 0, new List<Id>());
        objectResults = Database.query(soql);
        for (SObject record : objectResults) {
            idResults.add((Id)record.get('Id'));
        }
        return idResults;
    }

    /**
     * Gets a Record Count for the View up to ATTENDEE_SOQL_QUERY_VIEW_LIMIT + 1 Limit
     */
    @AuraEnabled(cacheable=true)
    public static Integer getQueryCount(String viewId, List<String> viewAccountIds, Filters filters) {
        String targetObj = getViewObject(viewId);
        VeevaBaseObject vbo = VeevaBaseObject.create(targetObj);
        String soql = buildQuery(vbo, new List<String> {'COUNT()'}, viewId, viewAccountIds, filters, '', '', ATTENDEE_SOQL_QUERY_VIEW_LIMIT + 1, 0, new List<Id>());
        return Database.countQuery(soql);
    }    

    @TestVisible
    static String buildQuery(VeevaBaseObject vbo, List<String> fields, String viewId, List<String> viewAccountIds, Filters filters, String orderBy, String orderDirection, Integer qLimit, Integer offset, List<String> recordIds) {
        String soqlTemplate = 'SELECT {0} FROM {1}';
        
        List<Object> parameters = new List<Object> {String.escapeSingleQuotes(String.join(fields, ',')), vbo.getName()};

        if (recordIds != null && !recordIds.isEmpty()) {
            soqlTemplate += whereOrderByLimitWithKnownIds(recordIds, vbo, orderBy, orderDirection, qLimit, offset);
        } else {
            soqlTemplate += whereOrderByLimit(vbo, viewId, viewAccountIds, filters, orderBy, orderDirection, qLimit, offset);
        }
        return String.format(soqlTemplate, parameters);
    }
    
    @TestVisible
    static String buildSearch(VeevaBaseObject vbo, String termString, List<String> fields, String viewId, List<String> viewAccountIds, Filters filters, String orderBy, String orderDirection, Integer qLimit, Integer offset) {
        SOSLQueryHelper helper = new SOSLQueryHelper();
        
        termString = helper.escapeSpecialCharacters(termString);
        List<String> terms = termString.split('\\s+');
        terms = helper.addWildcardToTerms(terms);
        String term = String.join(terms, ' AND ');
        
        String returnFields = String.escapeSingleQuotes(String.join(fields, ','));
        returnFields += whereOrderByLimit(vbo, viewId, viewAccountIds, filters, orderBy, orderDirection, qLimit, offset);
        
        List<Object> parameters = new List<Object> {'{'+term+'}', vbo.getName(), returnFields};
        String soslTemplate = 'FIND {0} IN ALL FIELDS RETURNING {1} ({2})';
        return String.format(soslTemplate, parameters);
    }
    
    static boolean getEnableParentAccountDisplaySetting() {
        Veeva_Settings_vod__c settings = Veeva_Settings_vod__c.getInstance();
        return settings.ENABLE_ACCOUNT_PARENT_DISPLAY_vod__c;
    }
    
    @TestVisible
    static void stampAccountName(List<SObject> rows, boolean appendParentAccountName) {
        for (SObject row : rows) {
            String name = (String) row.get(FORMATTED_NAME);
            if (appendParentAccountName) {
                String parentAccountName = (String) ((SObject) row.getSObject(PRIMARY_PARENT_RELATIONSHIP))?.get(FORMATTED_NAME);
                if (String.isNotBlank(parentAccountName)) {
                    name += ' @ '+parentAccountName;
                }
            }
            row.put('Name', name);
        }
    }
    
    @TestVisible
    static String whereOrderByLimit(VeevaBaseObject vbo, String viewId, List<String> viewAccountIds, Filters filters, String orderBy, String orderDirection, Integer qLimit, Integer offset) {
        String clause = '';
        List<String> whereConditions = new List<String>();
        if (String.isNotEmpty(viewId) && !ALL_ACCOUNTS.equals(viewId)) {
            String viewCondition = getViewWhereClause(viewId, viewAccountIds);
            if (String.isNotBlank(viewCondition)) {
                whereConditions.add(viewCondition);
            }
        }
        if (filters != null && filters.hasFilters())  {
            whereConditions.addAll(filters.getFilterClauses());
        }
        
        if (whereConditions.size() > 0) {
            clause += ' WHERE ';
            clause += String.join(whereConditions, ' AND ');
        }
        
        if (String.isNotBlank(orderBy) && String.isNotBlank(orderDirection)) {
            clause += orderBy(vbo, orderBy, orderDirection);
        }
        if (qLimit != null && offset != null) {
            clause += ' LIMIT ';
            clause += qLimit;
            clause += ' OFFSET ';
            clause += offset;
        }
        return clause;
    }

    @TestVisible
    static String whereOrderByLimitWithKnownIds(List<Id> recordIds, VeevaBaseObject vbo, String orderBy, String orderDirection, Integer qLimit, Integer offset) {
        String clause = ' WHERE Id in :recordIds ';
        List<String> whereConditions = new List<String>();

        if (String.isNotBlank(orderBy) && String.isNotBlank(orderDirection)) {
            clause += orderBy(vbo, orderBy, orderDirection);
        }
        if (qLimit != null && offset != null) {
            clause += ' LIMIT ';
            clause += qLimit;
            clause += ' OFFSET ';
            clause += offset;
        }
        return clause;
    }
    
    @TestVisible
    public static String orderBy(VeevaBaseObject vbo, String orderByField, String orderDirection) {
        String orderByClause = ' ORDER BY {0} {1}';
        DescribeFieldResult describe = vbo.getFieldDescribe(orderByField);
        Boolean isReferenceField = describe.getType() == DisplayType.REFERENCE;
        List<Object> parameters = new List<Object>{ vbo.getAccessibleField(orderByField, isReferenceField, false) };
        if ('desc'.equalsIgnoreCase(orderDirection)) {
            orderDirection += ' NULLS LAST';
        }
        parameters.add(String.escapeSingleQuotes(orderDirection));
        return String.format(orderByClause, parameters);
    }
    
    @TestVisible 
    static String getViewWhereClause(String viewId, List<String> viewAccountIds) {
        String viewKeyPrefix = VeevaBaseObject.create('View_vod__c')?.getDescribe()?.getKeyPrefix();
        String accountListKeyPrefix = VeevaBaseObject.create('Account_List_vod__c')?.getDescribe()?.getKeyPrefix();
        String accountKeyPrefix = VeevaBaseObject.create(ACCOUNT)?.getDescribe()?.getKeyPrefix();
        String clause = '';
        if (DEFAULT_VIEWS_CLAUSES.containsKey(viewId)) {
            clause = DEFAULT_VIEWS_CLAUSES.get(viewId);
        } else if (accountListKeyPrefix != null && viewId.startsWith(accountListKeyPrefix)) {
            clause = 'Id IN (SELECT Account_vod__c from Account_List_Item_vod__c WHERE Account_List_vod__c = \''+viewId+'\')';
        } else if (viewKeyPrefix != null && viewId.startsWith(viewKeyPrefix)) {
            clause = 'Id IN :viewAccountIds';
        } else if (accountKeyPrefix != null && viewId.startsWith(accountKeyPrefix)) {
            clause = 'Id IN (SELECT Child_Account_vod__c FROM Child_Account_vod__c WHERE Parent_Account_vod__c = :viewId)';
        } else {
            throw new InvalidViewException();
        }
        return clause;
    }
    
    @TestVisible
    static String getViewObject(String viewId) {
        String targetObj = ACCOUNT;
        if (ALL_USERS.equals(viewId)) {
            targetObj = 'User';
        } else if (ALL_CONTACTS.equals(viewId)) {
            targetObj = 'Contact';
        }
        return targetObj;
    }

    private static List<AttendeeResult> getAttendeeAccountResults(List<Account> accounts, boolean isSoslSearch) {
        List<AttendeeResult> results = new List<AttendeeResult>();
        if (accounts == null || accounts.isEmpty()) {
            return results;
        }
    
        // Initialize a Set to store account IDs
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
    
        Map<Id, Account> accountsWithAddresses = new Map<Id, Account>();
        if (isSoslSearch) {
            // Perform a single query to get accounts with their primary addresses
            accountsWithAddresses = new Map<Id, Account>(
                [SELECT Id, (SELECT Id, Name, Address_line_2_vod__c, City_vod__c, toLabel(State_vod__c), toLabel(Country_vod__c), Zip_vod__c, Zip_4_vod__c, Primary_vod__c FROM Address_vod__r WHERE Primary_vod__c = true) FROM Account WHERE Id IN :accountIds]
            );
        } else {
            // In case of non-SOSL search, populate the map directly from the provided accounts list
            for (Account acc : accounts) {
                accountsWithAddresses.put(acc.Id, acc);
            }
        }
    
        // Process each account and create AttendeeResult objects
        for (Account acc : accounts) {
            Account accToProcess = accountsWithAddresses.get(acc.Id);
            if (accToProcess != null && accToProcess.Address_vod__r != null && !accToProcess.Address_vod__r.isEmpty()) {
                results.add(new AttendeeResult(acc, constructAddress(accToProcess.Address_vod__r[0])));
            } else {
                results.add(new AttendeeResult(acc, ''));
            }
        }
    
        return results;
    }

    private static List<AttendeeResult> getAttendeeResults(List<SObject> records) {
        List<AttendeeResult> results = new List<AttendeeResult>();
        if (records == null || records.isEmpty()) {
            return results;
        }

        for (SObject record : records) {
            results.add(new AttendeeResult(record, ''));
        }
        return results;
    }

    @AuraEnabled
    public static Integer getParticipantCount(String eventId) {
        Integer eventCount = 0;
        Integer total = 0;
        if (Schema.SObjectType.EM_Event_vod__c.isAccessible() &&
        Schema.SObjectType.EM_Event_vod__c.fields.Start_Time_vod__c.isAccessible()) {
            Datetime currentDatetime = system.now();
            eventCount = [SELECT COUNT() FROM EM_Event_vod__c WHERE Id = :eventId AND Start_Time_vod__c > :currentDatetime];
        }
        if (eventCount != 1) { // specific event not found, return early
            return total;
        }
        if (Schema.SObjectType.EM_Attendee_vod__c.isAccessible() &&
        Schema.SObjectType.EM_Attendee_vod__c.fields.Event_vod__c.isAccessible() &&
        Schema.SObjectType.EM_Attendee_vod__c.fields.Webinar_Participant_URL_vod__c.isAccessible() &&
        Schema.SObjectType.EM_Attendee_vod__c.fields.Webinar_Participant_ID_vod__c.isAccessible()) {
            Integer attendeeCount = [SELECT COUNT() FROM EM_Attendee_vod__c WHERE Event_vod__c = :eventId AND Webinar_Participant_URL_vod__c != null AND Webinar_Participant_ID_vod__c != null];
            total += attendeeCount;
        }
        if (Schema.SObjectType.EM_Event_Speaker_vod__c.isAccessible() &&
        Schema.SObjectType.EM_Event_Speaker_vod__c.fields.Event_vod__c.isAccessible() &&
        Schema.SObjectType.EM_Event_Speaker_vod__c.fields.Webinar_Panelist_URL_vod__c.isAccessible() &&
        Schema.SObjectType.EM_Event_Speaker_vod__c.fields.Webinar_Panelist_ID_vod__c.isAccessible()) {
            Integer speakerCount = [SELECT COUNT() FROM EM_Event_Speaker_vod__c WHERE Event_vod__c = :eventId AND Webinar_Panelist_URL_vod__c != null AND Webinar_Panelist_ID_vod__c != null];
            total += speakerCount;
        }
        
        return total;
    }

    @AuraEnabled 
    public static List<SObject> getExistingAttendees(String eventId) {
        Set<String> queryFields = new Set<String>{'Id', 'Name', 'RecordTypeId', 'Attendee_Name_vod__c', 'Account_vod__c', 'User_vod__c', 'Contact_vod__c', 'Account_vod__r.Formatted_Name_vod__c', 'Account_vod__r.Name', 'Account_vod__r.IsPersonAccount', 'User_vod__r.Name', 'Contact_vod__r.Name', 'Child_Account_vod__c'};
        Boolean isChildAccountEnabled = isChildAccountEnabled();
        if (isChildAccountEnabled) {
            queryFields.addAll(new List<String> {'Child_Account_vod__r.Parent_Child_Name_vod__c', 'Child_Account_vod__r.Child_Account_vod__c'});
        }
        String query = 'SELECT {0} FROM EM_Attendee_vod__c WHERE Event_vod__c = :eventId {1}';
        
        VeevaBaseObject attendeeObj = VeevaBaseObject.create('EM_Attendee_vod__c');
        attendeeObj.addRelationship('Account_vod__r', VeevaBaseObject.create('Account'));
        attendeeObj.addRelationship('Child_Account_vod__r', VeevaBaseObject.create('Child_Account_vod__c'));
        attendeeObj.addRelationship('User_vod__r', VeevaBaseObject.create('User'));
        attendeeObj.addRelationship('Contact_vod__r', VeevaBaseObject.create('Contact'));

        Set<String> accessibleFields = attendeeObj.getAccessibleFields(queryFields);
        List<String> whereFields = new List<String>();
        if (accessibleFields.contains('Account_vod__c')) {
            accessibleFields.add('Account_vod__r.UserRecordAccess.HasReadAccess');
            whereFields.add('Account_vod__c != null');
        }
        if (accessibleFields.contains('User_vod__c')) {
            whereFields.add('User_vod__c != null');
        }
        if (accessibleFields.contains('Contact_vod__c')) {
            accessibleFields.add('Contact_vod__r.UserRecordAccess.HasReadAccess');
            whereFields.add('Contact_vod__c != null');
        }
        if (accessibleFields.contains('Child_Account_vod__c')) {
            accessibleFields.add('Child_Account_vod__r.Child_Account_vod__r.IsPersonAccount');
            accessibleFields.add('Child_Account_vod__r.UserRecordAccess.HasReadAccess');
            accessibleFields.add('Child_Account_vod__r.Child_Account_vod__r.UserRecordAccess.HasReadAccess');
            accessibleFields.add('Child_Account_vod__r.Parent_Account_vod__r.UserRecordAccess.HasReadAccess');
            whereFields.add('Child_Account_vod__c != null');
        }

        List<String> parameters = new List<String>{String.join(new List<String>(accessibleFields), ',')};
        if (whereFields.size() > 0) {
            parameters.add('AND ('+String.join(whereFields, ' OR ')+')');
        } else {
            parameters.add('');
        }
        List<SObject> attendees = new List<SObject>();
        for (SObject attendee : Database.query(String.format(query, parameters))) {
            if(isChildAccountEnabled) {
                if (
                    (attendee.getSObject('Child_Account_vod__r')?.getSObject('Child_Account_vod__r')?.getSObject('UserRecordAccess')?.get('HasReadAccess') == true &&
                    attendee.getSObject('Child_Account_vod__r')?.getSObject('Parent_Account_vod__r')?.getSObject('UserRecordAccess')?.get('HasReadAccess') == true &&
                    attendee.getSObject('Child_Account_vod__r')?.getSObject('UserRecordAccess')?.get('HasReadAccess') == true ) ||
                    attendee.getSObject('Contact_vod__r')?.getSObject('UserRecordAccess')?.get('HasReadAccess') == true ||
                    attendee.getSObject('User_vod__r') != null
                ) {
                    attendees.add(attendee);
                }
            } 
            else if (
                attendee.getSObject('Account_vod__r')?.getSObject('UserRecordAccess')?.get('HasReadAccess') == true ||
                attendee.getSObject('Contact_vod__r')?.getSObject('UserRecordAccess')?.get('HasReadAccess') == true ||
                attendee.getSObject('User_vod__r') != null
            ) {
                attendees.add(attendee);
            }
        }
        return attendees;
    }
    
    @AuraEnabled
    public static List<AttendeeSelectionView> getViews() {
        List<AttendeeSelectionView> views = new List<AttendeeSelectionView>();
        Id userId = UserInfo.getUserId();
        Id userProfile = UserInfo.getProfileId();
        
        for (String veevaMessage : DEFAULT_VIEWS_MESSAGES) {
            List<String> messageParts = veevaMessage.split(';;');
            String messageName = messageParts[0];
            String filterLabel = VeevaMessageController.getMsgWithDefault(messageName, messageParts[1], messageParts[2]);
            views.add(new AttendeeSelectionView(VEEVA_MESSAGE_TO_VIEW_ID.get(messageName), filterLabel, false));
        }
        
        //My Accounts views
        List<VeevaMyAccountsViewItem> customViews = VeevaMyAccountsController.getViews();
        for (VeevaMyAccountsViewItem customView : customViews) {
            if (!'LOCATION'.equals(customView.source)) {
                views.add(new AttendeeSelectionView(customView));
            }
        }
        return views;
    }
    
    @TestVisible
    public class AttendeeSelectionView {
        @AuraEnabled
        public String value {get;set;}
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public Boolean customView {get;set;}
        @AuraEnabled
        public String color {get;set;}
        
        public AttendeeSelectionView(String viewId, String label, boolean customView) {
            this.value = viewId;
            this.label = label;
            this.customView = customView;
            this.color = '';
        }

        public AttendeeSelectionView(String viewId, String label, String color) {
            this.value = viewId;
            this.label = label;
            this.customView = false;
            this.color = String.isNotBlank(color) ? 'vod-'+color : '';
        }

        public AttendeeSelectionView(VeevaMyAccountsViewItem myAccountViewItem) {
            this.value = myAccountViewItem.id;
            this.label = myAccountViewItem.name;
            this.customView = VeevaMyAccountsViewItem.VIEW_TYPE.equals(myAccountViewItem.type);
            this.color = String.isNotBlank(myAccountViewItem.color) ? 'vod-'+myAccountViewItem.color : '';
        }
    }
    
    @AuraEnabled
    public static AttendeeFields getAttendeeFields(String eventId) {
        EM_Event_vod__c event = [SELECT Account_Attendee_Fields_vod__c,User_Attendee_Fields_vod__c,Contact_Attendee_Fields_vod__c FROM EM_Event_vod__c WHERE Id = :eventId];
        return new AttendeeFields(event);
    }
    
    @TestVisible
    private class AttendeeFields {
        @AuraEnabled
        public List<AttendeeField> Account {get;set;}
        @AuraEnabled
        public List<AttendeeField> User {get;set;}
        @AuraEnabled
        public List<AttendeeField> Contact {get;set;}
        
        public AttendeeFields(EM_Event_vod__c event) {
            this.Account = parseFields(event.Account_Attendee_Fields_vod__c, VeevaBaseObject.create('Account'));
            this.User = parseFields(event.User_Attendee_Fields_vod__c, VeevaBaseObject.create('User'));
            this.Contact = parseFields(event.Contact_Attendee_Fields_vod__c, VeevaBaseObject.create('Contact'));
        }
        
        private List<AttendeeField> parseFields(String fields, VeevaBaseObject vbo) {
            List<AttendeeField> attendeeFields = new List<AttendeeField>();
            if (String.isNotBlank(fields)) {
                for (String field : fields.split(';;')) {
                    field = field.trim();
                    if (ATTENDEE_FIELD_KEYWORDS.contains(field)) {
                        attendeeFields.add(new AttendeeField(field));
                    } else {
                        DescribeFieldResult fieldDescribe = vbo.getFieldDescribe(field);
                        if (fieldDescribe == null) {
                            field += '__c';
                            fieldDescribe = vbo.getFieldDescribe(field);
                        }
                        if (fieldDescribe != null && fieldDescribe.isAccessible()) {
                            attendeeFields.add(new AttendeeField(field, fieldDescribe.getLabel()));
                        }
                    }
                }
            }
            
            return attendeeFields;
        }
    }
    
    @TestVisible
    private class AttendeeField {
        @AuraEnabled
        public String apiName {get;set;}
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public boolean isKeyword {get;set;}
        
        public AttendeeField(String field) {
            this.apiName = field;
            this.isKeyword = true;
        }

        public AttendeeField(String apiName, String label) {
            this.apiName = apiName;
            this.label = label;
        }
    }
    
    @AuraEnabled
    public static String getAttendeeRecordType(String eventRecordTypeId) {
        String recordTypeId = null;
        if (String.isBlank(eventRecordTypeId)) {
            return recordTypeId;
        }
        VeevaBaseObject attendeeObj = VeevaBaseObject.create('EM_Attendee_vod__c');
        VeevaBaseObject eventObj = VeevaBaseObject.create('EM_Event_vod__c');
        String currentEventRecordTypeName = eventObj.getDescribe().getRecordTypeInfosById()?.get(eventRecordTypeId)?.getDeveloperName();
        
        Veeva_Settings_vod__c veevaSettings = Veeva_Settings_vod__c.getInstance();
        String defaultAttendeeRecordTypeMessage = veevaSettings?.DEFAULT_ATTENDEE_RECORD_TYPE_vod__c;
        if (DEFAULT_ATTENDEE_RECORD_TYPE_MESSAGE.equals(defaultAttendeeRecordTypeMessage)) {
            String[] message = DEFAULT_ATTENDEE_RECORD_TYPE_MESSAGE.split(';;');
            defaultAttendeeRecordTypeMessage = VeevaMessageController.getMsgWithDefault(message[0], message[1], '');
        }
        
        if (String.isNotBlank(defaultAttendeeRecordTypeMessage)) {
            Map<String, RecordTypeInfo> attendeeRecordTypeMap = attendeeObj.getDescribe().getRecordTypeInfosByDeveloperName();
            for(String recordTypePair: defaultAttendeeRecordTypeMessage.split(';;')) {
                String[] mapping = recordTypePair.split(',');
                String eventRecordType = mapping[0];
                if (String.isNotBlank(currentEventRecordTypeName) && currentEventRecordTypeName.equals(eventRecordType)) {
                    RecordTypeInfo rt = attendeeRecordTypeMap?.get(mapping[1]);
                    if (rt != null && rt.isAvailable()) {
                        recordTypeId = rt.getRecordTypeId();
                    }
                    break;
                }
            }
        }
        if (String.isBlank(recordTypeId)) { 
            for (Schema.RecordTypeInfo recordType : attendeeObj.getDescribe().getRecordTypeInfos()) {
                if (recordType.isDefaultRecordTypeMapping() && !recordType.isMaster()) {
                    recordTypeId = recordType.getRecordTypeId();
                }
            }
        }
        return recordTypeId;
    }
    
    @AuraEnabled
    public static String getLastTopicDate(String objectName, String recordId, String eventId, String eventTopic) {
        String attendeeRollupStatusFilter = Events_Management_Settings_vod__c.getInstance().ATTENDEE_ROLLUP_STATUS_FILTER_vod__c;
        if (String.isNotBlank(attendeeRollupStatusFilter) && attendeeRollupStatusFilter.contains(';;')) {
            String[] message = attendeeRollupStatusFilter.split(';;');
            attendeeRollupStatusFilter = VeevaMessageController.getMsgWithDefault(message[0], message[1], '');
        }
        List<String> attendeeStatuses = new List<String>();
        if (String.isBlank(attendeeRollupStatusFilter)) {
            attendeeStatuses = DEFAULT_ATTENDEE_ROLLUP_STATUS_FILTER.split(',');
        } else {
            attendeeStatuses = attendeeRollupStatusFilter.split(',');
        }
        String soql = 'SELECT Id, FORMAT(Event_vod__r.Start_Time_vod__c) FROM EM_Attendee_vod__c WHERE ';
        soql += objectName;
        soql += '_vod__c = :recordId'; 
        soql += ' AND Status_vod__c IN :attendeeStatuses AND Event_vod__c != :eventId AND Event_vod__c != null AND Event_vod__r.Topic_vod__c != null AND Event_vod__r.Topic_vod__c = :eventTopic AND Event_vod__r.Status_vod__c != \'Canceled_vod\''; 
        soql += ' AND (Event_vod__r.Start_Time_vod__c <= TODAY OR Status_vod__c != \'Rejected_vod\')'; 
        soql += ' ORDER BY Event_vod__r.Start_Time_vod__c DESC LIMIT 1';
        List<EM_Attendee_vod__c> attendeeLastTopic = Database.query(soql);
        String lastTopicDate = '';
        if (attendeeLastTopic?.size() > 0) {
            lastTopicDate = Datetime.parse((String) attendeeLastTopic.get(0).getSObject('Event_vod__r').get('Start_Time_vod__c')).date().format();
        }
        return lastTopicDate;
    }
    
    @AuraEnabled
    public static List<EM_Attendee_vod__c> getRecentEvents(String objectName, Id recordId, Id eventId) {
        String soql = 'SELECT Event_vod__r.Name, Event_vod__r.Start_Time_vod__c, Event_vod__r.Owner.Name, toLabel(Status_vod__c) FROM EM_Attendee_vod__c WHERE {0}_vod__c = :recordId AND Event_vod__c != null AND Event_vod__c != :eventId ORDER BY Event_vod__r.Start_Time_vod__c DESC LIMIT 10';
        return Database.query(String.format(soql, new List<String>{objectName}));
    }
    
    @AuraEnabled(cacheable=true)
    public static EmOutsideTerritoryRule getOutsideTerritoryRule(Id eventId, Id eventConfig, Id eventCountry) {
        Set<String> allQueryFields = new Set<String>{'Search_Outside_Territory_vod__c', 'Search_Outside_Territory_Record_Type_vod__c', 'Search_Outside_Territory_Filter_vod__c', 'Country_Override_vod__c'};
        EmOutsideTerritoryRule ootRule = new EmOutsideTerritoryRule();
        
        VeevaBaseObject eventRuleObj = VeevaBaseObject.create(EM_Event_Rule_vod__c.SObjectType);
        Set<String> accessibleFields = eventRuleObj.getAccessibleFields(allQueryFields);
        List<Object> args = new List<Object>{String.join(new List<String>(accessibleFields),',')};
            
        if (accessibleFields.contains('Search_Outside_Territory_vod__c') && accessibleFields.contains('Country_Override_vod__c')) {
            String query = String.format('SELECT {0} FROM EM_Event_Rule_vod__c WHERE Event_Configuration_vod__c = :eventConfig AND RecordType.DeveloperName = \'Attendee_Fields_vod\' AND (Country_Override_vod__c = null OR Country_Override_vod__r.Country_vod__c = :eventCountry) ORDER BY Country_Override_vod__c NULLS LAST', args);
            List<EM_Event_Rule_vod__c> attendeeFieldsRules = Database.query(query);
            if (attendeeFieldsRules.size() > 0) {
                EM_Event_Rule_vod__c eventRule = attendeeFieldsRules.get(0);
                ootRule.enabled = eventRule.Search_Outside_Territory_vod__c;
                if (accessibleFields.contains('Search_Outside_Territory_Record_Type_vod__c') && String.isNotBlank(eventRule.Search_Outside_Territory_Record_Type_vod__c)) {
                    ootRule.recordTypeDeveloperNames = new List<String>(eventRule.Search_Outside_Territory_Record_Type_vod__c.split(';'));
                }
                if (accessibleFields.contains('Search_Outside_Territory_Filter_vod__c') && String.isNotBlank(eventRule.Search_Outside_Territory_Filter_vod__c)) {
                    if (eventRule.Search_Outside_Territory_Filter_vod__c.contains(OOT_USER_COUNTRY_FILTER)) {
                        User user = [SELECT Country FROM User WHERE Id = :UserInfo.getUserId()];
                        ootRule.addCountry(user?.Country);
                    }
                    if (eventRule.Search_Outside_Territory_Filter_vod__c.contains(OOT_EVENT_COUNTRY_FILTER)) {
                        Country_vod__c country = [SELECT Alpha_2_Code_vod__c FROM Country_vod__c WHERE Id = :eventCountry];
                        ootRule.addCountry(country?.Alpha_2_Code_vod__c);
                    }
                }
            }
        }
        return ootRule;
    }
    
    public class EmOutsideTerritoryRule {
        @AuraEnabled
        public boolean enabled {get;set;}
        @AuraEnabled
        public List<String> recordTypeDeveloperNames {get;set;}
        @AuraEnabled
        public List<String> countryCodes {get;set;}
        
        public EmOutsideTerritoryRule() {
            this.enabled = false;
            this.recordTypeDeveloperNames = new List<String>();
            this.countryCodes = new List<String>();
        }
        
        void addCountry(String countryCode) {
            if (String.isNotBlank(countryCode)) {
                countryCodes.add(countryCode);
            }
        }
    }

    public class Filters {
        final Pattern RECORD_TYPE_PATTERN = Pattern.compile('[A-Za-z\\d_]+'); // Only alphanumerics and underscores
        final Pattern COUNTRY_CODE_PATTERN = Pattern.compile('[A-Z]{2}'); // Only 2 Capital alphabet characters
        public List<String> ootRecordTypes {get;set;}
        public List<String> ootCountries {get;set;}
        String recordTypePredicateTemplate {get;set;}
        String countryPredicateTemplate {get;set;}
        
        public Filters() {
            ootRecordTypes = new List<String>();
            ootCountries = new List<String>();
        }

        public Filters setRecordTypePredicateTemplate(String template) {
            recordTypePredicateTemplate = template;
            return this;
        }

        public Filters setCountryPredicateTemplate(String template) {
            countryPredicateTemplate = template;
            return this;
        }

        public Filters setOutOfTerritoryRecordTypes(List<String> recordTypeDeveloperNames) {
            ootRecordTypes = recordTypeDeveloperNames;
            return this;
        }
        
        public Filters setOutOfTerritoryCountries(List<String> countryCodes) {
            for (String countryCode : countryCodes) {
                if (COUNTRY_CODE_PATTERN.matcher(countryCode).matches()) {
                    ootCountries.add(countryCode);
                }
            }
            return this;
        }
        
        public boolean hasFilters() {
            return ootRecordTypes.size() > 0 || ootCountries.size() > 0;
        }
        
        public List<String> getFilterClauses() {
            List<String> conditions = new List<String>();
            List<String> recordTypeDeveloperNames = new List<String>();
            List<String> countryCodes = new List<String>();
            
            if (this.ootRecordTypes.size() > 0) {
                for (String recordTypeDeveloperName : this.ootRecordTypes) {
                    if (RECORD_TYPE_PATTERN.matcher(recordTypeDeveloperName).matches()) {
                        recordTypeDeveloperNames.add(recordTypeDeveloperName);
                    }
                }
            }
            if (this.ootCountries.size() > 0) {
                for (String countryCode : this.ootCountries) {
                    if (COUNTRY_CODE_PATTERN.matcher(countryCode).matches()) {
                        countryCodes.add(countryCode);
                    }
                }
            }
            
            if (recordTypeDeveloperNames.size() > 0) {
                List<String> arguments = new List<String>{ '\'' + String.join(recordTypeDeveloperNames, '\',\'') + '\'' };
                String recordTypeFilter = String.format(recordTypePredicateTemplate, arguments);
                conditions.add(recordTypeFilter);
            }
            if (countryCodes.size() > 0) {
                List<String> arguments = new List<String>{ '\'' + String.join(countryCodes, '\',\'') + '\'' };
                String countryFilter = String.format(countryPredicateTemplate, arguments);
                conditions.add(countryFilter);
            }
            return conditions;
        }
    }

    private static String constructAddress(Address_vod__c address) {
        String fullAddress = '';
        if (address != null) {
            List<String> addressFields = new List<String> {'Name', 'Address_line_2_vod__c', 'City_vod__c', 'State_vod__c','Zip_vod__c','Country_vod__c'};
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

    public class AttendeeResult {
        @AuraEnabled
        public SObject record {get; set;}
        @AuraEnabled
        public String address {get; set;}

        public AttendeeResult(SObject record, String address) {
            this.record = record;
            this.address = address;
        }
    }
}