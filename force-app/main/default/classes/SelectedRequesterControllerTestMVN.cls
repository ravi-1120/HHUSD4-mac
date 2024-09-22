/*
* SelectedRequesterControllerTestMVN
* Created By:    Roman Lerman
* Created Date:  6/23/2013
* Description:   This is the test class for the SelectedRequesterControllerMVN class
*/
@isTest
private class SelectedRequesterControllerTestMVN {
	static Case interaction = null;
	static SelectedRequesterControllerMVN controller = null;
	private static Case childInteraction = null;
	private static Case parentInteraction = null;
	private static Account testAccount = null;
	private static Account referringAccount = null;
	private static Case hcpInteraction = null;
	private static Account hcpAccount = null;
	private static User callCenterUser;

	private static String ATestBusinessName = 'a new business name';

	static{
        TestDataFactoryMVN.createSettings(true);
        TestDataFactoryMVN.createDCRFieldTypes();

        Profile p = [select Id from Profile where Name='System Administrator'];
        callCenterUser = new User(Alias = 'mrtest', Email='mrtest@example.com',
                        EmailEncodingKey='UTF-8', FirstName = 'mr', LastName='test', LanguageLocaleKey='de',
                        LocaleSidKey='de', ProfileId = p.Id, MSD_CORE_Country_Code__c = 'us',
                        TimeZoneSidKey='Europe/Berlin', UserName='mrtest@merk.com');
        insert callCenterUser;
	}
	// Story:  Contact information is chosen for the caller
	// Narrative:
    // In order to properly send a fulfillment package/response
	// As a call center agent
    // I want to select an existing address, phone number, email, fax for the caller

	// Scenario 1:  Select an address
	static testMethod void selectAnAddress(){
		givenATestInteraction();
		givenCustomerPreviouslyProvidedAnAddress();
		whenLookCanSeeAndSelectAddress();
		addressAddedToTheInteraction();		
	}

	private static void givenATestInteraction(){
		givenATestInteraction(true);
	}

	private static void givenATestInteraction(Boolean withAddress){
		interaction = TestDataFactoryMVN.createTestCase(null, false);
		testAccount = [SELECT Id,
							  Preferred_Salutation_MRK__c,
							  Preferred_First_Name_MRK__c,
							  Preferred_Last_Name_MRK__c 
						 FROM Account
						WHERE Id =:interaction.AccountId];

		if(withAddress){			
			TestDataFactoryMVN.createTestAddress(testAccount);
		}

		interaction.Address_MVN__c = null;
		referringAccount = TestDataFactoryMVN.createTestEmployee();
		interaction.Referred_By_MVN__c = referringAccount.Id;

		update interaction;
	}

	static void repOpensInteraction(){
		ApexPages.standardController stdController = new ApexPages.standardController(interaction);
        controller = new SelectedRequesterControllerMVN(stdController);
	}

	// Given a customer has previously provided an address
	static void givenCustomerPreviouslyProvidedAnAddress(){
		repOpensInteraction();
        controller.getAddresses();
	}
	// When I look, I can see their address and select it
	static void whenLookCanSeeAndSelectAddress(){
		System.assertEquals(1, controller.addressesRecords.size(), controller.addressesRecords);
		System.assertEquals('123 Fake St.', controller.addressesRecords[0].Name);

		controller.activeAddressId = controller.addressesRecords[0].Id;
		controller.associateAddress();
		controller.createAddressView();
	}
	// Then it is added to the Interaction
	static void addressAddedToTheInteraction(){
		System.assertEquals([select Address_MVN__c from Case where Id=:interaction.Id].Address_MVN__c, controller.addressesRecords[0].Id);
	}
//***************
	// Scenario 2:  Select a phone number
	static testMethod void selectAPhoneNumber(){
		givenATestInteraction();
		givenCustomerPreviouslyProvidedPhoneNumber();
		Test.startTest();
		whenLookCanSeeAndSelectPhoneNumber();
		phoneAddedToTheInteraction();
		Test.stopTest();
	}
	// Given a customer has previously provided a phone number
	static void givenCustomerPreviouslyProvidedPhoneNumber(){
		Account acct = [select Id, Phone from Account where Id=:testAccount.Id];
		acct.Phone = '(555) 555-5555';
		update acct;

		repOpensInteraction();
	}
	// When I looks, I can see their phone number and select it
	static void whenLookCanSeeAndSelectPhoneNumber(){
		System.assertEquals(4, controller.phoneNumbers.size());
		System.assertEquals('(555) 555-5555', controller.phoneNumbers[0].getLabel());

		controller.accountPhoneText = '(555) 555-5555';
		controller.associatePhone();
		controller.createPhoneView();
	}
	// Then it is added to the Interaction
	static void phoneAddedToTheInteraction(){
		System.assertEquals([select case_Account_Phone_MVN__c from Case where Id=:interaction.Id].case_Account_Phone_MVN__c, controller.phoneNumbers[0].getLabel());
	}
//***************
	// Scenario 3:  Select an email
	static testMethod void selectAnEmail(){
		givenATestInteraction();
		givenCustomerPreviouslyProvidedEmail();
		Test.startTest();
		whenLookCanSeeAndSelectEmail();
		emailAddedToTheInteraction();
		Test.stopTest();
	}
	// Given a customer has previously provided an email
	static void givenCustomerPreviouslyProvidedEmail(){
		Account acct = [select Id, Phone from Account where Id=:testAccount.Id];
		acct.PersonEmail = 'testaccount@testaccount.com';
		update acct;

		repOpensInteraction();
	}
	// When I looks, I can see their email and select it
	static void whenLookCanSeeAndSelectEmail(){
		System.assertEquals(1, controller.emailAddresses.size());
		System.assertEquals('testaccount@testaccount.com', controller.emailAddresses[0].getLabel());

		controller.accountEmailText = 'testaccount@testaccount.com';
		controller.associateEmail();
		controller.createEmailView();
	}
	// Then it is added to the Interaction
	static void emailAddedToTheInteraction(){
		System.assertEquals([select case_Account_Email_MVN__c from Case where Id=:interaction.Id].case_Account_Email_MVN__c, controller.emailAddresses[0].getLabel());
	}
//***************
	// Scenario 4:  Select a fax
	static testMethod void selectAFax(){		
		givenATestInteraction();
		Test.startTest();
		givenCustomerPreviouslyProvidedFax();
		whenLookCanSeeAndSelectFax();
		faxAddedToTheInteraction();
		Test.stopTest();
	}
	// Given a customer has previously provided an email
	static void givenCustomerPreviouslyProvidedFax(){
		Account acct = [select Id, Phone from Account where Id=:testAccount.Id];
		acct.Fax = '(777) 777-7777';
		update acct;

		repOpensInteraction();
	}
	// When I looks, I can see their email and select it
	static void whenLookCanSeeAndSelectFax(){
		System.assertEquals(1, controller.faxNumbers.size());
		System.assertEquals('(777) 777-7777', controller.faxNumbers[0].getLabel());

		controller.accountFaxText = '(777) 777-7777';
		controller.associateFax();
	}
	// Then it is added to the Interaction
	static void faxAddedToTheInteraction(){
		System.assertEquals([select case_Account_Fax_MVN__c from Case where Id=:interaction.Id].case_Account_Fax_MVN__c, controller.faxNumbers[0].getLabel());
	}
//*****

	// Story:  New contact information is entered for the caller
	// Narrative:
    // In order to properly send a fulfillment package/response
	// As a call center agent
    // I want to add a new address, phone number, email, fax

	// Scenario 1:  A new address is provided
	static testMethod void aNewAddressIsProvided(){
		givenATestInteraction();
		Test.startTest();
		repOpensInteraction();
		givenACustomerProvidesANewAddress();
		whenISelectTheAddress();
		addressIsAddedForTheCustomer(interaction);
		Test.stopTest();
	}
	// Given a customer provides a new address
	static void givenACustomerProvidesANewAddress(){

        controller.newAddress.Name = '456 Fake St.';
        controller.newAddress.Address_Line_2_vod__c = 'Unit 1';
        controller.newAddress.City_vod__c = 'Chicago';
        controller.newAddress.State_vod__c = 'IL';
        controller.newAddress.Zip_vod__c = '12345';
        controller.newAddress.Country_vod__c = 'US';
	}
	// When I select the address
	static void whenISelectTheAddress(){
		controller.createAddress();
	}
	// Then it is added for the customer
	static void addressIsAddedForTheCustomer(Case theInteraction){
		System.assertEquals([select count() from Address_vod__c where Name = '456 Fake St.'], 1);
		System.assertEquals([select Address_MVN__c from Case where Id=:theInteraction.Id].Address_MVN__c, [select Id from Address_vod__c where Name='456 Fake St.'].Id);
	}
//*******
	// Scenario 2:  A new phone number is provided
	static testMethod void aNewPhoneIsProvided(){
		givenATestInteraction();
		Test.startTest();
		givenACustomerProvidesANewPhoneNumber();
		whenISelectThePhoneNumber();
		phoneNumberIsAddedForTheCustomer();
		Test.stopTest();
	}
	// Given a customer provides a new address
	static void givenACustomerProvidesANewPhoneNumber(){
		repOpensInteraction();

        controller.newAccountFields.Phone = '(555) 555-5555';
	}
	// When I select the address
	static void whenISelectThePhoneNumber(){
		controller.createPhone();
	}
	// Then it is added for the customer
	static void phoneNumberIsAddedForTheCustomer(){
		System.assertEquals([select Phone from Account where Id=:testAccount.Id].Phone, '(555) 555-5555');
		System.assertEquals('(555) 555-5555',[select case_Account_Phone_MVN__c from Case where Id=:interaction.Id].case_Account_Phone_MVN__c);
	}
//*******
	// Scenario 3:  A new email is provided
	static testMethod void aNewEmailIsProvided(){
		givenATestInteraction();
		Test.startTest();
		givenACustomerProvidesANewEmail();
		whenISelectTheEmail();
		emailIsAddedForTheCustomer();
		Test.stopTest();
	}
	// Given a customer provides a new email
	static void givenACustomerProvidesANewEmail(){
		repOpensInteraction();
        controller.newAccountFields.PersonEmail = 'testaccount@testaccount.com';
	}
	// When I select the address
	static void whenISelectTheEmail(){
		controller.createEmail();
	}
	// Then it is added for the customer
	static void emailIsAddedForTheCustomer(){
		System.assertEquals([select PersonEmail from Account where Id=:testAccount.Id].PersonEmail, 'testaccount@testaccount.com');
		System.assertEquals([select case_Account_Email_MVN__c from Case where Id=:interaction.Id].case_Account_Email_MVN__c, 'testaccount@testaccount.com');
	}
//*******
	// Scenario 4:  A new fax is provided
	static testMethod void aNewFaxIsProvided(){
		givenATestInteraction();
		Test.startTest();
		givenACustomerProvidesANewFax();
		whenISelectTheFax();
		thereWereNoErrors();
		faxIsAddedForTheCustomer();
		Test.stopTest();
	}
	// Given a customer provides a new email
	static void givenACustomerProvidesANewFax(){
		repOpensInteraction();
        controller.newAccountFields.Fax = '(777) 777-7777';
	}
	// When I select the address
	static void whenISelectTheFax(){
		controller.createFax();
	}
	// Then it is added for the customer
	static void faxIsAddedForTheCustomer(){
		System.assertEquals('(777) 777-7777',[select Fax from Account where Id=:testAccount.Id].Fax);
		System.assertEquals('(777) 777-7777',[select case_Account_Fax_MVN__c from Case where Id=:interaction.Id].case_Account_Fax_MVN__c);
	}

//*******
	// Scenario 5:  A new fax is provided then create is canceled
	static testMethod void aFaxAddedThenCanceled(){
		givenATestInteraction();
		Test.startTest();
		givenACustomerProvidesANewFax();
		cancelFaxSelection();
		Test.stopTest();
	}

	static void cancelFaxSelection() {
		controller.cancelCreate();
		System.assertEquals('',controller.newAccountFields.Fax);
	}

//*******

	// Story:  New contact information is entered for the caller
	// Narrative:
    // In order to properly send a fulfillment package/response
	// As a call center agent
    // I want to add a new address

	// Scenario 6:  A new address is provided without all of the necessary fields filled in
	static testMethod void aNewAddressIsProvidedWithoutEnoughInformation(){
		givenATestInteraction();
		Test.startTest();
		givenACustomerProvidesANewAddressWithoutEnoughInformation();
		whenISelectTheAddressIGetAnError();
		Test.stopTest();
	}
	// Given a customer provides a new address
	static void givenACustomerProvidesANewAddressWithoutEnoughInformation(){
		repOpensInteraction();
        controller.newAddress.Name = null;
        controller.newAddress.Address_Line_2_vod__c = null;
        controller.newAddress.City_vod__c = null;
        controller.newAddress.State_vod__c = null;
        controller.newAddress.Zip_vod__c = null;
        controller.newAddress.Country_vod__c = null;
	}
	// When I select the address
	static void whenISelectTheAddressIGetAnError(){
		try{
			controller.createAddress();
		}catch(Exception e){
			System.assert(e.getMessage().contains(System.Label.Error_Required_Address_Fields));
			return;
		}
	}
//*******
	// Scenario 7:  A new phone number is provided but the agent doesn't enter it
	static testMethod void aNewPhoneIsProvidedButNotEntered(){
		givenATestInteraction();
		Test.startTest();
		givenACustomerProvidesANewPhoneNumberButItsNotEntered();
		whenISelectThePhoneNumber();
		Test.stopTest();
	}
	// Given a customer provides a new address
	static void givenACustomerProvidesANewPhoneNumberButItsNotEntered(){
		repOpensInteraction();
        controller.newAccountFields.Phone = null;
	}
	// When I select the address
	static void whenISelectThePhoneNumberIGetAnError(){
		try{
			controller.createPhone();
		}catch(Exception e){
			System.assert(e.getMessage().contains(System.Label.Error_Phone_Required));
			return;
		}
	}
//*******
	// Scenario 8:  A new email is provided but not entered
	static testMethod void aNewEmailIsProvidedButNotEntered(){
		givenATestInteraction();
		Test.startTest();
		givenACustomerProvidesANewEmailButNotEntered();
		whenISelectTheEmailIGetAnError();
		Test.stopTest();
	}
	// Given a customer provides a new email
	static void givenACustomerProvidesANewEmailButNotEntered(){
		repOpensInteraction();
        controller.newAccountFields.PersonEmail = null;
	}
	// When I select the address
	static void whenISelectTheEmailIGetAnError(){
		try{
			controller.createEmail();
		}catch(Exception e){
			System.assert(e.getMessage().contains(System.Label.Error_Email_Required));
			return;
		}
	}
//*******
	// Scenario 9:  A new fax is provided but not entered
	static testMethod void aNewFaxIsProvidedButNotEntered(){
		givenATestInteraction();
		Test.startTest();
		givenACustomerProvidesANewFaxButNotEntered();
		whenISelectTheFaxIGetAnError();
		Test.stopTest();
	}
	// Given a customer provides a new email
	static void givenACustomerProvidesANewFaxButNotEntered(){
		repOpensInteraction();
        controller.newAccountFields.Fax = null;
	}
	// When I select the fax
	static void whenISelectTheFaxIGetAnError(){
		try{
			controller.createFax();
		}catch(Exception e){
			System.assert(e.getMessage().contains(System.Label.Error_Fax_Required));
			return;
		}
	}
//*******
	// Scenario 10:  A new fax is provided but not entered
	static testMethod void whenACaseHasAnAddressItIsActive(){
		givenATestInteraction();
		Test.startTest();
		repOpensInteraction();
		givenCustomerPreviouslyProvidedAnAddress();
		whenLookCanSeeAndSelectAddress();
		addressAddedToTheInteraction();	
		theAddressIsActive();
		Test.stopTest();

	}
	static void theAddressIsActive(){
		System.assertEquals(controller.activeAddressId, controller.addressesRecords[0].Id);
	}
//*******
	// Scenario 11:  A US address requires state
	static testMethod void aStateIsRequired(){
		givenATestInteraction();
		Test.startTest();
		repOpensInteraction();
		givenACustomerProvidesANewAddress();
		addressRequiresState();
		Test.stopTest();
	}
	static void addressRequiresState(){
		System.assertEquals(true, controller.getShouldRequireState());
	}
//*******
	// Scenario 11:  Can update business name
	static testMethod void canUpdateBusinessName(){
		givenATestInteraction();
		repOpensInteraction();
		Test.startTest();
		updatesBusinessName();
		thereWereNoErrors();
		Test.stopTest();
		businessNameUpdated();
	}

	private static void updatesBusinessName(){
		controller.currentCase.MSD_CORE_Business_Name__c = ATestBusinessName;
		controller.updateBusiness();
	}

	private static void businessNameUpdated(){		
		System.assertEquals(ATestBusinessName, 
			[SELECT MSD_CORE_Business_Name__c 
			  FROM Case 
			 WHERE Id = :controller.currentCase.Id].MSD_CORE_Business_Name__c);
	}

	private static void thereWereNoErrors(){
        List<ApexPages.Message> messages = ApexPages.getMessages();
		String errorMessages = 'Error messages:\n';
		Integer numberOfErrors = 0;
		for(ApexPages.Message message : messages){
            if(message.getSeverity() == ApexPages.Severity.ERROR){
                numberOfErrors += 1;
                errorMessages += message.getDetail() + '\n';
                System.debug(LoggingLevel.ERROR, message.getDetail());
            }
        }
        System.assertEquals(0, numberOfErrors, errorMessages);
	}
//*******
	// Scenario 11:  Can update business name
	static testMethod void canCreateFaxView(){
		givenATestInteraction();
		Test.startTest();
		repOpensInteraction();
		createTheFaxView();
		thereWereNoErrors();
		updatingFaxIsTrue();
		Test.stopTest();
	}

	private static void createTheFaxView(){
		controller.createFaxView();
	}

	private static void updatingFaxIsTrue(){
		System.assertEquals(true, controller.updatingFax);
	}
//*******
	// Scenario 12:  Has countries
	static testMethod void hasCountries(){
		givenATestInteraction();
		Test.startTest();
		repOpensInteraction();
		assertHasCountries();
		Test.stopTest();
	}

	private static void assertHasCountries(){
		System.assertEquals(true, controller.countries.size() > 0);
	}
//*******
	// Scenario 13:  Use parent interaction Id
	static testMethod void usesParentInteractionId(){
		Test.startTest();
		repOpensInteractionWithParent();
		currentCaseIsParent();
		Test.stopTest();
	}

	static void repOpensInteractionWithParent(){
		parentInteraction = TestDataFactoryMVN.createTestCase();
		childInteraction = TestDataFactoryMVN.createTestRequest(parentInteraction);
		ApexPages.standardController stdController = new ApexPages.standardController(childInteraction);
        controller = new SelectedRequesterControllerMVN(stdController);
	}

	private static void currentCaseIsParent(){
		System.assertEquals(parentInteraction.Id, controller.currentCase.Id);
	}
//*******
	// Scenario 14:  Has referred preferred name
	static testMethod void hasPreferredNames(){
		givenATestInteraction();
		Test.startTest();
		repOpensInteraction();
		assertAccountPreferName();
		assertReferredPreferName();
		Test.stopTest();
	}

	private static void assertAccountPreferName(){
		System.assertEquals('Test Account', controller.customerPreferedName);
	}

	private static void assertReferredPreferName(){
		System.assertEquals('Mr. Johnny Employee', controller.referedByPreferedName);
	}
//*******
	// Scenario 15:  Clear Search Clears Search
	static testMethod void clearSearchClearsSearch(){
		givenATestInteraction();
		Test.startTest();
		repOpensInteraction();
		populateSearch();
		clearTheSearch();
		assertSearchAccountClear();
		Test.stopTest();
	}

	private static void populateSearch(){
		controller.searchAccount = referringAccount;
	}

	private static void clearTheSearch(){
		controller.clearSearch();
	}

	private static void assertSearchAccountClear(){
		System.assertEquals(null, controller.searchAccount.Id);
	}
//*******
	// Scenario 16:  Uses Case_AddressLine1 Stamp if no address
	private static String CaseAddressLine1 = 'case address line 1';

	static testMethod void usesAddressLine1AsOption(){
		givenAnAddressedInteraction();
		Test.startTest();
		repOpensInteraction();
		hasTheRightAmountOfAddressOptions(1);
		Test.stopTest();
	}

	private static void givenAnAddressedInteraction(){
		interaction = TestDataFactoryMVN.createTestCase(null, false);
		testAccount = [SELECT Id,
							  Preferred_Salutation_MRK__c,
							  Preferred_First_Name_MRK__c,
							  Preferred_Last_Name_MRK__c 
						 FROM Account
						WHERE Id =:interaction.AccountId];

		interaction.Address_MVN__c = null;
		interaction.case_AddressLine1_MVN__c = CaseAddressLine1;

		update interaction;
	}

	private static void hasTheRightAmountOfAddressOptions(Integer count){
		System.assertEquals(count, controller.getAddresses().size(), controller.getAddresses());
	}

	private static void hasAddressLine1(){
		System.assertEquals(CaseAddressLine1, controller.getAddresses().get(0).getValue());
	}
//*******
	// Scenario 17:  Can create an address for an HCP
	static testMethod void createAnHCPAddress(){
		Test.startTest();
		System.runAs(callCenterUser){
			repOpensInteractionForHCP();
			givenACustomerProvidesANewAddress();
			whenISelectTheAddress();
			thereWereNoErrors();
			addressIsAddedForTheCustomer(hcpInteraction);
		}
		Test.stopTest();
	}

	static void repOpensInteractionForHCP(){
		hcpAccount = TestDataFactoryMVN.createTestHCP();
		Id contactId = [select PersonContactId from Account where Id = :hcpAccount.Id].PersonContactId;
		hcpInteraction = TestDataFactoryMVN.createTestCase(hcpAccount.Id, contactId);
		ApexPages.standardController stdController = new ApexPages.standardController(hcpInteraction);
        controller = new SelectedRequesterControllerMVN(stdController);
	}
//*******

	static testMethod void testExceptions(){
		Test.startTest();
		givenATestInteraction();
		givenCustomerPreviouslyProvidedAnAddress();

		Test.setReadOnlyApplicationMode(true);

    	controller.associateAddress();

    	controller.accountEmailText = 'test@test.com';
    	controller.accountPhoneText = '5555555';
    	controller.accountFaxText = '5555555';

    	controller.newAccountFields.PersonEmail = 'test@test.com';
    	controller.newAccountFields.Phone = '5555555';
    	controller.newAccountFields.Fax = '5555555';

    	controller.associateEmail();
    	controller.createEmail();
    	controller.associatePhone();
    	controller.createPhone();
    	controller.associateFax();
    	controller.createFax();
    	controller.updateBusiness();
    	controller.createAddress();
    	controller.doSearch();
		Test.stopTest();
	}
}