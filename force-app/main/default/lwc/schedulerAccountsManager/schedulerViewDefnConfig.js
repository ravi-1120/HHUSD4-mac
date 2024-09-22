import VeevaMedicalIdentifierHelper from "c/veevaMedicalIdentifierHelper";

export default class SchedulerViewDefnConfig{

    static getDefaultViewDefn(viewType, isChildAccountView){
        return {
            "addresses": "MINE",
            "baseQuery": "",
            "criteria": SchedulerViewDefnConfig.getDefaultViewCriteria(viewType),
            "isPublic": true,
            "isViewOwner": true,
            "owners": "ALL",
            "source": isChildAccountView ? "LOCATION" : "ACCOUNT",
            "columns": [],
            "hasErrors": false,
            "id": "a0M5e000004Lm9REAS",
            "name": "Scheduler_Test",
            "requiresTerritory": false,
            "type": "VIEW"
        }
    }

    static getDefaultViewCriteria(viewType){
        if (viewType === "ALL" || viewType === "CHILD") {
            return [];
        }        
        return [{
            "field": {
                "fieldType": "boolean",
                "hasError": false,
                "label": "IsPersonAccount",
                "name": "IsPersonAccount",
                "objectName": "Account",
                "qualifiers": []
            },
            "hasError": false,
            "operator": "eq",
            "value": viewType === "PERSON" ? "true" : "false"
        }]
    }

    static schedulerViewDefnColumns(tsfObjectInfo, addressObjectInfo, isChildAccountView){
        let columnList = [];
        if (isChildAccountView) {
            columnList = [ ...SchedulerViewDefnConfig.getChildAccountColumns() ];
        } else {
            columnList = [ ...SchedulerViewDefnConfig.getAccountColumns() ];
            if (tsfObjectInfo?.fields?.Address_vod__c){
                columnList = [ ...columnList, ...SchedulerViewDefnConfig.getAddressColumns(addressObjectInfo?.fields?.Address_line_2_vod__c) ];
            }
            if (tsfObjectInfo?.fields?.Address_vod__c && tsfObjectInfo?.fields?.Preferred_Account_vod__c){
                columnList = [ ...columnList, ...SchedulerViewDefnConfig.getTSFColumns() ];
            }
        }
        return columnList;
    }

    static getAccountColumns(){
        return [
            {
                "fieldType": "reference",
                "hasError": false,
                "label": "Record Type",
                "name": "RecordTypeId",
                "objectName": "Account",
                "qualifiers": [],
                "referenceNameField": "RecordType.DeveloperName",
                "referenceToObject": "RecordType"
            },
            {
                "fieldType": "boolean",
                "hasError": false,
                "label": "Is Person",
                "name": "IsPersonAccount",
                "objectName": "Account",
                "qualifiers": []
            },
            {
                "fieldType": "string",
                "hasError": false,
                "label": "Name",
                "name": "Formatted_Name_vod__c",
                "objectName": "Account",
                "qualifiers": []
            },
            {
                "fieldType": "string",
                "hasError": false,
                "label": "Account Identifier",
                "name": VeevaMedicalIdentifierHelper.getIdentifierApiName() ?? "Account_Identifier_vod__c",
                "objectName": "Account",
                "qualifiers": []
            },
            {
                "fieldType": "reference",
                "hasError": false,
                "label": "Primary Parent",
                "name": "Primary_Parent_vod__c",
                "objectName": "Account",
                "qualifiers": [],
                "referenceNameField": "Primary_Parent_vod__r.Name",
                "referenceToObject": "Account"
            },
            {
                "fieldType": "reference",
                "hasError": false,
                "label": "Primary Parent CreatedDate",
                "name": "Primary_Parent_vod__c",
                "objectName": "Account",
                "qualifiers": [],
                "referenceNameField": "Primary_Parent_vod__r.CreatedDate",
                "referenceToObject": "Account"
            }
        ];
    }

    static getAddressColumns(hasAddressLine2FLS){
        const addressColumns = [
            {
                "fieldType": "string",
                "hasError": false,
                "label": "Address line 1",
                "name": "Name",
                "objectName": "Address_vod__c",
                "qualifiers": []
            },
            {
                "fieldType": "string",
                "hasError": false,
                "label": "City",
                "name": "City_vod__c",
                "objectName": "Address_vod__c",
                "qualifiers": []
            },
            {
                "fieldType": "picklist",
                "hasError": false,
                "label": "State",
                "name": "State_vod__c",
                "objectName": "Address_vod__c",
                "qualifiers": []
            },
            {
                "fieldType": "string",
                "hasError": false,
                "label": "Zip",
                "name": "Zip_vod__c",
                "objectName": "Address_vod__c",
                "qualifiers": []
            }
        ];
        if (hasAddressLine2FLS){
            addressColumns.push({
                "fieldType": "string",
                "hasError": false,
                "label": "Address line 2",
                "name": "Address_line_2_vod__c",
                "objectName": "Address_vod__c",
                "qualifiers": []
            });
        }
        return addressColumns;
    }

    static getTSFColumns(){
        return [{
            "fieldType": "reference",
            "hasError": false,
            "label": "My Preferred Location",
            "name": "Preferred_Account_vod__c",
            "objectName": "TSF_vod__c",
            "qualifiers": [],
            "referenceNameField": "Preferred_Account_vod__r.Name",
            "referenceToObject": "Account"
        },
        {
            "fieldType": "reference",
            "hasError": false,
            "label": "My Preferred Location CreatedDate",
            "name": "Preferred_Account_vod__c",
            "objectName": "TSF_vod__c",
            "qualifiers": [],
            "referenceNameField": "Preferred_Account_vod__r.CreatedDate",
            "referenceToObject": "Account"
        }];
    }

    static getChildAccountColumns() {
        return [
            {
                "accountRelationship": "Child_Account_vod__r",
                "fieldType": "reference",
                "hasError": false,
                "isHtmlFormatted": false,
                "label": "Record Type",
                "name": "RecordTypeId",
                "objectName": "Account",
                "qualifiers": [],
                "scale": 0,
                "referenceNameField": "RecordType.DeveloperName",
                "referenceToObject": "RecordType"
            },
            {
                "accountRelationship": "Child_Account_vod__r",
                "fieldType": "id",
                "hasError": false,
                "isHtmlFormatted": false,
                "label": "Account ID",
                "name": "Id",
                "objectName": "Account",
                "qualifiers": [],
                "scale": 0
            },
            {
                "fieldType": "reference",
                "hasError": false,
                "isHtmlFormatted": false,
                "label": "Child Account",
                "name": "Child_Account_vod__c",
                "objectName": "Child_Account_vod__c",
                "qualifiers": [],
                "referenceNameField": "Child_Account_vod__r.Name",
                "referenceToObject": "Account",
                "scale": 0
            },
            {
                "fieldType": "reference",
                "hasError": false,
                "isHtmlFormatted": false,
                "label": "Parent Account",
                "name": "Parent_Account_vod__c",
                "objectName": "Child_Account_vod__c",
                "qualifiers": [],
                "referenceNameField": "Parent_Account_vod__r.Name",
                "referenceToObject": "Account",
                "scale": 0
            },
            {
                "accountRelationship": "Child_Account_vod__r",
                "fieldType": "string",
                "hasError": false,
                "isHtmlFormatted": false,
                "label": "First Name",
                "name": "FirstName",
                "objectName": "Account",
                "qualifiers": [],
                "scale": 0
            },
            {
                "accountRelationship": "Child_Account_vod__r",
                "fieldType": "string",
                "hasError": false,
                "isHtmlFormatted": false,
                "label": "Last Name",
                "name": "LastName",
                "objectName": "Account",
                "qualifiers": [],
                "scale": 0
            },
            {
                "fieldType": "string",
                "hasError": false,
                "isHtmlFormatted": false,
                "label": "Parent Child Furigana",
                "name": "Parent_Child_Furigana_vod__c",
                "objectName": "Child_Account_vod__c",
                "qualifiers": [],
                "scale": 0
            },
            {
                "fieldType": "string",
                "hasError": false,
                "isHtmlFormatted": false,
                "label": "Parent Child Name",
                "name": "Parent_Child_Name_vod__c",
                "objectName": "Child_Account_vod__c",
                "qualifiers": [],
                "scale": 0
            },
            {
                "fieldType": "string",
                "hasError": false,
                "isHtmlFormatted": false,
                "label": "Child Account Identifier",
                "name": "Child_Account_Identifier_vod__c",
                "objectName": "Child_Account_vod__c",
                "qualifiers": [],
                "scale": 0
            }
        ];
    }
}