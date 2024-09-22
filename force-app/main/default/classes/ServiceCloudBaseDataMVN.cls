/*
* ServiceCloudBaseDataMVN
* Created By:    Rick Locke
* Created Date:  7/25/2014
* Description:   This is a setup class that pre-populates
*                custom settings with defaults.
*/

public class ServiceCloudBaseDataMVN {
    public void runAll() {
        buildAccountTypeDocumentFilters();
        buildCaseDeliveryMethodMapSettings();
        buildCaseDocFieldSettings();
        buildServiceCloudSetting();
        buildVaultValueMappingSettings();
        buildProducts();
        buildSally();
        buildAccounts();
    }

    public void buildAccountTypeDocumentFilters() {

        List<Account_Type_Document_Filters_MVN__c> acdfList = new List<Account_Type_Document_Filters_MVN__c>();
        acdfList.add(new Account_Type_Document_Filters_MVN__c(Name='Off Label',Account_Record_Type_MVN__c='HCP',Case_Document_Field_MVN__c='Off_Label_MVN__c',Custom_Filter_Logic_MVN__c='off_label1__c = \'No\' or off_label1__c = NULL',Search_Filter_Value_MVN__c='\'Yes\''));
        insert acdfList;
    }

    public void buildCaseDeliveryMethodMapSettings() {

        List<Case_Delivery_Method_Map_MVN__c> cdmpList = new List<Case_Delivery_Method_Map_MVN__c>();
        cdmpList.add(new Case_Delivery_Method_Map_MVN__c(Name='Urgent_Mail_vod',Case_Translation_MVN__c='Urgent Mail'));
        cdmpList.add(new Case_Delivery_Method_Map_MVN__c(Name='Email_vod',Case_Translation_MVN__c='Email'));
        cdmpList.add(new Case_Delivery_Method_Map_MVN__c(Name='Mail_vod',Case_Translation_MVN__c='Mail'));
        cdmpList.add(new Case_Delivery_Method_Map_MVN__c(Name='Fax_vod',Case_Translation_MVN__c='Fax'));
        cdmpList.add(new Case_Delivery_Method_Map_MVN__c(Name='Phone_vod',Case_Translation_MVN__c='Phone'));
        insert cdmpList;
    }

    public void buildCaseDocFieldSettings() {

        List<Case_Document_Fields_MVN__c> caseDocFieldList = new List<Case_Document_Fields_MVN__c>();
        caseDocFieldList.add(new Case_Document_Fields_MVN__c(Name='2',Case_Document_Field_MVN__c='Document_Summary_MVN__c',Document_Field_MVN__c='summary__c'));
        insert caseDocFieldList;
    }

    public void buildServiceCloudSetting() {

        Service_Cloud_Settings_MVN__c serviceCloudSettings = new Service_Cloud_Settings_MVN__c();

        serviceCloudSettings.Account_Search_Max_Results_MVN__c = 50;
        serviceCloudSettings.Account_Search_Utility_Classes_MVN__c = 'SFAccountSearchUtilityMVN,SFAccountSearchUtilityMVN';
        serviceCloudSettings.Administrator_Email_MVN__c = 'vincent@mavensconsulting.com';
        serviceCloudSettings.Adverse_Event_Record_Type_MVN__c = 'Adverse_Event_MVN';
        serviceCloudSettings.Closed_Status_MVN__c = 'Closed';
        serviceCloudSettings.Consumer_Record_Type_MVN__c = 'Consumer_MVN';
        serviceCloudSettings.Document_Search_Max_Results_MVN__c = 50;
        serviceCloudSettings.Document_Search_Utility_Class_MVN__c = 'VaultSearchUtilityMVN';
        serviceCloudSettings.Do_Not_Default_Country_MVN__c = false;
        serviceCloudSettings.Document_Search_Family_Type_MVN__c = 'Family';
        serviceCloudSettings.MSD_CORE_Document_Search_Other_Type__c = 'Other';
        serviceCloudSettings.Employee_Record_Type_MVN__c = 'Employee_MVN';
        serviceCloudSettings.HCP_Record_Type_MVN__c = 'HCP';
        serviceCloudSettings.Interaction_Closed_Record_Type_MVN__c = 'Interaction_Closed_MVN';
        serviceCloudSettings.Interaction_Closing_Grace_Period_MVN__c = 1;
        serviceCloudSettings.Interaction_Record_Type_MVN__c = 'Request_MVN';
        serviceCloudSettings.Manager_Profiles_MVN__c = 'System Administrator';
        serviceCloudSettings.Medical_Inquiry_Source_MVN__c = 'Veeva';
        serviceCloudSettings.Medical_Inquiry_Submitted_Status_MVN__c = 'Submitted_vod';
        serviceCloudSettings.Open_Status_MVN__c = 'Open';
        serviceCloudSettings.Product_Complaint_Record_Type_MVN__c = 'Product_Complaint_MVN';
        serviceCloudSettings.Request_Record_Type_MVN__c = 'Request_MVN';
        serviceCloudSettings.Temporary_Account_Hold_Period_Days_MVN__c = 0;
        serviceCloudSettings.Vault_API_Version_MVN__c = 'v8.0';
        serviceCloudSettings.Vault_Base_URL_MVN__c = 'https://partners-mavensmc.veevavault.com';
        serviceCloudSettings.Vault_Delegated_Auth_Source_MVN__c = 'sfdc';
        serviceCloudSettings.Vault_Relationship_Includes_MVN__c = 'supportingDocuments_pm';
        serviceCloudSettings.Vault_Viewer_Doc_Type_Exclusion_List_MVN__c = 'FAQ';

        insert serviceCloudSettings;
    }

    public void buildVaultValueMappingSettings() {

        List<Vault_Value_Mapping_MVN__c> vvmList = new List<Vault_Value_Mapping_MVN__c>();

        vvmList.add(new Vault_Value_Mapping_MVN__c(Name='Language German Mapping', SFDC_Value_MVN__c='de', Vault_Value_MVN__c='German'));
        vvmList.add(new Vault_Value_Mapping_MVN__c(Name='Language English Mapping', SFDC_Value_MVN__c='en_US', Vault_Value_MVN__c='English'));
        vvmList.add(new Vault_Value_Mapping_MVN__c(Name='Language Spanish Mexico Mapping', SFDC_Value_MVN__c='es_MX', Vault_Value_MVN__c='Spanish'));
        vvmList.add(new Vault_Value_Mapping_MVN__c(Name='Language Spanish Mapping', SFDC_Value_MVN__c='es_ES', Vault_Value_MVN__c='Spanish'));

        insert vvmList;
    }

    public void buildProducts() {

        List<Product_vod__c> productList = new List<Product_vod__c>();
        productList.add(new Product_vod__c(Name='Cholecap',Description_vod__c='Cholecap® (rosuvastatin calcium) is a prescription drug belonging to a group of medicines — called statins — that are used to treat high cholesterol. When diet and exercise alone aren’t enough, adding Cholecap can help.',Product_Type_vod__c='Family'));
        productList.add(new Product_vod__c(Name='Labrinone',Description_vod__c='Labrinone® (ciclesonide) is a once-a-day medication indicated for the treatment of Parkinson\'s Disease. It\'s an effective medication for reducing symptoms of Parkinson\'s including resting tremor, bradykinesia, rigidity and postural instability.',Product_Type_vod__c='Family'));
        productList.add(new Product_vod__c(Name='Voderal',Description_vod__c='VODERAL® is indicated for the relief of moderate to moderately severe pain. VODERAL combines the efficacy of hydrocodone with the lowest dose of acetaminophen available of the commonly prescribed hydrocodone/acetaminophen combination products.',Product_Type_vod__c='Family'));
        productList.add(new Product_vod__c(Name='Restolar',Description_vod__c='Levodopa is a substance that is converted into dopamine by an enzyme in the brain. It is then released by brain cells and activates dopamine receptors allowing for normal function of the movement control centers of the brain.',Product_Type_vod__c='Family'));

        insert productList;
    }

    public void buildSally() {

        User sally = new User();
        sally.Username= 'sally_sc@example.com';
        sally.Email = 'sally_sc@example.com';
        sally.Lastname = 'sally';
        sally.Firstname = 'agent';
        sally.Alias = 'sally';
        sally.CommunityNickname = 'sally_sc';
        sally.MSD_CORE_Country_Code__c = 'US';

        //sally.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'MedInfo_USA' LIMIT 1].Id;
        sally.ProfileId = [SELECT Id FROM Profile WHERE Name = 'MSD_CORE Contact Center - Contact Center Agent' LIMIT 1].Id;

        sally.TimeZoneSidKey = 'GMT';
        sally.LocaleSidKey = 'en_US';
        sally.EmailEncodingKey = 'ISO-8859-1';
        sally.LanguageLocaleKey = 'en_US';
        sally.UserPermissionsMobileUser = false;

        insert sally;
    }

    public void buildAccounts() {

        List<Account> accounts = new List<Account>();
        Id recordTypeId = [SELECT Id FROM RecordType WHERE Name = 'HCP' LIMIT 1].Id;
        accounts.add(new Account(FirstName='Julius', LastName='Erving', Salutation='Dr.', Specialty_1_vod__c='General Practice', Phone='(555)326-5555', Credentials_vod__c='DO', RecordTypeId = recordTypeId));
        accounts.add(new Account(FirstName='John', LastName='Dolittle', Salutation='Dr.', Specialty_1_vod__c='Family Practice', Phone='(555)555-5555', Credentials_vod__c='MD', RecordTypeId = recordTypeId));
        accounts.add(new Account(FirstName='Michaela', LastName='Quinn', Salutation='Dr.', Specialty_1_vod__c='Internal Medicine', Phone='(555)555-5555', Credentials_vod__c='MD', RecordTypeId = recordTypeId));
        accounts.add(new Account(FirstName='Emmett', LastName='Brown', Salutation='Dr.', Phone='(555)555-5555', Credentials_vod__c='None', RecordTypeId = recordTypeId));
        accounts.add(new Account(FirstName='Benjamin', Middle_vod__c='Franklyn', LastName='Pierce', Salutation='Captain', Specialty_1_vod__c='General Practice', Phone='(555)55-5555', RecordTypeId = recordTypeId));
        accounts.add(new Account(FirstName='Leonard', LastName='McCoy', Salutation='Dr.', Specialty_1_vod__c='General Practice', Phone='(555)555-5555', Credentials_vod__c='MD', RecordTypeId = recordTypeId));
        accounts.add(new Account(FirstName='Beverly', LastName='Crusher', Salutation='Dr.', Specialty_1_vod__c='General Practice', Phone='(555)555-5555', Credentials_vod__c='MD', RecordTypeId = recordTypeId));
        accounts.add(new Account(FirstName='John', LastName='Zoidberg', Salutation='Dr.', Specialty_1_vod__c='Other', Phone='(555)555-5555', Credentials_vod__c='MD', RecordTypeId = recordTypeId));
        accounts.add(new Account(FirstName='Hubert', Middle_vod__c='J', LastName='Farnsworth', Salutation='Prof.', Specialty_1_vod__c='Other', Phone='(555)555-5555', Credentials_vod__c='MD', RecordTypeId = recordTypeId));
        accounts.add(new Account(FirstName='Doogie', LastName='Howser', Salutation='Dr.', Specialty_1_vod__c='General Practice', Phone='(555)555-5555', Credentials_vod__c='MD', RecordTypeId = recordTypeId));
        insert accounts;

        List<Address_vod__c> addresses = new List<Address_vod__c>();
        addresses.add(new Address_vod__c(Account_vod__c=accounts[0].Id, Name='3601 S Broad St', City_vod__c='Philadelphia', State_vod__c='PA', Zip_vod__c='19148', Country_vod__c='US'));
        addresses.add(new Address_vod__c(Account_vod__c=accounts[1].Id, Name='123 Main St', City_vod__c='Philadelphia', State_vod__c='PA', Zip_vod__c='12345', Country_vod__c='US'));
        addresses.add(new Address_vod__c(Account_vod__c=accounts[2].Id, Name='345 Main St', City_vod__c='Colorado Springs', State_vod__c='CO', Zip_vod__c='80901', Country_vod__c='US'));
        addresses.add(new Address_vod__c(Account_vod__c=accounts[3].Id, Name='123 Business Center Rd', City_vod__c='Hill Valley', State_vod__c='CA', Zip_vod__c='95420', Country_vod__c='US'));
        addresses.add(new Address_vod__c(Account_vod__c=accounts[4].Id, Name='567 Main St', City_vod__c='Crabapple Cove', State_vod__c='ME', Zip_vod__c='54607', Country_vod__c='US'));
        addresses.add(new Address_vod__c(Account_vod__c=accounts[5].Id, Name='145 Martindale', City_vod__c='University', State_vod__c='MS', Zip_vod__c='38677', Country_vod__c='US'));
        addresses.add(new Address_vod__c(Account_vod__c=accounts[6].Id, Name='435 Murray Cir', City_vod__c='Sausalito', State_vod__c='CA', Zip_vod__c='94965', Country_vod__c='US'));
        addresses.add(new Address_vod__c(Account_vod__c=accounts[7].Id, Name='631 W 57th St', City_vod__c='New York', State_vod__c='NY', Zip_vod__c='10019', Country_vod__c='US'));
        addresses.add(new Address_vod__c(Account_vod__c=accounts[8].Id, Name='631 W 57th St', City_vod__c='New York', State_vod__c='NY', Zip_vod__c='10019', Country_vod__c='US'));
        addresses.add(new Address_vod__c(Account_vod__c=accounts[9].Id, Name='1983 Marengo St', City_vod__c='Los Angeles', State_vod__c='CA', Zip_vod__c='90033', Country_vod__c='US'));
        insert addresses;
    }

}