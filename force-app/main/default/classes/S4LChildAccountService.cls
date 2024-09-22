public with sharing class S4LChildAccountService {

    public class Location {
        @AuraEnabled
        public Child_Account_vod__c parent;
        @AuraEnabled
        public Boolean isDefault;

        public Location (Child_Account_vod__c parent) {
            this.parent = parent;
            this.isDefault = false;
        }
    }

    @AuraEnabled
    public static List<Location> getChildLocations(Id accountId){
        List<Location> result = new List<Location>();

        List<Child_Account_vod__c> parentAccounts = getParentAccounts(accountId);

        if(parentAccounts != null && !parentAccounts.isEmpty()){
            Location primary = null;

            for(Child_Account_vod__c parentAccount : parentAccounts) {
                Location location = new Location(parentAccount);
                if(Label.Common_Yes_vod == parentAccount.Primary_vod__c) {
                    primary = location;
                }
                result.add(location);
            }

            // if there's only 1 parent, set as default
            if(shouldSetDefaultLocation() || parentAccounts.size() == 1) {
                if(primary != null) {
                    primary.isDefault = true;
                } else {
                    // if none of the parent accounts are primary, use the first location as default
                    result.get(0).isDefault = true;
                }
            }
        }

        return result;
    }

    private static Boolean shouldSetDefaultLocation() {
        return !Veeva_Settings_vod__c.getInstance().Default_Call_Address_None_vod__c;
    }

    private static List<Child_Account_vod__c> getParentAccounts(Id accountId) {
        return [SELECT Id, Parent_Account_vod__c, Parent_Name_vod__c, Parent_Furigana_vod__c, Primary_vod__c
                FROM Child_Account_vod__c
                WHERE Child_Account_vod__c =: accountId AND Parent_Account_vod__c != null
                ORDER BY Parent_Furigana_vod__c, Parent_Name_vod__c ASC];
    }


    @AuraEnabled
    public static List<Call2_vod__c> getChildCallChildAccounts(Id callId) {
        Map<Id, Child_Account_vod__c> childCallChildAccounts;
        List<Call2_vod__c> childCalls = [SELECT Id, Child_Account_vod__c, Child_Account_Id_vod__c, Signature_Date_vod__c FROM Call2_vod__c WHERE Parent_Call_vod__c =: callId];
        if(childCalls != null) {
            Set<String> childAccountIds = new Set<String>();
            for(Call2_vod__c childCall : childCalls) {
                childAccountIds.add((String) MCAConvertToCallController.get(childCall, 'Child_Account_vod__c'));
                childAccountIds.add((String) MCAConvertToCallController.get(childCall, 'Child_Account_Id_vod__c'));
            }
            childAccountIds.remove(null);
            childCallChildAccounts = new Map<Id, Child_Account_vod__c>([
                SELECT Id, Child_Account_vod__c, Parent_Account_vod__c, Primary_vod__c, Parent_Child_Name_vod__c, Parent_Child_Furigana_vod__c
                FROM Child_Account_vod__c
                WHERE Id IN: childAccountIds]);
            for(Call2_vod__c childCall : childCalls) { // add some null checks for child_account and child_account_id
                String childAccountId = childCall.Child_Account_vod__c != null ? childCall.Child_Account_vod__c : childCall.Child_Account_Id_vod__c;
                childCall.Child_Account_vod__r = childCallChildAccounts.get(childAccountId);
            }
        }
        return childCalls;
    }

    @AuraEnabled
    public static List<Child_Account_vod__c> getSuggestedChildAccounts(Id accountId){
        return [SELECT Id, Child_Account_vod__c, Parent_Account_vod__c, Primary_vod__c, Parent_Child_Name_vod__c, Parent_Child_Furigana_vod__c
                FROM Child_Account_vod__c
                WHERE IsDeleted = false AND
                    Child_Account_vod__r.IsPersonAccount = true AND
                    Child_Account_vod__r.Primary_Parent_vod__c =: accountId AND
                    Parent_Account_vod__c =: accountId];
    }

    @AuraEnabled
    public static List<Child_Account_vod__c> refineToChildAccountSearchResult(Id accountId, List<Id> matchedAccountIds){
        List<Child_Account_vod__c> childAccounts = [
            SELECT Id, Child_Account_vod__c, Parent_Account_vod__c, Primary_vod__c, Parent_Child_Name_vod__c, Parent_Child_Furigana_vod__c,
                Child_Account_vod__r.Id, Child_Account_vod__r.Name, Child_Account_vod__r.Primary_Parent_vod__c,
                Child_Account_vod__r.FirstName, Child_Account_vod__r.LastName, Child_Account_vod__r.Do_Not_Call_vod__c,
                Child_Account_vod__r.Account_Identifier_vod__c
            FROM Child_Account_vod__c
            WHERE IsDeleted = false AND
                Child_Account_vod__r.IsPersonAccount = true AND
                (Child_Account_vod__c IN: matchedAccountIds OR Parent_Account_vod__c IN: matchedAccountIds)
            ORDER BY Parent_Child_Furigana_vod__c, Parent_Account_vod__r.Formatted_Name_vod__c
        ];

        Map<Id, Child_Account_vod__c> matches = new Map<Id, Child_Account_vod__c>();
        for(Child_Account_vod__c row : childAccounts) {
            Id currentChild = row.Child_Account_vod__c;
            Child_Account_vod__c selected = matches.get(currentChild);
            if(selected == null) {
                matches.put(currentChild, row);
            } else {
                matches.put(currentChild, getChildAccountHit(selected, row, accountId));
            }
        }
        return matches.values();
    }

    private static Child_Account_vod__c getChildAccountHit(Child_Account_vod__c selected, Child_Account_vod__c row, Id accountId) {
        if(accountId != null) {
            if(selected.Parent_Account_vod__c == accountId) {
                return selected;
            }
            if(row.Parent_Account_vod__c == accountId) {
                return row;
            }
        }
        if(isPrimaryParent(selected)) {
            return selected;
        }
        if(isPrimaryParent(row)) {
            return row;
        }
        String selectedFurigana = selected.Parent_Child_Furigana_vod__c;
        String rowFurigana = row.Parent_Child_Furigana_vod__c;
        if(String.isEmpty(selectedFurigana)) {
            if(String.isNotBlank(rowFurigana)) {
                return row;
            }
        } else {
            if(String.isEmpty(rowFurigana)) {
                return selected;
            } else {
                // both are not empty
                String selectedFuriganaToLower = selectedFurigana.toLowerCase();
                String rowFuriganaToLower = rowFurigana.toLowerCase();
                Integer compare = selectedFuriganaToLower.compareTo(rowFuriganaToLower);
                if(compare < 0) {
                    return selected;
                } else if(compare > 0) {
                    return row;
                }
            }
        }
        String selectedParentChildNameLower = selected.Parent_Child_Name_vod__c.toLowerCase();
        String rowParentChildNameLower = row.Parent_Child_Name_vod__c.toLowerCase();
        return selectedParentChildNameLower.compareTo(rowParentChildNameLower) > 0? row : selected;
    }

    private static boolean isPrimaryParent (Child_Account_vod__c ca) {
        return Label.Common_Yes_vod == ca.Primary_vod__c ||
                (ca.Parent_Account_vod__c != null &&
                ca.Parent_Account_vod__c == ca.Child_Account_vod__r.Primary_Parent_vod__c);
    }

}