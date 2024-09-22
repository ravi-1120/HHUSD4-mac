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
/**
 * VeevaBaseObject can be used to represent any Salesforce object to do accessibility
 * checks and format the fields according to their type. It stores object describe
 * and field describes. Inorder to validate the accesibility to relationships, relationships
 * should be explictly added to this. Refer to addRelationship method
 */
public with sharing class VeevaBaseObject {

    static final String RECORD_TYPE_ID = 'RecordTypeId';
    private static Map<String, SObjectType> globalDescribe = Schema.getGlobalDescribe();
    private static final Set<String> FIELDS_WITHOUT_RELATION_NAME = new Set<String>{'ConnectionReceivedId', 'ConnectionSentId'};

    private DescribeSObjectResult sObjectDescribe;
    private Map<String, SObjectField> objectFieldsMap;
    private Map<String, VeevaBaseObject> relationships = new Map<String, VeevaBaseObject>();
	private Map<String, String> relationshipNamesMap;

    private VeevaBaseObject(SObjectType sObjectType){
        sObjectDescribe = sObjectType.getDescribe();
        objectFieldsMap = sObjectDescribe.fields.getMap();
    }

    /**
     * Creates new VeevaBaseObject. It check for user permission to the object.
     * If the user does not have permission, null is returned
    */
    public static VeevaBaseObject create(String objectName){
        SObjectType sObjectType = globalDescribe.get(objectName);
        return create(sObjectType);
    }

    /**
     * Creates new VeevaBaseObject. It check for user permission to the object.
     * If the user does not have permission, null is returned
    */
    public static VeevaBaseObject create(SObjectType sObjectType){
       if(sObjectType == null || !sObjectType.getDescribe().isAccessible()){
           return null;
       }
       return new VeevaBaseObject(sObjectType);
    }

    public DescribeSObjectResult getDescribe(){
        return sObjectDescribe;
    }

    public DescribeFieldResult getFieldDescribe(String field){
        SObjectField sField =  getField(field);
        return sField != null ? sField.getDescribe() : null;
    }

    /**
     Returns SObjectField if the field is part of current object.
     For fields from relationships, relationships should have been added
     using addRelationship.
     */
    public SObjectField getField(String field){
        SObjectField sField = objectFieldsMap.get(field);
        if(sField == null){
            List<String> fieldNameInfo = field.split('\\.', 2);
            if(fieldNameInfo.size() > 1){
                //find if relationship is available
                if(relationships.containsKey(fieldNameInfo[0])){
                    sField = relationships.get(fieldNameInfo[0]).getField(fieldNameInfo[1]);
                }
            }
        }
        return sField;
    }

    public List <Schema.sObjectType> getFieldReferenceTo(String field){
        return objectFieldsMap.get(field) != null ? objectFieldsMap.get(field).getDescribe().getReferenceTo() : null;
    }

    /*
    * Maps all relationship names to field names
    * For example: Product_vod__r -> Product_vod__c, RecordType -> RecordTypeId
    */
    private void createRelationshipNamesMap(){
        relationshipNamesMap = new Map<String,String>();
        for(Schema.SObjectField sField : objectFieldsMap.values()){
            String relationshipName = sField?.getDescribe().getRelationshipName();
            if(relationshipName != null && !relationshipNamesMap.containsKey(relationshipName)){
                relationshipNamesMap.put(relationshipName, sField.getDescribe().getName());
            }
        }
    }

    public Map<String,String> getRelationshipNamesMap(){
        if(relationshipNamesMap == null){
            createRelationshipNamesMap();
        }
        return relationshipNamesMap;
    }

    public String getName(){
        return sObjectDescribe.getName();
    }

    /**
     Adds relationship object to use in field mapping.
     For getting account's parent's field, relationship should be added like
     addRelationship("Parent", accountVeevaObject )
    */
    public void addRelationship(String relationshipName, VeevaBaseObject relatedObject){
        relationships.put(relationshipName, relatedObject);
    }

    /**
     * Returns fields accessible for the user from the given fields.
     * Field name returned is not formatted or any label conversion is done.
     * Refer to {@link
     * #applyToLabelAndFormat(SObjectField sField, String field) applyToLabelAndFormat}
     * for details about label and formatting.
     */
    public  Set<String> getAccessibleFields(Set<String> fields) {
        return getAccessibleFields(fields, false, false);
    }

    /**
     * Returns fields accessible for the user from the given fields.
     * Refer to {@link
     * #applyToLabelAndFormat(SObjectField sField, String field) applyToLabelAndFormat}
     * for details about label and formatting.
     * If duplicateRawFields is true, then query will include both formatted field and regular unformatted field
     * (ex: Currency_vod__c,FORMAT(Currency_vod__c) toFormat_Currency_vod__c)
     */
    public  Set<String> getAccessibleFields(Set<String> fields, boolean applyToLabelOrFormat, boolean duplicateRawFields) {
		Set<String> accessibleFields = new Set<String>();
		for (String field : fields) {
            String convertedField = getAccessibleField(field, applyToLabelOrFormat, duplicateRawFields);
            if(convertedField != null){
                accessibleFields.add(convertedField);
            }
		}
		return accessibleFields;
	}

    /**
     * Returns fields accessible for the user from the given fields,
     * applying custom formatting to fields, leaving numeric, and currency fields unformatted.
     */
    public Set<String> getAccessibleFieldsWithCustomFormatting(Set<String> fields) {
        Set<String> accessibleFields = new Set<String>();
        for (String field : fields) {
            SObjectField sField = getField(field);
            if (sField != null && sField.getDescribe().isAccessible()) {
                if (isQuantitativeFieldType(sField.getDescribe().getType())) {
                    accessibleFields.add(field);
                } else {
                    accessibleFields.add(applyToLabelAndFormat(sField, field, false));
                }
            }
        }
        return accessibleFields;
    }

   /**
    * Returns the formatted field or field (based on applyToLabelOrFormat) if the field
    * is accessible to the user otherwise null. Refer to {@link
    * #applyToLabelAndFormat(SObjectField sField, String field) applyToLabelAndFormat}
    * for details about label and formatting.
    * If duplicateRawFields is true, then query will include both formatted field and regular unformatted field
    * (ex: Currency_vod__c,FORMAT(Currency_vod__c) toFormat_Currency_vod__c)
    */
   public String getAccessibleField(String fieldName, boolean applyToLabelOrFormat, boolean duplicateRawFields){
        SObjectField sField = getField(fieldName);
        if (sField != null && sField.getDescribe().isAccessible()) {
            if(applyToLabelOrFormat){
                return applyToLabelAndFormat(sField, fieldName, duplicateRawFields);
            }else{
                return fieldName;
            }
        }
        return null;
    }

    /**
     * Applies label and formats the given field based on the type.
     * Field name returned is formatted for number, currency and Date types. ToLabel applied
     * for RecordType and Picklist types. Reference fields are converted to relationshioName.Name.
     * i.e (ownerId reference field for account would fetch account.owner.name)
     * For fetching specific fields using a relationship (i.e. owner.firstName for account)
     * relationship should be added to this object using "addRelationship"
     * If duplicateRawFields is true, then query will include both formatted field and regular unformatted field
     * (ex: Currency_vod__c,FORMAT(Currency_vod__c) toFormat_Currency_vod__c)
     */
    public String applyToLabelAndFormat(SObjectField sField, String field, boolean duplicateRawFields){
        DescribeFieldResult fldDesc = sField?.getDescribe();
        DisplayType fieldType = fldDesc?.getType();
        if (fieldType == null) {
            return null;
        }

        if(field.endsWith(RECORD_TYPE_ID)){
            return field + ',toLabel(' + field.removeEnd(RECORD_TYPE_ID) + fldDesc.getRelationshipName() + '.Name)';
        }else if (fieldType == DisplayType.PICKLIST || fieldType == DisplayType.MULTIPICKLIST) {
            if(duplicateRawFields){
                return field+',toLabel(' + field + ') toLabel_' + field.replace('.','_');
            }
            return 'toLabel(' + field + ')';
        } else if(fieldType == DisplayType.CURRENCY || fieldType == DisplayType.DATE ||
                                fieldType == DisplayType.TIME || fieldType == DisplayType.DATETIME
                                || isNumericalField(fieldType)){
            if(duplicateRawFields){
            	return field+',FORMAT('+field+') toFormat_'+field.replace('.','_');
            }
            return 'FORMAT('+field+')';
        }else if (fieldType == DisplayType.REFERENCE && !FIELDS_WITHOUT_RELATION_NAME.contains(field)){
            String fieldName = sField.getDescribe().getName();
            String relationshipName = fldDesc.getRelationshipName() + '.Name';
            if(duplicateRawFields){
                return field+','+field.replace(fieldName,relationshipName);
            }
            return field.replace(fieldName,relationshipName);
        }else{
            return field;
        }

    }

    private boolean isNumericalField(DisplayType fieldType){
        return (fieldType == DisplayType.DOUBLE) || (fieldType == DisplayType.INTEGER)
            || (fieldType == DisplayType.LONG) || (fieldType == DisplayType.PERCENT);
    }

    private boolean isQuantitativeFieldType(DisplayType fieldType){
        return fieldType == DisplayType.CURRENCY || isNumericalField(fieldType);
    }

    /*
    * Loops through list of query fields and adds appropriate relationship.
    */
    public void mapRelationships(List<String> queryParams){
        mapRelationships(queryParams, null);
    }

    public void mapRelationships(List<String> queryParams, Map<String, String> defaultRelationships){
        for(String param : queryParams){
            mapRelationshipsForField(param, defaultRelationships);
        }
    }

    /**
     * Helper method used in mapRelationships.
     * Recursively maps relationships for fields with nested relationships (example: Product_vod__r.Parent_Product_vod__r.Name),
     */
    public void mapRelationshipsForField(String param){
        mapRelationshipsForField(param, null);
    }

    public void mapRelationshipsForField(String param, Map<String, String> defaultRelationships){      
        List<String> fieldNameInfo = param.split('\\.',2);
        if(fieldNameInfo.size() > 1){
            String parentField = getRelationshipNamesMap().get(fieldNameInfo.get(0));
            if(parentField != null){
                if(!relationships.containsKey(fieldNameInfo.get(0))){
                    List <Schema.SObjectType> parentFieldObjectType = getFieldReferenceTo(parentField);
                    Schema.SObjectType relationshipObject = parentFieldObjectType.get(0);
                    if(defaultRelationships != null && defaultRelationships.containsKey(parentField)){
                        String defaultObjectName = defaultRelationships.get(parentField);
                        if (relationshipNamesMap.containsKey(defaultObjectName)) {
                            defaultObjectName = getRelationshipNamesMap().get(defaultObjectName);
                        }
                        relationshipObject = Schema.getGlobalDescribe().get(defaultObjectName);
                    }
                    VeevaBaseObject parentBaseObj = create(relationshipObject);
                    if (parentBaseObj != null) {
                        addRelationship(fieldNameInfo.get(0), parentBaseObj);
                        parentBaseObj.mapRelationshipsForField(fieldNameInfo.get(1), defaultRelationships);
                    }
                } else {
                    relationships.get(fieldNameInfo.get(0)).mapRelationshipsForField(fieldNameInfo.get(1), defaultRelationships);
                }
            }
        }
    }
}