public without sharing class HEQ_HeaderController {

    @AuraEnabled
    public static List<HEQ_Header_Config__mdt> retrieveHeqHeaderMetadata(){
        try {

            String profileName = [SELECT Id,Name FROM Profile WHERE ID =: Userinfo.getProfileId()].Name;

            return [SELECT Id, Label, URL__c, Icon__c, Profile__c, Order__c, IsActive__c, Menu_Type__c FROM HEQ_Header_Config__mdt WHERE IsActive__c = true AND Profile__c =: profileName ORDER BY Order__c];

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static User getuser(String userId){
//        return [SELECT Id,Name,FirstName,LAstName,ProfileId,Profile.Name FROM User WHERE id=: userId];
		String userIdVar = UserInfo.getUserId();
        System.debug('userIdVar->'+userIdVar);
        return [SELECT Id,Name,FirstName,LAstName,ProfileId,Profile.Name FROM User WHERE id =: userIdVar];
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
        
        for(HEQ_Search_Category_1__c cat: [SELECT Id,Name FROM HEQ_Search_Category_1__c WHERE Name =: category]){
            categoryIds.add(cat.Id);
        }
        
        return fetchResources(keyword,type,categoryIds);
    }
    
    @AuraEnabled
    public static List<Map<String,String>> fetchResources(String keyword, String type, List<String> category){
        
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
        
        if(!contentDocumentIdList.isEmpty()){
            String fields = 'Id,Title,ContentDocumentId,MSD_CORE_Topic__c';

            String query = '';
            List<ContentDocumentLink> cdlink = new List<ContentDocumentLink>();
            if (category != null && !category.isEmpty()) {
                System.debug('<category>'+category);
                List<Id> categoryIdList = new List<Id>();
                for (String cat : category) {
                    System.debug('categorycategory>>'+cat);
                    categoryIdList.add(cat);
                }
                cdlink = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:categoryIdList AND ContentDocumentId =:contentDocumentIdList]; 
                List<Id> cdIdlist = new List<Id>();
                for(ContentDocumentLink cd : cdlink){
                    cdIdlist.add(cd.ContentDocumentId);
                }
                
                if(type == 'By Resource'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: cdIdlist AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Resource_Code__c LIKE\'%'+keyword+'%\'';
                }else if(type == 'View All'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: cdIdlist AND MSD_CORE_Is_Active__c = true AND Title LIKE\'%'+keyword+'%\'';
                }else if(type == 'Browse All'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: cdIdlist AND MSD_CORE_Is_Active__c = true';
                }
            } else {
                System.debug('Else Not Category');
                if(type == 'By Resource'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: contentDocumentIdList AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Resource_Code__c LIKE\'%'+keyword+'%\'';
                }else if(type == 'View All'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: contentDocumentIdList AND MSD_CORE_Is_Active__c = true AND Title LIKE\'%'+keyword+'%\'';
                }else if(type == 'Browse All'){
                    query = 'SELECT '+fields+' FROM ContentVersion WHERE ContentDocumentId =: contentDocumentIdList AND MSD_CORE_Is_Active__c = true';
                }
            }

            System.debug(query);
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
            returnData = HEQ_ContentVersionController.updateBookmarkedStatus(UserInfo.getUserId(), returnData);
        }
        
        return returnData;
    }
    
}