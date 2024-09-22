public inherited sharing class VeevaGASAlignmentHistoryService {

    public void createAlignmentHistories(List<String> accountIds, Map<String, List<String>> oldTerritories, Map<String, List<String>> newTerritories, String platform, String source) {
        Integer previousTerritoryMaxLength = Manual_Territory_Alignment_History_vod__c.SObjectType.getDescribe().fields.getMap().get('Previous_Territories_vod__c').getDescribe().getLength();
        Map<String, String> beforeAssignmentAccountToFormattedTerrStringMap = formatTerritoryNameSet(oldTerritories, previousTerritoryMaxLength);

        Integer newTerritoryMaxLength = Manual_Territory_Alignment_History_vod__c.SObjectType.getDescribe().fields.getMap().get('New_Territories_vod__c').getDescribe().getLength();
        Map<String, String> afterAssignmentAccountToFormattedTerrStringMap = formatTerritoryNameSet(newTerritories, newTerritoryMaxLength);

        createAlignmentHistoriesFuture(accountIds, beforeAssignmentAccountToFormattedTerrStringMap, afterAssignmentAccountToFormattedTerrStringMap, platform, source);
    }

    @Future
    private static void createAlignmentHistoriesFuture(List<String> accountIds, Map<String, String> oldTerritories, Map<String, String> newTerritories, String platform, String source) {
        List<Manual_Territory_Alignment_History_vod__c> alignmentHistories = new List<Manual_Territory_Alignment_History_vod__c>();
        Id userId = UserInfo.getUserId();

        for (String accountId : accountIds) {
            Manual_Territory_Alignment_History_vod__c alignmentHistory = new Manual_Territory_Alignment_History_vod__c(
                User_vod__c = userId,
                Account_vod__c = accountId,
                Previous_Territories_vod__c = oldTerritories.get(accountId),
                New_Territories_vod__c = newTerritories.get(accountId),
                Platform_vod__c = platform,
                Source_vod__c = source
            );
            alignmentHistories.add(alignmentHistory);
        }

        List<Database.SaveResult> results = Database.insert(alignmentHistories, false);

        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                for (Database.Error error : result.getErrors()) {
                    System.debug(LoggingLevel.WARN, 'Failed to insert territory alignment history: ' + error.getMessage());
                }
            }
        }
    }

    public boolean alignmentHistoryPermissionCheck() {
        VeevaBaseObject matBaseObject = VeevaBaseObject.create('Manual_Territory_Alignment_History_vod__c');
        if (matBaseObject == null || !matBaseObject.getDescribe().isCreateable()) {
            return false;
        }

        List<String> requiredReadableFields = new List<String>{
            'User_vod__c', 'Account_vod__c', 'Platform_vod__c', 
            'Source_vod__c', 'Previous_Territories_vod__c', 'New_Territories_vod__c'
        };
        for (String requiredReadableField : requiredReadableFields) {
            DescribeFieldResult fieldDescribe = matBaseObject.getFieldDescribe(requiredReadableField); 
            if (fieldDescribe == null || !fieldDescribe.isAccessible()) {
                return false;
            }
        }
        
        return true;
    }

    private Map<String, String> formatTerritoryNameSet(Map<String, List<String>> accountToTerritoryNamesMap, Integer maxLength) {
        Map<String, String> accountToFormattedTerrStringMap = new Map<String, String>();
        for (String accountId : accountToTerritoryNamesMap.keySet()) {
            accountToFormattedTerrStringMap.put(accountId, joinWithMaxLength(accountToTerritoryNamesMap.get(accountId), maxLength));
        }
        return accountToFormattedTerrStringMap;
    }

    @TestVisible 
    private String joinWithMaxLength(List<String> stringList, Integer maxLength) {
        if (stringList == null || stringList.isEmpty()) {
            return '';
        }
        
        Integer useableMaxLength = maxLength - 2;
        String delimiter = ';';
        String resultSoFar = '';
        
        for (String str : stringList) {
            if (resultSoFar.length() == 0) {
                resultSoFar = str;
            } else {
                String potentialResult = resultSoFar + delimiter + str;
                if (potentialResult.length() <= useableMaxLength) {
                    resultSoFar = potentialResult;
                } else {
                    // If adding the next string exceeds the max length, break the loop.
                    break;
                }
            }
        }
        
        return ';' + resultSoFar + ';';
    }
}