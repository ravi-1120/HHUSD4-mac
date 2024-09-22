/**
 * Component Name:      HEQ_SearchCategoryController
 * Created By:          Ravi Modi (Focal CXM)
 * Created Date:        18th July 2024
 * @description:        Server side controller for hEQ_SearchCategory LWC component
 * Test Class:          HEQ_SearchCategoryControllerTest
 */

 public without sharing class HEQ_SearchCategoryController {
     
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
        List<HEQ_Search_Category_1__c> searchCategoryRecords;
        
        try {
            searchCategoryRecords = [SELECT Id, Name, HEQ_IsActive__c, HEQ_Order__c, HEQ_Parent_Category__c, HEQ_Parent_Category__r.Name, HEQ_Profile__c FROM HEQ_Search_Category_1__c WHERE HEQ_IsActive__c = true ORDER BY HEQ_Parent_Category__c, HEQ_Order__c];
            
            Map<Id, SearchCategoryWrapper> searchCategoryMap = new Map<Id, SearchCategoryWrapper>();
            
            for (HEQ_Search_Category_1__c record : searchCategoryRecords) {
                if (record.HEQ_Profile__c == 'All' || record.HEQ_Profile__c == profile) {
                    SearchCategoryWrapper wrapper = new SearchCategoryWrapper(record.Id, record.Name, record.Name, record.HEQ_Parent_Category__r != null ? record.HEQ_Parent_Category__r.Name : null);
                    searchCategoryMap.put(record.Id, wrapper);
                }
            }
            
            for (HEQ_Search_Category_1__c record : searchCategoryRecords) {
                if (record.HEQ_Profile__c == 'All' || record.HEQ_Profile__c == profile) {
                    SearchCategoryWrapper wrapper = searchCategoryMap.get(record.Id);
                    if (record.HEQ_Parent_Category__c != null) {
                        SearchCategoryWrapper parentWrapper = searchCategoryMap.get(record.HEQ_Parent_Category__c);
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

         @AuraEnabled
    public static HEQ_Saved_Search__c saveSearch(String searchName, String selectedFilters) {
        Id currentUserId = UserInfo.getUserId();
        HEQ_Saved_Search__c newSearch = new HEQ_Saved_Search__c();
        newSearch.Save_Search_Name__c = searchName;
        newSearch.HEQ_Selected_Filters__c = selectedFilters;
        newSearch.HEQ_User__c = currentUserId;
        try {
            insert newSearch;
            return newSearch;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to save search: ' + e.getMessage());
        }
    }

        @AuraEnabled
    public static List<HEQ_Saved_Search__c> getSavedSearches() {
    Id currentUserId = UserInfo.getUserId();
    return [SELECT Id, HEQ_Selected_Filters__c,Save_Search_Name__c FROM HEQ_Saved_Search__c WHERE HEQ_User__c = :currentUserId];
    }

      @AuraEnabled(cacheable=true)
    public static List<HEQ_Saved_Search__c> getSaveditems() {
    Id currentUserId = UserInfo.getUserId();
    return [SELECT Id,HEQ_Selected_Filters__c,Save_Search_Name__c FROM HEQ_Saved_Search__c WHERE HEQ_User__c = :currentUserId];
    }
    
    @AuraEnabled
    public static void deleteSavedSearch(Id searchId) {
        try {
            HEQ_Saved_Search__c searchToDelete = [SELECT Id FROM HEQ_Saved_Search__c WHERE Id = :searchId LIMIT 1];
            delete searchToDelete;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to delete saved search: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void renameSavedSearch(Id searchId, String newName) {
        try {
            HEQ_Saved_Search__c searchToRename = [SELECT Id, Save_Search_Name__c FROM HEQ_Saved_Search__c WHERE Id = :searchId LIMIT 1];
            searchToRename.Save_Search_Name__c = newName;
            update searchToRename;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to rename saved search: ' + e.getMessage());
        }
    }
}