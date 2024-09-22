public with sharing class VeevaRelatedListFilterController {
    @AuraEnabled
    public static List<FilterGroup> getFilters(
        String objectApiName,
        String referenceFieldName,
        String recordId,
        List<String> filterFields,
        Map<String, List<String>> nonGroupableFieldValues
    ) {
        List<FilterGroup> filterGroups = new List<FilterGroup>();

        if (filterFields == null) {
            return filterGroups;
        }

        VeevaBaseObject veevaBaseObj = VeevaBaseObject.create(objectApiName);

        for (String filterField : filterFields) {
            DescribeFieldResult fieldDescribe = veevaBaseObj.getFieldDescribe(filterField);

            if (!fieldDescribe.isAccessible()) {
                continue;
            }

            List<String> availableFieldValues = getAvailableFieldValues(
                veevaBaseObj,
                fieldDescribe,
                referenceFieldName,
                recordId,
                nonGroupableFieldValues
            );

            FilterGroup filterGroup = createFilterGroup(veevaBaseObj, fieldDescribe, availableFieldValues);

            if (!filterGroup.options.isEmpty()) {
                filterGroups.add(filterGroup);
            }
        }
        return filterGroups;
    }

    private static List<String> getAvailableFieldValues(
        VeevaBaseObject veevaBaseObj,
        DescribeFieldResult fieldDescribe,
        String referenceFieldName,
        String recordId,
        Map<String, List<String>> nonGroupableFieldValues
    ) {
        List<String> fieldValues = new List<String>();

        String objectApiName = veevaBaseObj.getName();
        String fieldName = fieldDescribe.getName();

        if (fieldDescribe.isGroupable()) {
            String soqlTemplate = 'SELECT {0} FROM {1} WHERE {2} = :recordId GROUP BY {0}';
            List<Object> parameters = new List<Object>{ fieldName, objectApiName, referenceFieldName };
            String soqlQueryString = String.format(soqlTemplate, parameters);
            List<AggregateResult> aggregateResults = Database.query(soqlQueryString);
            for (AggregateResult ar : aggregateResults) {
                fieldValues.add(String.valueOf(ar.get(fieldName)));
            }
        } else if (nonGroupableFieldValues != null && nonGroupableFieldValues.containsKey(fieldName)) {
            for (String fieldValue : nonGroupableFieldValues.get(fieldName)) {
                String soqlTemplate = 'SELECT Id FROM {0} WHERE {1} = :recordId AND {2} = :fieldValue LIMIT 1';
                List<Object> parameters = new List<Object>{ objectApiName, referenceFieldName, fieldName };
                String soqlQueryString = String.format(soqlTemplate, parameters);
                List<SObject> results = Database.query(soqlQueryString);
                if (!results.isEmpty()) {
                    fieldValues.add(fieldValue);
                }
            }
        }
        return fieldValues;
    }

    private static FilterGroup createFilterGroup(VeevaBaseObject veevaBaseObj, DescribeFieldResult fieldDescribe, List<String> availableFieldValues) {
        FilterGroup filterGroup = new FilterGroup(fieldDescribe);
        List<Filter> options = filterGroup.options;

        if (fieldDescribe.getName() == 'RecordTypeId') {
            filterGroup.fieldLabel = VOD_VEEVA_MESSAGE.getMsgWithDefault('RECORD_TYPE_LABEL', 'Common', 'Record Type');
            Map<ID, Schema.RecordTypeInfo> recordTypeIdMap = veevaBaseObj.getDescribe().getRecordTypeInfosById();
            for (String reecordTypeId : availableFieldValues) {
                Schema.RecordTypeInfo recordTypeInfo = recordTypeIdMap.get(reecordTypeId);
                if (recordTypeInfo != null) {
                    Filter option = new Filter(recordTypeInfo.getRecordTypeId(), recordTypeInfo.getName());
                    options.add(option);
                }
            }
        } else if (fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
            for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                if (availableFieldValues.contains(entry.getValue())) {
                    Filter option = new Filter(entry.getValue(), entry.getLabel());
                    options.add(option);
                }
            }
        } else {
            for (String availableFieldValue : availableFieldValues) {
                Filter option = new Filter(availableFieldValue, availableFieldValue);
                options.add(option);
            }
        }
        options.sort();
        return filterGroup;
    }

    public class FilterGroup {
        @AuraEnabled
        public String fieldName { get; set; }
        @AuraEnabled
        public String fieldLabel { get; set; }
        @AuraEnabled
        public List<Filter> options { get; set; }

        public FilterGroup(DescribeFieldResult field) {
            this.fieldName = field.getName();
            this.fieldLabel = field.getLabel();
            this.options = new List<Filter>();
        }
    }

    public class Filter implements Comparable {
        @AuraEnabled
        public String value { get; set; }
        @AuraEnabled
        public String label { get; set; }

        public Filter(String value, String label) {
            this.value = value;
            this.label = label;
        }

        public Integer compareTo(Object compareTo) {
            Filter compareToFilter = (Filter) compareTo;
            return label.compareTo(compareToFilter.label);
        }
    }
}