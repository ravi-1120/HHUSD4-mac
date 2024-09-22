public with sharing class VeevaTerritoryController {

    @AuraEnabled
    public static List<Map<String, String>> getAccountUserTerritories(String accountId) {
        TerritoryManagement territoryManagement = TerritoryManagementFactory.getInstance();
        Set<Id> userTerritoryIds = territoryManagement.getUserTerritories(UserInfo.getUserId());
        Set<Id> territoryIdsToQuery = new Set<Id>();
        Map<String, TerritoryAndChildren> territoriesByName = new Map<String, TerritoryAndChildren>();
        List<String> userTerritoryNames = new List<String>();
        Map<Id, Map<String, String>> territoriesMap = territoryManagement.getTerritoriesMap();
        for (Map<String, String> territory : territoriesMap.values()) {
            String territoryId = territory.get('Id');
            String territoryName = territory.get('Name');
            if (userTerritoryIds.contains(territoryId) || userTerritoryIds.contains(territory.get('ParentTerritoryId'))) {
                territoryIdsToQuery.add(territoryId);
                territoriesByName.put(territoryName, new TerritoryAndChildren(territory));
                if (userTerritoryIds.contains(territoryId)) {
                    userTerritoryNames.add(territoryName);
                }
            }
        }

        Set<Id> accountUserTerritoryIds = new Set<Id>();
        if (hasAccessToAccount(accountId)) {
            accountUserTerritoryIds.addAll(territoryManagement.getAccountAssignedTerritories(accountId, territoryIdsToQuery));
            for (Id territoryId : accountUserTerritoryIds) {
                addChildToParentTerritory(territoryId, territoriesMap, territoriesByName);
            }
            for (TerritoryAndChildren territoryObject : territoriesByName.values()) {
                removeChildFromUserTerritoryNames(territoryObject, userTerritoryNames);
            }
        }

        return getFilteredTerritories(userTerritoryNames, !accountUserTerritoryIds.isEmpty() ? accountUserTerritoryIds : userTerritoryIds, territoriesByName);
    }

    public static List<Map<String, String>> getUserTerritoryHierarchy(Id userId) {
        TerritoryManagement territoryManagement = TerritoryManagementFactory.getInstance();
        Set<Id> userTerritoryIds = territoryManagement.getUserTerritories(userId);
        Map<Id, Map<String, String>> territoryMap = territoryManagement.getTerritoriesMap();
        Map<Id, List<Id>> territoryChildren = getTerritoryChildren(territoryMap);

        // If the user is assigned to multiple parts of the same hierarchy we only want to keep the top-level territories
        List<Map<String, String>> topLevelTerritories = new List<Map<String, String>>();
        for (Id userTerritoryId : userTerritoryIds) {
            if (!isUserAssignedToAnscestor(userTerritoryId, userTerritoryIds, territoryMap)) {
                topLevelTerritories.add(territoryMap.get(userTerritoryId));
            }
        }
        topLevelTerritories = sortByTerritoryName(topLevelTerritories);

        List<Map<String, String>> userTerritoryHierarchy = new List<Map<String, String>>();
        Set<Id> territoryIdsVisited = new Set<Id>();
        List<Map<String, String>> territoriesToTraverse = new List<Map<String, String>>(topLevelTerritories);
        while (!territoriesToTraverse.isEmpty()) {
            Map<String, String> currentTerritory = territoriesToTraverse.remove(0);
            Id currentTerritoryId = currentTerritory.get('Id');
            if (!territoryIdsVisited.contains(currentTerritoryId)) {
                userTerritoryHierarchy.add(territoryMap.get(currentTerritoryId));
                territoryIdsVisited.add(currentTerritoryId);
                List<Map<String, String>> childTerritories = new List<Map<String, String>>();
                List<Id> childTerritoryIds = territoryChildren.get(currentTerritoryId);
                for (Id childTerritoryId : childTerritoryIds) {
                    Map<String, String> childTerritory = territoryMap.get(childTerritoryId);
                    childTerritories.add(childTerritory);
                }
                // We will perform a depth-first search through the territories
                // The territories will be ordered by name and depth-first
                List<Map<String, String>> sortedChildTerritories = sortByTerritoryName(childTerritories);
                List<Map<String, String>> existingTerritoriesToTraverse = territoriesToTraverse;
                territoriesToTraverse = new List<Map<String, String>>();
                territoriesToTraverse.addAll(sortedChildTerritories);
                territoriesToTraverse.addAll(existingTerritoriesToTraverse);
            }
        }

        return userTerritoryHierarchy;
    }

    private static boolean isUserAssignedToAnscestor(Id currentTerritoryId, Set<Id> userAssignedIds, Map<Id, Map<String, String>> territoryMap) {
        Map<String, String> territory = territoryMap.get(currentTerritoryId);
        Id parentTerritoryId = territory.get('ParentTerritoryId');
        if (parentTerritoryId == null) {
            return false;
        } else if (userAssignedIds.contains(parentTerritoryId)) {
            return true;
        } else {
            return isUserAssignedToAnscestor(parentTerritoryId, userAssignedIds, territoryMap);
        }
    }

    private static List<Map<String, String>> sortByTerritoryName(List<Map<String, String>> territories) {
        List<TerritoryAndChildren> territoryList = new List<TerritoryAndChildren>();
        for (Map<String, String> territory : territories) {
           territoryList.add(new TerritoryAndChildren(territory));
        }
        // Sorts territories by territory name
        territoryList.sort();

        List<Map<String, String>> territoriesSortedByName = new List<Map<String, String>>();
        for (TerritoryAndChildren territory : territoryList) {
            territoriesSortedByName.add(territory.territory);
        }
        return territoriesSortedByName;
    }

    private static Map<Id, List<Id>> getTerritoryChildren(Map<Id, Map<String, String>> territoryMap) {
        Map<Id, List<Id>> territoryChildren = new Map<Id, List<Id>>();

        for (Id territoryId : territoryMap.keySet()) {
            territoryChildren.put(territoryId, new List<Id>());
        }

        // Add children to territoryChildren map
        for (Id territoryId : territoryMap.keySet()) {
            Map<String, String> territory = territoryMap.get(territoryId);
            Id parentTerritoryId = territory.get('ParentTerritoryId');
            if (parentTerritoryId != null) {
                territoryChildren.get(parentTerritoryId).add(territoryId);
            }
        }

        return territoryChildren;
    }

    private static boolean hasAccessToAccount(Id accountId) {
        List<Account> accounts = [SELECT Id FROM Account WHERE Id = :accountId LIMIT 1];
        return !accounts.isEmpty() && accounts.get(0) != null;
    }

    private static void addChildToParentTerritory(Id childTerritoryId, Map<Id, Map<String, String>> territoriesMap, Map<String, TerritoryAndChildren> userVisibleTerritories) {
        Map<String, String> childTerritory = territoriesMap.get(childTerritoryId);
        String parentTerritoryId = childTerritory.get('ParentTerritoryId');
        Map<String, String> parentTerritoryData = territoriesMap.get(parentTerritoryId);
        String parentTerritoryName = (parentTerritoryData != null) ? parentTerritoryData.get('Name') : null;
        if(!String.isBlank(parentTerritoryName) && userVisibleTerritories.containsKey(parentTerritoryName)){
            String childTerritoryName = childTerritory.get('Name');
            if (childTerritoryName.compareTo(parentTerritoryName) >= 0) {
                TerritoryAndChildren parentTerritory = userVisibleTerritories.get(parentTerritoryName);
                parentTerritory.addChildTerritoryName(childTerritoryName);
            }  
        }
    }

    private static void removeChildFromUserTerritoryNames(TerritoryAndChildren territoryObject, List<String> userTerritoryNames) {
        for (String childTerritoryName : territoryObject.getChildTerritoryNames()) {
            Integer userTerritoryIndex = userTerritoryNames.indexOf(childTerritoryName);
            if(userTerritoryIndex >= 0) {
                userTerritoryNames.remove(userTerritoryIndex);
            }
        }
    }

    private static List<Map<String, String>> getFilteredTerritories(List<String> territoryNames, Set<Id> validTerritoryIds, Map<String, TerritoryAndChildren> territoriesByName) {
        List<Map<String, String>> filteredTerritories = new List<Map<String, String>>();
        
        territoryNames.sort();
        for (String territoryName : territoryNames) {
            TerritoryAndChildren territory = territoriesByName.get(territoryName);
            Map<String, String> territoryData = territory.getTerritoryData();
            if (validTerritoryIds.contains(territoryData.get('Id'))) {
                filteredTerritories.add(territoryData);
            }
            filteredTerritories.addAll(getFilteredTerritories(territory.getChildTerritoryNames(), validTerritoryIds, territoriesByName));
        }

        return filteredTerritories;
    }

    private class TerritoryAndChildren implements Comparable {
        private Map<String, String> territory;
        private List<String> childTerritoryNames = new List<String>();

        TerritoryAndChildren(Map<String, String> territory) {
            this.territory = territory;
        }

        void addChildTerritoryName(String name) {
            this.childTerritoryNames.add(name);
        }

        Map<String, String> getTerritoryData() {
            Map<String, String> territoryCopy = new Map<String, String>(this.territory);
            return territoryCopy;
        }

        List<String> getChildTerritoryNames() {
            List<String> childTerritoryNamesCopy = new List<String>(this.childTerritoryNames);
            return childTerritoryNamesCopy;
        }

        public Integer compareTo(Object compareTo) {
            TerritoryAndChildren other = (TerritoryAndChildren) compareTo;
            return this.territory.get('Name').compareTo(other.territory.get('Name'));
        }
    }

}