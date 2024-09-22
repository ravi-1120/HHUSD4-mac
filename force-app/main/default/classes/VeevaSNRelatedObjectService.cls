public inherited sharing class VeevaSNRelatedObjectService {

    public static VeevaSNRelatedObjectResponse getRelatedObjectResponse(VeevaSNRelatedObjectRequest relatedObjectRequest) {

        VeevaSNRelatedObjectResponse relatedObjectResponse = new VeevaSNRelatedObjectResponse();
        Map<String, Map<String, Map<String, Object>>> relatedObjectFields = new Map<String, Map<String, Map<String, Object>>>();
        
        for (String key : relatedObjectRequest.relatedObjectFields.keySet()) {
            if (key == 'Address_vod__c') {
                Map<String, Map<String, Object>> res = handleAddressRequest(relatedObjectRequest.accountId, relatedObjectRequest.relatedObjectFields.get(key));
                relatedObjectFields.put(key, res);
            }
        }

        return new VeevaSNRelatedObjectResponse(relatedObjectRequest.accountId, relatedObjectFields);
    }

    // If a TSF Preferred Address exists (TSF_vod.Address_vod) for the user's territory, use that address.
    // -> If the user has > 1 territory, grab the first alphabetically
    // If no TSF Preferred Address exists for the user's territory, display the primary address of the parent account if available.
    // If no TSF Preferred Address or Primary Address exists for the account, use the last modified address for the account.
    private static Map<String, Map<String, Object>> handleAddressRequest(String accountId, List<String> requestedAddressFields) {

        TerritoryManagement tm = TerritoryManagementFactory.getInstance();
        Set<Id> userTerrIds = tm.getUserTerritories(UserInfo.getUserId());
        List<String> userTerrNames = tm.getTerritoryNames(userTerrIds);
        userTerrNames.sort();

        String territoryName = (userTerrNames.size() > 0) ? userTerrNames[0] : '';

        if (!requestedAddressFields.contains('Account_vod__c')) {
            requestedAddressFields.add('Account_vod__c'); // required by VeevaAddress method
        }
        Map<Id, Address_vod__c> addressById = VeevaAddress.getPrimaryAddresses(new List<String>{accountId}, territoryName, requestedAddressFields, true);

        Address_vod__c address = addressById.get(Id.valueOf(accountId));
        if (address == null) {
            return new Map<String, Map<String, Object>>();
        }

        return VeevaSNQueryService.extractFormattedFieldsFromQueryResult(address, 'Address_vod__c', requestedAddressFields);
    }
}