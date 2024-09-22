/*
* SelectedRequesterControllerMVN
* Created By:    Roman Lerman
* Created Date:  1/21/2013
* Description:   This controller allows agents to input contact information for the callers such as
*                new addresses, phone numbers, emails, and faxes as well as select from existing
*                contact information.
*/
public with sharing class SelectedRequesterControllerMVN {
    public Case     currentCase { get; set; } { currentCase = new Case(); }
    public Account  currentCaseAccount { get; private set; }
    public String   activeAddressId { get; set; }
    public String   accountEmailText { get; set; }
    public String   accountPhoneText { get; set; }
    public String   accountFaxText { get; set; }
    public String   customerPreferedName {get; private set;}
    public String   referedByPreferedName {get; private set;}
    public String   businessName {get; set;}

    public Boolean  shouldRenderBusinessSearch { get; set; } { shouldRenderBusinessSearch = false; }
    public Boolean  updatingAddress { get; set; } { updatingAddress = false; }
    public Boolean  updatingEmail { get; set; } { updatingEmail = false; }
    public Boolean  updatingPhone { get; set; } { updatingPhone = false; }
    public Boolean  updatingFax { get; set; } { updatingFax = false; }

    public Boolean shouldRequireState { set; } //get defined in a method
    public Boolean shouldShowLicense { get; private set; }

    public Address_vod__c newAddress { get; set; } { newAddress = new Address_vod__c(); }
    public Account  newAccountFields { get; set; } { newAccountFields = new Account(); }

    public Boolean hasSaveError { get; private set; } { hasSaveError = false; }
    public Boolean saveSuccess { get; private set; } { saveSuccess = false; }

    public List<SelectOption> emailAddresses { get; private set; } { emailAddresses = new List<SelectOption>(); }
    public List<SelectOption> phoneNumbers { get; private set; } { phoneNumbers = new List<SelectOption>(); }
    public List<SelectOption> faxNumbers { get; private set; } { faxNumbers = new List<SelectOption>(); }

    public Account searchAccount {get;set;} { searchAccount = new Account(); }
    public Address_vod__c searchAddress { get;set; } { searchAddress = new Address_vod__c(); }

    private String phoneSearch = ApexPages.currentPage().getParameters().get('phoneSearch');
    private Set<Id> dcrRecordTypeIds;


    public List<SelectOption> countries { 
        get {
                if(countries == null) {
                    countries = new List<SelectOption>();

                    countries.add (new SelectOption ('', system.Label.Picklist_Select_Option));

                    for (Schema.PickListEntry ple : Schema.sObjectType.Address_vod__c.fields.Country_vod__c.getPicklistValues()) {
                        countries.add (new SelectOption (ple.getValue(), ple.getLabel()));
                    }
                }

                return countries;
            } 
        private set;
    }

    @TestVisible private List<Address_vod__c> addressesRecords { get; set; } { addressesRecords = new List<Address_vod__c>(); }

    public String userCountry { get; private set; }
    {
        User runningUser = [Select MSD_CORE_Country_Code__c from User where Id = :UserInfo.getUserId()];
        userCountry = runningUser.MSD_CORE_Country_Code__c;
    }

    private void setupContactInformation() {
        addressesRecords = [SELECT Id, Name, Address_line_2_vod__c, City_vod__c, State_vod__c, Zip_vod__c
                          , Country_vod__c, Primary_vod__c, Fax_vod__c, Fax_2_vod__c, Phone_vod__c, Phone_2_vod__c
                       FROM Address_vod__c
                      WHERE Account_vod__c = :currentCaseAccount.Id];

        if ( currentCase.Address_MVN__c == null && activeAddressId == null
                && ! addressesRecords.isEmpty() ) {
            activeAddressId = addressesRecords[0].Id;
        }
        else if (currentCase.Address_MVN__c != null) {
            activeAddressId = currentCase.Address_MVN__c;
        }


        for(String email : dedupeEmailPicklists()) {
            if(String.isNotBlank(email)) {
                emailAddresses.add(new SelectOption(email, email)); 
            }
        }

        accountEmailText = currentCase.case_Account_Email_MVN__c;

        Set<String> phoneList = dedupeAddressPicklists(addressesRecords, true); 
        for(String phone : phoneList) {
            if(String.isNotBlank(phone)) {
                phoneNumbers.add(new SelectOption(phone, phone)); 
            }
        }
        accountPhoneText = currentCase.case_Account_Phone_MVN__c;

        Set<String> faxList = dedupeAddressPicklists(addressesRecords, false); 
        for(String fax : faxList) {
            if(String.isNotBlank(fax)) {
                faxNumbers.add(new SelectOption(fax, fax)); 
            }
        }

        accountFaxText = currentCase.case_Account_Fax_MVN__c;
    }

    private Set<String> dedupeEmailPicklists() {
        Set<String> emails = new Set<String>();
        emails.add(currentCaseAccount.PersonEmail);
        emails.add(currentCaseAccount.Alternate_Email_MRK__c);
        emails.add(currentCaseAccount.MSD_CORE_Contact_Center_Email__c);
        return emails;
    }

    private Set<String> dedupeAddressPicklists(List<Address_vod__c> addressRecords, Boolean isPhone) {
        Set<String> values = new Set <String>(); 
        if(isPhone) {
            values.add(currentCaseAccount.Phone);
            values.add(currentCaseAccount.PersonHomePhone);
            values.add(currentCaseAccount.PersonMobilePhone);
            values.add(currentCaseAccount.PersonOtherPhone);

            for(Address_vod__c adr : addressRecords) {
                values.add(adr.Phone_vod__c);
                values.add(adr.Phone_2_vod__c);
            }
        } else {
            values.add(currentCaseAccount.Fax);
            
            for(Address_vod__c adr : addressRecords) {
                values.add(adr.Fax_vod__c);
                values.add(adr.Fax_2_vod__c);
            }
        }
        return values; 
    }
    
    public Boolean getShouldRequireState() {
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
        Set<String> required_state = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(settings.MSD_CORE_Address_Country_Requires_State__c));
        System.debug('My country is: ' + newAddress.Country_vod__c);
        return required_state.contains(newAddress.Country_vod__c);        
    }

    public SelectedRequesterControllerMVN(ApexPages.StandardController controller) {
        updatingAddress = false;
        Service_Cloud_Settings_MVN__c serviceCloudSettings = Service_Cloud_Settings_MVN__c.getInstance();

        if (string.isNotBlank(controller.getId())) {
            currentCase = [select Id, ParentId
                             from Case
                            where Id = :controller.getId()];
            System.debug('Current Case Id: '+controller.getId());

            Id interactionId;
            if (currentCase.ParentId != null) {
                interactionId = currentCase.ParentId;
            }
            else {
                interactionId = currentCase.Id;
            }

            determineSearchScreen(); 

            String currentCaseQuery = 'SELECT Id, isClosed, CaseNumber, Address_MVN__c, AccountId, Status' + 
                                ', case_Account_Email_MVN__c, case_Account_Phone_MVN__c, case_Account_Fax_MVN__c' + 
                                ', Referred_By_MVN__c, Referred_By_MVN__r.Name, ParentId, MSD_CORE_Business_Name__c, case_AddressLine1_MVN__c' + 
                                ', case_AddressLine2_MVN__c' + 
                                ', Referred_By_MVN__r.Preferred_First_Name_MRK__c, Referred_By_MVN__r.Preferred_Last_Name_MRK__c' + 
                                ', Referred_By_MVN__r.Preferred_Salutation_MRK__c' + 
                                ', Referred_By_MVN__r.Class_of_Trade_Sub_MRK__c' + 
                                ', case_City_MVN__c, case_State_MVN__c, case_Postal_Code_MVN__c' + 
                                ', MSD_CORE_Business__c, MSD_CORE_Business__r.Preferred_Full_Name_MRK__c, account.' +
                                String.join(UtilitiesMVN.personAccountSelectFields(), ', account.') + 
                                ' FROM Case WHERE Id = :interactionId';

            currentCase = Database.query(currentCaseQuery);

            System.debug('Current Case Account Id: '+currentCase.AccountId);

            if (currentCase.AccountId != null) {
                
                currentCaseAccount = currentCase.Account;
                shouldShowLicense = (currentCaseAccount.Class_of_Trade_MRK__c == serviceCloudSettings.MSD_CORE_HCP_Type__c); 
                setupContactInformation();
            }

        } else {
            System.debug('Current Case Id was null');
        }

        newAddress.Country_vod__c = userCountry;

        searchAddress.Country_vod__c = userCountry;

        if(currentCase.Account.Id != null) {
            customerPreferedName = getPreferredName(currentCase.Account);
        }

        if(currentCase.Referred_By_MVN__c != null) {
            referedByPreferedName = getPreferredName(currentCase.Referred_By_MVN__r);
        }

        List<String> dcrRecordTypeDeveloperNames = UtilitiesMVN.splitCommaSeparatedString(serviceCloudSettings.MSD_CORE_DCR_Record_Types__c);

        List<RecordType> dcrRecordTypes = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName IN :dcrRecordTypeDeveloperNames];
        dcrRecordTypeIds = new Set<Id>();
        for(RecordType dcrRecordType : dcrRecordTypes) {
            dcrRecordTypeIds.add(dcrRecordType.Id);
        }
    }

    private String getPreferredName(Account theAccount) {
        return (theAccount.Preferred_Salutation_MRK__c != null ? theAccount.Preferred_Salutation_MRK__c + ' ': '') 
                + (theAccount.Preferred_First_Name_MRK__c != null ? theAccount.Preferred_First_Name_MRK__c + ' ': '') 
                + (theAccount.Preferred_Last_Name_MRK__c != null ? theAccount.Preferred_Last_Name_MRK__c : '');
    }

    private void determineSearchScreen() {
        Id profileId = UserInfo.getProfileId();
        String profileName = [SELECT Name FROM Profile WHERE Id = :profileId].Name; 
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
        Set<String> profileSet = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(settings.MSD_CORE_Default_to_Business_Search__c));
        

        if(profileSet.contains(profileName)) {
            shouldRenderBusinessSearch = true; 
        }
    }

    public PageReference doSearch(){
        return null;
    }

    public PageReference clearSearch() {
        String country = searchAddress.Country_vod__c;

        searchAccount = new Account();
        searchAddress = new Address_vod__c();
        searchAddress.Country_vod__c = userCountry;
        
        return null;
    }

    public List<SelectOption> getAddresses() {
        List<SelectOption> options = new List<SelectOption>();

        for (Address_vod__c ad : addressesRecords) {
            options.add(new SelectOption( ad.Id
                                        , ad.Name + (ad.Address_line_2_vod__c != null ? ', ' + ad.Address_line_2_vod__c : '')
                                            + (ad.City_vod__c != null ? ', ' + ad.City_vod__c : '')
                                            + (ad.State_vod__c != null ? ', ' + ad.State_vod__c : '')
                                            + (ad.Zip_vod__c != null ? ', ' + ad.Zip_vod__c : '')));
        }

        if (currentCase.Address_MVN__c == null && String.isNotBlank(currentCase.case_AddressLine1_MVN__c)) {
            String addressString = currentCase.case_AddressLine1_MVN__c;
            addressString += currentCase.case_AddressLine2_MVN__c != null ? ', ' + currentCase.case_AddressLine2_MVN__c : ''; 
            addressString += currentCase.case_City_MVN__c != null ? ', ' + currentCase.case_City_MVN__c : '';
            addressString += currentCase.case_State_MVN__c != null ? ', ' + currentCase.case_State_MVN__c : '';
            addressString += currentCase.case_Postal_Code_MVN__c != null ? ', ' + currentCase.case_Postal_Code_MVN__c : '';

            options.add(new SelectOption('CaseAddress', addressString));

            activeAddressId = 'CaseAddress';
        }

        return options;
    }

    public PageReference associateAddress() {
        hasSaveError = false;
		System.debug('activeAddressId -->'+activeAddressId);
        if (String.isNotBlank(activeAddressId)
            && activeAddressId != system.Label.Picklist_New_Option
            && activeAddressId != system.Label.Picklist_Select_Option) {

            try {
                currentCase.Address_MVN__c = activeAddressId;
                update currentCase;
            }
            catch (Exception e) {
                hasSaveError = true;
                ApexPages.addMessages(e);
                return null;
            }
        }
        return null;
    }

    public PageReference createAddressView() {
        updatingAddress = true;
        hasSaveError = false;
        return null;
    }

    public PageReference createAddress() {
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance(); 
        Set<String> businessRecordTypes = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(settings.MSD_CORE_Type_Has_Business_Address__c));

        newAddress.Account_vod__c = currentCaseAccount.Id;
        if (businessRecordTypes.contains(currentCaseAccount.Class_of_Trade_MRK__c)) {
            newAddress.Business_vod__c = true; 
        }

        newAddress.Mailing_vod__c = false;
        newAddress.Home_and_Office_MRK__c = false;

        newAddress.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Address_vod__c' AND DeveloperName =: settings.MSD_CORE_Company_Maintained_Rec_Type__c].Id; 

        SavePoint sp = Database.setSavePoint();
        try {
            insert newAddress;
            currentCase.Address_MVN__c = newAddress.Id;
            update currentCase;
            if(dcrRecordTypeIds.contains(currentCaseAccount.RecordTypeId) &&
                currentCaseAccount.Status_MRK__c != settings.MSD_CORE_Account_Status_Inactive__c &&
                currentCaseAccount.Status_MRK__c != settings.MSD_CORE_Account_Status_Pending__c){
                String country = [SELECT MSD_CORE_Country_Code__c 
                                    FROM User 
                                   WHERE Id = :userinfo.getUserId()].MSD_CORE_Country_Code__c; 
                List<String> fieldsToQuery = new List<String>();
                List<MSD_CORE_NAW_Field_Types__c> accountFields = MSD_CORE_DCRUtility.fieldsFor('Account', country, currentCaseAccount.RecordTypeId);

                for (MSD_CORE_NAW_Field_Types__c field : accountFields){
                    fieldsToQuery.add(field.Field_API_Name__c);
                }
                Id accountId = currentCaseAccount.Id;
                String accountToSubmitQuery = 'SELECT ' + String.join(fieldsToQuery, ', ') +
                                               ' FROM Account WHERE Id = :accountId ' +
                                               'LIMIT 1';
                Account accountToSubmit = Database.query(accountToSubmitQuery);
                MSD_CORE_DCRUtility.checkAndSubmitNewRecordsToDCR(accountToSubmit, newAddress);
            }
        } catch (Exception e) {
            hasSaveError = true;
            ApexPages.addMessages(e);
            newAddress = newAddress.clone(false,true,false,false);
            Database.rollback(sp);
            return null;
        }

        saveSuccess = true;

        return null;
    }

    public PageReference associateEmail() {
        hasSaveError = false;
        if (String.isNotBlank(accountEmailText)){
            Account acc = new Account(id=currentCaseAccount.Id);

            try {
                currentCase.case_Account_Email_MVN__c = accountEmailText;
                update currentCase;
            }
            catch (Exception e) {
                hasSaveError = true;
                ApexPages.addMessages(e);
                return null;
            }
        }
        return null;
    }

    public PageReference createEmailView() {

        updatingEmail = true;

        return null;
    }

    public PageReference updateBusiness() {
        try {
            System.debug('the name is: ' + currentCase.MSD_CORE_Business_Name__c);
            update currentCase;
        } catch (Exception e) {
            hasSaveError = true;
            ApexPages.addMessages(e);
            return null;
        }
        return null; 
    }

    public PageReference createEmail(){
        hasSaveError = false;
        saveSuccess = false;

        if (newAccountFields.PersonEmail == null || newAccountFields.PersonEmail.length() == 0) {
            hasSaveError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, system.Label.Error_Email_Required));
            return null;
        }

        //Account acc = new Account(id=currentCaseAccount.Id);
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
        Set<String> overWritePersonEmail = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(settings.MSD_CORE_Overwrite_Person_Email_Cust_Typ__c)); 
        Id caseAccountId = currentCaseAccount.Id;
        String accountQuery = 'SELECT ' + String.join(UtilitiesMVN.personAccountSelectFields(), ',')
                            + '  FROM Account WHERE Id = :caseAccountId';

        List<Account> accounts = Database.query(accountQuery);
        
        if(accounts == null || accounts.size() == 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.MSD_CORE_Error_Retrieving_Account));
            return null;
        }

        Account acc = accounts.get(0);

        if(String.isBlank(acc.PersonEmail) || overWritePersonEmail.contains(acc.Class_of_Trade_MRK__c)) {
            acc.PersonEmail = newAccountFields.PersonEmail;
        } else {
            acc.MSD_CORE_Contact_Center_Email__c = newAccountFields.PersonEmail;
        }
        
        SavePoint sp = Database.setSavePoint();

        try {
            update acc;
            currentCase.case_Account_Email_MVN__c = newAccountFields.PersonEmail;
            update currentCase;
        }
        catch (Exception e) {
            hasSaveError = true;
            ApexPages.addMessages(e);

            acc = acc.clone(false,true,false,false);
            Database.rollback(sp);
            return null;
        }
        updatingEmail = false;
        saveSuccess = true;

        return null;
    }

    public PageReference associatePhone() {
        hasSaveError = false;
        if (String.isNotBlank(accountPhoneText)){
            Account acc = new Account(id=currentCaseAccount.Id);

            try {
                currentCase.case_Account_Phone_MVN__c = accountPhoneText;
                update currentCase;
            }
            catch (Exception e) {
                hasSaveError = true;
                ApexPages.addMessages(e);
                return null;
            }
        }
        return null;
    }

    public PageReference createPhoneView() {
        updatingPhone = true;
        return null;
    }

    public PageReference createPhone() {
        hasSaveError = false;
        saveSuccess = false;

        if (newAccountFields.Phone == null || newAccountFields.Phone.length() == 0) {
            hasSaveError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, system.Label.Error_Phone_Required));
            return null;
        }
        Account acc = new Account(id=currentCaseAccount.Id);

        SavePoint sp = Database.setSavePoint();
        acc.Phone = newAccountFields.Phone;
        try {
            update acc;
            currentCase.case_Account_Phone_MVN__c = acc.Phone;
            update currentCase;
        }
        catch (Exception e) {
            hasSaveError = true;
            ApexPages.addMessages(e);

            acc = acc.clone(false,true,false,false);
            Database.rollback(sp);
            return null;
        }

        updatingPhone = false;
        saveSuccess = true;

        return null;
    }

    public PageReference associateFax() {
        hasSaveError = false;
        if (String.isNotBlank(accountFaxText)){
            Account acc = new Account(id=currentCaseAccount.Id);

            try {
                currentCase.case_Account_Fax_MVN__c = accountFaxText;
                update currentCase;
            }
            catch (Exception e) {
                hasSaveError = true;
                ApexPages.addMessages(e);
                return null;
            }
        }
        return null;
    }

    public PageReference createFaxView() {
        updatingFax = true;
        return null;
    }

    public PageReference createFax() {
        hasSaveError = false;
        saveSuccess = false;

        if (newAccountFields.Fax == null || newAccountFields.Fax.length() == 0) {
            hasSaveError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, system.Label.Error_Fax_Required));
            return null;
        }

        Account acc = new Account(id=currentCaseAccount.Id);

        SavePoint sp = Database.setSavePoint();
        acc.Fax = newAccountFields.Fax;
        try {
            update acc;
            currentCase.case_Account_Fax_MVN__c = acc.Fax;
            update currentCase;
        }
        catch (Exception e) {
            hasSaveError = true;
            ApexPages.addMessages(e);

            acc = acc.clone(false,true,false,false);
            Database.rollback(sp);
            return null;
        }

        updatingFax = false;
        saveSuccess = true;

        return null;
    }

    public void cancelCreate() {
        updatingAddress = false;
        updatingEmail = false;
        updatingPhone = false;
        updatingFax = false;
        hasSaveError = false;
        saveSuccess = false;
        setupContactInformation();

        newAddress = new Address_vod__c();
        newAddress.Country_vod__c = userCountry;

        newAccountFields.Fax = '';
        newAccountFields.Phone = '';
        newAccountFields.PersonEmail = '';
    }
}