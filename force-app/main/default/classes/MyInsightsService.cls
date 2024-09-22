public with sharing class MyInsightsService {
    private static final Map<Schema.SObjectType, List<String>> OBJECT_TO_REPORT_TYPES = new Map<Schema.SObjectType, List<String>>{
        null => new List<String>{'\'Territory_Insights_vod\'', '\'Territory_Insights_Default_vod\''},
        Account.SObjectType => new List<String>{'\'KOL_Profile_vod\'', '\'Account_Profile_Override_vod\'', '\'Account_Reports_vod\''},
        Account_Plan_vod__c.SObjectType => new List<String>{'\'Account_Plan_vod\''},
        Inventory_Monitoring_vod__c.SObjectType => new List<String>{'\'Inventory_Monitoring_vod\''},
        Order_vod__c.SObjectType => new List<String>{'\'Orders_vod\''}
    };

    private static final Map<Schema.SObjectType, List<String>> REPORT_OVERRIDES = new Map<Schema.SObjectType, List<String>>{
        null => new List<String>{'Territory_Insights_Default_vod'},
        Account.SObjectType => new List<String>{'KOL_Profile_vod', 'Account_Profile_Override_vod'}
    };

    @AuraEnabled(cacheable=true)
    public static String getFirstTSFIdMatchingUserTerritoryNames(String accountId) {
        List<String> userTerritoryNames = getUserTerritoryNames();
        List<TSF_vod__c> sortedTSFRecordsByTerritoryNameForAccount = [SELECT Id FROM TSF_vod__c WHERE Account_vod__c = :accountId AND Territory_vod__c in :userTerritoryNames ORDER BY Territory_vod__c ASC LIMIT 1];
        String firstTSFIdMatchingUserTerritoryNamesForAccount;
        if (sortedTSFRecordsByTerritoryNameForAccount.size() > 0) {
            firstTSFIdMatchingUserTerritoryNamesForAccount = sortedTSFRecordsByTerritoryNameForAccount.get(0).Id;
        } else {
            firstTSFIdMatchingUserTerritoryNamesForAccount = null;
        }
        return firstTSFIdMatchingUserTerritoryNamesForAccount;
    }

    @AuraEnabled(cacheable=true)
    public static List<HTML_Report_vod__c> getVisibleHTMLReports(Id recordId, MyInsightsReportOptionId reportValue) {
        Boolean allReports = reportValue.id == null;
        if (!allReports && !reportValue.isValid()) {
            String errorMessage = 'Invalid HTML Report Id';
            AuraHandledException error = new AuraHandledException(errorMessage);
            error.setMessage(errorMessage);
            throw error;
        }

        // Check that user has OLS to HTML_Report_vod__c
        // If not, return an empty list
        VeevaBaseObject reportPermissions = VeevaBaseObject.create(HTML_Report_vod__c.getSObjectType());
        if (reportPermissions == null) {
            return new List<HTML_Report_vod__c>();
        }

        Boolean statusFLS = reportPermissions.getAccessibleField('Status_vod__c', false, false) != null;
        Boolean platformFLS = reportPermissions.getAccessibleField('Platform_vod__c', false, false) != null;
        if (allReports && (!platformFLS || !statusFLS)) {
            // Without FLS access to Status_vod__c or Platform_vod__c, we treat all reports as unpublished
            // (when report was not already specified)
            return new List<HTML_Report_vod__c>();
        }
        Schema.SObjectType currObject = recordId?.getSobjectType();
        Boolean visCriteriaFLS = reportPermissions.getAccessibleField('Visibility_Criteria_vod__c', false, false) != null;
        List<String> validOverrides = REPORT_OVERRIDES.get(currObject);

        List<HTML_Report_vod__c> validReports = queryReports(recordId, reportValue.id, currObject, allReports, visCriteriaFLS, validOverrides, reportPermissions);
        List<HTML_Report_vod__c> filteredReports = filterAndTranslateReports(validReports, visCriteriaFLS, currObject, recordId, validOverrides);
        Boolean overridePresent = validOverrides != null && filteredReports.size() > 0 &&
            validOverrides.contains(filteredReports.get(0).RecordType.DeveloperName);

        // We need to wrap the HTML Reports so we can sort them case insensitively
        // List.sort() accounts for case when sorting
        List<HTMLReportWrapper> wrappedReports = wrapReports(filteredReports);
        alphabetizeReports(wrappedReports, overridePresent);
        List<HTML_Report_vod__c> reports = new List<HTML_Report_vod__c>();
        for (HTMLReportWrapper currWrapper : wrappedReports) {
            reports.add(currWrapper.report);
        }
        return reports;
    }

    @AuraEnabled
    public static Map<String, String> getPicklistLabelsByValue(String objectName, String fieldName) {
        try {
            return retrievePicklistLabelsByValue(objectName, fieldName);
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage()); // This is necessary for unit tests
            throw ex;
        }
    }

    @AuraEnabled(cacheable=true)
    public static boolean verifyContentPresentOnCdn(String requestUrl) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(requestUrl);
		req.setMethod('GET');
        HttpResponse response = http.send(req);
        return response.getStatusCode() == 200;
    }

    private static List<String> getUserTerritoryNames() {
        TerritoryManagement2 territoryManagement = new TerritoryManagement2();
        Set<Id> userTerritoryIds = territoryManagement.getUserTerritories(UserInfo.getUserId());
        List<Territory2> userTerritories = [SELECT Name,Territory2ModelId FROM Territory2 WHERE Id in :userTerritoryIds And Territory2Model.State='Active'];
        return getTerritoryNames(userTerritories);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getUserTerritoryHierarchy() {
        List<Map<String, String>> userTerritoryHierarchy = VeevaTerritoryController.getUserTerritoryHierarchy(UserInfo.getUserId());
        return userTerritoryHierarchy;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getUserTerritories() {
        TerritoryManagement2 territoryManagement = new TerritoryManagement2();
        Set<Id> userTerritoryIds = territoryManagement.getUserTerritories(UserInfo.getUserId());
        List<Territory2> userTerritories = [SELECT Name, Id, DeveloperName, ParentTerritory2Id, Description,Territory2ModelId FROM Territory2 WHERE Id in :userTerritoryIds And Territory2Model.State='Active'];
        return territoryManagement.extractSObject(userTerritories).values();
    }

    private static List<String> getTerritoryNames(List<Territory2> territories) {
        List<String> territoryNames = new List<String>();
        for (Territory2 territory : territories) {
            territoryNames.add(territory.Name);
        }
        return territoryNames;
    }

    private static Map<String, String> retrievePicklistLabelsByValue(String objectName, String fieldName) {
        Map<String, String> picklistLabelsByValue = new Map<String, String>();
        Schema.SObjectType objectType = getSObjectType(objectName);
        if (objectType == null) {
            throw createAuraHandledException(objectName + ' is not a recognized Object Name');
        }

        Schema.SObjectField sObjectField = getSObjectField(objectType, fieldName);
        if (sObjectField == null) {
            throw createAuraHandledException(fieldName + ' is not a recognized field name for ' + objectName);
        }
        Schema.DescribeFieldResult fieldDescribe = sObjectField.getDescribe();
        if (!isPicklistType(fieldDescribe)) {
            throw createAuraHandledException(fieldName + ' is not a picklist field type for ' + objectName);
        }

        List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
        for (Schema.PicklistEntry picklistValue : picklistValues) {
            picklistLabelsByValue.put(picklistValue.value, picklistValue.label);
        }

        return picklistLabelsByValue;
    }

    private static Schema.SObjectType getSObjectType(String objectName) {
        Type typeOfObject = Type.forName(objectName);
        if (typeOfObject != null) {
            return ((SObject) typeOfObject.newInstance()).getSObjectType();
        } else {
            return null;
        }
    }

    private static Schema.SObjectField getSObjectField(Schema.SObjectType sobjectType, String fieldName) {
        Schema.DescribeSObjectResult objectDescribeResult = sobjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objectDescribeResult.fields.getMap();
        Schema.SObjectField sObjectField = fieldMap.get(fieldName);
        return sObjectField;
    }

    private static boolean isPicklistType(Schema.DescribeFieldResult fieldDescribe) {
        return fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST;
    }

    private static AuraHandledException createAuraHandledException(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message); // This is necessary for unit tests
        return ex;
    }

    private static List<HTML_Report_vod__c> queryReports(Id recordId, String reportId,  Schema.SObjectType currObject, Boolean allReports,
        Boolean hasVisibilityCriteriaFLS, List<String> validOverrides, VeevaBaseObject reportPermissions) {
        Map<String, Object> queryBindMap = new Map<String, Object>();

        String reportQuery = 'SELECT {0} FROM HTML_Report_vod__c WHERE Platform_vod__c includes (\'Lightning_vod\')';
        if (!allReports) {
            reportQuery += ' AND External_Id_vod__c = :reportId';
            queryBindMap.put('reportId', reportId);
        } else {
            Id profileId = UserInfo.getProfileId();
            reportQuery += ' AND (Profile_vod__c = :profileId OR Profile_vod__c = null)';
            queryBindMap.put('profileId', profileId);

            Boolean isKOL = false;
            if (recordId != null) {
                SObject currInfo = getObjectInfo(recordId, currObject).get(0);
                isKOL = isObjectKOL(currInfo, currObject);
                reportQuery += generateObjectRecordTypeCondition(currInfo);
            }

            List<String> validReportTypes;
            if (!isKOL && currObject == Account.SObjectType) {
                // Removing KOL report from validReportTypes and validOverrides
                validReportTypes = OBJECT_TO_REPORT_TYPES.get(currObject);
                validReportTypes.remove(0);
                validOverrides.remove(0);
            } else {
                validReportTypes = OBJECT_TO_REPORT_TYPES.get(currObject);
            }
            reportQuery += ' AND RecordType.DeveloperName IN ' + validReportTypes + ' AND Status_vod__c = \'Published_vod\'';
        }
        reportQuery += ' ORDER BY LastModifiedDate DESC';
        try {
            Boolean studioIdFLS = reportPermissions.getAccessibleField('Studio_Id_vod__c', false, false) != null;
            Boolean externalIdFLS = reportPermissions.getAccessibleField('External_Id_vod__c', false, false) != null;

            List<String> queryFields = new List<String>{'Id', 'Name', 'RecordType.DeveloperName'};

            // If the user does not have FLS to Visibility_Criteria_vod__c, Studio_Id_vod__c or External_Id_vod__c, we can completely ignore the field
            if (hasVisibilityCriteriaFLS) {
                queryFields.add('Visibility_Criteria_vod__c');
            }
            if (studioIdFLS) {
                queryFields.add('Studio_Id_vod__c');
            }
            if (externalIdFLS) {
                queryFields.add('External_Id_vod__c');
            }
            return Database.queryWithBinds(
                String.format(reportQuery, new List<String>{String.join(queryFields, ',')}),
                queryBindMap,
                AccessLevel.SYSTEM_MODE);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<SObject> getObjectInfo(String recordId, Schema.SObjectType currObject) {
        String objectInfoQuery = 'SELECT {0} FROM ' + currObject + ' WHERE Id = \'' + recordId + '\'';
        List<String> queryFields = new List<String>{'RecordTypeId'};
        if (currObject == Account.SObjectType) {
            queryFields.add('KOL_vod__c');
        }
        List<SObject> objectInfoResult;
        try {
            return Database.query(String.format(objectInfoQuery, new List<String>{String.join(queryFields, ',')}));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Boolean isObjectKOL(SObject result, Schema.SObjectType currObject) {
        return currObject == Account.SObjectType && (Boolean) result.get('KOL_vod__c');
    }

    private static String generateObjectRecordTypeCondition(SObject result) {
        Object recordTypeId = result.get('RecordTypeId');
        if (recordTypeId != null) {
            return ' AND (Object_RecordType_Id_vod__c = \'' + recordTypeId.toString() + '\' OR Object_RecordType_Id_vod__c = null)';
        }
        return '';
    }

    private static List<HTML_Report_vod__c> filterAndTranslateReports(List<HTML_Report_vod__c> reports, Boolean visCriteriaFLS,
        Schema.SObjectType currObject, Id recordId, List<String> validOverrides) {
        List<HTML_Report_vod__c> filteredReports = new List<HTML_Report_vod__c>();
        Boolean overridePresent = false;
        Map<String, SObject> cachedCriteria = new Map<String, SObject>();
        for (HTML_Report_vod__c currReport : reports) {
            currReport.Name = getTranslatedReportNameOrDefault(currReport);
            if (recordId != null && visCriteriaFLS && currReport.Visibility_Criteria_vod__c != null) {
                if (checkVisibilityCriteria(currReport, currObject, recordId, cachedCriteria)) {
                    overridePresent = addReport(filteredReports, currReport, overridePresent, validOverrides);
                }
            } else {
                overridePresent = addReport(filteredReports, currReport, overridePresent, validOverrides);
            }
        }
        return filteredReports;
    }

    private static String getTranslatedReportNameOrDefault(HTML_Report_vod__c report) {
        // Checking if the name matches the format of Veeva Messages
        String[] messageParts = report.Name.split(';;');
        if (messageParts.size() == 2) {
            String message = VeevaMessageController.getMsgWithDefault(messageParts[0], messageParts[1], null);
            if (message != null) {
                return message;
            }
        }
        return report.Name;
    }

    private static Boolean addReport(List<HTML_Report_vod__c> reports, HTML_Report_vod__c report, Boolean overridePresent, List<String> validOverrides) {
        if (!overridePresent && validOverrides != null && validOverrides.contains(report.RecordType.DeveloperName)) {
            addOverride(reports, report);
            return true;
        }
        reports.add(report);
        return overridePresent;
    }

    private static List<HTMLReportWrapper> wrapReports(List<HTML_Report_vod__c> reports) {
        List<HTMLReportWrapper> wrappedReports = new List<HTMLReportWrapper>();
        for (HTML_Report_vod__c currReport : reports) {
            wrappedReports.add(new HTMLReportWrapper(currReport));
        }
        return wrappedReports;
    }

    private static Boolean checkVisibilityCriteria(HTML_Report_vod__c currReport, Schema.SObjectType currObject, Id recordId,
        Map<String, SObject> cachedCriteria) {
        // Check that user has OLS to current object
        // If not, do not insert the report and return false
        VeevaBaseObject currObjPermissions = VeevaBaseObject.create(currObject);
        if (currObjPermissions == null) {
            return false;
        }

        // If field is invalid or user does not have FLS access to field, it should be shown automatically
        // (existing behavior in MyInsights)
        String[] criteriaParts = currReport.Visibility_Criteria_vod__c.trim().split('\\.');
        String criteriaObject = null;
        String criteriaField = null;
        if (criteriaParts.size() == 2) {
            criteriaObject = criteriaParts[0];
            criteriaField = criteriaParts[1];
        } else {
            return true;
        }
        Map<String, Schema.SObjectField> fieldMap = currObject.getDescribe().fields.getMap();
        Boolean validField  = currObject.getDescribe().getName().equals(criteriaObject)
            && fieldMap.containsKey(criteriaField.toLowerCase());
        Boolean fieldFLS = validField && currObjPermissions.getAccessibleField(criteriaField, false, false) != null;

        SObject currCriteria = null;
        Schema.DisplayType fieldType = null;
        if (validField && fieldFLS) {
            // Checking if the object's criteriaField has already been queried for
            // If it has, retrieve the cached value
            // If it hasn't, conduct a query
            if (!cachedCriteria.containsKey(criteriaField)) {
                String visibilityCriteriaQuery = 'SELECT ' + criteriaField + ' FROM ' + currObject + ' WHERE Id = :recordId';
                Map<String, Object> queryBindMap = new Map<String, Object>();
                queryBindMap.put('recordId', recordId);
                List<SObject> criteriaResults = new List<SObject>();
                try {
                    criteriaResults = Database.queryWithBinds(visibilityCriteriaQuery, queryBindMap, AccessLevel.SYSTEM_MODE);
                } catch (Exception e) {
                    throw new AuraHandledException(e.getMessage());
                }
                currCriteria = criteriaResults[0];

                // Caching response for possible future use
                cachedCriteria.put(criteriaField, currCriteria);
            } else {
                currCriteria = cachedCriteria.get(criteriaField);
            }
            fieldType = fieldMap.get(criteriaField.toLowerCase()).getDescribe().getType();
        }
        // Copy of original logic in MyInsights for checking if a report should be displayed or not
        // Optional chaining is unnecessary for fieldType and currCriteria because if they are null, validField = true
        if (!validField || !fieldFLS || !fieldType.equals(Schema.DisplayType.BOOLEAN) || currCriteria.get(criteriaField) == true) {
            return true;
        }
        return false;
    }

    private static void addOverride(List<HTML_Report_vod__c> reports, HTML_Report_vod__c overrideToAdd) {
        if (reports.size() > 0) {
            reports.add(0, overrideToAdd);
        } else {
            reports.add(overrideToAdd);
        }
    }

    private static void alphabetizeReports(List<HTMLReportWrapper> reports, Boolean overridePresent) {
        HTMLReportWrapper overridingReport;
        if (reports.size() > 1) {
            if (overridePresent) {
                overridingReport = reports.remove(0);
            }
            reports.sort();
            if (overridePresent) {
                reports.add(0, overridingReport);
            }
        }
    }

    private class HTMLReportWrapper implements Comparable {
        private HTML_Report_vod__c report;

        private HTMLReportWrapper(HTML_Report_vod__c report) {
            if (report == null) {
                Exception ex = new NullPointerException();
                ex.setMessage('Report argument cannot be null');
                throw ex;
            }
            this.report = report;
        }

        public Integer compareTo(Object compareTo) {
            HTMLReportWrapper compareToWrapper = (HTMLReportWrapper) compareTo;
            return report.Name.toLowerCase().compareTo(compareToWrapper.report.Name.toLowerCase());
        }
    }
}