public without sharing class MSD_CORE_ae_PortalStageHandler {

    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getPicklist(String objectApiName, String fieldApiName) {
        List<PicklistOption> picklistOptions = new List<PicklistOption>();
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
        if (sObjType == null) {
            return null;
        }
        Schema.DescribeSObjectResult objDescribe = sObjType.getDescribe();
        Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get(fieldApiName).getDescribe();
        for (Schema.PicklistEntry picklistEntry : fieldDescribe.getPicklistValues()) {
            PicklistOption option = new PicklistOption();
            option.label = picklistEntry.getLabel();
            option.value = picklistEntry.getValue();
            picklistOptions.add(option);
        }
        return picklistOptions;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<MSD_CORE_ae_Wrapper> getEmployeeDetails(String winId, String lastName) {
       String externalId = String.escapeSingleQuotes(winId);
       String escapedLastName = String.escapeSingleQuotes(lastName);
       List<Account> accounts = [
            SELECT Id, Preferred_First_Name_MRK__c, Preferred_Last_Name_MRK__c, Phone, PersonEmail,
                   Class_of_Trade_MRK__c, MSD_CORE_Primary_Address_Line_1__c, MSD_CORE_Primary_Address_Line_2__c,
                   MSD_CORE_Primary_Zip__c, MSD_CORE_Primary_City__c, PersonMailingCountryCode, MSD_CORE_Primary_State__c
            FROM Account
            WHERE External_ID_vod__c =: externalId
            AND RecordType.DeveloperName = 'Employee_MVN'
            AND Preferred_Last_Name_MRK__c =: escapedLastName
       ];
       List<MSD_CORE_ae_Wrapper> wrappedAccounts = new List<MSD_CORE_ae_Wrapper>();
       for (Account acc : accounts) {
            wrappedAccounts.add(new MSD_CORE_ae_Wrapper(acc));
        }
    
        return wrappedAccounts;     
     }
    /*@AuraEnabled ( cacheable= true)
    public static List<Product_vod__c> getProducts(String searchTerm){
        List<String> productTypes = new List<String>{'Family','Strength'};
            String searchKeyword = String.escapeSingleQuotes(searchTerm);
        String query = 'SELECT Name FROM Product_vod__c WHERE (Name LIKE \'%' + searchKeyword + '%\') ' +
                   'AND (Product_Type_vod__c IN :productTypes) ORDER BY Name LIMIT 50';
        return Database.query(query);
            
}*/
    @AuraEnabled( cacheable= true)
    public static List<Product_vod__c> getProducts(String searchTerm, List<String> productTypes){
        // Create a dynamic query based on the searchTerm
        //List<String> productTypes = new List<String>{'Family','Strength'};
        String searchKeyword = String.escapeSingleQuotes(searchTerm);
            
        String searchPattern = '';
        for (Integer i = 0; i < searchKeyword.length(); i++) {
            if (i > 0) {
                 searchPattern += '%';
            }
            searchPattern += searchKeyword.substring(i, i + 1);
        }
        searchPattern += '%';
        System.debug('Search Term is:-' +searchPattern);
        String query = 'SELECT Name FROM Product_vod__c WHERE (Name LIKE \'%' + searchPattern + '%\') ' +
                   'AND (Product_Type_vod__c IN :productTypes) ORDER BY Name LIMIT 2000';
        return Database.query(query);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<MSD_CORE_AE_Contact__c> getCredentials(String searchTerm) {
        System.debug('Original searchTerm: ' + searchTerm);
        String searchKeyword = String.escapeSingleQuotes(searchTerm);
        String searchPattern = '';
        for (Integer i = 0; i < searchKeyword.length(); i++) {
            if (i > 0) {
                 searchPattern += '%';
            }
            searchPattern += searchKeyword.substring(i, i + 1);
        }
        searchPattern += '%';
        String query = 'SELECT Id, Name, MSD_CORE_Credentials__c FROM MSD_CORE_AE_Contact__c ' +
                       'WHERE MSD_CORE_Credentials__c LIKE :searchPattern ' +
                       'ORDER BY MSD_CORE_Credentials__c LIMIT 200';
        List<MSD_CORE_AE_Contact__c> results = Database.query(query);
        System.debug('Query results: ' + results);
        return results;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static MSD_CORE_ae_PortalSetting__mdt picklistOptions() {
        MSD_CORE_ae_PortalSetting__mdt portalSetting = [
            SELECT Reporters__c, Present_Status__c, Rechallenge__c, Dechallenge__c,Validate_Count__c,
            Reporting_AEs_for_multiple_patients__c, Patient_Reported_this_AE_to_you__c, HBP_Type__c, Licensed_HCP__c, Patients_HCP__c, Upload_File__c,
            Permission_to_Contact__c, Product_Types__c, Product_Limit__c, File_Format__c, Field_Based__c, First_Report__c, Permission__c, Country__c 
            FROM MSD_CORE_ae_PortalSetting__mdt 
            WHERE DeveloperName = 'AE_Portal'
        ];

        return portalSetting;
    }
 
}