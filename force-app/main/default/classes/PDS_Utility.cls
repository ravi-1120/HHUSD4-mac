/*
* Class: PDS_Utility
* Description: Utility class to store PDS reusable methods
* Author: Raghvendra Rathore (Focal CXM)
* Created On: 04/18/2024
* Version: Initial
*/
public without sharing class PDS_Utility {
    @AuraEnabled
    public static List<Map<String, String>> getPicklistValues(String objectApiName, String fieldApiName) {
        List<Map<String, String>> picklistValuesList = new List<Map<String, String>>();
        
        try {
            Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
            Schema.DescribeFieldResult fieldDescribe = describeResult.fields.getMap().get(fieldApiName).getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
       
            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isActive()) {
                    Map<String, String> picklistValue = new Map<String, String>();
                    picklistValue.put('label', entry.getLabel());
                    picklistValue.put('value', entry.getValue());
                    picklistValuesList.add(picklistValue);
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        
        return picklistValuesList;
    }

    //This method is used to attach given files to the record
    public static String attachRecordDocuments(String recordId, String base64String, String fileName, String fileType) {
        String result = 'Failure';

        try {
            List<ContentVersion> existingVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = :fileName LIMIT 1];

            if (!existingVersions.isEmpty()) {
                Id contentDocumentId = existingVersions[0].ContentDocumentId;

                List<ContentDocumentLink> existingLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :recordId AND ContentDocumentId = :contentDocumentId];

                if (!existingLinks.isEmpty()) {
                    delete existingLinks;
                }

                delete new ContentDocument(Id = contentDocumentId);
            }

            // Create a new ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64String);
            cv.PathOnClient = fileName + '.' + fileType;
            insert cv;

            // Link ContentDocument to recordId
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
            contentDocumentLink.LinkedEntityId = recordId;
            contentDocumentLink.Visibility = 'AllUsers';
            insert contentDocumentLink;

            result = 'Success';

        } catch (Exception e) {
            System.debug('attachRecordDocuments Error: ' + e.getMessage());
        }
        return result;
    }



    /** Method to fetch and format copyright label for footer */
    @AuraEnabled
    public static String getCopyrightLabel(){
        List<String> params = new List<String>{String.valueOf(System.today().year())};
        String result = String.format(System.label.PDS_Footer_Copyright, params);
        return result;
    }

}