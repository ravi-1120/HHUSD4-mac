public with sharing class VeevaMyAccountsController {

    @AuraEnabled(cacheable=true)
    public static List<VeevaMyAccountsViewItem> getViews() {
        try {
            return new VeevaMyAccountsService().getViews();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static VeevaMyAccountsBaseView getViewDefinition(Id viewId) {
        try {
            return new VeevaMyAccountsService().getViewDefinition(viewId, false);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static VeevaMyAccountsBaseView createDefaultView() {
        try {
            return new VeevaMyAccountsService().createDefaultView();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<VeevaMyAccountsTerritory> getUserTerritories() {
        try {
            List<Map<String, String>> userTerritoryHierarchy = VeevaTerritoryController.getUserTerritoryHierarchy(UserInfo.getUserId());
            return convertUserTerritories(userTerritoryHierarchy);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static VeevaMyAccountsPreferences getMyAccountsUserPreference() {
        try {
            return new VeevaMyAccountsPreferencesService(new VeevaMyAccountsService()).getMyAccountsUserPreference();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<VeevaMyAccountsListItem> createAccountListItems(Id accountListId, List<Id> accountIds) {
        try {
            if (accountIds == null || accountIds.isEmpty()) {
                return new List<VeevaMyAccountsListItem>();
            }

            VeevaBaseObject accountListItemBaseObject = VeevaBaseObject.create(Account_List_Item_vod__c.getSObjectType());
            Set<String> requiredAccountListItemFields = new Set<String>{'Account_vod__c', 'Account_List_vod__c'};
            if (accountListItemBaseObject?.getAccessibleFields(requiredAccountListItemFields).size() != requiredAccountListItemFields.size()) {
                return new List<VeevaMyAccountsListItem>();
            }

            List<Account_List_Item_vod__c> existingListItems = getExistingListItems(accountListId);
            Set<Id> accountIdsAlreadyInList = getAccountIds(existingListItems);

            List<Account_List_Item_vod__c> accountListItemsToInsert = new List<Account_List_Item_vod__c>();
            for (Id accountId : accountIds) {
                if (!accountIdsAlreadyInList.contains(accountId)) {
                    accountListItemsToInsert.add(new Account_List_Item_vod__c(
                        Account_vod__c=accountId,
                        Account_List_vod__c=accountListId
                        ));
                }
            }
            // Prevent errors from being thrown for account list item failures
            Database.SaveResult[] insertResults = Database.insert(accountListItemsToInsert, false);

            // insertResults contains the result of each attempted insert. Parse through and find the items that were inserted successfully
            // We will return a list of VeevaMyAccountsListItem since this is the same type we send for Account List Definitions
            List<Id> insertedListItemIds = new List<Id>();
            List<VeevaMyAccountsListItem> accountListItems = new List<VeevaMyAccountsListItem>();
            for (Integer index = 0; index < insertResults.size(); index++) {
                Database.SaveResult result = insertResults[index];
                if (result.isSuccess()) {
                    Account_List_Item_vod__c currItem = accountListItemsToInsert.get(index);
                    currItem.Id = result.getId();
                    accountListItems.add(new VeevaMyAccountsListItem(currItem));
                }
            }
            return accountListItems;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Integer removeAccountListItems(List<Id> listItemIds) {
        try {
            if (listItemIds == null || listItemIds.isEmpty()) {
                return 0;
            }

            VeevaBaseObject accountListItemBaseObject = VeevaBaseObject.create(Account_List_Item_vod__c.getSObjectType());
            if (!accountListItemBaseObject.getDescribe().isDeletable()) {
                return 0;
            }

            List<Account_List_Item_vod__c> accountListItemsToDelete = new List<Account_List_Item_vod__c>();
            for (Id listItemId : listItemIds) {
                accountListItemsToDelete.add(new Account_List_Item_vod__c(Id=listItemId));
            }
            delete accountListItemsToDelete;

            return listItemIds.size();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<VeevaMyAccountsTerritory> convertUserTerritories(List<Map<String, String>> territoryMaps) {
        Set<String> territoryIds = new Set<String>();
        for (Map<String, String> territory : territoryMaps) {
            territoryIds.add(territory.get('Id'));
        }

        Map<String, String> groupIdByTerritoryId = getGroupIdByTerritoryId(territoryIds);
        List<VeevaMyAccountsTerritory> territories = new List<VeevaMyAccountsTerritory>();
        for (Map<String, String> territory : territoryMaps) {
            String territoryId = territory.get('Id');
            territories.add(new VeevaMyAccountsTerritory(territoryId, territory.get('Name'), territory.get('ParentTerritoryId'), groupIdByTerritoryId.get(territoryId)));
        }
        return territories;
    }

    private static Map<String, String> getGroupIdByTerritoryId(Set<String> territoryIds) {
        Map<String, String> territoryIdToGroupId = new Map<String, String>();
        for (Group row : [SELECT Id, RelatedId FROM Group WHERE Type = 'Territory' AND RelatedId IN :territoryIds]) {
            territoryIdToGroupId.put(row.RelatedId, row.Id);
        }
        return territoryIdToGroupId;
    }

    private static List<Account_List_Item_vod__c> getExistingListItems(Id accountListId) {
        return [SELECT Id, Account_vod__c FROM Account_List_Item_vod__c WHERE Account_List_vod__c = :accountListId];
    }

    private static Set<Id> getAccountIds(List<Account_List_Item_vod__c> listItems) {
        Set<Id> accountIds = new Set<Id>();
        for (Account_List_Item_vod__c listItem : listItems) {
            accountIds.add(listItem.Account_vod__c);
        }
        return accountIds;
    }
}