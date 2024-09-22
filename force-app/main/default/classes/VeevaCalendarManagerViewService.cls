public with sharing class VeevaCalendarManagerViewService {

    private static String territoryObjectLabel = Territory2.SObjectType.getDescribe().getLabel();

    public static Map<Id, Map<String, String>> getSubordinatesInfo(){
        List<Map<String, String>> userTerrHierarchy = VeevaTerritoryController.getUserTerritoryHierarchy(UserInfo.getUserId());
        Map<Id, Map<String, String>> userTerrMap = new Map<Id, Map<String, String>>();
        Set<Id> territoryList = new Set<Id>();

        for (Map<String, String> terrMap : userTerrHierarchy) {
            territoryList.add((Id) terrMap.get('Id'));
        }        
        // Remove first level territories
        Set<Id> firstLevelTerritories = new Set<Id>();
        for (Map<String, String> terrMap : userTerrHierarchy) {
            if (terrMap.get('ParentTerritoryId') == null || !territoryList.contains(terrMap.get('ParentTerritoryId'))){
                firstLevelTerritories.add((Id) terrMap.get('Id'));
            }
        }
        territoryList.removeAll(firstLevelTerritories);
        List<SObject> userTerrAssociations = getAllUsersForTerritories(territoryList);
        for (SObject sObj : userTerrAssociations) {
            UserTerritory2Association userTerrInfo = (UserTerritory2Association) sObj;
            Id userId = (Id) userTerrInfo.get('userId');
            String terrName = userTerrInfo.Territory2.Name;
            Map<String, String> userInfoMap = userTerrMap.get(userId);
            if (userInfoMap == null) {
                userInfoMap = new Map<String, String>();
                userInfoMap.put('territories', terrName);
                userInfoMap.put('name', userTerrInfo.User.Name);
                userInfoMap.put('userIdentifier', userTerrInfo.User.User_Identifier_vod__c);
                userInfoMap.put('territoryObjLabel', territoryObjectLabel);
            } else {
                userInfoMap.put('territories', userInfoMap.get('territories') + ',' + terrName);
            }
            userTerrMap.put(userId, userInfoMap);
        }
        return userTerrMap;
    }

    private static List<SObject> getAllUsersForTerritories(Set<Id> territoryIds) {
        if (territoryIds == null || territoryIds.isEmpty()) {
            return new List<SObject>();
        }
        List<SObject> sObjects = [ Select Id, UserId, Territory2Id, Territory2.Name, User.Name, User.User_Identifier_vod__c From UserTerritory2Association Where Territory2Id in :territoryIds And IsActive = true And UserId != :UserInfo.getUserId()];
        return sObjects;
    }
}