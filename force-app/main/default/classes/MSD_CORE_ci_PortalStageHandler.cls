public without sharing class MSD_CORE_ci_PortalStageHandler {
    @AuraEnabled(cacheable=true)
    public static List<Product_vod__c> getProducts(String searchTerm) {
        String searchKeyword = String.escapeSingleQuotes(searchTerm);
            
        String searchPattern = '';
        for (Integer i = 0; i < searchKeyword.length(); i++) {
            if (i > 0) {
                 searchPattern += '%';
            }
            searchPattern += searchKeyword.substring(i, i + 1);
        }
        searchPattern += '%';
        String query = 'SELECT Id, Name FROM Product_vod__c ' +
                       'WHERE Name LIKE :searchPattern ' +
                       'AND Product_Type_vod__c = \'Family\' ' +
                       'ORDER BY Name ' +
                       'LIMIT 2000';
        return Database.query(query);
    }
    @AuraEnabled(cacheable=true)
    public static List<Product_vod__c> getFilteredProductIndications() {
        List<Product_vod__c> products = new List<Product_vod__c>();
        String query = 'SELECT Id, Name, Product_Type_vod__c, Active_MRK__c FROM Product_vod__c ' +
                       'WHERE (Product_Type_vod__c = \'Detail\' AND Active_MRK__c = TRUE ' +
                       'AND (Name LIKE \'%KEYTRUDA%\' OR Name LIKE \'%LENVIMA%\' OR Name LIKE \'%LYNPARZA%\')) ' +
                       'LIMIT 50';
    
    products = Database.query(query);
    
    return products;
}
    @AuraEnabled(cacheable=true)
    public static List<String> StageNames() {
        MSD_CORE_CI_PortalSetting__mdt setting = MSD_CORE_CI_PortalSetting__mdt.getInstance('CI_Portal');
        List<String> stageNames = new List<String>();
        if (setting != null && setting.Stage_Names__c != null) {
            stageNames = setting.Stage_Names__c.split(',');
        }
        return stageNames;
    }
    
    @AuraEnabled(cacheable=true)
    public static MSD_CORE_CI_PortalSetting__mdt picklistOptions() {
        MSD_CORE_CI_PortalSetting__mdt portalSetting = [
            SELECT Compet__c, TypeofInfo__c, uploadFile__c, PermissionGranted__c   
            FROM MSD_CORE_CI_PortalSetting__mdt 
            WHERE DeveloperName = 'CI_Portal'
        ];
        return portalSetting;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<MSD_CORE_ci_Wrapper> getEmployeeDetails(String winId, String lastName) {
       String externalId = String.escapeSingleQuotes(winId);
       String escapedLastName = String.escapeSingleQuotes(lastName);
       List<Account> accounts = [
            SELECT Id, Preferred_First_Name_MRK__c, Preferred_Last_Name_MRK__c
            FROM Account
            WHERE External_ID_vod__c =: externalId
            AND RecordType.DeveloperName = 'Employee_MVN'
            AND Preferred_Last_Name_MRK__c =: escapedLastName
       ];
       List<MSD_CORE_ci_Wrapper> wrappedAccounts = new List<MSD_CORE_ci_Wrapper>();
       for (Account acc : accounts) {
            wrappedAccounts.add(new MSD_CORE_ci_Wrapper(acc));
        }
    
        return wrappedAccounts;     
     }
}