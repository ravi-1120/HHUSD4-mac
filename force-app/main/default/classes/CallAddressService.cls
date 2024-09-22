public with sharing class CallAddressService {

    private static List<String> requiredAddressFields = new List<String>{'Inactive_vod__c', 'Primary_vod__c', 'Controlling_Address_vod__c'};
    private static List<String> requiredTsfFields = new List<String>{'Address_vod__c', 'Preferred_Account_vod__c', 'Account_vod__c', 'Territory_vod__c'};

    public static Boolean populateCallAddress(Call2_vod__c call, Id accountId, String territoryName, Id callRecordTypeId) {
        Boolean defaultCallAddressNone = MCAConvertToCallController.getVeevaCustomSettings().Default_Call_Address_None_vod__c == null ? false : MCAConvertToCallController.getVeevaCustomSettings().Default_Call_Address_None_vod__c;
        if (defaultCallAddressNone) {
            return false;
        }
        Boolean enableMyScheduleCallLocation = MCAConvertToCallController.getVeevaCustomSettings().Enable_MySchedule_Call_Location_vod__c == null ? false : MCAConvertToCallController.getVeevaCustomSettings().Enable_MySchedule_Call_Location_vod__c;
        
        List<String> accessibleAddressFields = getAccessibleAddressFields();
        List<String> updateableCallFields = getUpdateableCallFields();

        Address_vod__c defaultAddress;
        Boolean zvodBusinessAccountOnPageLayout = VeevaLayoutService.isFieldOnEditLayout('Call2_vod__c', 'zvod_Business_Account_vod__c', callRecordTypeId);
        if (enableMyScheduleCallLocation && zvodBusinessAccountOnPageLayout) {
            defaultAddress = getDefaultCallAddressFromControllingAddress(accountId, territoryName, accessibleAddressFields, getAccessibleTsfFields());
        } else {
            defaultAddress = getDefaultCallAddressOnlyCheckAccount(accountId, territoryName, accessibleAddressFields);
        }
        if (defaultAddress != null) {
            setCallAddressFields(defaultAddress, accessibleAddressFields, updateableCallFields, call);
            return true;
        }
        return false;
    }

    @TestVisible
    private static Address_vod__c getDefaultCallAddressFromControllingAddress(Id accountId, String territoryName, List<String> accessibleAddressFields, List<String> accessibleTsfFields) {
        if (!hasAllRequiredAddressAndTsfFls(accessibleAddressFields, accessibleTsfFields)) {
            return null;
        }
        List<TSF_vod__c> tsfs = [SELECT Address_vod__c, Preferred_Account_vod__c FROM TSF_vod__c WHERE Account_vod__c = :accountId AND Territory_vod__c = :territoryName]; 
        TSF_vod__c tsf;
        if (tsfs.size() > 0) {
            tsf = tsfs.get(0);
        }
        Id locationId = tsf?.Preferred_Account_vod__c;
        if (locationId == null) {
            return null;
        }

        List<Address_vod__c> preferredLocationAddresses = Database.query('SELECT ' + String.join(accessibleAddressFields, ',') + ' FROM Address_vod__c WHERE Account_vod__c = :locationId AND Inactive_vod__c = false');

        Address_vod__c defaultAddress;
        defaultAddress = getDefaultAddressFromTsfControllingAddress(accessibleAddressFields, locationId, tsf, preferredLocationAddresses);
        if (defaultAddress != null) {
            return defaultAddress;
        }

        defaultAddress = getDefaultAddressFromAccountPrimaryControllingAddress(accessibleAddressFields, accountId, preferredLocationAddresses);
        if (defaultAddress != null) {
            return defaultAddress;
        }

        defaultAddress = getDefaultAddressFromLocationPrimaryAddress(accessibleAddressFields, locationId, accountId, preferredLocationAddresses);
        if (defaultAddress != null) {
            return defaultAddress;
        }
        return null;
    }

    private static Address_vod__c getDefaultAddressFromTsfControllingAddress(List<String> accessibleAddressFields, Id locationId, TSF_vod__c tsf, List<Address_vod__c> preferredLocationAddresses) {
        if (tsf.Address_vod__c != null) {
            List<Address_vod__c> tsfAddresses = Database.query('SELECT ' + String.join(accessibleAddressFields, ',') + ' FROM Address_vod__c WHERE Id = \'' + tsf.Address_vod__c + '\'');
            if (tsfAddresses.size() > 0) {
                Address_vod__c tsfAddress = tsfAddresses.get(0);
                String controlling = tsfAddress.Controlling_Address_vod__c;
                if (controlling != null) {
                    for (Address_vod__c addr : preferredLocationAddresses) {
                        if (addr.Id == controlling) {
                            return tsfAddress;
                        }
                    }
                }
            }
        }
        return null;
    }

    private static Address_vod__c getDefaultAddressFromAccountPrimaryControllingAddress(List<String> accessibleAddressFields, Id accountId, List<Address_vod__c> preferredLocationAddresses) {
        List<Address_vod__c> accountPrimaryAddresses = Database.query('SELECT ' + String.join(accessibleAddressFields, ',') + ' FROM Address_vod__c WHERE Account_vod__c = :accountId AND Primary_vod__c = true'); 
        Address_vod__c accountPrimaryAddress;
        if (accountPrimaryAddresses.size() > 0) {
            accountPrimaryAddress = accountPrimaryAddresses.get(0);
        }
        if (accountPrimaryAddress != null) {
            String controlling = accountPrimaryAddress.Controlling_Address_vod__c;
            if (controlling != null) {
                for (Address_vod__c addr : preferredLocationAddresses) {
                    if (addr.Id == controlling) {
                        return accountPrimaryAddress;
                    }
                }
            }
        }
        return null;
    }

    private static Address_vod__c getDefaultAddressFromLocationPrimaryAddress(List<String> accessibleAddressFields, Id locationId, Id accountId, List<Address_vod__c> preferredLocationAddresses) {
        List<Address_vod__c> locationPrimaryAddresses = Database.query('SELECT ' + String.join(accessibleAddressFields, ',') + ' FROM Address_vod__c WHERE Account_vod__c = :locationId AND Primary_vod__c = true');
        Address_vod__c locationPrimaryAddress;
        if (locationPrimaryAddresses.size() > 0) {
            locationPrimaryAddress = locationPrimaryAddresses.get(0);
        }
        if (locationPrimaryAddress != null) {
            String controlling = locationPrimaryAddress.Id;
            List<Address_vod__c> accountAddresses = Database.query('SELECT ' + String.join(accessibleAddressFields, ',') + ' FROM Address_vod__c WHERE Account_vod__c = :accountId AND Inactive_vod__c = false');
            for (Address_vod__c addr : accountAddresses) { 
                if (controlling == addr.Controlling_Address_vod__c) {
                    return addr;
                }
            }
        }
        return null;
    }

    @TestVisible
    private static Address_vod__c getDefaultCallAddressOnlyCheckAccount(Id accountId, String territoryName, List<String> accessibleAddressFields) {
        // fetch default address from first in hierachy: 1. TSF preferred address, 2. primary address, 3. first address
        Map<Id, Address_vod__c> res = VeevaAddress.getPrimaryAddresses(new List<Id>{accountId}, territoryName, accessibleAddressFields, true);
        Address_vod__c address = res.get(accountId);
        return address;
    }

    private static List<String> getAccessibleAddressFields() {
        List<String> addressFlsToCheck = new List<String>{'Name', 'Account_vod__c', 'Address_Line_2_vod__c', 'City_vod__c', 'State_vod__c', 'Zip_vod__c', 'Zip_4_vod__c', 'Country_vod__c', 'Controlling_Address_vod__c', 'Id', 'Inactive_vod__c', 'Primary_vod__c'};
        List<String> accessibleAddressFields = new List<String>();
        for (Integer i = 0; i < addressFlsToCheck.size(); i++) {
            if (MCAConvertToCallController.canAccessObjectWithFields(Address_vod__c.getSObjectType().getDescribe(), new String[]{addressFlsToCheck.get(i)})) {
                accessibleAddressFields.add(addressFlsToCheck.get(i));
            }
        }
        return accessibleAddressFields;
    }

    private static List<String> getAccessibleTsfFields() {
        List<String> tsfFlsToCheck = new List<String>{'Address_vod__c', 'Preferred_Account_vod__c', 'Account_vod__c', 'Territory_vod__c'};
        List<String> accessibleTsfFields = new List<String>();
        for (Integer i = 0; i < tsfFlsToCheck.size(); i++) {
            if (MCAConvertToCallController.canAccessObjectWithFields(TSF_vod__c.getSObjectType().getDescribe(), new String[]{tsfFlsToCheck.get(i)})) {
                accessibleTsfFields.add(tsfFlsToCheck.get(i));
            }
        }
        return accessibleTsfFields;
    }

    private static List<String> getUpdateableCallFields() {
        List<String> callFlsToCheck = new List<String>{'Address_Line_1_vod__c', 'Address_Line_2_vod__c', 'City_vod__c', 'State_vod__c', 'Zip_vod__c', 'Zip_4_vod__c', 'Parent_Address_vod__c', 'Parent_Address_Id_vod__c', 'Address_vod__c'};
        List<String> updateableCallFields = new List<String>();
        for (Integer i = 0; i < callFlsToCheck.size(); i++) {
            if (MCAConvertToCallController.canUpdateObjectWithFields(Call2_vod__c.getSObjectType().getDescribe(), new String[]{callFlsToCheck.get(i)})) {
                updateableCallFields.add(callFlsToCheck.get(i));
            }
        }
        return updateableCallFields;
    }

    @TestVisible
    private static void setCallAddressFields(Address_vod__c address, List<String> accessibleAddressFields, List<String> updateableCallFields, Call2_vod__c call) {
        String addressStr = '';
        if (address.Name != null) {
            addressStr += address.Name;
            if (updateableCallFields.contains('Address_Line_1_vod__c')) {
                call.Address_Line_1_vod__c = address.Name;
            }
        }
        if (accessibleAddressFields.contains('Address_Line_2_vod__c') && address.Address_Line_2_vod__c != null) {
            if (addressStr != '') {
                addressStr += ', ';
            }
            addressStr += address.Address_Line_2_vod__c;
            if (updateableCallFields.contains('Address_Line_2_vod__c')) {
                call.Address_Line_2_vod__c = address.Address_Line_2_vod__c;
            }
        }
        if (accessibleAddressFields.contains('City_vod__c') && address.City_vod__c != null) {
            if (addressStr != '') {
                addressStr += ', ';
            }
            addressStr += address.City_vod__c;
            if (updateableCallFields.contains('City_vod__c')) {
                call.City_vod__c = address.City_vod__c;
            }
        }
        if (accessibleAddressFields.contains('State_vod__c')) {
            String state = null;
            if (address.get('State_vod__c') != null) {
                state = (String) address.get('State_vod__c');
            }
            String stateLabel = null;
            try {
                stateLabel = (String) address.get('toLabel_State_vod__c');
            } catch (System.SObjectException e) {
                // Handle the case where the aliased field is not present
                // Do nothing, stateLabel remains null
            }
            if (state != null) {
                if (addressStr != '') {
                    addressStr += ', ';
                }
                addressStr += stateLabel != null ? stateLabel : state;
                if (updateableCallFields.contains('State_vod__c')) {
                    call.State_vod__c = state;
                }
            }
        }        
        if (accessibleAddressFields.contains('Zip_vod__c') && updateableCallFields.contains('Zip_vod__c') && address.Zip_vod__c != null) {
            call.Zip_vod__c = address.Zip_vod__c;
        }
        if (accessibleAddressFields.contains('Zip_4_vod__c') && updateableCallFields.contains('Zip_4_vod__c') && address.Zip_4_vod__c != null) {
            call.Zip_4_vod__c = address.Zip_4_vod__c;
        }
        if (accessibleAddressFields.contains('Country_vod__c')) {
            String country = null;
            if (address.get('Country_vod__c') != null) {
                country = (String) address.get('Country_vod__c');
            }
            String countryLabel = null;
            try {
                countryLabel = (String) address.get('toLabel_Country_vod__c');
            } catch (System.SObjectException e) {
                // Handle the case where the aliased field is not present
                // Do nothing, countryLabel remains null
            }
            if (countryLabel != null) {
                country = countryLabel;
            }
            if (country != null) {
                if (addressStr != '') {
                    addressStr += ' ';
                }
                addressStr += country;
            }
        }
        if (updateableCallFields.contains('Parent_Address_vod__c')) {
            call.Parent_Address_vod__c = address.Id;
        }
        if (updateableCallFields.contains('Parent_Address_Id_vod__c')) {
            call.Parent_Address_Id_vod__c = address.Id;
        }
        if (updateableCallFields.contains('Address_vod__c')) {
            call.Address_vod__c = addressStr;
        }
    }

    private static Boolean hasAllRequiredAddressAndTsfFls(List<String> accessibleAddressFields, List<String> accessibleTsfFields) {
        for (Integer i = 0; i < requiredAddressFields.size(); i++) {
            if (!accessibleAddressFields.contains(requiredAddressFields.get(i))) {
                return false;
            }
        }
        for (Integer i = 0; i < requiredTsfFields.size(); i++) {
            if (!accessibleTsfFields.contains(requiredTsfFields.get(i))) {
                return false;
            }
        }
        return true;
    }
}