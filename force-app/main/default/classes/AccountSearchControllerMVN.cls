/*
 * AccountSearchControllerMVN
 * Created by: Vincent Reeder
 * Created Date: January 9, 2012
 * Modified On: September 11, 2015
 * Description: Controller for the Account Search page.
 *              Enables searching for Customers/Businesses via different
 *              search parameters such as Name, Phone, City, State, Postal Code,
 *              Country, Employee Number, and Customer Number.  
 *              It also allows creation of new Customers (HCPs/HBPs/Consumers)
 *              as well as Businesses.  The controler also provides the ability to
 *              affiliate a Customer to a Business.
 *              If enough information to submit a Data Change Request is supplied for
 *              HCP/HBP/Business Accounts then a Data Change Request will be
 *              created.
 * 
 * Change Log: 
 *              KRB REL 9.0 CR 3/13/2017 - Article Search will now be based on either the Customer 
                Type or (new for REL 9.0) the referredBy Customer Type. Inserted code to handle the
                loading/removal of the referredBy Customer Type when a referred by costumer Type is 
                either added or removed.  
 * 
 */

public with sharing class AccountSearchControllerMVN {

    private static Integer SEARCHLIMIT = (Integer) Service_Cloud_Settings_MVN__c.getInstance().Account_Search_Max_Results_MVN__c;
    private static String NONEOPTION = Label.Common_None_vod;
                
    public Map<String, RecordType> recordTypes { get; set; }
    public Map<String, String> typeToRecordTypeIdMapping { get; set; }
    public Set<String> businessTypes { get; set; }
    public List<SelectOption> businessRecordTypeSelectOptions { get; set; }
    public Set<String> typesThatHaveBusinessAddress { get; set; }
    public Set<String> activePersonTypes { get; set; }
    public Set<String> countriesThatRequireState { get; set; }
    public Set<String> typesThatRequireFirstName { get; set; }
    public Map<String, Schema.SObjectField> addressFieldMap { get; set; }
    public Id companyMaintainedRecordType { get; set; }
    public Set<Id> dcrRecordTypeIds { get; set; }

    public String typeText { get; set; }
    public List<SelectOption> typeSelectOptions { get; set; }
    public List<SelectOption> typeNewSelectOptions { get; set; }    

    public String reqId {get;set;}
    public Id accountLinkId {get; private set;}
    public String refId {get;set;}
    public String businessId { get; set; }
    public Case cs {get; set;}
    public Boolean isPersonSearch { get; set; }
    public Id recentlyAddedPerson { get; set; }
    public Id recentlyAddedBusiness { get; set; }
    public Boolean isAddressEmpty { get; set; }
    public Boolean isAddressRequired { get; set; }
    public Boolean isStateRequired { get; set; }

    public Address_vod__c searchAddress {get;set;}
    public Address_vod__c createAddress {get;set;}
    public Account searchAccount {get;set;}
    public Account accountToSearch { get; set; }
    public Account createAccount {get;set;}
    public String searchFirstName { get; set; }
    public String searchLastName { get; set; }
    public String searchName { get; set; }
    public String alternateId {get;set;}
    public String searchMerckID {get; set;} // Added for Merck_id_Search
    public String searchMerckIDpersonAccount {get; set;} // Added for Merck_id_Search
    public Boolean isPrescriber { get; set; }
    public Boolean isDCR { get; set; }

    public String selectedType { get; set; }
    public String hcpType { get; set; }
    public String hbpType { get; set; }
    public String employeeType { get; set; }
    public String consumerType { get; set; }

    public Account affiliationTo { get; set; }
    public Account affiliationFrom { get; set; }
    public Child_Account_vod__c affiliation { get; set; }
    public Id childAccountMerckRecordTypeId { get; set; }
    public Boolean showAffiliationModal { get; set; }
    public Boolean didAffiliationCreateSucceed { get; set; }
    public String affiliationPrompt { get; set; }

    public Id hcpRecordTypeId {get; set;}
    public Id employeeRecordTypeId {get; set;}
    public Map<String, AccountSearchResultMockMVN> resultMap {get;set;}

    public Boolean didInsertSucceed {get;set;}
    public Boolean didSearch {get;set;}
    public Boolean didTryCreate {get;set;}
    public Boolean showNewButton {get;set;}
    public Boolean createReferredBy{get; set;}
    public Boolean removeAccountError{get; set;}
    public Boolean standAloneSearch{get; set;}
    public Boolean isReadOnlyUser{get; set;}

    public String customerPreferedName {get; private set;}
    public String referedByPreferedName {get; private set;}

    private Service_Cloud_Settings_MVN__c serviceCloudSettings;
    private String caseId;

    private ApexPages.StandardController ctrl;
    private Set<String> countrySet;
    private User runningUser;
    private List<AccountSearchUtilityMVN.searchInterface> accountSearchUtilities;

    static {
        if(SEARCHLIMIT == null || SEARCHLIMIT < 1) {
            SEARCHLIMIT = 50;
        }
    }

    public AccountSearchControllerMVN(ApexPages.StandardController controller){
        typeText = Label.Account_Search_All_Record_Type;
        serviceCloudSettings = Service_Cloud_Settings_MVN__c.getInstance();
        accountSearchUtilities = new List<AccountSearchUtilityMVN.searchInterface>();
        for (String utilityClass: UtilitiesMVN.splitCommaSeparatedString(serviceCloudSettings.Account_Search_Utility_Classes_MVN__c)) {
            try {
                Type t = Type.forName(utilityClass);
                AccountSearchUtilityMVN.searchInterface utilityInstance = (AccountSearchUtilityMVN.searchInterface) t.newInstance();
                accountSearchUtilities.add(utilityInstance);
            } catch(Exception e) {
                ApexPages.addMessages(e);
            }
        }

        affiliationFrom = null;
        affiliationTo = null;
        showAffiliationModal = false;
        removeAccountError = false;
        didTryCreate = false;
        didInsertSucceed = false;
        showNewButton = false;
        isPersonSearch = true;
        recentlyAddedPerson = null;
        recentlyAddedBusiness = null;
        isAddressEmpty = true;
        isPrescriber = false;
        isDCR = false;

        isReadOnlyUser = UtilitiesMVN.isReadOnlyUser;

        List<String> dcrRecordTypeDeveloperNames = UtilitiesMVN.splitCommaSeparatedString(serviceCloudSettings.MSD_CORE_DCR_Record_Types__c);

        employeeRecordTypeId = [select Id from RecordType where SObjectType='Account' and DeveloperName = :serviceCloudSettings.Employee_Record_Type_MVN__c].Id;
        hcpRecordTypeId = [select Id from RecordType where SObjectType='Account' and DeveloperName = :serviceCloudSettings.HCP_Record_Type_MVN__c].Id;
        childAccountMerckRecordTypeId = [select Id from RecordType where SObjectType='Child_Account_vod__c' and DeveloperName = :serviceCloudSettings.MSD_CORE_Merck_Affiliation_Record_Type__c].Id;
        companyMaintainedRecordType = [select Id from RecordType where SObjectType='Address_vod__c' and DeveloperName = :serviceCloudSettings.MSD_CORE_Company_Maintained_Rec_Type__c].Id;
        List<RecordType> dcrRecordTypes = [select Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName IN :dcrRecordTypeDeveloperNames];
        
        dcrRecordTypeIds = new Set<Id>();
        for(RecordType dcrRecordType : dcrRecordTypes){
            dcrRecordTypeIds.add(dcrRecordType.Id);
        }

        typesThatHaveBusinessAddress = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(serviceCloudSettings.MSD_CORE_Type_Has_Business_Address__c));
        activePersonTypes = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(serviceCloudSettings.MSD_CORE_Active_Person_Types__c));
        typesThatRequireFirstName = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(serviceCloudSettings.MSD_CORE_Types_Require_First_Name__c));
        countriesThatRequireState = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(serviceCloudSettings.MSD_CORE_Address_Country_Requires_State__c));
        hcpType = serviceCloudSettings.MSD_CORE_HCP_Type__c;
        hbpType = serviceCloudSettings.MSD_CORE_HBP_Type__c;
        employeeType = serviceCloudSettings.MSD_CORE_Employee_Type__c;
        consumerType = serviceCloudSettings.MSD_CORE_Consumer_Type__c;
        addressFieldMap = Schema.getGlobalDescribe().get('Address_vod__c').getDescribe().fields.getMap();

        if(null != ApexPages.currentPage().getParameters().get('isPersonSearch')){
            isPersonSearch = ApexPages.currentPage().getParameters().get('isPersonSearch') == '1';            
        }

        cs = (Case) controller.getRecord();
        caseId = ApexPages.currentPage().getParameters().get('caseId');

        if(caseId != null && caseId != ''){
            getCaseValues();
            standAloneSearch = false;
        } else {
            standAloneSearch = true;
        }

        runningUser = [Select Country, MSD_CORE_Country_Code__c from User where Id = :UserInfo.getUserId()];
        countrySet = new Set<String>();
        
        for(Schema.PicklistEntry countryPicklistValue:Address_vod__c.Country_vod__c.getDescribe().getPicklistValues()){
            countrySet.add(countryPicklistValue.getValue());
        }

        clearSearch();

        initializeRecordTypeMap();

        initializeTypeToRecordTypeMapping();

        initializeTypeSelectOptions();

        if(processSearchParams()){
            doSearch();
            if(!(String.isBlank(searchAccount.Phone) && 
                (isPersonSearch && String.isBlank(searchAccount.MSD_CORE_Merck_Employee_ID__c)) ||
                (!isPersonSearch && String.isBlank(alternateId)))){

                showNewButton = false;
            }
        }
    }

    public List<AccountSearchResultMockMVN> orderedResultList {
        get {
            if(resultMap == null || resultMap.size() == 0) {
                return new List<AccountSearchResultMockMVN>();
            }
            
            List<AccountSearchResultMockMVN> asrMockList = resultMap.values();
            asrMockList.sort();
            
            return asrMockList;
        }
    }

    // Process params passed in via query string from the quick search in Selected Requester
    // or from the CTI integration via the Create Case Redirect page
    public Boolean processSearchParams(){
        Boolean passedParams = false;
        if(null != ApexPages.currentPage().getParameters().get('type')){
            typeText = ApexPages.currentPage().getParameters().get('type');
        }

        if(null != ApexPages.currentPage().getParameters().get('name')){
            searchName = ApexPages.currentPage().getParameters().get('name');
            passedParams = true;
        }

        if(null != ApexPages.currentPage().getParameters().get('lastName')){
            searchLastName = ApexPages.currentPage().getParameters().get('lastName');
            passedParams = true;
        }

        if(null != ApexPages.currentPage().getParameters().get('firstName')){
            searchFirstName = ApexPages.currentPage().getParameters().get('firstName');
            passedParams = true;
        }

        if(null != ApexPages.currentPage().getParameters().get('phone')){
            searchAccount.Phone = ApexPages.currentPage().getParameters().get('phone');
            passedParams = true;
        }

        if(null != ApexPages.currentPage().getParameters().get('phoneSearch')){
            searchAccount.Phone = ApexPages.currentPage().getParameters().get('phoneSearch');
            passedParams = true;
        }

        if(null != ApexPages.currentPage().getParameters().get('employeeNumber')){
            searchAccount.MSD_CORE_Merck_Employee_ID__c = ApexPages.currentPage().getParameters().get('employeeNumber');
            passedParams = true;
        }

        if(null != ApexPages.currentPage().getParameters().get('customerNumber')){
            alternateId = ApexPages.currentPage().getParameters().get('customerNumber');
            passedParams = true;
        }

        if(null != ApexPages.currentPage().getParameters().get('employeeNumberSearch')){
            searchAccount.MSD_CORE_Merck_Employee_ID__c = ApexPages.currentPage().getParameters().get('employeeNumberSearch');
            passedParams = true;
        }

        if(null != ApexPages.currentPage().getParameters().get('customerNumberSearch')){
            alternateId = ApexPages.currentPage().getParameters().get('customerNumberSearch');
            passedParams = true;
        }
        // Added for Merck_id_Search
        if(null != ApexPages.currentPage().getParameters().get('merckId')){
            searchMerckID = ApexPages.currentPage().getParameters().get('merckId');
            passedParams = true;
        }
        if(null != ApexPages.currentPage().getParameters().get('masterId')){
            searchMerckIDpersonAccount = ApexPages.currentPage().getParameters().get('masterId');
            System.debug('Master ID in Person Account Search: '+ApexPages.currentPage().getParameters().get('masterId'));
            passedParams = true;
        }
        //end code
        if(null != ApexPages.currentPage().getParameters().get('city')){
            searchAddress.City_vod__c = ApexPages.currentPage().getParameters().get('city');
            passedParams = true;
        }

        if(null != ApexPages.currentPage().getParameters().get('zip')){
            searchAddress.Zip_vod__c = ApexPages.currentPage().getParameters().get('zip');
            passedParams = true;
        }

        if(null != ApexPages.currentPage().getParameters().get('country')){
            searchAddress.Country_vod__c = ApexPages.currentPage().getParameters().get('country');
            passedParams = true;

            if(null != ApexPages.currentPage().getParameters().get('state')){
                searchAddress.State_vod__c = ApexPages.currentPage().getParameters().get('state');
            }
        }

        return passedParams;
    }

    // Create a map of Account record types
    public void initializeRecordTypeMap() {        
        recordTypes = recordTypeMap();
    }

    private void initializeTypeToRecordTypeMapping(){
        typeToRecordTypeIdMapping = new Map<String, String>();
        businessTypes = new Set<String>();

        List<MSD_CORE_Type_To_Record_Type_Map__c> mapSettingsList = 
            MSD_CORE_Type_To_Record_Type_Map__c.getAll().values();

        for(MSD_CORE_Type_To_Record_Type_Map__c mapSetting : mapSettingsList){
            if(!recordTypes.containsKey(mapSetting.MSD_CORE_Record_Type_MVN__c)){
                continue;                
            }

            if(!typeToRecordTypeIdMapping.containsKey(mapSetting.MSD_CORE_Type_MVN__c)){
                typeToRecordTypeIdMapping.put(mapSetting.MSD_CORE_Type_MVN__c, recordTypes.get(mapSetting.MSD_CORE_Record_Type_MVN__c).Id);
            }

            if(!mapSetting.MSD_CORE_Is_Person_Type__c){
                businessTypes.add(mapSetting.MSD_CORE_Type_MVN__c);
            }
        }
    }

    private Map<String,RecordType> recordTypeMap(){
        Map<String,RecordType> recordTypes = new Map<String,RecordType>();
        for(RecordType rt : [SELECT Id, Name, DeveloperName, IsActive, IsPersonType FROM RecordType WHERE sObjectType = 'Account']){
            recordTypes.put(rt.DeveloperName,rt);
        }
        return recordTypes;
    }

    // Setup the Type picklist
    public void initializeTypeSelectOptions(){
        typeSelectOptions = new List<SelectOption>();
        typeNewSelectOptions = new List<SelectOption>();        
        typeNewSelectOptions.add(new SelectOption(NONEOPTION, Label.Picklist_Select_Option));

        Schema.DescribeFieldResult fieldResult = Account.Class_of_Trade_MRK__c.getDescribe();
        List<Schema.PicklistEntry> typeOptions = fieldResult.getPicklistValues();

        if(isPersonSearch){            
            Set<String> validTypes = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(serviceCloudSettings.Person_Account_Search_Types_MVN__c));
            for(Schema.PicklistEntry typeOption : typeOptions){
                String typeValue = typeOption.getValue();
                String typeLabel = typeOption.getLabel();
                if(validTypes.contains(typeValue)){                
                    if(typeValue == hcpType){
                        SelectOption prescriberOptionType = new SelectOption(typeLabel + ' ' + Label.MSD_CORE_Prescriber_Type_Suffix,
                            typeValue + ' ' + Label.MSD_CORE_Prescriber_Type_Suffix);
                        SelectOption nonPrescriberOptionType = new SelectOption(typeLabel + ' ' + Label.MSD_CORE_Non_Prescriber_Type_Suffix,
                            typeValue + ' ' + Label.MSD_CORE_Non_Prescriber_Type_Suffix);
                        typeNewSelectOptions.add(prescriberOptionType);
                        typeNewSelectOptions.add(nonPrescriberOptionType);
                    } else {
                        typeNewSelectOptions.add(new SelectOption(typeLabel,typeValue));
                    }
                    typeSelectOptions.add(new SelectOption(typeLabel,typeValue));
                }
            }
        } else {
            for(Schema.PicklistEntry typeOption : typeOptions){
                String typeValue = typeOption.getValue();
                String typeLabel = typeOption.getLabel();
                if(businessTypes.contains(typeValue)){
                    typeNewSelectOptions.add(new SelectOption(typeLabel,typeValue));
                }
            }
        }
    }

    // Retrieve all of the necessary data for the Interaction from which
    // the search was invoked
    public void getCaseValues() {
        if(caseId != null && caseId != ''){
            caseId = String.escapeSingleQuotes(caseId);
        } else {
            return;
        }

        List<Case> cases = [select Id, AccountId, Account.Name, 
                                Account.Salutation, Account.Merck_ID_MRK__c, 
                                Referred_By_MVN__c, Referred_By_MVN__r.Name, 
                                Referred_By_MVN__r.Merck_ID_MRK__c, 
                                MSD_CORE_Business__c, MSD_CORE_Business__r.Merck_ID_MRK__c, 
                                MSD_CORE_Business__r.Name,
                                Referred_By_MVN__r.Preferred_First_Name_MRK__c,
                                Referred_By_MVN__r.Preferred_Last_Name_MRK__c,
                                Referred_By_MVN__r.Preferred_Salutation_MRK__c,
                                Account.Preferred_First_Name_MRK__c,
                                Account.Preferred_Last_Name_MRK__c,
                                Account.Preferred_Salutation_MRK__c,
                                MSD_CORE_Business__r.Preferred_Full_Name_MRK__c 
                            from Case 
                            where Id = :caseId LIMIT 1];
        if(cases.size() > 0){
            cs = cases[0];

            if(cs.account.Id != null) {
                if(String.isBlank(cs.account.Preferred_Salutation_MRK__c)) {
                    customerPreferedName = (cs.account.Preferred_First_Name_MRK__c != null ? cs.account.Preferred_First_Name_MRK__c + ' ': '') + (cs.account.Preferred_Last_Name_MRK__c != null ? cs.account.Preferred_Last_Name_MRK__c : ''); 
                } else {
                    customerPreferedName = cs.account.Preferred_Salutation_MRK__c + ' ' + (cs.account.Preferred_First_Name_MRK__c != null ? cs.account.Preferred_First_Name_MRK__c + ' ': '') + (cs.account.Preferred_Last_Name_MRK__c != null ? cs.account.Preferred_Last_Name_MRK__c : '');
                }
            }

            if(cs.Referred_By_MVN__c != null) {
                if(String.isBlank(cs.Referred_By_MVN__r.Preferred_Salutation_MRK__c)) {
                    referedByPreferedName = (cs.Referred_By_MVN__r.Preferred_First_Name_MRK__c != null ? cs.Referred_By_MVN__r.Preferred_First_Name_MRK__c + ' ': '') + (cs.Referred_By_MVN__r.Preferred_Last_Name_MRK__c != null ? cs.Referred_By_MVN__r.Preferred_Last_Name_MRK__c : ''); 
                } else {
                    referedByPreferedName = cs.Referred_By_MVN__r.Preferred_Salutation_MRK__c + ' ' + (cs.Referred_By_MVN__r.Preferred_First_Name_MRK__c != null ? cs.Referred_By_MVN__r.Preferred_First_Name_MRK__c + ' ': '') + (cs.Referred_By_MVN__r.Preferred_Last_Name_MRK__c != null ? cs.Referred_By_MVN__r.Preferred_Last_Name_MRK__c : '');
                }
            }
        } else {
            System.debug(LoggingLevel.ERROR, 'Missing a case for caseId ' + caseId);
        }
    }

    // Remove the selected "Customer" from the Interaction
    public PageReference removeRequester(){
        cs.AccountId = null;
        cs.ContactId = null;
        cs.Address_MVN__c = null;
        cs.case_Account_Email_MVN__c = null;
        cs.case_City_MVN__c = null;
        cs.case_AddressLine1_MVN__c = null;
        cs.case_AddressLine2_MVN__c = null;
        cs.case_State_MVN__c = null;
        cs.case_Postal_Code_MVN__c = null;
        cs.case_Account_Phone_MVN__c = null;
        cs.case_Account_Fax_MVN__c = null;

        try{
            update cs;
        }catch(Exception e){
            ApexPages.addMessages(e);
            removeAccountError = true;
        }
        getCaseValues();

        return null;
    }

    public PageReference removeReferredBy(){
        cs.Referred_By_MVN__c = null;
        
        //KRB REL 9.0 3/10/2017
        cs.MSD_CORE_Referred_By_Customer_Type__c = null;

        try{
            update cs;
        }catch(Exception e){
            ApexPages.addMessages(e);
            removeAccountError = true;
        }
        getCaseValues();

        return null;
    }

    public PageReference addReferredBy(){
        cs.Referred_By_MVN__c = refId;
        
        //KRB REL 9.0 3/13/2017 Start Code
        List<Account> referredByCustomerTypeList = new List<Account>();
            
        referredByCustomerTypeList = [SELECT Class_of_Trade_MRK__c 
                                      FROM   Account 
                                      WHERE  ID = : refId ];
        
        if(!referredByCustomerTypeList.isEmpty()){
           cs.MSD_CORE_Referred_By_Customer_Type__c =  referredByCustomerTypeList[0].Class_of_Trade_MRK__c;
        }
        //KRB REL 9.0 3/13/2017 End Code
        
        try{
            update cs;
        }catch(Exception e){
            ApexPages.addMessages(e);
        }

        recentlyAddedPerson = refId;

        getCaseValues();

        return null;
    }

    public PageReference addBusiness(){
        cs.MSD_CORE_Business__c = businessId;

        try {
            update cs;
        } catch(Exception e){
            ApexPages.addMessages(e);
        }

        recentlyAddedBusiness = businessId;

        getCaseValues();

        return null;
    }
    
    @AuraEnabled
    public static String addBusinessAura(String businessId, String csId){
        Case cs = new Case(Id = csId, MSD_CORE_Business__c = businessId);

        try {
            update cs;
        } catch(Exception e){
            ApexPages.addMessages(e);
        }

        return null;
    }

    public PageReference removeBusiness(){
        cs.MSD_CORE_Business__c = null;

        try{
            update cs;
        }catch(Exception e){
            ApexPages.addMessages(e);
            removeAccountError = true;
        }
        getCaseValues();

        return null;
    }

    public PageReference changeType() {        
        showNewButton = false;
        createAccount.Fax = null;
        return null;
    }

    // Actions performed when an agent selects the type of the Customer
    public PageReference typeSelected(){
        isPrescriber = false;
        isDCR = false;
        String cleanSelectedType = selectedType;
        if(cleanSelectedType.endsWithIgnoreCase(Label.MSD_CORE_Prescriber_Type_Suffix)){
            isPrescriber = true;
            cleanSelectedType = cleanSelectedType.removeEnd(' ' + Label.MSD_CORE_Prescriber_Type_Suffix);
        }

        if(cleanSelectedType.endsWithIgnoreCase(Label.MSD_CORE_Non_Prescriber_Type_Suffix)){
            cleanSelectedType = cleanSelectedType.removeEnd(' ' + Label.MSD_CORE_Non_Prescriber_Type_Suffix);
        }

        if(cleanSelectedType == NONEOPTION || cleanSelectedType == null){
            createAccount.Class_of_Trade_MRK__c = null;
        } else {
            createAccount.Class_of_Trade_MRK__c = cleanSelectedType;
            if(createAccount.Class_of_Trade_MRK__c == hcpType && isPrescriber){
                createAccount.RecordTypeId = hcpRecordTypeId;
            } else {
                createAccount.RecordTypeId = getRecordTypeIdFromType(createAccount);
            }
            isDCR = dcrRecordTypeIds.contains(createAccount.RecordTypeId);
        }       
        return null;
    }

    // Method used when New Customer/Referred By/Business buttons are used
    // and sets up the corresponding data
    public PageReference updateNewAccount() {
        createAccount = null;
        createAddress = searchAddress.clone();
        checkAddress();
        createAccount = searchAccount.clone();
        
        if(isPersonSearch){
            createAccount.Preferred_First_Name_MRK__c = searchFirstName;
            createAccount.Preferred_Last_Name_MRK__c = searchLastName;
        } else {
            createAccount.Preferred_Full_Name_MRK__c = searchName;
        }

        List<String> fNames = new List<String>{'City_vod__c','Zip_vod__c'};
        for(String field : fNames) {
            String value = (String) createAddress.get(field);
            if(!String.isBlank(value)) {
                createAddress.put(field,value.replaceAll('\\*',''));
            }
        }

        fNames = new List<String>{'Preferred_Full_Name_MRK__c','Preferred_First_Name_MRK__c','Preferred_Last_Name_MRK__c','Preferred_Middle_Name_MRK__c','Phone'};
        for(String field : fNames) {
            String value = (String) createAccount.get(field);
            if(!String.isBlank(value)) {
                createAccount.put(field,value.replaceAll('\\*',''));
            }
        }
        isPrescriber = false;

        if(typeText != Label.Account_Search_All_Record_Type && typeText != hcpType){
            selectedType = typeText; 
            typeSelected();   
            
        } else {
            selectedType = null;
        }
        return null;
    }

    // Update the Case values after a Customer or Referred By is selected
    public PageReference updateCase(){
        AccountSearchResultMockMVN selectedPerson = getSelectedAccount();

        if (selectedPerson != null) {
            Account selectedAccount = selectedPerson.getAccount();
            Address_vod__c selectedAddress = selectedPerson.getAddress();

            cs.AccountId = selectedAccount.Id;
            cs.Address_MVN__c = selectedAddress.Id;
            cs.case_Account_Email_MVN__c = selectedAccount.PersonEmail;
            cs.case_Account_Phone_MVN__c = selectedAccount.Phone;
            cs.case_Account_Fax_MVN__c = selectedAccount.Fax;

            try{
                update cs;
            }catch(Exception e){
                ApexPages.addMessages(e);
            }

            recentlyAddedPerson = selectedAccount.Id;

            getCaseValues();
        }

        return null;
    }
    
    
    @AuraEnabled
    public static String updateCaseAura(String selectedPersonId, String selectedAddressId, String csId){
        if (selectedPersonId != null && selectedAddressId != null) {
            Account selectedAccount = [select id, PersonEmail, Phone, Fax from Account where id =: selectedPersonId];
            System.debug('selectedPersonId -->'+selectedPersonId);
            System.debug('selectedAddressId -->'+selectedAddressId);
            Case cs = new Case(Id = csId,
                               AccountId = selectedPersonId,
                               case_Account_Email_MVN__c = selectedAccount.PersonEmail,
                               case_Account_Phone_MVN__c = selectedAccount.Phone,
                               case_Account_Fax_MVN__c = selectedAccount.Fax);
            
            if( !String.isBlank(selectedAddressId)){
                cs.Address_MVN__c = selectedAddressId;
            }              
            
            try{
                update cs;
            }catch(Exception e){
                ApexPages.addMessages(e);
            }
        }

        return null;
    }
    
    
    @AuraEnabled
    public static Case queryCaseInformations(String csId){
        return [select id, AccountId, Account.Name, Address_MVN__c, case_Account_Email_MVN__c,
                case_Account_Phone_MVN__c, case_Account_Fax_MVN__c, MSD_CORE_Business__c, MSD_CORE_Business__r.Name,
                Referred_By_MVN__c, Referred_By_MVN__r.Name 
                from Case
                where id =: csId];
    }
    
    
    @AuraEnabled
    public static String addReferredBy(String refId, String csId){
        List<Account> referredByCustomerTypeList = [SELECT Class_of_Trade_MRK__c 
                                                    FROM Account 
                                                    WHERE ID =: refId];
        
        if(!referredByCustomerTypeList.isEmpty()){
            Case cs = new Case(Id = csId,
                               Referred_By_MVN__c = refId,
                               MSD_CORE_Referred_By_Customer_Type__c = referredByCustomerTypeList[0].Class_of_Trade_MRK__c);
        
            try{
                update cs;
            }catch(Exception e){
                ApexPages.addMessages(e);
            }
        }
        
        return null;
    }
    

    public PageReference goToAccountPage() {
        AccountSearchResultMockMVN selectedPerson = getSelectedAccount();

        if(selectedPerson != null) {
            accountLinkId = selectedPerson.getAccount().Id;
        }

        return null;
    }
@testvisible
    private AccountSearchResultMockMVN getSelectedAccount() {
        AccountSearchResultMockMVN selectedPerson = resultMap.get(reqId);
        AccountSearchResultMockMVN asr = selectedPerson.insertAccountDetails();

        return asr;
    }

    public PageReference enterAccount() {
        removeAccountError = false;
        didInsertSucceed = false;
        didTryCreate = true;

        return createAccount();
    }
    
    public PageReference createAccount() {
        removeAccountError = false;
        Boolean isAddressValid = true;
        Boolean isAccountValid = true;
        didInsertSucceed = false;
        didTryCreate = true;

        Account rollbackAccount = createAccount.clone(false,true,false,false);
        Address_vod__c rollbackAddress = createAddress.clone(false,true,false,false);

        SavePoint sp = Database.setSavePoint();

        try {               

            if(createAccount.RecordTypeId == null) {
                isAccountValid = false;
            }

            if(String.isNotBlank(createAccount.Class_Of_Trade_MRK__c)){
                if(String.isBlank(createAccount.Class_of_Trade_Sub_MRK__c)
                    && createAccount.Class_Of_Trade_MRK__c != consumerType
                    && createAccount.Class_Of_Trade_MRK__c != employeeType){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.MSD_CORE_Please_Select_A_Sub_Type));
                    isAccountValid = false;                    
                }

                if(createAccount.Class_of_Trade_MRK__c != employeeType){
                    createAccount.MSD_CORE_Merck_Employee_ID__c = null;
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.MSD_CORE_Please_Select_A_Type));
                isAccountValid = false;
            }

            if(String.isNotBlank(createAccount.Class_Of_Trade_MRK__c)
                && (createAccount.Class_Of_Trade_MRK__c == consumerType
                    || createAccount.Class_Of_Trade_MRK__c == employeeType)){
                        createAccount.Class_Of_Trade_Sub_MRK__c = createAccount.Class_Of_Trade_MRK__c;
            }

            if(isPersonSearch){
                if(typesThatRequireFirstName.contains(createAccount.Class_Of_Trade_MRK__c)
                    && String.isBlank(createAccount.Preferred_First_Name_MRK__c)){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.MSD_CORE_Error_First_Name_Required));
                    isAccountValid = false;
                }
                createAccount.Class_of_Trade_Owner_MRK__c = createAccount.Class_of_Trade_Sub_MRK__c;
                if(activePersonTypes.contains(createAccount.Class_of_Trade_MRK__c)) {
                    createAccount.Status_MRK__c = serviceCloudSettings.MSD_CORE_Account_Status_Active__c;
                }

                createAddress.Physical_Address_MRK__c = false;
            } else {
                createAccount.Phone = null;         
                createAddress.Business_vod__c = false;       
                createAddress.Physical_Address_MRK__c = true;
            }

            checkAddress();
            if(!isAddressEmpty || !isPersonSearch){                
                isAddressValid = addressIsValid(createAddress);
            }

            if(!String.isBlank(createAccount.Phone)) {
                createAccount.Phone = createAccount.Phone;
            }
            if(!String.isBlank(createAccount.Fax)) {
                createAccount.Fax = createAccount.Fax;
            }
            if(createAddress.Country_vod__c != null && createAddress.Country_vod__c != '') {
                createAccount.MSD_CORE_Country_Code__c = createAddress.Country_vod__c;
            }

            MSD_CORE_DCRUtility.stampObject(createAccount, 
                (isPersonSearch ? 
                MSD_CORE_DCRUtility.PersonFieldsToStamp : 
                MSD_CORE_DCRUtility.BusinessFieldsToStamp));

            if(!(isAccountValid && isAddressValid)){
                return null;
            }

            createAccount.IsExcludedFromRealign = true;
            
            /*Code inserted to put rep notes in the DCR process - Satish*/
            createAccount.MSD_Core_Rep_Notes__c = createAddress.MSD_Core_Rep_Notes__c;
            /*Code Ends here*/
            insert createAccount;

            createAddress.Account_vod__c = createAccount.Id;
            if(typesThatHaveBusinessAddress.contains(createAccount.Class_of_Trade_MRK__c)){
                createAddress.Business_vod__c = true;
            }

            createAddress.RecordTypeId = companyMaintainedRecordType;


            if(isAddressValid && !isAddressEmpty){
                insert createAddress;

                if(isDCR){
                    MSD_CORE_DCRUtility.checkAndSubmitNewRecordsToDCR(createAccount, createAddress);
                } 
            } else if(isDCR){
                MSD_CORE_DCRUtility.checkAndSubmitNewRecordsToDCR(createAccount, null);            
            }

            if(!standAloneSearch){
                Boolean addedBusiness = false;
                Boolean addedReferrer = false;
                if(!isPersonSearch){
                    cs.MSD_CORE_Business__c = createAccount.Id;
                    addedBusiness = true;
                } else {
                    if(!createReferredBy){
                        cs.AccountId = createAccount.Id;
                        cs.Address_MVN__c = createAddress.Id;
                        cs.case_Account_Fax_MVN__c = createAccount.Fax;
                        cs.case_Account_Phone_MVN__c = createAccount.Phone;
                        cs.case_Account_Email_MVN__c = createAccount.PersonEmail;
                    }else{
                        cs.Referred_By_MVN__c = createAccount.Id;
                        addedReferrer = true;
                    }
                }

                createReferredBy = false;

                update cs;
                getCaseValues();
            }

            clearSearch(false);

            didInsertSucceed = true;
        }
        catch (Exception e) {
            // Need to clone failed account and address records to clear id field
            createAccount = rollbackAccount;
            createAddress = rollbackAddress;
            if(!standAloneSearch && caseId != null){
                getCaseValues();
            } else {
                System.debug('\tCan not getCaseValues when standAloneSearch (' + standAloneSearch + ') or caseId ('+caseId+') is null');
            }
            System.debug(e.getMessage() + '\n' + e.getLineNumber() + '\n' + e.getStackTraceString() + '\n\n' + e.getCause());
            ApexPages.addMessages(e);

            Database.rollback(sp);
        }
        return null;
    }

    private void checkAddress(){
        isAddressEmpty =  (String.isBlank(createAddress.Name)
                        && String.isBlank(createAddress.Address_line_2_vod__c)
                        && String.isBlank(createAddress.City_vod__c)
                        && String.isBlank(createAddress.Zip_vod__c)
                        && String.isBlank(createAddress.State_vod__c)
                        && String.isBlank(createAddress.License_vod__c));
        isAddressRequired = !isAddressEmpty || !isPersonSearch;
        isStateRequired = isAddressRequired && createAddress.Country_vod__c != null && countriesThatRequireState.contains(createAddress.Country_vod__c);
    }

    private Boolean addressIsValid(Address_vod__c createAddress){
        Set<String> requiredBusinessFields = new Set<String>{ 'Name', 'City_vod__c', 'Zip_vod__c', 'Country_vod__c' };

        if(isStateRequired){
            requiredBusinessFields.add('State_vod__c');
        }

        return objectIsValid(createAddress, addressFieldMap, requiredBusinessFields);
    }

    private Boolean objectIsValid(SObject anObject, Map<String, Schema.SObjectField> fieldMap, Set<String> requiredFields){
        Boolean objectIsValid = true;        
        List<String> missingFields = new List<String>();
        for(String field : requiredFields){
            if(String.isBlank((String)anObject.get(field))){
                if(objectIsValid){
                    objectIsValid = false;                
                }
                String fieldLabel = fieldMap.get(field).getDescribe().getLabel();
                missingFields.add(fieldLabel);
                
            } else {
                System.debug(LoggingLevel.FINER, anObject + ' has a value (' + anObject.get(field) + ') for field (' + field + ')');
            }
        }
        if(!objectIsValid){
            String missingFieldsString = '';
            if(missingFields.size() > 2){
                String lastRequiredField = missingFields.get(missingFields.size() - 1);                
                missingFields.remove(missingFields.size()-1);
                missingFieldsString = String.join(missingFields, ', ') + ', '+Label.MSD_CORE_And+' ' + lastRequiredField;
            } else if(missingFields.size() == 2){
                missingFieldsString = missingFields.get(0) + ' '+Label.MSD_CORE_And+' ' + missingFields.get(1);
            } else {
                missingFieldsString = missingFields.get(0);
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.MSD_CORE_Following_Required_For_Address + ': ' + missingFieldsString));
        }
        return objectIsValid;
    }

    private Id getRecordTypeIdFromType(Account account){
        Id recordTypeId = null;
        
        if(account.Class_of_Trade_MRK__c == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.MSD_CORE_Please_Select_A_Type));
            return null;            
        }

        if(!typeToRecordTypeIdMapping.containsKey(account.Class_of_Trade_MRK__c)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.MSD_CORE_No_Record_Type_For_Type + ': ' + account.Class_of_Trade_MRK__c));
        } else {
            recordTypeId = typeToRecordTypeIdMapping.get(account.Class_of_Trade_MRK__c);
        }

        return recordTypeId;
    }

    public PageReference setupAffiliateModal(){
        if(cs.MSD_Core_Business__c != null
            && cs.AccountId != null
            && String.isNotBlank(cs.MSD_Core_Business__r.Merck_ID_MRK__c)
            && String.isNotBlank(cs.Account.Merck_ID_MRK__c)){
            
            List<Child_Account_vod__c> affiliations = [SELECT Id, Parent_Account_vod__c, Child_Account_vod__c FROM Child_Account_vod__c WHERE Parent_Account_vod__c = :cs.MSD_CORE_Business__c AND Child_Account_vod__c = :cs.AccountId];
            
            if(affiliations.size() == 0){
                affiliationFrom = cs.Account;
                affiliationTo = cs.MSD_Core_Business__r;
                showAffiliationModal = true;
                affiliation = new Child_Account_vod__c(
                    Child_Account_vod__c = affiliationFrom.Id,
                    Parent_Account_vod__c  = affiliationTo.Id,
                    RecordTypeId = childAccountMerckRecordTypeId);    
                    
                //What Role Does {affiliationFrom.Name} Have at {affiliationTo.Name}?
                affiliationPrompt = Label.MSD_CORE_Affiliation_Prompt
                    .replace('{affiliationFrom.Name}', affiliationFrom.Name)
                    .replace('{affiliationTo.Name}', affiliationTo.Name);
            }
        } 
        return null;
    }

    public PageReference createAffiliation(){
        didAffiliationCreateSucceed = false;
        SavePoint sp = Database.setSavePoint();

        try{
            insert affiliation;
            didAffiliationCreateSucceed = true;
        } catch (Exception e) {
            // Need to clone failed account and address records to clear id field
            affiliation = affiliation.clone();
            System.debug('Exception creating affiliation: ' + e.getMessage());
            ApexPages.addMessages(e);
            Database.rollback(sp);
        }

        return null;
    }

    public PageReference clearSearch() {
        clearSearch(true);


        return null;
    }

    private void clearSearch(Boolean clearSearchValues){
        removeAccountError = false;

        String phoneNumber = null;

        if(searchAccount != null){
            phoneNumber = searchAccount.Phone;
        }

        searchAccount = new Account();

        if(clearSearchValues){
            searchAddress = new Address_vod__c();
            createAddress = new Address_vod__c();
            checkAddress();
        } else {
            if(createAddress != null){
                searchAddress = createAddress.clone();            
                createAddress = new Address_vod__c();
            }
            
            searchAccount.Phone = phoneNumber;
        }

        createAccount = new Account();
        searchName = null;
        searchFirstName = null;
        searchLastName = null;
        alternateId = null;

        searchAddress.License_vod__c = null;
        createAddress.License_vod__c = null;

        resultMap = new Map<String, AccountSearchResultMockMVN>();
        didSearch = false;
        createReferredBy = false;

        if(!serviceCloudSettings.Do_Not_Default_Country_MVN__c && countrySet.contains(runningUser.MSD_CORE_Country_Code__c)){
            searchAddress.Country_vod__c = runningUser.MSD_CORE_Country_Code__c;
        }
    }
    
    @AuraEnabled
    public static String userCountry(){
        User runningUser = [Select Country, MSD_CORE_Country_Code__c from User where Id = :UserInfo.getUserId()];
        
        Service_Cloud_Settings_MVN__c serviceCloudSettings = Service_Cloud_Settings_MVN__c.getInstance();
        
        if(!serviceCloudSettings.Do_Not_Default_Country_MVN__c)
            return null;
        
        return runningUser.MSD_CORE_Country_Code__c;
    }

    public PageReference isPersonUpdated() {
        initializeRecordTypeMap();
        initializeTypeSelectOptions();
        typeText = Label.Account_Search_All_Record_Type;
        clearSearchResults();

        if((recentlyAddedPerson != null && !isPersonSearch)
            || (recentlyAddedBusiness != null && isPersonSearch)){
            doChildSearch();
            recentlyAddedBusiness = null;
            recentlyAddedPerson = null;
        }

        return null;
    }    

    public PageReference clearSearchResults() {
        resultMap = new Map<String, AccountSearchResultMockMVN>();
        didSearch = false;

        return null;
    }

    // Perform a search based on Account, Address, and Communication Mechanism (in cases of business search)
    public PageReference doSearch(){
        removeAccountError = false;
        accountToSearch = new Account();

        if(isPersonSearch){
            accountToSearch.Preferred_First_Name_MRK__c = escapeSingleQuotesIfNotEmpty(searchFirstName);
            accountToSearch.Preferred_Last_Name_MRK__c = escapeSingleQuotesIfNotEmpty(searchLastName);
        } else {
            accountToSearch.Preferred_Full_Name_MRK__c = escapeSingleQuotesIfNotEmpty(searchName);
        }
        
        accountToSearch.Phone = escapeSingleQuotesIfNotEmpty(searchAccount.Phone);
        accountToSearch.MSD_CORE_Merck_Employee_ID__c = escapeSingleQuotesIfNotEmpty(searchAccount.MSD_CORE_Merck_Employee_ID__c);
        if (!String.isBlank(searchMerckID)){
            accountToSearch.Merck_Id_MRK__c = escapeSingleQuotesIfNotEmpty(searchMerckID); // Added for Merck_id_Search
            System.debug('1. Bussiness searchMerckID: '+searchMerckID);
        }
        if(!String.isBlank(searchMerckIDpersonAccount)){
            accountToSearch.Merck_Id_MRK__c = escapeSingleQuotesIfNotEmpty(searchMerckIDpersonAccount); // Added for Merck_id_Search
            System.debug('1. Person searchMerckIDpersonAccount: '+searchMerckIDpersonAccount);
        }
        searchAddress.City_vod__c = escapeSingleQuotesIfNotEmpty(searchAddress.City_vod__c);
        searchAddress.Zip_vod__c = escapeSingleQuotesIfNotEmpty(searchAddress.Zip_vod__c);
        searchAddress.State_vod__c = escapeSingleQuotesIfNotEmpty(searchAddress.State_vod__c);
        searchAddress.Country_vod__c = escapeSingleQuotesIfNotEmpty(searchAddress.Country_vod__c);
        typeText = escapeSingleQuotesIfNotEmpty(typeText);
        
        // Make sure at least one search parameter outside of Country is present
        // Added for Merck_id_Search the criteria to check if the MerckId is blank
        didTryCreate = false;
        if ((isPersonSearch &&
                (String.isBlank(searchFirstName) && String.isBlank(searchLastName) && String.isBlank(accountToSearch.Preferred_Middle_Name_MRK__c) && String.isBlank(accountToSearch.Phone) && String.isBlank(searchAddress.City_vod__c) && String.isBlank(searchAddress.State_vod__c) && String.isBlank(searchAddress.Zip_vod__c) && String.isBlank(accountToSearch.MSD_CORE_Merck_Employee_ID__c) && String.isBlank(accountToSearch.Merck_Id_MRK__c)))
            || (!isPersonSearch &&
                (String.isBlank(searchName) && String.isBlank(alternateId) && String.isBlank(accountToSearch.Phone) && String.isBlank(searchAddress.City_vod__c) && String.isBlank(searchAddress.State_vod__c) && String.isBlank(searchAddress.Zip_vod__c) && String.isBlank(accountToSearch.Merck_Id_MRK__c)))) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, System.Label.Search_Term_Required));
            System.debug('accountToSearch.Merck_Id_MRK__c: '+accountToSearch.Merck_Id_MRK__c);
            System.debug('2. Person searchMerckIDpersonAccount: '+searchMerckIDpersonAccount);
            System.debug('2. Bussiness searchMerckID: '+searchMerckID);
            return null;
        }

        buildMergedSearchResults();

        searchAddress.City_vod__c = searchAddress.City_vod__c.replaceAll('\\\\','');
        searchAddress.Zip_vod__c = searchAddress.Zip_vod__c.replaceAll('\\\\','');

        if(resultMap == null) {
            resultMap = new Map<String, AccountSearchResultMockMVN>();
            return null;
        }

        if (resultMap.size() >= SEARCHLIMIT) {
            resultMap = new Map<String, AccountSearchResultMockMVN>();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, System.Label.Too_Many_Results));
        } else if (resultMap.size() == 0 ) {
            resultMap = new Map<String, AccountSearchResultMockMVN>();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, System.Label.No_Search_Results));
        }

        didSearch = true;
        showNewButton = true;
        return null;
    }
    
    // Perform a search based on Account, Address, and Communication Mechanism (in cases of business search)
    @AuraEnabled
    public static List<AccountSearchResultMockMVN> doAuraSearch(boolean isPersonSearch, 
                                    String searchFirstName, 
                                    String searchLastName, 
                                    String searchName,
                                    String Preferred_Middle_Name_MRK,
                                    String Merck_Id_MRK,
                                    String Phone,
                                    String MSD_CORE_Merck_Employee_ID,
                                    String searchMerckID,
                                    String searchMerckIDpersonAccount,
                                    String typeText,
                                    String City_vod,
                                    String Zip_vod,
                                    String State_vod,
                                    String Country_vod,
                                    String alternateId){
                                        System.debug('alternateId -->'+alternateId);
        
        Account accountToSearch = new Account();
        System.debug('searchLastName -->'+searchLastName);
        System.debug('escapeSingleQuotesIfNotEmpty(searchLastName) -->'+escapeSingleQuotesIfNotEmpty(searchLastName));
        if(isPersonSearch){
            accountToSearch.Preferred_First_Name_MRK__c = escapeSingleQuotesIfNotEmpty(searchFirstName);
            accountToSearch.Preferred_Last_Name_MRK__c = escapeSingleQuotesIfNotEmpty(searchLastName);
        } else {
            accountToSearch.Preferred_Full_Name_MRK__c = escapeSingleQuotesIfNotEmpty(searchName);
        }
        
        accountToSearch.Phone = escapeSingleQuotesIfNotEmpty(Phone);
        accountToSearch.MSD_CORE_Merck_Employee_ID__c = escapeSingleQuotesIfNotEmpty(MSD_CORE_Merck_Employee_ID);
        
        if (!String.isBlank(searchMerckID)){
            accountToSearch.Merck_Id_MRK__c = escapeSingleQuotesIfNotEmpty(searchMerckID); // Added for Merck_id_Search
            System.debug('1. Bussiness searchMerckID: '+searchMerckID);
        }
        if(!String.isBlank(searchMerckIDpersonAccount)){
            accountToSearch.Merck_Id_MRK__c = escapeSingleQuotesIfNotEmpty(searchMerckIDpersonAccount); // Added for Merck_id_Search
            System.debug('1. Person searchMerckIDpersonAccount: '+searchMerckIDpersonAccount);
        }
        
        Address_vod__c searchAddress = new Address_vod__c();
        
        searchAddress.City_vod__c = escapeSingleQuotesIfNotEmpty(City_vod);
        searchAddress.Zip_vod__c = escapeSingleQuotesIfNotEmpty(Zip_vod);
        searchAddress.State_vod__c = escapeSingleQuotesIfNotEmpty(State_vod);
        searchAddress.Country_vod__c = escapeSingleQuotesIfNotEmpty(Country_vod);
        
        typeText = escapeSingleQuotesIfNotEmpty(typeText);
        
        // Make sure at least one search parameter outside of Country is present
        // Added for Merck_id_Search the criteria to check if the MerckId is blank
        System.debug('Phone -->'+Phone);
        if ((isPersonSearch &&
                (String.isBlank(searchFirstName) && String.isBlank(searchLastName) && String.isBlank(Preferred_Middle_Name_MRK) && String.isBlank(Phone) && String.isBlank(City_vod) && String.isBlank(State_vod) && String.isBlank(Zip_vod) && String.isBlank(MSD_CORE_Merck_Employee_ID) && String.isBlank(Merck_Id_MRK)))
            || (!isPersonSearch &&
                (String.isBlank(searchName) && /*String.isBlank(alternateId) &&*/ String.isBlank(Phone) && String.isBlank(City_vod) && String.isBlank(State_vod) && String.isBlank(Zip_vod) && String.isBlank(Merck_Id_MRK)))) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, System.Label.Search_Term_Required));
            System.debug('accountToSearch.Merck_Id_MRK__c: '+accountToSearch.Merck_Id_MRK__c);
            System.debug('2. Person searchMerckIDpersonAccount: '+searchMerckIDpersonAccount);
            System.debug('2. Bussiness searchMerckID: '+searchMerckID);
        }

        Map<String, AccountSearchResultMockMVN> resultMap;
        List<AccountSearchUtilityMVN.searchInterface> accountSearchUtilities = new List<AccountSearchUtilityMVN.searchInterface>();
        
        for (String utilityClass: UtilitiesMVN.splitCommaSeparatedString(Service_Cloud_Settings_MVN__c.getInstance().Account_Search_Utility_Classes_MVN__c)) {
            try {
                Type t = Type.forName(utilityClass);
                AccountSearchUtilityMVN.searchInterface utilityInstance = (AccountSearchUtilityMVN.searchInterface) t.newInstance();
                accountSearchUtilities.add(utilityInstance);
            } catch(Exception e) {
                ApexPages.addMessages(e);
            }
        }
        System.debug('accountSearchUtilities -->'+accountSearchUtilities);
        System.debug('resultMap -->'+resultMap);
        resultMap = buildMergedSearchResultsMap(resultMap, accountSearchUtilities, accountToSearch, searchAddress, typeText, isPersonSearch, alternateId);
        System.debug('resultMap -->'+resultMap);
        searchAddress.City_vod__c = City_vod.replaceAll('\\\\','');
        searchAddress.Zip_vod__c = Zip_vod.replaceAll('\\\\','');
        
        if(resultMap == null) {
            resultMap = new Map<String, AccountSearchResultMockMVN>();
        }

        if (resultMap.size() >= SEARCHLIMIT) {
            AuraHandledException e = new AuraHandledException(System.Label.Too_Many_Results);
            e.setMessage(System.Label.Too_Many_Results);
            throw e;
            //resultMap = new Map<String, AccountSearchResultMockMVN>();
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, System.Label.Too_Many_Results));
        } else if (resultMap.size() == 0 ) {
            resultMap = new Map<String, AccountSearchResultMockMVN>();
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, System.Label.No_Search_Results));
        }
        
        if(resultMap == null || resultMap.size() == 0) {
            return new List<AccountSearchResultMockMVN>();
        }
        System.debug('resultMap.values() -->'+resultMap.values());
        List<AccountSearchResultMockMVN> asrMockList = resultMap.values();
        asrMockList.sort();
        
        return asrMockList;
    }
    
    // Perform a search based on Account, Address, and Communication Mechanism (in cases of business search)
    @AuraEnabled
    public static List<AccountSearchResultMockMVN> doChildSearch(boolean isPersonSearch, 
                                                                 String recentlyAddedBusiness,
                                                                 String recentlyAddedPerson){
        
        List<AccountSearchResultMockMVN> utilityResults = new List<AccountSearchResultMockMVN>();
        
        if(isPersonSearch) {
            utilityResults = buildChildAccountSearchResultsAura(recentlyAddedBusiness, true);
        } else {
            utilityResults = buildChildAccountSearchResultsAura(recentlyAddedPerson, false);
        }
        
        if(utilityResults == null) {
            return null;
        }

        if (utilityResults.size() >= SEARCHLIMIT) {
            AuraHandledException e = new AuraHandledException(System.Label.Too_Many_Results);
            e.setMessage(System.Label.Too_Many_Results);
            throw e;
        } else if (utilityResults.size() == 0 ) {
        
        }
        else {
            return utilityResults;
        }
        return null;
    }
    
    private static List<AccountSearchResultMockMVN> buildChildAccountSearchResultsAura(Id accountId, Boolean searchChildren) {
        List<AccountSearchResultMockMVN> utilityResults = null;
        
        SFAccountSearchUtilityMVN utilityInstance = new SFAccountSearchUtilityMVN();
        
        if(searchChildren){
            utilityResults = utilityInstance.searchChildAccounts(accountId);
        } else {
            utilityResults = utilityInstance.searchParentAccounts(accountId);
        }
        
        return utilityResults;
    }

    // Once a Customer is selected and the Business tab is clicked find all of the
    // Businesses the Customer works at.  Conversely if a Business is selected
    // and the Customer tab is clicked, find all of the Customers that work
    // at the selected Business.
    public PageReference doChildSearch(){
        removeAccountError = false;
        
        didTryCreate = false;

        if(isPersonSearch) {
            buildChildAccountSearchResults(recentlyAddedBusiness, true);
        } else {
            buildChildAccountSearchResults(recentlyAddedPerson, false);
        }
        

        if(resultMap == null) {
            resultMap = new Map<String, AccountSearchResultMockMVN>();
            return null;
        }

        if (resultMap.size() >= SEARCHLIMIT) {
            resultMap = new Map<String, AccountSearchResultMockMVN>();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, System.Label.Too_Many_Results));
        } else if (resultMap.size() == 0 ) {
            resultMap = new Map<String, AccountSearchResultMockMVN>();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, System.Label.No_Search_Results));
        }

        didSearch = true;
        showNewButton = true;
        return null;
    }

    private static String escapeSingleQuotesIfNotEmpty(String inputString){
        if(inputString != null && inputString.length() > 0){
            return String.escapeSingleQuotes(inputString.trim());
        } else {
            return '';
        }
    }

    // Loop through the search utilities and merge
    // Currently a single Utility (SFAccountSearchUtility) is used which queries
    // data that is present in the org
    private void buildMergedSearchResults() {
        resultMap = new Map<String, AccountSearchResultMockMVN>();
        Set<String> accountKeys = new Set<String>();
        for (AccountSearchUtilityMVN.searchInterface utilityInstance:accountSearchUtilities) {
            List<AccountSearchResultMockMVN> utilityResults = utilityInstance.search(accountToSearch, searchAddress, typeText, isPersonSearch, alternateId);

            if (utilityResults != null) {
                for (AccountSearchResultMockMVN asr: utilityResults) {
                    String key = asr.getResultKey();  // Account Id + '_' + Address Id
                    String accountId = asr.getAccountID();

                    resultMap.remove(key); // Remove if entry for account only exists

                    if (!accountKeys.contains(key)) { // Don't add if the key is an account id (no address) already used
                        resultMap.put(key, asr);

                        if (key.contains('_')) {   // Has an account and an address
                            accountKeys.add(accountId);
                        }
                    }
                }
            }
        }
    }
    
    // Loop through the search utilities and merge
    // Currently a single Utility (SFAccountSearchUtility) is used which queries
    // data that is present in the org
    private static Map<String, AccountSearchResultMockMVN> buildMergedSearchResultsMap(Map<String, AccountSearchResultMockMVN> resultMap, 
                                                    List<AccountSearchUtilityMVN.searchInterface> accountSearchUtilities,
                                                    Account accountToSearch,
                                                    Address_vod__c searchAddress,
                                                    String typeText,
                                                    boolean isPersonSearch,
                                                    String alternateId) {
        resultMap = new Map<String, AccountSearchResultMockMVN>();
        Set<String> accountKeys = new Set<String>();
        for (AccountSearchUtilityMVN.searchInterface utilityInstance : accountSearchUtilities) {
            List<AccountSearchResultMockMVN> utilityResults = utilityInstance.search(accountToSearch, searchAddress, typeText, isPersonSearch, alternateId);

            if (utilityResults != null) {
                for (AccountSearchResultMockMVN asr: utilityResults) {
                    String key = asr.getResultKey();  // Account Id + '_' + Address Id
                    String accountId = asr.getAccountID();

                    resultMap.remove(key); // Remove if entry for account only exists

                    if (!accountKeys.contains(key)) { // Don't add if the key is an account id (no address) already used
                        resultMap.put(key, asr);

                        if (key.contains('_')) {   // Has an account and an address
                            accountKeys.add(accountId);
                        }
                    }
                }
            }
        }
        
        return resultMap;
    }

    // Loop through the search utilities and merge
    // Currently a single Utility (SFAccountSearchUtility) is used which queries
    // data that is present in the org
    private void buildChildAccountSearchResults(Id accountId, Boolean searchChildren) {
        resultMap = new Map<String, AccountSearchResultMockMVN>();
        Set<String> accountKeys = new Set<String>();
        for (AccountSearchUtilityMVN.searchInterface utilityInstance:accountSearchUtilities) {
            List<AccountSearchResultMockMVN> utilityResults = null;

            if(searchChildren){
                utilityResults = utilityInstance.searchChildAccounts(accountId);
            } else {
                utilityResults = utilityInstance.searchParentAccounts(accountId);
            }

            if (utilityResults != null) {
                for (AccountSearchResultMockMVN asr: utilityResults) {
                    String key = asr.getResultKey();  // Account Id + '_' + Address Id
                    String resultAccountId = asr.getAccountID();

                    resultMap.remove(key); // Remove if entry for account only exists

                    if (!accountKeys.contains(key)) { // Don't add if the key is an account id (no address) already used
                        resultMap.put(key, asr);

                        if (key.contains('_')) {   // Has an account and an address
                            accountKeys.add(resultAccountId);
                        }
                    }
                }
            }
        }
    }
    
    
    @AuraEnabled
    public static List<SelectWrapper> countryList(){
        List<SelectWrapper> pickListValuesList= new List<SelectWrapper>();
        Schema.DescribeFieldResult fieldResult = Address_vod__c.Country_vod__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(new SelectWrapper(pickListVal.getLabel(), pickListVal.getValue()));
        }  
           
        return pickListValuesList;
    }
    
    
    @AuraEnabled
    public static List<String> stateList(){
        List<String> pickListValuesList= new List<String>();
        Schema.DescribeFieldResult fieldResult = Address_vod__c.State_vod__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }  
           
        return pickListValuesList;
    }
    
    @AuraEnabled
    public static AffiliationWrapper checkCaseAffliation(String csId){
        List<Case> cs = [SELECT MSD_Core_Business__c, AccountId, Account.Name, MSD_Core_Business__r.Name, MSD_Core_Business__r.Merck_ID_MRK__c, Account.Merck_ID_MRK__c FROM Case WHERE Id =:csId];
        if(!cs.isEmpty() && cs[0].MSD_Core_Business__c != null
            && cs[0].AccountId != null
            && String.isNotBlank(cs[0].MSD_Core_Business__r.Merck_ID_MRK__c)
            && String.isNotBlank(cs[0].Account.Merck_ID_MRK__c))
        {
            List<Child_Account_vod__c> affiliations = [SELECT Id, Parent_Account_vod__c, Child_Account_vod__c FROM Child_Account_vod__c WHERE Parent_Account_vod__c = :cs[0].MSD_CORE_Business__c AND Child_Account_vod__c = :cs[0].AccountId];
            
            if(affiliations.size() == 0){
                AffiliationWrapper wrap = new AffiliationWrapper();
                Service_Cloud_Settings_MVN__c serviceCloudSettings = Service_Cloud_Settings_MVN__c.getInstance();
                Id childAccountMerckRecordTypeId = [select Id from RecordType where SObjectType='Child_Account_vod__c' and DeveloperName = :serviceCloudSettings.MSD_CORE_Merck_Affiliation_Record_Type__c].Id;
                wrap.affiliationFrom = cs[0].Account.Name;
                wrap.affiliationTo = cs[0].MSD_Core_Business__r.Name;
                wrap.affiliation = new Child_Account_vod__c(
                    Child_Account_vod__c = cs[0].AccountId,
                    Parent_Account_vod__c  = cs[0].MSD_Core_Business__c,
                    RecordTypeId = childAccountMerckRecordTypeId);    
                return wrap;
            }
        }
        
        return null;
    }
    
    public class AffiliationWrapper {
        @AuraEnabled
        public string affiliationFrom;
        @AuraEnabled
        public string affiliationTo;
        @AuraEnabled
        public Child_Account_vod__c affiliation;
    }
    
    public class SelectWrapper {
        @AuraEnabled
        public string label{get;set;}
        @AuraEnabled
        public string value{get;set;}
        
        public SelectWrapper(string label, String value)
        {
            this.label = label;
            this.value = value;
        }
    }
}