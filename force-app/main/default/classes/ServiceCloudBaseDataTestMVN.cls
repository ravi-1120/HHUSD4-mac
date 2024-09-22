/*
* ServiceCloudBaseDataTestMVN
* Created By:    Rick Locke
* Created Date:  7/25/2014
* Description:   Tests ServiceCloudBaseDataMVN making certain 
*                that the class is pre-populating custom 
*                settings with defaults.
*/


@isTest
private class ServiceCloudBaseDataTestMVN {
	@isTest static void accountTypeDocumentFiltersTest() {
		Test.startTest();
		ServiceCloudBaseDataMVN scbd = new ServiceCloudBaseDataMVN();
		scbd.buildAccountTypeDocumentFilters();
		Test.stopTest();

		System.assertEquals(1,[SELECT Id FROM Account_Type_Document_Filters_MVN__c].size());
	}

	@isTest static void caseDeliveryMethodMapSettingsTest() {
		Test.startTest();
		ServiceCloudBaseDataMVN scbd = new ServiceCloudBaseDataMVN();
		scbd.buildCaseDeliveryMethodMapSettings();
		Test.stopTest();

		System.assertEquals(5,[SELECT Id FROM Case_Delivery_Method_Map_MVN__c].size());
	}
	
	@isTest static void caseDocFieldSettingsTest() {
		Test.startTest();
		ServiceCloudBaseDataMVN scbd = new ServiceCloudBaseDataMVN();
		scbd.buildCaseDocFieldSettings();
		Test.stopTest();

		System.assertEquals(1,[SELECT Id FROM Case_Document_Fields_MVN__c].size());
	}
	
	@isTest static void serviceCloudSettingTest() {

		Test.startTest();
		ServiceCloudBaseDataMVN scbd = new ServiceCloudBaseDataMVN();
		scbd.buildServiceCloudSetting();
		Test.stopTest();

		System.assertEquals(1,[SELECT Id FROM Service_Cloud_Settings_MVN__c].size());
	}

	@isTest static void vaultValueMappingSettingsTest() {

		Test.startTest();
		ServiceCloudBaseDataMVN scbd = new ServiceCloudBaseDataMVN();
		scbd.buildVaultValueMappingSettings();
		Test.stopTest();

		System.assertEquals(4,[SELECT Id FROM Vault_Value_Mapping_MVN__c].size());
	}

	@isTest static void productTest() {

		Test.startTest();
		ServiceCloudBaseDataMVN scbd = new ServiceCloudBaseDataMVN();
		scbd.buildProducts();
		Test.stopTest();

		System.assertEquals(4,[SELECT Id FROM Product_vod__c].size());
	}

	@isTest static void sallyTest() {

		Test.startTest();
		ServiceCloudBaseDataMVN scbd = new ServiceCloudBaseDataMVN();
		scbd.buildSally();
		Test.stopTest();

		System.assertEquals(1,[SELECT Id FROM User WHERE Username= 'sally_sc@example.com'].size());
	}

	@isTest static void accountsTest() {

		Test.startTest();
		ServiceCloudBaseDataMVN scbd = new ServiceCloudBaseDataMVN();
		scbd.buildAccounts();
		Test.stopTest();

		System.assertEquals(10,[SELECT Id FROM Account].size());
		System.assertEquals(10,[SELECT Id FROM Address_vod__c].size());
	}

	@isTest static void runAllTest() {

		Test.startTest();
		ServiceCloudBaseDataMVN scbd = new ServiceCloudBaseDataMVN();
		scbd.runAll();
		Test.stopTest();

		System.assertEquals(1,[SELECT Id FROM Account_Type_Document_Filters_MVN__c].size());
		System.assertEquals(5,[SELECT Id FROM Case_Delivery_Method_Map_MVN__c].size());
		System.assertEquals(1,[SELECT Id FROM Case_Document_Fields_MVN__c].size());
		System.assertEquals(1,[SELECT Id FROM Service_Cloud_Settings_MVN__c].size());
		System.assertEquals(4,[SELECT Id FROM Vault_Value_Mapping_MVN__c].size());
		System.assertEquals(4,[SELECT Id FROM Product_vod__c].size());
		System.assertEquals(1,[SELECT Id FROM User WHERE Username= 'sally_sc@example.com'].size());
		System.assertEquals(10,[SELECT Id FROM Account].size());
		System.assertEquals(10,[SELECT Id FROM Address_vod__c].size());
	}
}