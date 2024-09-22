/**
* Component Name:      MSD_CORE_HEQ_SearchCategoryController
* Created By:          Ravi Modi (Focal CXM)
* Created Date:        18th July 2024
* @description:        Server side controller for hEQ_SearchCategory LWC component
* Test Class:          MSD_CORE_HEQ_SearchCategoryController
*/

public without sharing class MSD_CORE_HEQ_SearchCategoryController {
    
    /**
* Method Name  :   getSearchCategory
* @description :   Use to get HEQ Search Category Object Records 
* param        :   profile 
* @return      :   List<SearchCategoryWrapper>
* Created By   :   Devansh Shukla (Focal CXM)
* Modified By  :   Ravi Modi (Focal CXM)
* Created Date :   30th July 2024
*/
    @AuraEnabled
    public static List<SearchCategoryWrapper> getSearchCategory(String profile){
        List<SearchCategoryWrapper> rootCategories = new List<SearchCategoryWrapper>();
        List<MSD_CORE_HEQ_Search_Category__c> searchCategoryRecords;
        
        try {
            searchCategoryRecords = [SELECT Id, Name, MSD_CORE_HEQ_IsActive__c, MSD_CORE_HEQ_Order__c, MSD_CORE_HEQ_Parent_Category__c, MSD_CORE_HEQ_Parent_Category__r.Name, MSD_CORE_HEQ_Profile__c FROM MSD_CORE_HEQ_Search_Category__c WHERE MSD_CORE_HEQ_IsActive__c = true ORDER BY MSD_CORE_HEQ_Parent_Category__c, MSD_CORE_HEQ_Order__c];
            
            Map<Id, SearchCategoryWrapper> searchCategoryMap = new Map<Id, SearchCategoryWrapper>();
            
            for (MSD_CORE_HEQ_Search_Category__c record : searchCategoryRecords) {
                if (record.MSD_CORE_HEQ_Profile__c == 'All' || record.MSD_CORE_HEQ_Profile__c == profile) {
                    SearchCategoryWrapper wrapper = new SearchCategoryWrapper(record.Id, record.Name, record.Name, record.MSD_CORE_HEQ_Parent_Category__r != null ? record.MSD_CORE_HEQ_Parent_Category__r.Name : null);
                    searchCategoryMap.put(record.Id, wrapper);
                }
            }
            
            for (MSD_CORE_HEQ_Search_Category__c record : searchCategoryRecords) {
                if (record.MSD_CORE_HEQ_Profile__c == 'All' || record.MSD_CORE_HEQ_Profile__c == profile) {
                    SearchCategoryWrapper wrapper = searchCategoryMap.get(record.Id);
                    if (record.MSD_CORE_HEQ_Parent_Category__c != null) {
                        SearchCategoryWrapper parentWrapper = searchCategoryMap.get(record.MSD_CORE_HEQ_Parent_Category__c);
                        if (parentWrapper != null) {
                            parentWrapper.childCategories.add(wrapper);
                        }
                    } else {
                        rootCategories.add(wrapper);
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug('Error>>' + e.getMessage() + '----' + e.getLineNumber());
        }
        
        return rootCategories;
    }
    
    public class SearchCategoryWrapper {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String developerName;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String parentCategoryName;
        @AuraEnabled
        public List<SearchCategoryWrapper> childCategories;
        
        public SearchCategoryWrapper(Id id, String developerName, String name, String parentCategoryName) {
            this.id = id;
            this.developerName = developerName;
            this.name = name;
            this.parentCategoryName = parentCategoryName;
            this.childCategories = new List<SearchCategoryWrapper>();
        }
    }
    
    // @AuraEnabled
    // public static MSD_CORE_HEQ_Saved_Search__c saveSearch(String searchName, String selectedFilters) {
    //     Id currentUserId = UserInfo.getUserId();
    //     MSD_CORE_HEQ_Saved_Search__c newSearch = new MSD_CORE_HEQ_Saved_Search__c();
    //     newSearch.MSD_CORE_Search_Name__c = searchName;
    //     newSearch.MSD_CORE_Selected_Filters__c = selectedFilters;
    //     newSearch.MSD_CORE_HeqUser__c = currentUserId;
    //     try {
    //         insert newSearch;
    //         return newSearch;
    //     } catch (Exception e) {
    //         throw new AuraHandledException('Unable to save search: ' + e.getMessage());
    //     }
    // }

    @AuraEnabled
public static String saveSearch(String searchName, String selectedFilters) {
    String message;
    Id currentUserId = UserInfo.getUserId();
    
    try {
        // Check for existing search with the same name for the current user
        List<MSD_CORE_HEQ_Saved_Search__c> existingSearches = [
            SELECT Id 
            FROM MSD_CORE_HEQ_Saved_Search__c 
            WHERE MSD_CORE_Search_Name__c = :searchName 
            AND MSD_CORE_HeqUser__c = :currentUserId
        ];
        
        if (!existingSearches.isEmpty()) {
            message = System.Label.MSD_CORE_Name_already_used;
            return message;
        }
        
        // Create and insert new search record
        MSD_CORE_HEQ_Saved_Search__c newSearch = new MSD_CORE_HEQ_Saved_Search__c(
            MSD_CORE_Search_Name__c = searchName,
            MSD_CORE_Selected_Filters__c = selectedFilters,
            MSD_CORE_HeqUser__c = currentUserId
        );
        insert newSearch;
        message = 'Search saved successfully.';
    } catch (DmlException e) {
        message = 'DML Error: ' + e.getMessage();
    } catch (Exception e) {
        message = 'Unexpected error: ' + e.getMessage();
    }
    
    return message;
}

    
    @AuraEnabled
    public static List<MSD_CORE_HEQ_Saved_Search__c> getSavedSearches() {
        Id currentUserId = UserInfo.getUserId();
        return [SELECT Id, MSD_CORE_Selected_Filters__c,MSD_CORE_Search_Name__c FROM MSD_CORE_HEQ_Saved_Search__c WHERE MSD_CORE_HeqUser__c = :currentUserId ORDER BY CreatedDate DESC];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<MSD_CORE_HEQ_Saved_Search__c> getSaveditems() {
        Id currentUserId = UserInfo.getUserId();
        return [SELECT Id,MSD_CORE_Selected_Filters__c,MSD_CORE_Search_Name__c FROM MSD_CORE_HEQ_Saved_Search__c WHERE MSD_CORE_HeqUser__c = :currentUserId];
    }
    
    @AuraEnabled
    public static void deleteSavedSearch(Id searchId) {
        try {
            MSD_CORE_HEQ_Saved_Search__c searchToDelete = [SELECT Id FROM MSD_CORE_HEQ_Saved_Search__c WHERE Id = :searchId LIMIT 1];
            delete searchToDelete;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to delete saved search: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void renameSavedSearch(Id searchId, String newName) {
        try {
            MSD_CORE_HEQ_Saved_Search__c searchToRename = [SELECT Id, MSD_CORE_Search_Name__c FROM MSD_CORE_HEQ_Saved_Search__c WHERE Id = :searchId LIMIT 1];
            searchToRename.MSD_CORE_Search_Name__c = newName;
            update searchToRename;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to rename saved search: ' + e.getMessage());
        }
    }

}