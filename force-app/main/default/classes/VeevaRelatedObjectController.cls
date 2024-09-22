public with sharing class VeevaRelatedObjectController {
    @AuraEnabled
    public static List<SObject> getRelatedRecords(
        String fields,
        String objectApiName,
        String relationField,
        String id,
        Integer qlimit,
        Integer offset,
        String sortBy,
        String sortDirection,
        Boolean formatFields,
        Boolean duplicateRawFields,
        Map<String, List<String>> filters
    ) {
        try {
            List<String> fieldsList = fields.split(',');
            if (String.isBlank(sortBy)) {
                sortBy = 'Name';
            }
            if ('DESC'.equalsIgnoreCase(sortDirection)) {
                sortDirection = 'DESC NULLS LAST';
            }
            if (formatFields == null) {
                formatFields = true;
            }
            if (duplicateRawFields == null) {
                duplicateRawFields = false;
            }
            fieldsList.add('Owner.Name');

            return queryRelatedObjects(
                fieldsList,
                objectApiName,
                relationField,
                id,
                formatFields,
                duplicateRawFields,
                qlimit,
                offset,
                sortBy,
                sortDirection,
                filters
            );
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<SObject> searchRelatedRecords(
        String fields,
        String objectApiName,
        String relationField,
        String id,
        Integer qlimit,
        Integer offset,
        String sortBy,
        String sortDirection,
        Boolean formatFields,
        Boolean duplicateRawFields,
        String searchTerm,
        Map<String, List<String>> filters
    ) {
        try {
            List<String> fieldsList = fields.split(',');
            if (String.isBlank(sortBy)) {
                sortBy = 'Name';
            }
            if ('DESC'.equalsIgnoreCase(sortDirection)) {
                sortDirection = 'DESC NULLS LAST';
            }
            if (formatFields == null) {
                formatFields = true;
            }
            if (duplicateRawFields == null) {
                duplicateRawFields = false;
            }

            return searchRelatedObjects(
                fieldsList,
                objectApiName,
                relationField,
                id,
                formatFields,
                duplicateRawFields,
                qlimit,
                offset,
                sortBy,
                sortDirection,
                searchTerm,
                filters
            );
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<SObject> getRecordsById(
        List<String> ids,
        String fields,
        String objectApiName,
        Boolean formatFields,
        Boolean duplicateRawFields
    ) {
        try {
            List<String> fieldsList = fields.split(',');
            if (formatFields == null) {
                formatFields = true;
            }
            if (duplicateRawFields == null) {
                duplicateRawFields = false;
            }
            return queryObjects(ids, fieldsList, objectApiName, formatFields, duplicateRawFields);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Integer getRelatedRecordsCount(String childObject, String referenceFieldName, String objectId, Map<String, List<String>> filters) {
        try {
            VeevaBaseObject veevaBaseObj = VeevaBaseObject.create(childObject);
            String stmt = 'SELECT COUNT()';
            stmt += ' FROM ' + String.escapeSingleQuotes(childObject);
            stmt += buildWhereClause(veevaBaseObj, referenceFieldName, filters);
            Integer result = Database.countQuery(stmt);
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> getRelatedObjects(VeevaWiredWrapperParams wrapper) {
        String referenceFieldName = wrapper.referenceFieldName;
        if (referenceFieldName == null) {
            return null;
        }
        List<String> queryParams = wrapper.queryParams;
        String childObject = wrapper.childObject;
        String objectId = wrapper.objectId;

        return queryRelatedObjects(queryParams, childObject, referenceFieldName, objectId, true, true, null, null, null, null, null);
    }

    private static List<SObject> queryRelatedObjects(
        List<String> queryParams,
        String childObject,
        String referenceFieldName,
        String objectId,
        Boolean applyToLabelOrFormat,
        Boolean duplicateRawFields,
        Integer qlimit,
        Integer offset,
        String sortBy,
        String sortDirection,
        Map<String, List<String>> filters
    ) {
        VeevaBaseObject veevaBaseObj = createVeevaBaseObject(queryParams, childObject);
        Set<String> formattedQueryParams = getFormattedQueryParams(queryParams, veevaBaseObj, applyToLabelOrFormat, duplicateRawFields);

        List<SObject> result = new List<SObject>();
        if (formattedQueryParams != null && formattedQueryParams.size() > 0) {
            String stmt = 'SELECT ' + String.join(new List<String>(formattedQueryParams), ',');
            stmt += ' FROM ' + String.escapeSingleQuotes(childObject);
            stmt += buildWhereOrderByLimitClause(veevaBaseObj, referenceFieldName, qlimit, offset, sortBy, sortDirection, filters);
            result = Database.query(stmt);
        }
        return result;
    }

    private static List<SObject> searchRelatedObjects(
        List<String> queryParams,
        String childObject,
        String referenceFieldName,
        String objectId,
        Boolean applyToLabelOrFormat,
        Boolean duplicateRawFields,
        Integer qlimit,
        Integer offset,
        String sortBy,
        String sortDirection,
        String searchTerm,
        Map<String, List<String>> filters
    ) {
        SOSLQueryHelper helper = new SOSLQueryHelper();
        VeevaBaseObject veevaBaseObj = createVeevaBaseObject(queryParams, childObject);
        Set<String> formattedQueryParams = getFormattedQueryParams(queryParams, veevaBaseObj, applyToLabelOrFormat, duplicateRawFields);

        searchTerm = helper.escapeSpecialCharacters(searchTerm);
        List<String> terms = searchTerm.split('\\s+');
        terms = helper.addWildcardToTerms(terms);
        String term = String.join(terms, ' AND ');

        String returnFields = String.escapeSingleQuotes(String.join(formattedQueryParams, ','));
        returnFields += buildWhereOrderByLimitClause(veevaBaseObj, referenceFieldName, qlimit, offset, sortBy, sortDirection, filters);

        List<Object> parameters = new List<Object>{ '{' + term + '}', childObject, returnFields };
        String soslTemplate = 'FIND {0} IN ALL FIELDS RETURNING {1} ({2})';
        String soslQueryString = String.format(soslTemplate, parameters);
        return Search.query(soslQueryString).get(0);
    }

    private static String buildWhereOrderByLimitClause(
        VeevaBaseObject veevaBaseObj,
        String referenceFieldName,
        Integer qlimit,
        Integer offset,
        String sortBy,
        String sortDirection,
        Map<String, List<String>> filters
    ) {
        String clause = buildWhereClause(veevaBaseObj, referenceFieldName, filters);
        if (String.isNotBlank(sortBy)) {
            clause += ' ORDER BY ' + String.escapeSingleQuotes(sortBy);
            if (String.isNotBlank(sortDirection)) {
                clause += ' ' + String.escapeSingleQuotes(sortDirection);
            }
        }
        if (qlimit != null) {
            clause += ' LIMIT :qlimit';
            if (offset != null) {
                clause += ' OFFSET :offset';
            }
        }
        return clause;
    }

    private static String buildWhereClause(VeevaBaseObject veevaBaseObj, String referenceFieldName, Map<String, List<String>> filters) {
        String clause = ' WHERE ' + String.escapeSingleQuotes(referenceFieldName) + ' = :objectId';

        if (filters == null) {
            return clause;
        }

        for (String fieldName : filters.keySet()) {
            DescribeFieldResult fieldDescribe = veevaBaseObj.getFieldDescribe(fieldName);
            List<String> fieldValues = filters.get(fieldName);
            if (fieldDescribe != null && fieldValues != null && !fieldValues.isEmpty()) {
                list<String> escapedFieldValues = escapeStringList(fieldValues);
                clause += ' AND ' + String.escapeSingleQuotes(fieldName) + ' IN (';
                if (fieldDescribe.getType() == Schema.DisplayType.BOOLEAN) {
                    clause += String.join(escapedFieldValues, ',');
                } else {
                    clause += '\'' + String.join(escapedFieldValues, '\',\'') + '\'';
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

    private static List<SObject> queryObjects(
        List<String> ids,
        List<String> queryParams,
        String childObject,
        Boolean applyToLabelOrFormat,
        Boolean duplicateRawFields
    ) {
        VeevaBaseObject veevaBaseObj = createVeevaBaseObject(queryParams, childObject);
        Set<String> formattedQueryParams = getFormattedQueryParams(queryParams, veevaBaseObj, applyToLabelOrFormat, duplicateRawFields);
        List<SObject> result = new List<SObject>();
        if (formattedQueryParams != null && formattedQueryParams.size() > 0) {
            String stmt = 'SELECT ' + String.join(new List<String>(formattedQueryParams), ',');
            stmt += ' FROM ' + String.escapeSingleQuotes(childObject);
            stmt += ' WHERE ' + 'Id IN ' + ':ids';
            result = Database.query(stmt);
        }
        return result;
    }

    private static VeevaBaseObject createVeevaBaseObject(List<String> queryParams, String childObject) {
        VeevaBaseObject veevaBaseObj = VeevaBaseObject.create(childObject);
        Map<String, String> defaultRelationships = new Map<String, String>{'OwnerId' => 'User'};
        veevaBaseObj.mapRelationships(queryParams, defaultRelationships);
        return veevaBaseObj;
    }

    private static Set<String> getFormattedQueryParams(
        List<String> queryParams,
        VeevaBaseObject veevaBaseObj,
        Boolean applyToLabelOrFormat,
        Boolean duplicateRawFields
    ) {
        Set<String> formattedQueryParams = new Set<String>();
        for (String param : queryParams) {
            String formattedField = veevaBaseObj.getAccessibleField(param, applyToLabelOrFormat, duplicateRawFields);
            if (formattedField == null && param == 'Owner.NameOrAlias'){
                formattedField = veevaBaseObj.getAccessibleField('Owner.Alias', applyToLabelOrFormat, duplicateRawFields);
                if (formattedField == null) {
                    formattedField = veevaBaseObj.getAccessibleField('Owner.Name', applyToLabelOrFormat, duplicateRawFields);
                }
                if (formattedField == 'Owner.Alias'|| formattedField == 'Owner.Name'){
                    formattedField = 'Owner.NameOrAlias';
                }
            }
            if (formattedField != null) {
                if (formattedField.indexOf(',') != -1) {
                    List<String> splitFields = formattedField.split(',', 2);
                    formattedQueryParams.addAll(splitFields);
                } else {
                    formattedQueryParams.add(formattedField);
                }
            }
        }
        return formattedQueryParams;
    }
}