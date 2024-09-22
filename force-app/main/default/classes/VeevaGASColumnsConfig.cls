public inherited sharing class VeevaGASColumnsConfig {

    private static Map<String, SObjectType> globalDescribe = Schema.getGlobalDescribe();

    /**
     * List to maintain result set fields in order
     */
    private List<String> orderedResultSetFields;

    /**
     * Map of fields to be queried for Account and Address_vod__c objects
     */
    private Map<String, List<String>> objectQueryFields;

    /**
     * Map of fields to be retrieved for Account and Address_vod__c objects
     */
    private Map<String, List<String>> objectResultFields;

    /**
     * Map to hold Schema.DescribeSObjectResult information for Account and Address_vod__c objects
     */
    private Map<String, Schema.DescribeSObjectResult> sObjectDescribeMap;

    /**
     * List of Address Fields For Parent Account Addresses
     */
    private List<String> PARENT_ADDRESS_FIELDS = new List<String> { 'Id', 'Account_vod__c', 'Primary_vod__c', 'Name', 'Address_Line_2_vod__c', 'City_vod__c', 'State_vod__c', 'Zip_vod__c' };

    /**
     * List of Address Fields Required For Fetching Parent Account Addresses
     */
    private List<String> REQ_PARENT_ADDRESS_FIELDS = new List<String> { 'Account_vod__c', 'Primary_vod__c', 'CreatedDate' };

    /**
     * List of fields required by GAS to perform the search
     */
    private Map<String, List<String>> gasRequiredFields;

    public VeevaGASColumnsConfig(Map<String, List<String>> requiredFields, List<String> orderedFields){
        objectQueryFields = new Map<String, List<String>>();
        objectResultFields = new Map<String, List<String>>();
        this.gasRequiredFields = requiredFields;
        this.orderedResultSetFields = orderedFields;
        initializeObjectDescribeMap();
    }

    private void initializeObjectDescribeMap(){
        Schema.DescribeSObjectResult accountSObjectDescribe = globalDescribe.get('Account').getDescribe();
        Schema.DescribeSObjectResult addressCustomSObjectDescribe = globalDescribe.get('Address_vod__c').getDescribe();
        sObjectDescribeMap = new Map<String, Schema.DescribeSObjectResult>();
        sObjectDescribeMap.put('account', accountSObjectDescribe);
        sObjectDescribeMap.put('address_vod__c', addressCustomSObjectDescribe);
    }

    /**
     * Method to update objectQueryFields and objectResultFields
     */
    public void addObjectFields(String objectName, List<String> objFields) {
        objectQueryFields.put(objectName, getFormattedObjectFields(objectName, objFields, true));
        objectResultFields.put(objectName, getFormattedObjectFields(objectName, objFields, false));
    }

    public List<String> getObjectQueryFields(String objectName){
        List<String> objectFields = objectQueryFields.get(objectName);
        if (objectFields == null) {
            objectFields = new List<String>();
        }
        return objectFields;
    }

    public List<String> getObjectResultFields(String objectName){
        List<String> objectFields = objectResultFields.get(objectName);
        if (objectFields == null) {
            objectFields = new List<String>();
        }
        return objectFields;
    }

    public List<Map<String, String>> getResultSetMetadata(){
        return getResultSetFieldsInfo(this.orderedResultSetFields);
    }

    private List<String> getFormattedObjectFields(String objectName, List<String> fields, boolean fieldsForQuery){
        List<String> formattedFields = new List<String>();
        //Skip fields if an incorrect object name is provided
        if (sObjectDescribeMap.containsKey(objectName)){
            Schema.DescribeSObjectResult sObjectDescribe = sObjectDescribeMap.get(objectName);
            Map<String, Schema.SObjectField> objectFieldsMap = sObjectDescribe.fields.getMap();
            List<String> objRequiredFields = gasRequiredFields.get(objectName);
            for (String field : fields){
                List<String> fieldNameInfo = field.split('\\.');
                if (objectFieldsMap.get(fieldNameInfo[1]) != null){
                    Schema.DescribeFieldResult fldDesc = objectFieldsMap.get(fieldNameInfo[1]).getDescribe();
                    //Skip field if inaccessible and not a required field for search
                    if ((fldDesc.isAccessible() || objRequiredFields.contains(fldDesc.getName()))
                        && fldDesc.getName().equals(fieldNameInfo[1])){
                        String formattedFieldInfo = getFieldDetailForProcessing(fldDesc, fieldNameInfo, fieldsForQuery);
                        if (!formattedFields.contains(formattedFieldInfo)){
                            formattedFields.add(formattedFieldInfo);
                        }
                    }
                }
            }
        }
        return formattedFields;
    }

    private List<Map<String, String>> getResultSetFieldsInfo(List<String> resultSetFields){
        List<Map<String, String>> resultSetInfo = new List<Map<String, String>>();        
        for (String field : resultSetFields){
            List<String> fieldNameInfo = field.split('\\.');
            String objectName = fieldNameInfo[0].trim();
            String fieldName = fieldNameInfo[1].trim();
            if (sObjectDescribeMap.containsKey(objectName.toLowerCase())){
                Schema.DescribeSObjectResult sObjectDescribe = sObjectDescribeMap.get(objectName.toLowerCase());
                Map<String, Schema.SObjectField> objectFieldsMap = sObjectDescribe.fields.getMap();
                if (objectFieldsMap.get(fieldName) != null){
                    Map<String, String> fieldInfo = new Map<String, String>();
                    Schema.DescribeFieldResult fldDesc = objectFieldsMap.get(fieldName).getDescribe();
                    if (fldDesc.isAccessible() && fldDesc.getName().equals(fieldName)){
                        fieldInfo.put('label', getLabelForField(fldDesc, fieldNameInfo));
                        fieldInfo.put('objectName', objectName);
                        fieldInfo.put('fieldName', objectName + '.' + getFieldDetailForProcessing(fldDesc, fieldNameInfo, false));
                        resultSetInfo.add(fieldInfo);
                    }
                }
            }
        }
        return resultSetInfo;
    }

    private String getFieldDetailForProcessing(Schema.DescribeFieldResult fldDesc, List<String> fieldNameInfo, Boolean fieldsForQuery){
        String fieldDetail;
        if (fldDesc.getType() == Schema.DisplayType.REFERENCE){
            String refFieldName = (fieldNameInfo.size() > 2) ? fieldNameInfo[2] : 'Name';
            if (fieldsForQuery && !String.isEmpty(fldDesc.getRelationshipName())){
                fieldDetail = applyTranslationPrefixIfApplicable(fldDesc.getRelationshipName(), refFieldName);
            } else {
                fieldDetail = fieldNameInfo[1] + '.' + refFieldName;
            }
        } else if ((fldDesc.getType() == Schema.DisplayType.PICKLIST || fldDesc.getType() == Schema.DisplayType.MULTIPICKLIST) && fieldsForQuery){
            fieldDetail = 'toLabel(' + fieldNameInfo[1] + ')';
        } else {
            fieldDetail = fieldNameInfo[1];
        }
        return fieldDetail;
    }

    private String applyTranslationPrefixIfApplicable(String relationshipName, String fieldName){
        String fieldInfo;
        //Apply toLabel prefix if the field is Record Type Name
        if (relationshipName.equalsIgnoreCase('RecordType') && fieldName.equalsIgnoreCase('Name')){
            fieldInfo = 'toLabel(' + relationshipName + '.' + fieldName + ')';
        } else {
            fieldInfo = relationshipName + '.' + fieldName;
        }
        return fieldInfo;
    }

    private String getLabelForField(Schema.DescribeFieldResult fieldDesc, List<String> fieldNameInfo){
        String fieldLabel;
        if (fieldDesc.getType() == Schema.DisplayType.REFERENCE && fieldNameInfo.size() > 2){
            for (Schema.SObjectType sObjType : fieldDesc.getReferenceTo()){
                Map<String, Schema.SObjectField> objectFieldsMap = sObjType.getDescribe().fields.getMap();
                Schema.SObjectField refField = objectFieldsMap.get(fieldNameInfo[2].trim());
                if (refField != null){
                    Schema.DescribeFieldResult refFieldDesc = refField.getDescribe();
                    fieldLabel = fieldDesc.getLabel() + ' ' + refFieldDesc.getLabel();
                    break;
                }
            }
        }
        fieldLabel = String.isNotBlank(fieldLabel) ? fieldLabel : fieldDesc.getLabel() ;
        return fieldLabel;
    }

    public List<String> getParentAddressFields(Boolean fieldsForQuery){
        List<String> formattedFields = new List<String>();
        Schema.DescribeSObjectResult sObjectDescribe = sObjectDescribeMap.get('address_vod__c');
        Map<String, Schema.SObjectField> objectFieldsMap = sObjectDescribe.fields.getMap();
        for (String fieldName : PARENT_ADDRESS_FIELDS){
            if (objectFieldsMap.get(fieldName) != null){
                Schema.DescribeFieldResult fldDesc = objectFieldsMap.get(fieldName).getDescribe();
                //Skip field if inaccessible and not a required field for search
                if (fieldsForQuery && (fldDesc.isAccessible() || REQ_PARENT_ADDRESS_FIELDS.contains(fieldName))){
                    String formattedFieldName = isPicklistOrMultiPicklist(fldDesc.getType()) ? 'toLabel(' + fieldName + ')' : fieldName;
                    formattedFields.add(formattedFieldName);
                } else if (!fieldsForQuery && fldDesc.isAccessible()){
                    formattedFields.add(fieldName);
                }
            }
        }
        return formattedFields;
    }

    private Boolean isPicklistOrMultiPicklist(Schema.DisplayType type){
        return type == Schema.DisplayType.PICKLIST || type == Schema.DisplayType.MULTIPICKLIST;
    }
}