public with sharing class VeevaAddress {
    @AuraEnabled
    public static Map<Id, List<Address_vod__c>> getAllAddresses(List<Id> accountIds, String territoryName, String[] fieldNames, String orderBy, Boolean duplicateRawAddressFields) {
        return mapAddressesByAccountId(getAddress(accountIds, territoryName, fieldNames, orderBy, duplicateRawAddressFields));
    }

    @AuraEnabled
    public static Map<Id, Address_vod__c> getPrimaryAddresses(List<Id> accountIds, String territoryName, String[] fieldNames, Boolean duplicateRawAddressFields) {
        return mapAddressByAccountId(getAddress(accountIds, territoryName, fieldNames, 'Account_vod__c, Primary_vod__c DESC, LastModifiedDate DESC', duplicateRawAddressFields));
    }

    private static List<Address_vod__c> getAddress(List<Id> accountIds, String territoryName, String[] fieldNames, String orderBy, Boolean duplicateRawAddressFields) {
        VeevaBaseObject address = VeevaBaseObject.create('Address_vod__c');
        Set<String> addressAccessibleFields = address.getAccessibleFields(new Set<String>(fieldNames), true, duplicateRawAddressFields);

        Set<String> tsfQueryFields = new Set<String>{'Id','Name','Territory_vod__c'};
        VeevaBaseObject tsf = VeevaBaseObject.create('TSF_vod__c');
        Set<String> tsfAccessibleFields = tsf.getAccessibleFields(tsfQueryFields, false, false);

        String statement = 'SELECT ';
        if(addressAccessibleFields != null && addressAccessibleFields.size() > 0){
            statement += String.join(new List<String>(addressAccessibleFields), ',');
        }
        if(tsfAccessibleFields != null && tsfAccessibleFields.size() > 0){
            statement += ', (SELECT ' + String.join(new List<String>(tsfAccessibleFields), ',') + ' FROM TSF_vod__r WHERE Territory_vod__c = :territoryName)';
        }
        statement += ' FROM Address_vod__c WHERE Account_vod__c IN :accountIds AND Inactive_vod__c = false ORDER BY ' + orderBy;

        return Database.query(statement);
    }

    private static Map<Id, Address_vod__c> mapAddressByAccountId(List<Address_vod__c> addresses) {
        Map<Id, Address_vod__c> addressByAccountId = new Map<Id, Address_vod__c>();
        
        for(Address_vod__c address : addresses) {
            if(!addressByAccountId.containsKey(address.Account_vod__c) || address.TSF_vod__r.size() > 0) {
                addressByAccountId.put(address.Account_vod__c, address);
            }
        }
        return addressByAccountId;
    }

    private static Map<Id, List<Address_vod__c>> mapAddressesByAccountId(List<Address_vod__c> addresses) {
        Map<Id, List<Address_vod__c>> addressesByAccountId = new Map<Id, List<Address_vod__c>>();
        
        for(Address_vod__c address : addresses) {
            if(addressesByAccountId.containsKey(address.Account_vod__c)) {
                addressesByAccountId.get(address.Account_vod__c).add(address);
            } else {
                List<Address_vod__c> a = new List<Address_vod__c>();
                a.add(address);
                addressesByAccountId.put(address.Account_vod__c, a);
            }
        }
        return addressesByAccountId;
    }
}