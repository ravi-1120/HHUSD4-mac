public with sharing virtual class VeevaBusinessCalendarService {
    private static final String CALENDAR_RELATIONSHIP_NAME = Calendar_Event_vod__c.Calendar_vod__c.getDescribe().getRelationshipName();
    private static final Set<String> CALENDAR_EVENT_QUERY_FIELDS = new Set<String>{
        'Id',
        'Name',
        'Start_Date_vod__c',
        'End_Date_vod__c',
        'Start_Time_Local_vod__c',
        'End_Time_Local_vod__c',
        'Time_Zone_vod__c',
        'Description_vod__c',
        'Important_vod__c',
        CALENDAR_RELATIONSHIP_NAME + '.RecordType.DeveloperName'
    };
    private static final Set<String> CALENDAR_EVENT_FORMATTED_QUERY_FIELDS = new Set<String>{ CALENDAR_RELATIONSHIP_NAME + '.RecordTypeId' };
    private static final List<String> CALENDAR_EVENT_NON_NULL_FIELDS = new List<String>{
        'Start_Date_vod__c',
        'End_Date_vod__c',
        'Start_Time_Local_vod__c',
        'End_Time_Local_vod__c'
    };

    private static final Set<String> MC_CYCLE_QUERY_FIELDS = new Set<String>{ 'Id', 'Name', 'Start_Date_vod__c', 'End_Date_vod__c' };
    private static final Set<String> MC_CYCLE_FORMATTED_QUERY_FIELDS = new Set<String>{ 'Status_vod__c', 'RecordTypeId' };
    private static final List<String> MC_CYCLE_NON_NULL_FIELDS = new List<String>{ 'Start_Date_vod__c', 'End_Date_vod__c' };

    private static final String PRODUCT_RELATIONSHIP_NAME = Campaign_vod__c.Product_vod__c.getDescribe().getRelationshipName();
    private static final String DETAIL_GROUP_RELATIONSHIP_NAME = Campaign_vod__c.Detail_Group_vod__c.getDescribe().getRelationshipName();
    private static final Set<String> CAMPAIGN_QUERY_FIELDS = new Set<String>{
        'Id',
        'Name',
        'Start_Date_vod__c',
        'End_Date_vod__c',
        PRODUCT_RELATIONSHIP_NAME + '.Name',
        PRODUCT_RELATIONSHIP_NAME + '.Brand_Color_Code_vod__c',
        DETAIL_GROUP_RELATIONSHIP_NAME + '.Name'
    };
    private static final Set<String> CAMPAIGN_FORMATTED_QUERY_FIELDS = new Set<String>{ 'Status_vod__c' };
    private static final List<String> CAMPAIGN_NON_NULL_FIELDS = new List<String>{ 'Start_Date_vod__c', 'End_Date_vod__c' };

    private static final String ACCOUNT_RELATIONSHIP_NAME = Account_Plan_vod__c.Account_vod__c.getDescribe().getRelationshipName();
    private static final Set<String> ACCOUNT_PLAN_QUERY_FIELDS = new Set<String>{
        'Id',
        'Name',
        'Start_Date_vod__c',
        'End_Date_vod__c',
        'Progress_vod__c',
        ACCOUNT_RELATIONSHIP_NAME + '.Formatted_Name_vod__c'
    };
    private static final Set<String> ACCOUNT_PLAN_FORMATTED_QUERY_FIELDS = new Set<String>{ 'RecordTypeId' };
    private static final List<String> ACCOUNT_PLAN_NON_NULL_FIELDS = new List<String>{ 'Start_Date_vod__c', 'End_Date_vod__c' };

    private final VeevaBaseObject calendarEventObj;
    private final VeevaBaseObject mcCycleObj;
    private final VeevaBaseObject campaignObj;
    private final VeevaBaseObject accountPlanObj;

    public VeevaBusinessCalendarService() {
        calendarEventObj = VeevaBaseObject.create(Calendar_Event_vod__c.getSObjectType());
        calendarEventObj?.addRelationship(CALENDAR_RELATIONSHIP_NAME, VeevaBaseObject.create(Calendar_vod__c.getSObjectType()));
        calendarEventObj?.mapRelationships(new List<String>(CALENDAR_EVENT_QUERY_FIELDS));

        mcCycleObj = VeevaBaseObject.create(MC_Cycle_vod__c.getSObjectType());

        campaignObj = VeevaBaseObject.create(Campaign_vod__c.getSObjectType());
        campaignObj?.addRelationship(PRODUCT_RELATIONSHIP_NAME, VeevaBaseObject.create(Product_vod__c.getSObjectType()));
        campaignObj?.addRelationship(DETAIL_GROUP_RELATIONSHIP_NAME, VeevaBaseObject.create(Product_vod__c.getSObjectType()));
        campaignObj?.mapRelationships(new List<String>(CAMPAIGN_QUERY_FIELDS));

        accountPlanObj = VeevaBaseObject.create(Account_Plan_vod__c.getSObjectType());
        accountPlanObj?.addRelationship(ACCOUNT_RELATIONSHIP_NAME, VeevaBaseObject.create(Account.getSObjectType()));
        accountPlanObj?.mapRelationships(new List<String>(ACCOUNT_PLAN_QUERY_FIELDS));
    }

    public List<Calendar_Event_vod__c> getCalendarEvents() {
        if (!hasCalendarEventOLS()) {
            return new List<Calendar_Event_vod__c>();
        }

        // Combine the two sets of fields we want to validate.
        // Note that CALENDAR_EVENT_FORMATTED_QUERY_FIELDS is not yet formatted here; that is because it's more difficult to validate the field
        // strings after they've been wrapped by VeevaBaseObject.applyToLabelAndFormat.
        Set<String> fieldsToValidate = new Set<String>(calendarEventObj.getAccessibleFields(CALENDAR_EVENT_QUERY_FIELDS));
        fieldsToValidate.addAll(calendarEventObj.getAccessibleFields(CALENDAR_EVENT_FORMATTED_QUERY_FIELDS));
        if (!hasCalendarEventFLS(fieldsToValidate)) {
            return new List<Calendar_Event_vod__c>();
        }

        // Query and return the Calendar Event objects with the specified formatted fields if user has OLS and FLS.
        // Only return objects that have non-null values for the fields described in `CALENDAR_EVENT_NON_NULL_FIELDS`
        Set<String> formattedFieldsToQuery = new Set<String>(calendarEventObj.getAccessibleFields(CALENDAR_EVENT_QUERY_FIELDS));
        formattedFieldsToQuery.addAll(calendarEventObj.getAccessibleFields(CALENDAR_EVENT_FORMATTED_QUERY_FIELDS, true, false));
        List<Calendar_Event_vod__c> accessibleRecords = Database.query(
            String.format(
                'SELECT {0} FROM Calendar_Event_vod__c WHERE {1}.Status_vod__c = \'Active_vod\' AND {2}',
                new List<String>{
                    String.join(new List<String>(formattedFieldsToQuery), ', '),
                    CALENDAR_RELATIONSHIP_NAME,
                    getNonNullFieldsQueryString(CALENDAR_EVENT_NON_NULL_FIELDS)
                }
            )
        );

        return filterRecordsWithValidStartEndDateTimes(accessibleRecords);
    }

    public List<MC_Cycle_vod__c> getMCCycles() {
        if (!hasMCCycleOLS()) {
            return new List<MC_Cycle_vod__c>();
        }

        // Combine the two sets of fields we want to validate.
        // Note that MC_CYCLE_FORMATTED_QUERY_FIELDS is not yet formatted here; that is because it's more difficult to validate the field
        // strings after they've been wrapped by VeevaBaseObject.applyToLabelAndFormat.
        Set<String> fieldsToValidate = new Set<String>(mcCycleObj.getAccessibleFields(MC_CYCLE_QUERY_FIELDS));
        fieldsToValidate.addAll(mcCycleObj.getAccessibleFields(MC_CYCLE_FORMATTED_QUERY_FIELDS));
        if (!hasMCCycleFLS(fieldsToValidate)) {
            return new List<MC_Cycle_vod__c>();
        }

        // Query and return the MC Cycle objects with the specified formatted fields if user has OLS and FLS.
        // Only return objects that have non-null values for the fields described in `MC_CYCLE_NON_NULL_FIELDS`
        Set<String> formattedFieldsToQuery = new Set<String>(mcCycleObj.getAccessibleFields(MC_CYCLE_QUERY_FIELDS));
        formattedFieldsToQuery.addAll(mcCycleObj.getAccessibleFields(MC_CYCLE_FORMATTED_QUERY_FIELDS, true, false));
        List<MC_Cycle_vod__c> accessibleRecords = Database.query(
            String.format(
                'SELECT {0} FROM MC_Cycle_vod__c WHERE {1}',
                new List<String>{ String.join(new List<String>(formattedFieldsToQuery), ', '), getNonNullFieldsQueryString(MC_CYCLE_NON_NULL_FIELDS) }
            )
        );

        return filterRecordsWithValidStartEndDates(accessibleRecords);
    }

    public List<Campaign_vod__c> getCampaigns() {
        if (!hasCampaignOLS()) {
            return new List<Campaign_vod__c>();
        }

        // Combine the two sets of fields we want to validate.
        // Note that CAMPAIGN_FORMATTED_QUERY_FIELDS is not yet formatted here; that is because it's more difficult to validate the field
        // strings after they've been wrapped by VeevaBaseObject.applyToLabelAndFormat.
        Set<String> fieldsToValidate = new Set<String>(campaignObj.getAccessibleFields(CAMPAIGN_QUERY_FIELDS));
        fieldsToValidate.addAll(campaignObj.getAccessibleFields(CAMPAIGN_FORMATTED_QUERY_FIELDS));
        if (!hasCampaignFLS(fieldsToValidate)) {
            return new List<Campaign_vod__c>();
        }

        // Query and return the Campaign objects with the specified formatted fields if user has OLS and FLS.
        // Only return objects that have non-null values for the fields described in `CAMPAIGN_NON_NULL_FIELDS`
        Set<String> formattedFieldsToQuery = new Set<String>(campaignObj.getAccessibleFields(CAMPAIGN_QUERY_FIELDS));
        formattedFieldsToQuery.addAll(campaignObj.getAccessibleFields(CAMPAIGN_FORMATTED_QUERY_FIELDS, true, false));
        List<Campaign_vod__c> accessibleRecords = Database.query(
            String.format(
                'SELECT {0} FROM Campaign_vod__c WHERE {1}',
                new List<String>{ String.join(new List<String>(formattedFieldsToQuery), ', '), getNonNullFieldsQueryString(CAMPAIGN_NON_NULL_FIELDS) }
            )
        );

        return filterRecordsWithValidStartEndDates(accessibleRecords);
    }

    public List<Account_Plan_vod__c> getAccountPlans() {
        if (!hasAccountPlanOLS()) {
            return new List<Account_Plan_vod__c>();
        }

        // Combine the two sets of fields we want to validate.
        // Note that ACCOUNT_PLAN_FORMATTED_QUERY_FIELDS is not yet formatted here; that is because it's more difficult to validate the field
        // strings after they've been wrapped by VeevaBaseObject.applyToLabelAndFormat.
        Set<String> fieldsToValidate = new Set<String>(accountPlanObj.getAccessibleFields(ACCOUNT_PLAN_QUERY_FIELDS));
        fieldsToValidate.addAll(accountPlanObj.getAccessibleFields(ACCOUNT_PLAN_FORMATTED_QUERY_FIELDS));
        if (!hasAccountPlanFLS(fieldsToValidate)) {
            return new List<Account_Plan_vod__c>();
        }

        // Query and return the Account Plan objects with the specified formatted fields if user has OLS and FLS.
        // Only return objects that have non-null values for the fields described in `ACCOUNT_PLAN_NON_NULL_FIELDS`
        Set<String> formattedFieldsToQuery = new Set<String>(accountPlanObj.getAccessibleFields(ACCOUNT_PLAN_QUERY_FIELDS));
        formattedFieldsToQuery.addAll(accountPlanObj.getAccessibleFields(ACCOUNT_PLAN_FORMATTED_QUERY_FIELDS, true, false));
        List<Account_Plan_vod__c> accessibleRecords = Database.query(
            String.format(
                'SELECT {0} FROM Account_Plan_vod__c WHERE Active_vod__c=true AND {1}',
                new List<String>{
                    String.join(new List<String>(formattedFieldsToQuery), ', '),
                    getNonNullFieldsQueryString(ACCOUNT_PLAN_NON_NULL_FIELDS)
                }
            )
        );

        return filterRecordsWithValidStartEndDates(accessibleRecords);
    }

    protected virtual boolean hasCalendarEventOLS() {
        return calendarEventObj != null;
    }

    protected virtual boolean hasCalendarEventFLS(Set<String> userAccessibleFieldsToQuery) {
        return userAccessibleFieldsToQuery.containsAll(CALENDAR_EVENT_QUERY_FIELDS) &&
            userAccessibleFieldsToQuery.containsAll(CALENDAR_EVENT_FORMATTED_QUERY_FIELDS);
    }

    protected virtual boolean hasMCCycleOLS() {
        return mcCycleObj != null;
    }

    protected virtual boolean hasMCCycleFLS(Set<String> userAccessibleFieldsToQuery) {
        return userAccessibleFieldsToQuery.containsAll(MC_CYCLE_QUERY_FIELDS) &&
            userAccessibleFieldsToQuery.containsAll(MC_CYCLE_FORMATTED_QUERY_FIELDS);
    }

    protected virtual boolean hasCampaignOLS() {
        return campaignObj != null;
    }

    protected virtual boolean hasCampaignFLS(Set<String> userAccessibleFieldsToQuery) {
        return userAccessibleFieldsToQuery.containsAll(CAMPAIGN_QUERY_FIELDS) &&
            userAccessibleFieldsToQuery.containsAll(CAMPAIGN_FORMATTED_QUERY_FIELDS);
    }

    protected virtual boolean hasAccountPlanOLS() {
        return accountPlanObj != null;
    }

    protected virtual boolean hasAccountPlanFLS(Set<String> userAccessibleFieldsToQuery) {
        return userAccessibleFieldsToQuery.containsAll(ACCOUNT_PLAN_QUERY_FIELDS) &&
            userAccessibleFieldsToQuery.containsAll(ACCOUNT_PLAN_FORMATTED_QUERY_FIELDS);
    }

    private List<SObject> filterRecordsWithValidStartEndDateTimes(List<SObject> recordsToFilter) {
        List<SObject> filteredRecords = new List<SObject>();
        for (SObject record : recordsToFilter) {
            Date startDate = (Date) record.get('Start_Date_vod__c');
            Time startTime = (Time) record.get('Start_Time_Local_vod__c');
            Date endDate = (Date) record.get('End_Date_vod__c');
            Time endTime = (Time) record.get('End_Time_Local_vod__c');
            if (VeevaDateValidationHelper.areStartDateTimeAndEndDateTimeValid(startDate, startTime, endDate, endTime)) {
                filteredRecords.add(record);
            }
        }

        return filteredRecords;
    }

    private List<SObject> filterRecordsWithValidStartEndDates(List<SObject> recordsToFilter) {
        List<SObject> filteredRecords = new List<SObject>();
        for (SObject record : recordsToFilter) {
            Date startDate = (Date) record.get('Start_Date_vod__c');
            Date endDate = (Date) record.get('End_Date_vod__c');
            if (VeevaDateValidationHelper.areStartDateAndEndDateValid(startDate, endDate)) {
                filteredRecords.add(record);
            }
        }

        return filteredRecords;
    }

    private static String getNonNullFieldsQueryString(List<String> fieldNames) {
        if (fieldNames.isEmpty()) {
            return '';
        }

        String clause = fieldNames.get(0) + ' != null';
        for (Integer i = 1; i < fieldNames.size(); i++) {
            clause += String.format(' AND {0} != null', new List<String>{ fieldNames.get(i) });
        }

        return clause;
    }
}