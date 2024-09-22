public with sharing class VeevaRemoveFromTerritoryController {

    @AuraEnabled
    public static List<ObjectTerritory2Association> getUserAccountTerritories(String accountId){
        return [SELECT Id, Territory2.Name FROM ObjectTerritory2Association WHERE ObjectId = :accountId AND AssociationCause = 'Territory2Manual'
        AND Territory2Id IN (SELECT Territory2Id FROM UserTerritory2Association WHERE UserId = :UserInfo.getUserId()) ORDER BY Territory2.Name];
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getDCRModeAndRecordTypeId(){
        Map<String, String> dcrModeAndRecordTypeId = new Map<String, String>();

        Integer dcrMode = getDcrMode();
        dcrModeAndRecordTypeId.put('dcrMode', String.valueOf(dcrMode));

        String recordTypeId = getRemoveFromTerritoryRecordTypeId();
        dcrModeAndRecordTypeId.put('recordTypeId', recordTypeId);

        return dcrModeAndRecordTypeId;
    }

    private static Integer getDcrMode() {
        Veeva_Settings_vod__c settings = Veeva_Settings_vod__c.getInstance();
        return settings != null ? Integer.valueOf(settings.DATA_CHANGE_REQUEST_MODE_vod__c) : null;
    }

    private static Id getRemoveFromTerritoryRecordTypeId(){
        RecordType recordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Data_Change_Request_vod__c' AND DeveloperName = 'Remove_From_Territory_vod' AND IsActive = true];
        return recordType != null ? recordType.Id : null;
    }

}