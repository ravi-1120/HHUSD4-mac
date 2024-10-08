@RestResource(urlMapping='/veeva/global-account-search/*')
global without sharing class VeevaGlobalAccountSearchController {

    global class VeevaGlobalAccountSearchResponse extends VeevaBaseResponse {
        private final Map<String, Object> data;
        private final Map<String, Object> meta;
        private VeevaGlobalAccountSearchResponse(Map<String, Object> results) {
            this.data = new Map<String, Object>();
            this.meta = new Map<String, Object>();
            this.data.put('records', results.get('records'));
            this.meta.put('fields', results.get('fields') );
        }
    }

    @HttpGet
    global static VeevaBaseResponse searchAccountsMobile(){
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        string accountSearchText = request.params.get('accountSearchText');
        string addressSearchText = request.params.get('addressSearchText');
        string accountType = request.params.get('accountType');
        Map<String, Object> searchResults = searchAccounts(accountSearchText, addressSearchText, accountType, 'Mobile', new List<Map<String,Object>>(), new Map<String, String>());
        response.statusCode = 200;
        VeevaBaseResponse gasResponse = new VeevaGlobalAccountSearchResponse(searchResults);
        return gasResponse;
    }

    @HttpPost
    global static VeevaBaseResponse addAccountToTerritory() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        List<String> urlParts = request.requestURI.split('/');
        if (urlParts.size() == 3) {
            response.statusCode = 405;
            return new VeevaBaseResponse('FAILURE', 'Method Not Allowed');
        } else if (urlParts.size() > 3 && urlParts.get(3) != 'import') {
            response.statusCode = 404;
            return new VeevaBaseResponse('FAILURE', 'Not Found');
        }

        try {
            VeevaGASAddToTerritoryRequestBody requestBody = getAddToTerritoryRequestBody(request);
            VeevaGASTerritoryAssignmentResult result = assignAccountAndParentAccountsToTerritories(requestBody);

            if (result.success) {                
                VeevaGASAccountDetailRetriever accountDetailRetriever = new VeevaGASAccountDetailRetriever();
                List<String> parentAccountIds = requestBody.getParentAccountIds() != null ? requestBody.getParentAccountIds() : new List<String>();
                VeevaGASAccountWithDetails accountWithDetails = accountDetailRetriever.retrieveAccountAndRelatedRecords(requestBody.getAccountId(), parentAccountIds);
                
                response.statusCode = 200;
                return new VeevaGASAddToTerritoryResponse(accountWithDetails);
            } else {
                response.statusCode = 500;
                return new VeevaBaseResponse('FAILURE', result.errorMessage);
            }
        } catch (Exception ex) {
            response.statusCode = 500;
            return new VeevaBaseResponse('FAILURE', 'Internal Server Error');
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<Id, RecordType> getAccountRecordTypeInfos() {
        return new Map<Id, RecordType>(
            [SELECT Id, Name, SObjectType, DeveloperName, IsPersonType FROM RecordType
                 WHERE SObjectType = 'Account']
          );
    }

    @AuraEnabled
    public static Map<String, Object> searchAccounts(String searchText, String locationSearchText, String accountType, String platform, List<Map<String, Object>> userFilters, Map<String, String> sortConditions){
        VeevaGlobalAccountSearchProcessor searchProcessor = new VeevaGASSearchProcessorBuilder()
            .withPlatform(platform)
            .withUserFilters(userFilters)
            .withSortConditions(sortConditions)
            .build();
        Map<String, Object> results = searchProcessor.searchAccounts(searchText, locationSearchText, accountType);
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static List<VeevaUserTerritory> getUserTerritories() {
        try {
            TerritoryManagement territoryManagement = TerritoryManagementFactory.getInstance();
            Set<Id> userTerritoryIds = territoryManagement.getUserTerritories(UserInfo.getUserId());

            List<VeevaUserTerritory> userTerritoryList = new List<VeevaUserTerritory>();
            for (Territory2 territory : [SELECT Id, Name FROM Territory2 WHERE Id in :userTerritoryIds]) {
                userTerritoryList.add(new VeevaUserTerritory(territory.Id, territory.Name));
            }
            return userTerritoryList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getParentAccounts(String accountId) {
        try {
            VeevaGASAccountManagement gasAccountManagement = new VeevaGASAccountManagement();
            return gasAccountManagement.getParentAccounts(accountId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getUserAccessibleAddressFields() {
        try {
            List<Schema.SObjectField> addressFieldsInDisplayOrder = new List<Schema.SObjectField>{
                Address_vod__c.Name,
                Address_vod__c.Address_Line_2_vod__c,
                Address_vod__c.City_vod__c,
                Address_vod__c.State_vod__c,
                Address_vod__c.Zip_vod__c
            };
            List<String> userAccessibleAddressFieldsInDisplayOrder = new List<String>();
            for (Schema.SObjectField field : addressFieldsInDisplayOrder) {
                if (field.getDescribe().isAccessible()) {
                    userAccessibleAddressFieldsInDisplayOrder.add(field.getDescribe().getName());
                }
            }
            return userAccessibleAddressFieldsInDisplayOrder;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static VeevaGASTerritoryAssignmentResult assignAccountsToTerritories(List<String> accountIds, List<String> territoryIds, String platform, String source) {
        try {
            List<String> filteredTerritoryIds = filterByUserTerritories(territoryIds);
            if (filteredTerritoryIds.isEmpty()) {
                return new VeevaGASTerritoryAssignmentResult(false, null);
            }
            
            VeevaGASAccountManagement gasAccountManagement = new VeevaGASAccountManagement();
            return gasAccountManagement.assignAccountsToTerritories(accountIds, filteredTerritoryIds, platform, source);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<VeevaGASFilterField> getImplicitFilterFields() {
        try {
            VeevaGASFilterFieldConfig filterFieldConfig = new VeevaGASFilterFieldConfig();
            return filterFieldConfig.getImplicitFilterFields();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<VeevaGASFilterField> getUserFilterFields() {
        try {
            VeevaGASFilterFieldConfig filterFieldConfig = new VeevaGASFilterFieldConfig();
            return filterFieldConfig.getUserFilterFields();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Implicit_Filter_vod__c> getImplicitFilters() {
        try {
            List<Implicit_Filter_vod__c> implicitFilters = new List<Implicit_Filter_vod__c>();
            for (Implicit_Filter_vod__c filter : [SELECT Id, Location_vod__c, Applies_To_vod__c, Inclusion_vod__c,
                    (SELECT Id, Object_Name_vod__c, Field_Name_vod__c FROM Implicit_Filter_Condition_vod__r) FROM Implicit_Filter_vod__c]) {
                implicitFilters.add(filter);
            }
            return implicitFilters;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Implicit_Filter_Condition_vod__c> getImplicitFilterConditions(String implicitFilterId) {
        try {
            List<Implicit_Filter_Condition_vod__c> conditions = new List<Implicit_Filter_Condition_vod__c>();
            for (Implicit_Filter_Condition_vod__c condition : [SELECT Id, Object_Name_vod__c, Field_Name_vod__c, Criteria_vod__c FROM Implicit_Filter_Condition_vod__c WHERE Implicit_Filter_vod__c = :implicitFilterId]) {
                conditions.add(condition);
            }
            return conditions;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Object> getLocationsWithAppliesToValues() {
        try {
            return VeevaGlobalAccountSearchConfiguration.getLocationsWithAppliesTo();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCustomSettingsForNewButtonConfig() {
        Map<String, Object> settingsMap = new Map<String, Object>();
        Network_Settings_vod__c networkSettings = Network_Settings_vod__c.getInstance();
        Veeva_Settings_vod__c veevaSettings = Veeva_Settings_vod__c.getInstance();
        settingsMap.put('networkCustomerMasterMode', getDecimalSettingValueAsString(networkSettings.NETWORK_CUSTOMER_MASTER_MODE_vod__c));
        settingsMap.put('hasNoManagedAccountTypeSettings', String.valueOf(hasNoManagedAccountTypeSettings(networkSettings)));
        settingsMap.put('dcrMode', getDecimalSettingValueAsString(veevaSettings.DATA_CHANGE_REQUEST_MODE_vod__c));
        settingsMap.put('isNAWEnabled', veevaSettings.NEW_ACCOUNT_WIZARD_vod__c);
        return settingsMap;
    }

    private static VeevaGASAddToTerritoryRequestBody getAddToTerritoryRequestBody(RestRequest request) {
        return (VeevaGASAddToTerritoryRequestBody)Json.deserialize(request.requestBody.toString(), VeevaGASAddToTerritoryRequestBody.class);
    }

    private static VeevaGASTerritoryAssignmentResult assignAccountAndParentAccountsToTerritories(VeevaGASAddToTerritoryRequestBody requestBody) {
        VeevaGASAccountManagement gasAccountManagement = new VeevaGASAccountManagement();

        String accountId = requestBody.getAccountId();
        List<String> parentAccountIds = requestBody.getParentAccountIds();
        List<String> accountIds = new List<String>{accountId};
        if (parentAccountIds != null) {
            accountIds.addAll(parentAccountIds);
        }
        List<String> territoryIds = requestBody.getTerritoryIds();
        return gasAccountManagement.assignAccountsToTerritories(accountIds, territoryIds, requestBody.getPlatform(), requestBody.getSource());
    }

    private static boolean hasNoManagedAccountTypeSettings(Network_Settings_vod__c networkSettings){
        String crmManagedTypes = getVeevaMsgFromCustomSetting(networkSettings.CRM_MANAGED_ACCOUNT_TYPES_vod__c);
        String thirdPartManagedTypes = getVeevaMsgFromCustomSetting(networkSettings.THIRD_PARTY_MANAGED_ACCOUNT_TYPES_vod__c);
        return String.isBlank(crmManagedTypes) && String.isBlank(thirdPartManagedTypes);
    }

    private static String getVeevaMsgFromCustomSetting(String customSettingValue){
        String veevaMessageValue;
        if (customSettingValue != null){
            List<String> customSettingArr = customSettingValue.split(';;');
            if (customSettingArr.size() == 2){
                veevaMessageValue = VeevaMessageController.getMsgWithDefault(customSettingArr[0], customSettingArr[1], '');
            }
        }
        return veevaMessageValue;
    }

    private static String getDecimalSettingValueAsString(Decimal settingValue){
        return (settingValue == null ? '' : String.valueOf(settingValue.intValue()));
    }

    private static List<String> filterByUserTerritories(List<String> requestedTerritoryIds) {
        List<VeevaUserTerritory> userTerritories = getUserTerritories();

        Set<String> userTerritoryIds = new Set<String>();
        for (VeevaUserTerritory userTerritory : userTerritories) {
            userTerritoryIds.add(userTerritory.value);
        }

        List<String> validatedTerritoryIds = new List<String>();
        for (String requestedTerritoryId : requestedTerritoryIds) {
            if (userTerritoryIds.contains(requestedTerritoryId)) {
                validatedTerritoryIds.add(requestedTerritoryId);
            }
        }

        return validatedTerritoryIds;
    }
}