public class MSD_CORE_CC_CaseCustomerInfo {
    @AuraEnabled
    public static Case queryCaseInformations(String csId){
        return [select id, AccountId, Account.Name, Address_MVN__c, case_Account_Email_MVN__c,
                case_Account_Phone_MVN__c, case_Account_Fax_MVN__c, MSD_CORE_Business__c, MSD_CORE_Business__r.Name,
                Referred_By_MVN__c, Referred_By_MVN__r.Name 
                from Case
                where id =: csId];
    }
    
    @AuraEnabled
    public static CustomerInfoWrapper getCustomerInfo(String csId){
        CustomerInfoWrapper wrap = new CustomerInfoWrapper();
        wrap.objCase = [SELECT Id, AccountId, Account.Name, Address_MVN__c, case_Account_Email_MVN__c,
                case_Account_Phone_MVN__c, case_Account_Fax_MVN__c, MSD_CORE_Business__c, MSD_CORE_Business__r.Name,
                Referred_By_MVN__c, Referred_By_MVN__r.Name 
                FROM Case
                WHERE id =: csId];
        if(wrap.objCase.AccountId != null){
            wrap.optionsMap = getFieldsMapPicklists(csId);
        }
        else{
            wrap.optionsMap = new Map<String, Map<String, String>>();
        }
        
        String profileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        if(profileName.contains('Read Only')){
            wrap.isReadOnlyUser = true;
        }
        else{
            wrap.isReadOnlyUser = false;
        }
        
        return wrap;
    }
    
    @AuraEnabled
    public static Map<String,Map<String,String>> getFieldsMapPicklists(String caseId){
        String caseAccountId = [SELECT AccountId FROM Case WHERE Id =:caseId].AccountId;
        List<Address_vod__c> lstaddressRecords = [SELECT Id, Name, Address_line_2_vod__c, City_vod__c, State_vod__c, Zip_vod__c
                          , Country_vod__c, Primary_vod__c, Fax_vod__c, Fax_2_vod__c, Phone_vod__c, Phone_2_vod__c
                       FROM Address_vod__c
                      WHERE Account_vod__c = :caseAccountId]; 
        Account currentCaseAccount = [SELECT Id, Phone, PersonHomePhone, PersonMobilePhone, PersonOtherPhone, Fax,
                                      PersonEmail, Alternate_Email_MRK__c, MSD_CORE_Contact_Center_Email__c
                                      FROM Account WHERE Id =:caseAccountId];
        
        Map<String,Map<String,String>> optionsMap = new Map<String,Map<String,String>>();  
        optionsMap.put('Address',new Map<String,String>());
        optionsMap.put('Phone',new Map<String,String>());
        optionsMap.put('Email',new Map<String,String>());
        optionsMap.put('Fax',new Map<String,String>());
        
        for (Address_vod__c ad : lstaddressRecords) {
            optionsMap.get('Address').put(ad.Id, 
                                            ad.Name + (ad.Address_line_2_vod__c != null ? ', ' + ad.Address_line_2_vod__c : '')
                                            + (ad.City_vod__c != null ? ', ' + ad.City_vod__c : '')
                                            + (ad.State_vod__c != null ? ', ' + ad.State_vod__c : '')
                                            + (ad.Zip_vod__c != null ? ', ' + ad.Zip_vod__c : ''));
        }
        
        Set<String> phoneList = dedupeAddressPicklists(currentCaseAccount, lstaddressRecords, true); 
        for(String phone : phoneList) {
            if(String.isNotBlank(phone)) {
                optionsMap.get('Phone').put(phone, phone); 
            }
        }
        
        Set<String> faxList = dedupeAddressPicklists(currentCaseAccount, lstaddressRecords, false); 
        for(String fax : faxList) {
            if(String.isNotBlank(fax)) {
                optionsMap.get('Fax').put(fax, fax); 
            }
        }
        
        for(String email : dedupeEmailPicklists(currentCaseAccount)) {
            if(String.isNotBlank(email)) {
                optionsMap.get('Email').put(email, email); 
            }
        }        
        return optionsMap;
    }
    
    
    private static Set<String> dedupeAddressPicklists(Account currentCaseAccount, List<Address_vod__c> addressRecords, Boolean isPhone) {
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
    
    private static Set<String> dedupeEmailPicklists(Account currentCaseAccount) {
        Set<String> emails = new Set<String>();
        emails.add(currentCaseAccount.PersonEmail);
        emails.add(currentCaseAccount.Alternate_Email_MRK__c);
        emails.add(currentCaseAccount.MSD_CORE_Contact_Center_Email__c);
        return emails;
    }
    
    public class CustomerInfoWrapper{
        @AuraEnabled public Case objCase;
        @AuraEnabled public Map<String,Map<String,String>> optionsMap;
        @AuraEnabled public Boolean isReadOnlyUser;
    }
    
    @AuraEnabled
    public static void removeSelectedCustomer(String caseId){
        Case cs = new Case(Id = caseId);
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
        update cs;
    }
    
    @AuraEnabled
    public static void removeSelectedReferredBy(String caseId){
        Case cs = new Case(Id = caseId);
        cs.Referred_By_MVN__c = null;
        cs.MSD_CORE_Referred_By_Customer_Type__c = null;
        update cs;
    }
    
    @AuraEnabled
    public static void removeSelectedBusiness(String caseId){
        Case cs = new Case(Id = caseId);
        cs.MSD_CORE_Business__c = null;
        update cs;
    }
    
    @AuraEnabled
    public static void updateAddress(String caseId, String addId){
        Case cs = new Case();
        cs.Id = caseId;
        cs.Address_MVN__c = addId;
        update cs;
    }
    
    @AuraEnabled
    public static void updatePhone(String caseId, String accountPhoneText){
        Case cs = new Case();
        cs.Id = caseId;
        cs.Case_Account_Phone_MVN__c = accountPhoneText;
        update cs;
    } 
    
    @AuraEnabled
    public static void updateEmail(String caseId, String emailText){
        Case cs = new Case();
        cs.Id = caseId;
        cs.Case_Account_Email_MVN__c = emailText;
        update cs;
    } 
    
    @AuraEnabled
    public static void updateFax(String caseId, String faxText){
        Case cs = new Case();
        cs.Id = caseId;
        cs.Case_Account_Fax_MVN__c = faxText;
        update cs;
    } 
    
    @AuraEnabled
    public static String createEmail(String caseId, String email){
        System.debug('caseId -->'+caseId);
        System.debug('email -->'+email);
        Id caseAccountId = [SELECT AccountId FROM Case WHERE Id =:caseId].AccountId;
        Account newAccountFields = new Account();
        newAccountFields.PersonEmail = email;
        Case currentCase = new Case();
        currentCase.Id = caseId;
        /*if (newAccountFields.PersonEmail == null || newAccountFields.PersonEmail.length() == 0) {
            hasSaveError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, system.Label.Error_Email_Required));
            return null;
        }*/

        //Account acc = new Account(id=currentCaseAccount.Id);
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
        Set<String> overWritePersonEmail = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(settings.MSD_CORE_Overwrite_Person_Email_Cust_Typ__c)); 
       
        String accountQuery = 'SELECT ' + String.join(UtilitiesMVN.personAccountSelectFields(), ',')
                            + '  FROM Account WHERE Id = :caseAccountId';

        List<Account> accounts = Database.query(accountQuery);
        
        if(accounts == null || accounts.size() == 0){
            throw new AuraHandledException(Label.MSD_CORE_Error_Retrieving_Account);
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.MSD_CORE_Error_Retrieving_Account));
            //return null;
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
            System.debug('Acc update successful');
            currentCase.case_Account_Email_MVN__c = newAccountFields.PersonEmail;
            System.debug('currentCase -->'+currentCase);
            update currentCase;
            System.debug('Case update successful');
        }
        catch (Exception e) {
            //hasSaveError = true;
            //ApexPages.addMessages(e);
            acc = acc.clone(false,true,false,false);
            Database.rollback(sp);
            System.debug('Exception');
            throw new AuraHandledException(Label.MSD_CORE_Error_Retrieving_Account);
        }
        return null;
    }
    
    @AuraEnabled
    public static String createPhone(String caseId, String phone){
        Id caseAccountId = [SELECT AccountId FROM Case WHERE Id =:caseId].AccountId;
        Account newAccountFields = new Account();
        newAccountFields.Phone = phone;
        Case currentCase = new Case();
        currentCase.Id = caseId;
        
        Account acc = new Account(id=caseAccountId);

        SavePoint sp = Database.setSavePoint();
        acc.Phone = newAccountFields.Phone;
        try {
            update acc;
            currentCase.case_Account_Phone_MVN__c = acc.Phone;
            update currentCase;
        }
        catch (Exception e) {
            acc = acc.clone(false,true,false,false);
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
        return null;
    }
    
    @AuraEnabled
    public static String createFax(String caseId, String fax){
        System.debug('fax -->'+fax);
        Id caseAccountId = [SELECT AccountId FROM Case WHERE Id =:caseId].AccountId;
        Account newAccountFields = new Account();
        newAccountFields.Fax = fax;
        Case currentCase = new Case();
        currentCase.Id = caseId;
        
        Account acc = new Account(id=caseAccountId);

        SavePoint sp = Database.setSavePoint();
        acc.Fax = newAccountFields.Fax;
        try {
            update acc;
            currentCase.case_Account_Fax_MVN__c = acc.Fax;
            System.debug('currentCase -->'+currentCase);
            update currentCase;
        }
        catch (Exception e) {
            acc = acc.clone(false,true,false,false);
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
        return null;
    }
	
    @AuraEnabled
	public static void createAddress(String caseId, String caseAccId, Address_vod__c newAddress) {
        Case currentCase = new Case();
        currentCase.Id = caseId;
        
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance(); 
        Set<String> businessRecordTypes = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(settings.MSD_CORE_Type_Has_Business_Address__c));
		Account currentCaseAccount = [SELECT Id, Class_of_Trade_MRK__c,RecordTypeId,Status_MRK__c FROM Account WHERE Id =:caseAccId];
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
            Service_Cloud_Settings_MVN__c serviceCloudSettings = Service_Cloud_Settings_MVN__c.getInstance();
            List<String> dcrRecordTypeDeveloperNames = UtilitiesMVN.splitCommaSeparatedString(serviceCloudSettings.MSD_CORE_DCR_Record_Types__c);
            List<RecordType> dcrRecordTypes = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName IN :dcrRecordTypeDeveloperNames];
            Set<Id> dcrRecordTypeIds = new Set<Id>();
            for(RecordType dcrRecordType : dcrRecordTypes) {
                dcrRecordTypeIds.add(dcrRecordType.Id);
            }
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
            newAddress = newAddress.clone(false,true,false,false);
            Database.rollback(sp);
        }
    }    
    
    @AuraEnabled
	public static void check(Address_vod__c newAddress) {
        System.debug('check');
    }
}