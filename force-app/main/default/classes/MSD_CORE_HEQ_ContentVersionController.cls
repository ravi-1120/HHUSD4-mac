public without sharing class MSD_CORE_HEQ_ContentVersionController {
    @AuraEnabled
    public static List<Map<String, String>> getRecords(String objectName, String fields, String conditions, String sortOrder, Integer limitSize) {
        System.debug('Fetching records for object: ' + objectName);
        System.debug('Fields: ' + fields);
        System.debug('Conditions: ' + conditions);
        System.debug('Sort order: ' + sortOrder);
        System.debug('Limit size: ' + limitSize);
        
        List<Map<String, String>> result = new List<Map<String, String>>();
        List<Map<String, String>> updatedResult = new List<Map<String, String>>();
        List<SObject> records;
        Id currentUserId = UserInfo.getUserId();
        
        // Construct the query string dynamically
        String query = 'SELECT ' + fields + ' FROM ' + objectName;
        
        if (conditions != null && conditions != '') {
            query += ' WHERE ' + conditions + ' AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false';
        }else{
            query += ' WHERE MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false';
        }
        
        if (sortOrder != null && sortOrder != '') {
            query += ' ORDER BY ' + sortOrder;
        }
        
        if (limitSize != null && limitSize > 0) {
            query += ' LIMIT ' + limitSize;
        }
        
        System.debug('Generated Query: ' + query);
        try {
            records = Database.query(query);
            System.debug('Fetched records: ' + records);
            
            for (SObject record : records) {
                Map<String, String> recordMap = new Map<String, String>();
                for (String field : fields.split(',')) {
                    field = field.trim();
                    recordMap.put(field, String.valueOf(record.get(field)));
                }
                result.add(recordMap);
            }
            
            updatedResult = MSD_CORE_HEQ_ContentVersionController.updateBookmarkedStatus(currentUserId, result);
            System.debug('Processed records: ' + result);
            System.debug('Updated ContentVersions: ' + updatedResult);
            
        } catch (Exception e) {
            System.debug('Error fetching records: ' + e.getMessage());
            MSD_CORE_ExceptionLogs.logException(e, 'HEQ_ContentVersionController', 'getRecords', null, 'Error');
            throw new AuraHandledException('Error fetching records: ' + e.getMessage());
        }
        
        return updatedResult;
    }
    
    @AuraEnabled
    public static List<Map<String, String>> getCustomerRecords(String userId, String fields, String conditions, String sortOrder, Integer limitSize) {
        System.debug('Fetching ContentVersions for user: ' + userId);
        System.debug('Fields: ' + fields);
        System.debug('Conditions: ' + conditions);
        System.debug('Sort order: ' + sortOrder);
        System.debug('Limit size: ' + limitSize);
        
        List<Map<String, String>> result = new List<Map<String, String>>();
        List<Map<String, String>> updatedResult = new List<Map<String, String>>();
        List<SObject> contentVersions;
        
        // Fetch AccountId based on userId
        User user = [SELECT AccountId FROM User WHERE Id = :userId LIMIT 1];
        Id accountId = user.AccountId;
        System.debug('AccountId for user: ' + accountId);
        
        if (accountId != null) {
            // Fetch ContentDocumentLinks for the AccountId
            List<ContentDocumentLink> documentLinks = [SELECT ContentDocumentId 
                                                       FROM ContentDocumentLink 
                                                       WHERE LinkedEntityId = :accountId];
            
            Set<Id> contentDocumentIds = new Set<Id>();
            for (ContentDocumentLink link : documentLinks) {
                contentDocumentIds.add(link.ContentDocumentId);
            }
            
            if (!contentDocumentIds.isEmpty()) {
                // Construct the query string dynamically
                String query = 'SELECT ' + fields + ' FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false';
                
                if (conditions != null && conditions != '') {
                    query += ' AND ' + conditions;
                }
                
                if (sortOrder != null && sortOrder != '') {
                    query += ' ORDER BY ' + sortOrder;
                }
                
                if (limitSize != null && limitSize > 0) {
                    query += ' LIMIT ' + limitSize;
                }
                
                System.debug('Generated Query: ' + query);
                
                try {
                    contentVersions = Database.query(query);
                    System.debug('Fetched ContentVersions: ' + contentVersions);
                    
                    for (SObject record : contentVersions) {
                        Map<String, String> recordMap = new Map<String, String>();
                        for (String field : fields.split(',')) {
                            field = field.trim();
                            recordMap.put(field, String.valueOf(record.get(field)));
                        }
                        result.add(recordMap);
                    }
                    
                    updatedResult = MSD_CORE_HEQ_ContentVersionController.updateBookmarkedStatus(userId, result);
                    System.debug('Processed ContentVersions: ' + result);
                    System.debug('Updated ContentVersions: ' + updatedResult);
                    
                } catch (Exception e) {
                    System.debug('Error fetching ContentVersions: ' + e.getMessage());
                    MSD_CORE_ExceptionLogs.logException(e, 'HEQ_ContentVersionController', 'getDynamicContentVersions', null, 'Error');
                    throw new AuraHandledException('Error fetching ContentVersions: ' + e.getMessage());
                }
            } else {
                System.debug('No ContentDocumentIds associated with the account');
            }
        } else {
            System.debug('No AccountId associated with the user');
        }
        
        return updatedResult;
    }
    
    /*This method is used to bookmark the resource and link it to user*/
    @AuraEnabled
    public static String bookmarkResource(Id userId, Id contentVersionId) {
        String result;
        String userEntityId;
        Id userPreferenceId;
        try {
            user a = [SELECT AccountId, Profile.Name FROM User WHERE Id = :userId LIMIT 1];
            Id accountId = a.AccountId;
            
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1].ContentDocumentId;
            
            if(a.Profile.Name == 'HEQ Customer'){
                userEntityId = [SELECT Id FROM MSD_CORE_HEQ_UserPreference__c WHERE MSD_CORE_Account__c = :accountId LIMIT 1].Id;
            }else{
                userEntityId = [SELECT Id FROM MSD_CORE_HEQ_UserPreference__c WHERE MSD_CORE_User__c = :userId LIMIT 1].Id;
            }
            
            Boolean linkExists = [SELECT COUNT() 
                                  FROM ContentDocumentLink 
                                  WHERE ContentDocumentId = :contentDocumentId 
                                  AND LinkedEntityId = :userEntityId 
                                  LIMIT 1] > 0;
            
            if (!linkExists) {
                ContentDocumentLink newLink = new ContentDocumentLink();
                newLink.ContentDocumentId = contentDocumentId;
                newLink.LinkedEntityId = userEntityId;
                newLink.ShareType = 'V';
                
                insert newLink;
            } else {
                System.debug('ContentDocumentLink already exists for ContentDocumentId: ' + contentDocumentId + ' and LinkedEntityId: ' + userPreferenceId);
            }
            result = 'success';
            
        } catch (QueryException qe) {
            System.debug('Query exception occurred in bookmarkResource method: ' + qe.getMessage());
            MSD_CORE_ExceptionLogs.logException(qe, 'HEQ_ContentVersionController', 'bookmarkResource', null, qe.getMessage());
        } catch (DmlException de) {
            System.debug('DML exception occurred in bookmarkResource method: ' + de.getMessage());
            MSD_CORE_ExceptionLogs.logException(de, 'HEQ_ContentVersionController', 'bookmarkResource', null, de.getMessage());
        } catch (Exception e) {
            System.debug('Exception occurred in bookmarkResource method: ' + e.getMessage());
            MSD_CORE_ExceptionLogs.logException(e, 'HEQ_ContentVersionController', 'bookmarkResource', null, e.getMessage());
        }
        
        return result;
    }
    
    /*This method is used to unbookmark the resources linked to the user*/
    @AuraEnabled
    public static String unBookmarkResource(Id userId, Id contentVersionId) {
        String result;
        String userEntityId;
        Id userPreferenceId;
        try {
            user a = [SELECT AccountId, Profile.Name FROM User WHERE Id = :userId LIMIT 1];
            Id accountId = a.AccountId;
            
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1].ContentDocumentId;
            
            if(a.Profile.Name == 'HEQ Customer'){
                userEntityId = [SELECT Id FROM MSD_CORE_HEQ_UserPreference__c WHERE MSD_CORE_Account__c = :accountId LIMIT 1].Id;
            }else{
                userEntityId = [SELECT Id FROM MSD_CORE_HEQ_UserPreference__c WHERE MSD_CORE_User__c = :userId LIMIT 1].Id;
            }
            
            List<ContentDocumentLink> linksToDelete = [SELECT Id
                                                       FROM ContentDocumentLink
                                                       WHERE ContentDocumentId = :contentDocumentId
                                                       AND LinkedEntityId = :userEntityId];
            
            if (!linksToDelete.isEmpty()) {
                delete linksToDelete;
            }
            result = 'success';
            
        } catch (QueryException qe) {
            System.debug('Query exception occurred in unBookmarkResource method: ' + qe.getMessage());
            MSD_CORE_ExceptionLogs.logException(qe, 'HEQ_ContentVersionController', 'unBookmarkResource', null, qe.getMessage());
        } catch (DmlException de) {
            System.debug('DML exception occurred in unBookmarkResource method: ' + de.getMessage());
            MSD_CORE_ExceptionLogs.logException(de, 'HEQ_ContentVersionController', 'unBbookmarkResource', null, de.getMessage());
        } catch (Exception e) {
            System.debug('Exception occurred in unBookmarkResource method: ' + e.getMessage());
            MSD_CORE_ExceptionLogs.logException(e, 'HEQ_ContentVersionController', 'unBbookmarkResource', null, e.getMessage());
        }
        
        return result;
    }
    
    /*This method is used to return the status of resource bookmark*/
    public static List<Map<String, String>> updateBookmarkedStatus(String userId, List<Map<String, String>> result) {
        try {
            Id userEntityId;
            user a = [SELECT AccountId, Profile.Name FROM User WHERE Id = :userId LIMIT 1];
            Id accountId = a.AccountId;
            
            if(a.Profile.Name == 'HEQ Customer'){
                userEntityId = [SELECT Id FROM MSD_CORE_HEQ_UserPreference__c WHERE MSD_CORE_Account__c = :accountId LIMIT 1].Id;
            }else{
                userEntityId = [SELECT Id FROM MSD_CORE_HEQ_UserPreference__c WHERE MSD_CORE_User__c = :userId LIMIT 1].Id;
            }
            
            if (userEntityId != null) {
                List<ContentDocumentLink> contentLinks = new List<ContentDocumentLink>();
                contentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :userEntityId];
                Set<Id> contentDocumentIds = new Set<Id>();
                for (ContentDocumentLink link : contentLinks) {
                    contentDocumentIds.add(link.ContentDocumentId);
                }
                
                List<ContentVersion> contentVersions = new List<ContentVersion>();
                if(!contentDocumentIds.isEmpty()){
                    contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false];
                }
                
                Set<Id> contentVersionIds = new Set<Id>();
                for (ContentVersion version : contentVersions) {
                    contentVersionIds.add(version.Id);
                }
                
                for (Map<String, String> record : result) {
                    if (record.containsKey('Id')) {
                        String contentVersionId = record.get('Id');
                        if (contentVersionIds.contains(contentVersionId)) {
                            record.put('isBookmarked', 'true');
                        } else {
                            record.put('isBookmarked', 'false');
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Exception occurred in updateBookmarkedStatus method: ' + e.getMessage());
            MSD_CORE_ExceptionLogs.logException(e, 'HEQ_ContentVersionController', 'updateBookmarkStatus', null, e.getMessage());
            throw e;
        }
        
        return result;
    }
    
    /*This method is used to fetch all the bookmarked resources linked to the user*/
    @AuraEnabled
    public static List<Map<String, String>> getUserResources() {
        List<Map<String, String>> result = new List<Map<String, String>>();
        Id userEntityId;
        
        try {
            Id currentUserId = UserInfo.getUserId();
            
            User user = [SELECT AccountId, Profile.Name FROM User WHERE Id = :currentUserId LIMIT 1];
            String profileName = user.Profile.Name;
            Id AccountId = user.AccountId;
            
            List<ContentVersion> contentVersions;
            
            if(profileName == 'HEQ Customer'){
                userEntityId = [SELECT Id FROM MSD_CORE_HEQ_UserPreference__c WHERE MSD_CORE_Account__c = :AccountId LIMIT 1].Id;
            }else{
                userEntityId = [SELECT Id FROM MSD_CORE_HEQ_UserPreference__c WHERE MSD_CORE_User__c = :currentUserId LIMIT 1].Id;
            }
            
            if (userEntityId != null) {
                List<ContentDocumentLink> contentLinks = [
                    SELECT ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :userEntityId
                ];
                
                Set<Id> contentDocumentIds = new Set<Id>();
                for (ContentDocumentLink link : contentLinks) {
                    contentDocumentIds.add(link.ContentDocumentId);
                }
                
                contentVersions = [
                    SELECT Id, Title, MSD_CORE_Topic__c, MSD_CORE_Expiration_Date__c
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :contentDocumentIds AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false 
                ];
            }
            
            Set<String> fieldSet = new Set<String>{'Id', 'Title', 'MSD_CORE_Topic__c', 'MSD_CORE_Expiration_Date__c'};
                
                for (ContentVersion record : contentVersions) {
                    Map<String, String> recordMap = new Map<String, String>();
                    for (String field : fieldSet) {
                        recordMap.put(field, String.valueOf(record.get(field)));
                    }
                    result.add(recordMap);
                }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            MSD_CORE_ExceptionLogs.logException(e, 'HEQ_ContentVersionController', 'getUserResources', null, e.getMessage());
        }
        
        return result;
    }
    
    @AuraEnabled
    public static List<ContentVersionDTO> getContentRecords() {
        List<ContentVersionDTO> gridItems = new List<ContentVersionDTO>();
        
        List<ContentVersion> contentRecords = [
            SELECT Id, Description, Title, FileType, MSD_CORE_Is_Thumbnail__c, MSD_CORE_Is_Active__c, 
            MSD_CORE_Therapeutic_Area__c, MSD_CORE_Topic__c, MSD_CORE_Video_Resource__c, 
            MSD_CORE_Expiration_Date__c, LastModifiedDate, MSD_CORE_Resource_Code__c, MSD_CORE_Fulfillment_Method__c
            , ContentDocumentId, CreatedDate, MSD_CORE_New_Item__c, MSD_CORE_IsNewItem__c	 
            FROM ContentVersion 
            WHERE MSD_CORE_Is_Active__c = true 
            AND MSD_CORE_Is_Thumbnail__c = false AND MSD_CORE_Expiration_Date__c > TODAY ORDER BY LastModifiedDate DESC
        ];
        
        Date today = Date.today();
        
        for (ContentVersion cv : contentRecords) {
            //Integer expiryDays = cv.MSD_CORE_Expiration_Date__c != null ? today.daysBetween(cv.MSD_CORE_Expiration_Date__c) : 0;
            String expiryDays = DateTime.newInstance(cv.MSD_CORE_Expiration_Date__c, Time.newInstance(0, 0, 0, 0)).format('MM/dd/yyyy');
            String filetype = '';
            if(cv.MSD_CORE_Video_Resource__c != null) {
                filetype = 'Video';
            } else {
                filetype = 'PDF';
            }
            
            gridItems.add(new ContentVersionDTO(
                cv.Id,
                cv.Title,
                cv.MSD_CORE_Therapeutic_Area__c,
                filetype,
                expiryDays,
                cv.LastModifiedDate,
                cv.MSD_CORE_Resource_Code__c,
                cv.MSD_CORE_Topic__c,
                cv.contentDocumentId,
                cv.MSD_CORE_IsNewItem__c
            ));
        }
        
        return gridItems;
    }
    
    public class ContentVersionDTO {
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String FileType {get; set;}
        @AuraEnabled public String boldText {get; set;}
        @AuraEnabled public String normalText {get; set;}
        @AuraEnabled public String expiryDays {get; set;}
        @AuraEnabled public Datetime lastModifiedDate {get; set;}
        @AuraEnabled public String resourceCode {get; set;}
        @AuraEnabled public String topic {get; set;}
        @AuraEnabled public String contentDocumentId {get; set;}
        @AuraEnabled public String headerColorCssClass {get; set;}
        @AuraEnabled public Boolean isNewItem {get; set;}
        
        public ContentVersionDTO(String id, String boldText, String normalText, String fileType, String expiryDays, Datetime lastModifiedDate, String resourceCode, String topic, String contentDocumentId, Boolean isNewItem) {
            this.id = id;
            this.boldText = boldText;
            this.normalText = normalText;
            this.FileType = fileType;
            this.expiryDays = expiryDays;
            this.lastModifiedDate = lastModifiedDate;
            this.resourceCode = resourceCode;
            this.topic = topic;
            this.contentDocumentId = contentDocumentId;
            this.isNewItem = isNewItem; 
            if(fileType == 'PDF') {
                this.headerColorCssClass = 'header-color-2';
            } else if(fileType == 'Video') {
                this.headerColorCssClass = 'header-color-3';
            }
        }
    }
    
    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }
    
    @AuraEnabled
    public static List<PicklistOption> getPicklist(String objectApiName, String fieldApiName) {
        List<PicklistOption> picklistOptions = new List<PicklistOption>();
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
        if (sObjType == null) {
            return null;
        }
        Schema.DescribeSObjectResult objDescribe = sObjType.getDescribe();
        Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get(fieldApiName).getDescribe();
        for (Schema.PicklistEntry picklistEntry : fieldDescribe.getPicklistValues()) {
            PicklistOption option = new PicklistOption();
            option.label = picklistEntry.getLabel();
            option.value = picklistEntry.getValue();
            picklistOptions.add(option);
        }
        return picklistOptions;
    }
    
    @AuraEnabled
    public static List<ContentVersion> getTherapeuticAreaContent(String therapeuticArea) {
        String query = 'SELECT Id, CreatedDate, MSD_CORE_New_Item__c, MSD_CORE_IsNewItem__c, ContentDocumentId, Description, Title, FileType, MSD_CORE_Is_Thumbnail__c, MSD_CORE_Is_Active__c, ' +
            'MSD_CORE_Therapeutic_Area__c, MSD_CORE_Topic__c, MSD_CORE_Video_Resource__c, MSD_CORE_Expiration_Date__c, ' +
            'LastModifiedDate, MSD_CORE_Resource_Code__c, MSD_CORE_Fulfillment_Method__c ' +
            'FROM ContentVersion WHERE MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false ' +
            'AND MSD_CORE_Therapeutic_Area__c INCLUDES (:therapeuticArea)' +
            'AND MSD_CORE_Expiration_Date__c > TODAY ' +
            'ORDER BY LastModifiedDate DESC LIMIT 5';
        return Database.query(query);
    }
    
    @AuraEnabled
    public static List<ContentVersion> getTopicContent(String topic) {
        String query = 'SELECT Id, CreatedDate, MSD_CORE_New_Item__c, MSD_CORE_IsNewItem__c, ContentDocumentId, Description, Title, FileType, MSD_CORE_Is_Thumbnail__c, MSD_CORE_Is_Active__c, ' +
            'MSD_CORE_Topic__c, MSD_CORE_Therapeutic_Area__c, MSD_CORE_Video_Resource__c, MSD_CORE_Expiration_Date__c, ' +
            'LastModifiedDate, MSD_CORE_Resource_Code__c, MSD_CORE_Fulfillment_Method__c ' +
            'FROM ContentVersion WHERE MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false ' +
            'AND MSD_CORE_Topic__c INCLUDES (:topic)' +
            'AND MSD_CORE_Expiration_Date__c > TODAY ' +
            'ORDER BY LastModifiedDate DESC LIMIT 5';
        return Database.query(query);
    }  
}