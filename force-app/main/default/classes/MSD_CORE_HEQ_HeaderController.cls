public without sharing class MSD_CORE_HEQ_HeaderController {
    
    @AuraEnabled
    public static List<MSD_CORE_HEQ_Header_Config__mdt> retrieveHeqHeaderMetadata(){
        try {
            
            // String profileName = [SELECT Id,Name FROM Profile WHERE ID =: '00ecW0000003kkfQAA'].Name;
            String profileName = [SELECT Id,Name FROM Profile WHERE ID =: Userinfo.getProfileId()].Name;
            
            return [SELECT Id, Label, URL__c, Icon__c, Profile__c, Order__c, IsActive__c, Menu_Type__c FROM MSD_CORE_HEQ_Header_Config__mdt WHERE IsActive__c = true AND Profile__c =: profileName ORDER BY Order__c];
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static User getuser(String userId){
        //        return [SELECT Id,Name,FirstName,LAstName,ProfileId,Profile.Name FROM User WHERE id=: userId];
        String userIdVar = UserInfo.getUserId();
        System.debug('userIdVar->'+userIdVar);
        // return [SELECT Id,Name,FirstName,LAstName,ProfileId,Profile.Name FROM User WHERE id =: userIdVar];
        return [SELECT Id, Name, FirstName, LAstName, ProfileId, Profile.Name, Username, UserRole.Name, Phone, Email, LanguageLocaleKey, TimeZoneSidKey, Country FROM User WHERE id =: userIdVar];
    }
    @AuraEnabled(cacheable=true)
    public static String getUserProfileName() {
        Id userId = UserInfo.getUserId();
        User user = [SELECT Profile.Name FROM User WHERE Id = :userId LIMIT 1];
        return user.Profile.Name;
    }
    
    @AuraEnabled
    public static List<Map<String,String>> fetchResourcesFromSavedSearch(String keyword,String type,List<String> category){
        
        List<String> categoryIds = new List<String>();
        
        for(MSD_CORE_HEQ_Search_Category__c cat: [SELECT Id,Name FROM MSD_CORE_HEQ_Search_Category__c WHERE Name =: category]){
            categoryIds.add(cat.Id);
        }
        
        return fetchResources(keyword,type,categoryIds,null);
    }
    
    @AuraEnabled
    public static List<Map<String,String>> fetchResources(String keyword, String type, List<String> category, String categoryName){
        
        String profileName = [SELECT Id,Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;
        
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        
        Set<Id> contentDocumentIdList = new Set<Id>();
        
        if(profileName == 'HEQ Customer'){
            
            String AccountId = [SELECT Id,AccountId FROM User WHERE Id=: UserInfo.getUserId()].AccountId;
            
            contentDocumentLinkList = [SELECT Id, ContentDocumentId, LinkedEntityId, ShareType, Visibility FROM ContentDocumentLink WHERE LinkedEntityId =: AccountId];
            for(ContentDocumentLink cdl: contentDocumentLinkList){
                contentDocumentIdList.add(cdl.ContentDocumentId);
            }
        }else if(profileName == 'HEQ - Account Exe'){
            for(ContentDocument cd: [SELECT Id,Title FROM ContentDocument]){
                contentDocumentIdList.add(cd.Id);
            }
        }
        
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        List<Map<String,String>> returnData = new List<Map<String,String>>();
        
        System.debug('type->'+type);
        
        if(!contentDocumentIdList.isEmpty() && type != null){
            String fields = 'Id, Description, Title, ContentDocumentId, FileType, MSD_CORE_Is_Thumbnail__c, MSD_CORE_Is_Active__c, MSD_CORE_Therapeutic_Area__c, MSD_CORE_Topic__c, MSD_CORE_Video_Resource__c, MSD_CORE_Expiration_Date__c, LastModifiedDate, MSD_CORE_Resource_Code__c, MSD_CORE_Fulfillment_Method__c, CreatedDate, MSD_CORE_New_Item__c, MSD_CORE_IsNewItem__c';
            
            String query = '';
            List<ContentDocumentLink> cdlink = new List<ContentDocumentLink>();
            List<Id> categoryIdList = new List<Id>();
            if ((category != null && !category.isEmpty()) || categoryName != null) {
                System.debug('<category>'+category);
                if (categoryName != null) {
                    MSD_CORE_HEQ_Search_Category__c catRec = [
                        SELECT Id, Name 
                        FROM MSD_CORE_HEQ_Search_Category__c 
                        WHERE Name = :categoryName
                        LIMIT 1
                    ];

                    if (catRec != null) {
                        categoryIdList.add(catRec.Id);
                    }
                }else{
                    for (String cat : category) {
                        System.debug('categorycategory>>'+cat);
                        categoryIdList.add(cat);
                    }
                }
                cdlink = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:categoryIdList AND ContentDocumentId =:contentDocumentIdList]; 
                List<Id> cdIdlist = new List<Id>();
                for(ContentDocumentLink cd : cdlink){
                    cdIdlist.add(cd.ContentDocumentId);
                }
                
                if(type == 'By Resource'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: cdIdlist AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false AND MSD_CORE_Resource_Code__c LIKE\'%'+keyword+'%\'';
                }else if(type == 'View All'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: cdIdlist AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false AND Title LIKE\'%'+keyword+'%\'';
                }else if(type == 'Browse All'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: cdIdlist AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false';
                } else if(type == 'New Materials'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: cdIdlist AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false AND MSD_CORE_Expiration_Date__c > TODAY order by lastmodifieddate desc';
                } else if(type == 'Expiring Soon'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: cdIdlist AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false AND MSD_CORE_Expiration_Date__c > TODAY  order by MSD_CORE_Expiration_Date__c asc';
                } else if(type == 'Therapeutic Area'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: cdIdlist AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false AND MSD_CORE_Expiration_Date__c > TODAY  order by lastmodifieddate desc';
                } else if(type == 'Topics'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: cdIdlist AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false AND MSD_CORE_Expiration_Date__c > TODAY  order by MSD_CORE_Expiration_Date__c asc';
                } else{
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: cdIdlist AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false AND MSD_CORE_Expiration_Date__c > TODAY  order by MSD_CORE_Expiration_Date__c asc';
                }  
            } else {
                System.debug('Else Not Category');
                if(type == 'By Resource'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: contentDocumentIdList AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false AND MSD_CORE_Resource_Code__c LIKE\'%'+keyword+'%\'';
                }else if(type == 'View All'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: contentDocumentIdList AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false AND Title LIKE\'%'+keyword+'%\'';
                }else if(type == 'Browse All'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: contentDocumentIdList AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false';
                } else if(type == 'New Materials'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: contentDocumentIdList AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false AND MSD_CORE_Expiration_Date__c > TODAY order by lastmodifieddate desc';
                } else if(type == 'Expiring Soon'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: contentDocumentIdList AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false AND MSD_CORE_Expiration_Date__c > TODAY  order by MSD_CORE_Expiration_Date__c asc';
                }else if(type == 'Therapeutic Area'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: contentDocumentIdList AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false AND MSD_CORE_Expiration_Date__c > TODAY  order by lastmodifieddate desc';
                } else if(type == 'Topics'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: contentDocumentIdList AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false AND MSD_CORE_Expiration_Date__c > TODAY  order by MSD_CORE_Expiration_Date__c asc';
                }  

            }
            
            System.debug('### query : '+query);
            contentVersionList = Database.query(query); 
            System.debug('contentVersionList>>'+contentVersionList);
            
            for(ContentVersion cd: contentVersionList){
                Map<String, String> recordMap = new Map<String, String>();
                for (String field : fields.split(',')) {
                    field = field.trim();
                    recordMap.put(field, String.valueOf(cd.get(field)));
                }
                returnData.add(recordMap);
            }
            returnData = MSD_CORE_HEQ_ContentVersionController.updateBookmarkedStatus(UserInfo.getUserId(), returnData);
        }
        
        return returnData;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTimezoneOptions() {
        List<Map<String, String>> timezoneOptions = new List<Map<String, String>>();
        
        timezoneOptions.add(new Map<String, String>{'label' => 'America/New_York', 'value' => 'America/New_York'});
        timezoneOptions.add(new Map<String, String>{'label' => 'America/Chicago', 'value' => 'America/Chicago'});
        timezoneOptions.add(new Map<String, String>{'label' => 'America/Denver', 'value' => 'America/Denver'});
        timezoneOptions.add(new Map<String, String>{'label' => 'America/Los_Angeles', 'value' => 'America/Los_Angeles'});
        
        return timezoneOptions;
    }
    
    @AuraEnabled
    public static void updateUserTimezone(String userId, String timezone) {
        User userToUpdate = [SELECT Id, TimeZoneSidKey FROM User WHERE Id = :userId LIMIT 1];
        userToUpdate.TimeZoneSidKey = timezone;
        update userToUpdate;
    }
    
    @AuraEnabled
    public static List<Map<String, String>> getLanguageOptions() {
        List<Map<String, String>> languageOptions = new List<Map<String, String>>();
        
        
        languageOptions.add(new Map<String, String>{'label' => 'English', 'value' => 'en_US'});
        languageOptions.add(new Map<String, String>{'label' => 'Spanish', 'value' => 'es'});
        
        return languageOptions;
    }
    
    @AuraEnabled
    public static void updateUserLanguage(Id userId, String language) {
        User user = [SELECT Id, LanguageLocaleKey FROM User WHERE Id = :userId LIMIT 1];
        user.LanguageLocaleKey = language;
        update user;
    }
    
}