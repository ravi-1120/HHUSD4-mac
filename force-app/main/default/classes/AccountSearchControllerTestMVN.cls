/*
* AccountSearchControllerTestMVN
* Created By: Roman Lerman
* Created Date: 3/7/2013
* Description: This is the test class for the AccountSearchControllerMVN
*/
@isTest
private class AccountSearchControllerTestMVN {
    private static Account hcp;
    private static Account employee;
    private static Account business;
    private static User callCenterUser;

    private static String AN_ALTERNATE_ID = 'anAlternateId';

    private static AccountSearchResultMockMVN searchResult;

    private static String TestSAPIDs = 'testSAPIds';
    private static String TestExternalID = 'test_external_id';

    static {

        TestDataFactoryMVN.createSettings(true);
        Product_vod__c product = new Product_vod__c(Name='Test Product', External_ID_vod__c = 'testid');
        insert product;


        Profile p = [select Id from Profile where Name='MSD_CORE Contact Center - Contact Center Agent'];
        callCenterUser = new User(Alias = 'mrtest', Email='mrtest@example.com',
                        EmailEncodingKey='UTF-8', FirstName = 'mr', LastName='test', LanguageLocaleKey='de',
                        LocaleSidKey='de', ProfileId = p.Id, MSD_CORE_Country_Code__c = 'us',
                        TimeZoneSidKey='Europe/Berlin', UserName='mrtest@merk.com');
        insert callCenterUser;

        System.runAs(callCenterUser){
            hcp = TestDataFactoryMVN.createTestHCP();

            employee = TestDataFactoryMVN.createTestEmployee();
            business = TestDataFactoryMVN.createBusiness();

            TestDataFactoryMVN.createTestAddress(hcp);
            TestDataFactoryMVN.createTestAddress(employee);
            TestDataFactoryMVN.createTestAddressByCountry(business, 'us', 'externalId');
        }

        TestDataFactoryMVN.createDCRFieldTypes();
        TestDataFactoryMVN.createDCRServices();
    }

    static Case interaction = new Case();
    static AccountSearchControllerMVN controller;

    /**
     * Narrative
     * In order to: track a customer
     * As a: Call center agent
     * I want to: find contacts and associate an account with the case
     */

    /**
     * Scenario 1: Account search should return according to term.
     * Given: an HCP calls the call center
     * And: They exist in the database
     * When I search for Contacts
     * Then only the contacts that have this information should appear
     */

    /* Scenario 1 */
    @isTest static void accountSearchShouldReturnAccordingToTerm(){ 
        repReceivesCallAndOpensSearch();
        repEntersContactInformation();
        searchTheAccounts();
        theAccountsReturnedShouldContainTheTerm();
    }

    public static void repReceivesCallAndOpensSearch(){
        //Create a new request and controller
        interaction = TestDataFactoryMVN.createTestCase();
        Test.setCurrentPage(new PageReference('/apex/AccountSearchMVN?caseId='+interaction.Id));
        ApexPages.standardController stdController = new ApexPages.standardController(interaction);
        controller = new AccountSearchControllerMVN(stdController);
    }

    public static void repEntersContactInformation(){
        //"enter" the person's info.
        controller.searchFirstName  = 'Test';
        controller.searchLastName = 'Account';
        controller.searchAccount.Middle_vod__c   = 'Lit*';
        controller.searchAddress.Address_line_2_vod__c   = 'St.';
        controller.searchAddress.City_vod__c     = 'San Fran*';
        controller.searchAddress.Country_vod__c    = 'US';
        controller.searchAddress.State_vod__c    = 'ca';
        controller.searchAddress.Zip_vod__c        = '9*';
    }

    public static void repEntersContactInformationWithAllSortsOfWhiteSpace(){
        //"enter" the person's info.
        controller.searchFirstName  = '   Test   ';
        controller.searchLastName = '  Account   ';
        controller.searchAccount.Middle_vod__c   = '   Lit*    ';
        controller.searchName   = 'St. apostrophe\'s Hospital';
        controller.searchAddress.City_vod__c     = '  San Fran*    ';
        controller.searchAddress.Zip_vod__c        = ' 9*  ';
    }

    public static void searchTheAccounts(){
        //Search The accounts
        controller.doSearch();
    }

    public static void theAccountsReturnedShouldContainTheTerm(){
        //Confirm the results contain test in the first name and account in the last.
        System.assert(controller.resultMap.size() > 0);
        for (AccountSearchResultMockMVN resultAddress : controller.resultMap.values()){
            System.debug('resultAddress: ' + resultAddress);
            System.assertEquals(true,resultAddress.getAccount().Preferred_First_Name_MRK__c.containsIgnoreCase('test'));
            System.assertEquals(true,resultAddress.getAccount().Preferred_Last_Name_MRK__c.containsIgnoreCase('account'));
        }
    }
    /**/

    /**
     * Scenario 2: Attach an HCP to a case.
     * Given an HCP identified in a search
     * When I select the address
     * The Account is attached to the case.
     */

    @isTest static void selectedAddressAttachesAccountToCase(){ 
        System.runAs(callCenterUser){
            repReceivesCallAndOpensSearch();
            repEntersContactInformation();
            searchTheAccounts();
            selectAnAccount();
            theSelectedAddressAttachesTheAccountToTheCase();
        }
    }

    public static void selectAnAccount(){
        //Pick a contact and add it to the case.
        for (String reqId:controller.resultMap.keySet()){
            if(reqId.startsWith(hcp.Id)){
                controller.reqId = reqId;
            }
        }

        controller.updateCase();
    }

    public static void theSelectedAddressAttachesTheAccountToTheCase(){

        System.assertEquals(controller.cs.AccountId,controller.resultMap.get(controller.reqId).getAccountID());
    }


    /**
     * Scenario 3: Search for Employee and attach to case.
     * Given a Employee identified in a search
     * Attach them to a case.
     */

    @isTest static void searchForEmployeeAndAttachToCase(){ 
        System.runAs(callCenterUser){
            repReceivesCallAndOpensSearch();
            repEntersEmployeeInformation();
            repSetsTheTypeToEmployee();
            searchTheEmployeeAccount();
            Test.startTest();
            selectTheEmployee();
            Test.stopTest();
            theSelectedEmployeeIsAttachedToTheCase();

            controller.removeRequester();
            System.assertEquals(null,controller.cs.AccountId);
        }
    }

    public static void repEntersEmployeeInformation(){
        controller.searchLastName   = 'Employee*';
        controller.searchFirstName  = 'Jo*';
    }

    public static void repSetsTheTypeToEmployee(){
        controller.typeText = 'EMPLOYEE';
        controller.changeType();
    }

    public static void searchTheEmployeeAccount(){
        controller.doSearch();
    }

    public static void selectTheEmployee(){
        for (String reqId: controller.resultMap.keySet())
            controller.reqId = reqId;

        controller.updateCase();
    }

    public static void theSelectedEmployeeIsAttachedToTheCase(){
        System.assertEquals(controller.cs.AccountId,controller.resultMap.get(controller.reqId).getAccountID());
    }
    /***********/

    /**
     * Scenario 4: Search for Employee, employee isn't found, so a new Employee is created and attached to the Case.
     */
    @isTest static void createEmployeeAndAttachToCase(){ 
        repReceivesCallAndOpensSearch();
        repEntersNewEmployeeInformation();
        repSetsTheTypeToEmployee();
        searchTheEmployeeAccount();
        employeeNotFound();
        Test.startTest();
        createEmployee();
        theCreatedEmployeeIsAttachedToTheCase();
        Test.stopTest();
    }
    public static void repEntersNewEmployeeInformation(){
        controller.searchLastName   = 'Employee';
        controller.searchFirstName  = 'Peter';
        controller.searchName = '123 Test St';
    }
    public static void employeeNotFound(){
        System.assertEquals(0, controller.resultMap.size());
    }
    public static void createEmployee(){
        controller.createReferredBy = true;
        controller.updateNewAccount();
        controller.createAccount();
    }
    public static void theCreatedEmployeeIsAttachedToTheCase(){
        System.assertEquals('Peter', [select Referred_By_MVN__r.Preferred_First_Name_MRK__c from Case where Id =: interaction.Id].Referred_By_MVN__r.Preferred_First_Name_MRK__c);
        System.assertEquals('Employee', [select Referred_By_MVN__r.Preferred_Last_Name_MRK__c from Case where Id =: interaction.Id].Referred_By_MVN__r.Preferred_Last_Name_MRK__c);
    }

    /**
     * Scenario 5: Account search on phone should return according to term.
     * Given: an HCP calls the call center
     * And: They exist in the database
     * When I search for phone number
     * Then only the contacts that have this information should appear
     */
    @isTest static void accountSearchShouldReturnAccordingToPhone(){ 
        //Define sosl search results
        Map<Id,Account> fixedSearchResults = new Map<Id,Account>([select Id from Account where Phone='5555555555']);
        Test.setFixedSearchResults(new List<Id>(fixedSearchResults.keySet()));


        repReceivesCallAndOpensSearch();
        repEntersPhoneInformation();
        searchTheAccounts();
        theAccountsReturnedShouldContainThePhone();
    }

    public static void repEntersPhoneInformation(){
        //"enter" the person's info.
        controller.searchAccount.Phone = '5555555555';
    }

    public static void theAccountsReturnedShouldContainThePhone(){
        //Confirm the results contain test in the first name and account in the last.
        System.assert(controller.resultMap.size() > 0);
    }

    /**********/

    /**
     * Scenario 7: Search for Employee and add a referred by
     * Given: a rep calls on behalf of an HCP
     * And: They exist in the database
     * I can search and find them
     * I can then add them as a referred by
     */
    @isTest static void findEmployeeAndAttachToCase(){ 
        repReceivesCallAndOpensSearch();
        repSetsEmployeeInformation();
        repSetsTheTypeToEmployee();
        Test.startTest();
        searchTheEmployeeAccount();
        employeeFound();
        addReferredBy();
        theEmployeeIsAttachedToTheCase();
        Test.stopTest();
    }
    public static void repSetsEmployeeInformation(){
        controller.searchLastName   = 'Employee';
        controller.searchFirstName  = 'Johnny';
    }

    public static void employeeFound(){
        System.assertEquals(1, controller.resultMap.size());
    }
    public static void addReferredBy(){
        for (String refId: controller.resultMap.keySet())
            controller.refId = controller.resultMap.get(refId).getAccountID();

        controller.addReferredBy();
    }
    public static void theEmployeeIsAttachedToTheCase(){
        System.assertEquals([select Referred_By_MVN__r.FirstName from Case where Id =: interaction.Id].Referred_By_MVN__r.FirstName, 'Johnny');
        System.assertEquals([select Referred_By_MVN__r.LastName from Case where Id =: interaction.Id].Referred_By_MVN__r.LastName, 'Employee');
    }

    /**
     * Scenario 8: Remove Employee as Referred By
     * Given: a rep calls on behalf of an HCP
     * And: They exist in the database
     * I can search and find them
     * I can then add them as a referred by
     * But then I need to remove them since I picked the wrong rep
     */
    @isTest static void removeEmployeeFromCase(){ 
        repReceivesCallAndOpensSearch();
        repSetsEmployeeInformation();
        repSetsTheTypeToEmployee();
        searchTheEmployeeAccount();
        employeeFound();
        addReferredBy();
        Test.startTest();
        theEmployeeIsAttachedToTheCase();
        removeReferredBy();
        checkThatReferredByIsRemoved();
        Test.stopTest();
    }
    public static void removeReferredBy(){
        controller.removeReferredBy();
    }
    public static void checkThatReferredByIsRemoved(){
        System.assertEquals([select Referred_By_MVN__c from Case where Id =: interaction.Id].Referred_By_MVN__c, null);
    }

    /**
     * Scenario 9: Can Search on Employee ID
     * Given: a rep calls on behalf of an HCP
     * And: They exist in the database
     * I can search and find them
     * I can then add them as a referred by
     */
    @isTest static void searchByEmployeeID(){ 
        repReceivesCallAndOpensSearch();
        repSetsEmployeeID();
        repSetsTheTypeToEmployee();
        Test.startTest();
        searchTheEmployeeAccount();
        employeeFound();
        addReferredBy();
        theEmployeeIsAttachedToTheCase();
        Test.stopTest();
    }

    public static void repSetsEmployeeID(){
        controller.searchAccount.MSD_CORE_Merck_Employee_ID__c = 'testID';
    }

    /**
     * Scenario 10: 
     * Given: A rep enters an HCP with address missing city
     * And: An error is displayed
    **/
    @isTest static void attemptToCreateHCPWithInvalidAddress(){ 
        repReceivesCallAndOpensSearch();
        repEntersHCPInformationWithInvalidAddress();
        searchTheAccounts();
        openCreateModal();
        addressWasCopied('Invalid address');
        setAccountTypeAndSubType();
        createAccount();
        thereAreErrors(1);
    }

    public static void repEntersHCPInformationWithInvalidAddress(){
        //"enter" the person's info.
        controller.searchFirstName  = 'Test';
        controller.searchLastName = 'Account';
        controller.searchName = '1';
        controller.searchAddress.Name = 'Invalid address';
        controller.searchAddress.Address_line_2_vod__c   = 'St.';
        controller.searchAddress.Country_vod__c    = 'US';
        controller.searchAddress.State_vod__c    = 'ca';
        controller.searchAddress.City_vod__c = null;
        controller.searchAddress.Zip_vod__c        = '00000';
    }

    public static void openCreateModal(){
        controller.updateNewAccount();
    }

    public static void addressWasCopied(String copiedName){
        System.assertEquals(copiedName, controller.createAddress.Name, copiedName);
    }

    public static void setAccountTypeAndSubType(){
        controller.selectedType = 'INDIV HEALTHCARE PROF ' + Label.MSD_CORE_Prescriber_Type_Suffix;
        controller.typeSelected();
        controller.createAccount.Class_of_Trade_Sub_MRK__c = 'PHYSICIAN';
    }

    public static void createAccount(){
        controller.createAccount();
    }

    public static void thereAreErrors(Integer expectedErrors){
        List<ApexPages.Message> messages = ApexPages.getMessages();

        Integer numberOfErrors = 0;

        for(ApexPages.Message message : messages){
            if(message.getSeverity() == ApexPages.Severity.ERROR){
                numberOfErrors += 1;
                System.debug(LoggingLevel.ERROR, message.getDetail());
            }
        }

        System.assertEquals(expectedErrors, numberOfErrors);
    }

    @isTest static void attemptToCreateHCPWithoutFirstName(){ 
        repReceivesCallAndOpensSearch();
        repEntersHCPInformationWithoutFirstName();
        searchTheAccounts();
        openCreateModal();
        setAccountTypeAndSubType();
        createAccount();
        thereAreErrors(2);
    }

    public static void repEntersHCPInformationWithoutFirstName(){
        //"enter" the person's info.
        controller.searchFirstName  = null;
        controller.searchLastName = 'Account';
        controller.searchName = '1';
        controller.searchAddress.Name = 'Invalid address';
        controller.searchAddress.Address_line_2_vod__c   = 'St.';
        controller.searchAddress.Country_vod__c    = 'US';
        controller.searchAddress.State_vod__c    = 'ca';
        controller.searchAddress.City_vod__c = null;
        controller.searchAddress.Zip_vod__c        = '00000';
    }

    /**
     * Scenario 11: 
     * Given: A rep enters a business with address missing
     * And: An error is displayed
    **/
    @isTest static void attemptToCreateBusinessWithoutAddress(){ 
        repReceivesCallAndOpensSearch();
        repSwitchesToBusiness();
        repEntersNewBusinessInformation();
        searchTheAccounts();
        openCreateModal();
        setBusinessType();
        createAccount();
        thereAreErrors(1);
    }

    public static void repSwitchesToBusiness(){
        controller.isPersonSearch = false;
        controller.isPersonUpdated();
    }

    public static void repEntersNewBusinessInformation(){
        controller.searchName = 'a new test business';
        controller.searchAddress.Name = null;
        controller.searchAddress.City_vod__c = null;
        controller.searchAddress.Zip_vod__c = null;
        controller.searchAddress.State_vod__c = null;
        controller.searchAddress.Country_vod__c = null;
    }

    public static void repEnterBusinessAddress(){
        controller.createAddress.Name = 'test address';
        controller.createAddress.City_vod__c = 'test city';
        controller.createAddress.Zip_vod__c = '00000';
        controller.createAddress.State_vod__c = 'test state';
        controller.createAddress.Country_vod__c = 'test country';
    }

    public static void setBusinessType(){
        controller.createAccount.Class_Of_Trade_MRK__c = 'PHARMACY';
        controller.createAccount.Class_of_Trade_Sub_MRK__c = 'MAIL ORDER';
    }


    /**
     * Scenario 12: 
     * Given: A rep enters an HCP that has a business address
     * And: The address has business checked 
    **/
    @isTest static void createBusinessAddress(){ 
        repReceivesCallAndOpensSearch();
        repEntersHCPInformationWithAddress();
        searchTheAccounts();
        Test.startTest();
        openCreateModal();
        setAccountTypeAndSubType();
        createAccount();
        theAddressHasBusinessChecked();
        Test.stopTest();
    }

    public static void repEntersHCPInformationWithAddress(){
        //"enter" the person's info.
        controller.searchFirstName  = 'Business Address Test';
        controller.searchLastName = 'Account';
        controller.searchAddress.Name = 'business address';
        controller.searchAddress.Address_line_2_vod__c   = 'St.';
        controller.searchAddress.Country_vod__c    = 'US';
        controller.searchAddress.State_vod__c    = 'ca';
        controller.searchAddress.City_vod__c = 'a city';
        controller.searchAddress.Zip_vod__c = '00000';
    }

    public static void theAddressHasBusinessChecked(){
        List<Address_vod__c> addressesToAssert = [SELECT Business_vod__c, Account_vod__r.Name FROM Address_vod__c WHERE Account_vod__r.Preferred_First_Name_MRK__c = 'Business Address Test'];
        System.assertEquals(1, addressesToAssert.size(), 'Expecting 1 address but found ' + addressesToAssert.size());
        System.assertEquals(true, addressesToAssert.get(0).Business_vod__c, 'Business_vod__c not checked');
    }

    @isTest static void createBusinessAddressForNonPrescriber(){ 
        repReceivesCallAndOpensSearch();
        repEntersHCPInformationWithAddress();
        searchTheAccounts();
        Test.startTest();
        openCreateModal();
        setAccountTypeAndSubTypeForNonPrescriber();
        createAccount();
        theAddressHasBusinessChecked();
        Test.stopTest();
    }

    public static void setAccountTypeAndSubTypeForNonPrescriber(){
        controller.selectedType = 'INDIV HEALTHCARE PROF ' + Label.MSD_CORE_Non_Prescriber_Type_Suffix;
        controller.typeSelected();
        controller.createAccount.Class_of_Trade_Sub_MRK__c = 'PHYSICIAN';
    }

    /**
      * Scenario 13:
      * Given: A rep associates a business with a case
      * And: The child account of the business is in the search results
    **/
    @isTest static void searchChildAccounts(){ 
        System.runAs(callCenterUser){
            TestDataFactoryMVN.relateAccounts(hcp, business);
            repReceivesCallAndOpensSearch();
            repSwitchesToBusiness();
            repEntersBusinessInformation();
            searchTheAccounts();
            Test.startTest();
            selectTheBusiness();
            repSwitchesToPersonSearch();
            theAccountsReturnedShouldContainTheTerm();
            Test.stopTest();
        }
    }

    public static void repEntersBusinessInformation(){
        controller.searchName = 'Test business';
    }

    public static void selectTheBusiness(){        
        for(AccountSearchResultMockMVN result : controller.resultMap.values()){
            if(result.getSFDCAccountID() == business.Id){
                controller.businessId = result.getSFDCAccountID();
            }
        }
        controller.addBusiness();
    }

    public static void repSwitchesToPersonSearch(){
        controller.isPersonSearch = true;
        controller.isPersonUpdated();
    }

    /**
      * Scenario 14:
      * Given: A rep associates a person with a case
      * And: The parent account of the person is in the search results
    **/
    @isTest static void searchParentAccounts(){
        TestDataFactoryMVN.relateAccounts(hcp, business);
        repReceivesCallAndOpensSearch();
        repEntersContactInformation();
        searchTheAccounts();
        selectThePerson();
        repSwitchesToBusiness();
        theAccountsReturnedShouldIncludeTheBusiness();
    }

    public static void selectThePerson(){
        for(AccountSearchResultMockMVN result : controller.resultMap.values()){
            if(result.getSFDCAccountID() == hcp.Id){
                controller.refId = result.getAccount().Id;
            }
        }
        System.assertNotEquals(null, controller.refId, 'Did not find the Person to select:\n' + hcp);

        controller.addReferredBy();
    }

    public static void theAccountsReturnedShouldIncludeTheBusiness(){
        System.assertEquals(true, controller.didSearch);
        //Confirm the results contain test in the first name and account in the last.
        System.assert(controller.resultMap.size() > 0);
        for (AccountSearchResultMockMVN resultAddress : controller.resultMap.values()){
            System.debug('resultAddress: ' + resultAddress);
            System.assertEquals(true,resultAddress.getAccount().Preferred_Full_Name_MRK__c.containsIgnoreCase('Test business'));
            System.assertEquals('anAlternateId', resultAddress.getSAPIds());
        }
    }

    /**
      * Scenario 15:
      * Given: A rep searches for an alternate id
      * And: The rep finds the business
    **/
    @isTest static void searchAlternateIds(){
        repReceivesCallAndOpensSearch();
        repSwitchesToBusiness();
        repEntersAlternateId();
        searchTheAccounts();
        theAccountsReturnedShouldIncludeTheBusiness();
    }

    public static void repEntersAlternateId(){
        controller.alternateId = AN_ALTERNATE_ID;
    }

    /**
      * Scenario 16:
      * Given: A rep searches for an alternate id
      * And: The rep finds the business
    **/
    @isTest static void searchBusinessPhones(){
        Map<Id,Communication_Mechanism_MRK__c> fixedSearchResults = new Map<Id,Communication_Mechanism_MRK__c>([select Id from Communication_Mechanism_MRK__c where Phone_MRK__c = '9999999999']);
        Test.setFixedSearchResults(new List<Id>(fixedSearchResults.keySet()));
        repReceivesCallAndOpensSearch();
        repSwitchesToBusiness();
        repEntersBusinessPhone();
        searchTheAccounts();
        theAccountsReturnedShouldIncludeTheBusiness();
    }

    /**
      * Scenario 17:
      * Given: A Person Account Search
      * The search results are ordered
    **/
    @isTest static void returnOrderedPersonAccountList(){
        Id hcpRecordTypeId = [select Id from RecordType where SObjectType = 'Account' and DeveloperName = 'HCP'].Id;

        List<Account> accountSearchResults = new List<Account>();
        Account accountResult = new Account(FirstName = 'John', LastName = 'Astlerberri', 
                                            Preferred_First_Name_MRK__c = 'John', Preferred_Last_Name_MRK__c = 'Astlerberri', Status_MRK__c = 'ACTIVE',
                                            MSD_CORE_Country_Code__c = 'US', RecordTypeId = hcpRecordTypeId, Class_Of_Trade_MRK__c = 'INDIV HEALTHCARE PROF');
        Account accountResult2 = new Account(FirstName = 'Joe', LastName = 'Astlerberry', 
                                            Preferred_First_Name_MRK__c = 'Joe', Preferred_Last_Name_MRK__c = 'Astlerberry', Status_MRK__c = 'ACTIVE',
                                            MSD_CORE_Country_Code__c = 'US', RecordTypeId = hcpRecordTypeId, Class_Of_Trade_MRK__c = 'INDIV HEALTHCARE PROF');
        Account accountResult3 = new Account(FirstName = 'John', LastName = 'Astlerberry', 
                                            Preferred_First_Name_MRK__c = 'John', Preferred_Last_Name_MRK__c = 'Astlerberry', Status_MRK__c = 'ACTIVE',
                                            MSD_CORE_Country_Code__c = 'US', RecordTypeId = hcpRecordTypeId, Class_Of_Trade_MRK__c = 'INDIV HEALTHCARE PROF');
        
        accountSearchResults.add(accountResult);
        accountSearchResults.add(accountResult2);
        accountSearchResults.add(accountResult3);

        insert accountSearchResults;

        repReceivesCallAndOpensSearch();

        controller.searchLastName = 'Astlerbe*';

        searchTheAccounts();

        List<AccountSearchResultMockMVN> results = controller.orderedResultList;

        System.assertEquals(3, results.size());
        System.assertEquals('Astlerberri', results[0].getAccount().Preferred_Last_Name_MRK__c);
        System.assertEquals('Astlerberry', results[1].getAccount().Preferred_Last_Name_MRK__c);
        System.assertEquals('Joe', results[1].getAccount().Preferred_First_Name_MRK__c);
        System.assertEquals('Astlerberry', results[2].getAccount().Preferred_Last_Name_MRK__c);
        System.assertEquals('John', results[2].getAccount().Preferred_First_Name_MRK__c);        
    }

    /**
      * Scenario 18:
      * Given: A Business Account Search
      * The search results are ordered
    **/
    @isTest static void returnOrderedBusinessAccountList(){
        Id hospitalRecordTypeId = [select Id from RecordType where SObjectType = 'Account' and DeveloperName = 'Hospital_vod'].Id;

        List<Account> accountSearchResults = new List<Account>();
        Account accountResult = new Account(Name = 'Astlerberry Clinic', Status_MRK__c = 'Active',
                                            Preferred_Full_Name_MRK__c = 'Astlerberry Clinic', Class_of_Trade_MRK__c = 'HOSPITAL',
                                            MSD_CORE_Country_Code__c = 'US', RecordTypeId = hospitalRecordTypeId);
        Account accountResult2 = new Account(Name = 'Astlerberry Facility', Status_MRK__c = 'Active',
                                            Preferred_Full_Name_MRK__c = 'Astlerberry Facility', Class_of_Trade_MRK__c = 'HOSPITAL',
                                            MSD_CORE_Country_Code__c = 'US', RecordTypeId = hospitalRecordTypeId);
        Account accountResult3 = new Account(Name = 'Astlerberry Hospital', Status_MRK__c = 'Active',
                                            Preferred_Full_Name_MRK__c = 'Astlerberry Hospital', Class_of_Trade_MRK__c = 'HOSPITAL',
                                            MSD_CORE_Country_Code__c = 'US', RecordTypeId = hospitalRecordTypeId);
        
        accountSearchResults.add(accountResult);
        accountSearchResults.add(accountResult2);
        accountSearchResults.add(accountResult3);

        insert accountSearchResults;

        repReceivesCallAndOpensSearch();
        repSwitchesToBusiness();

        controller.searchName = 'Astlerbe*';

        searchTheAccounts();

        List<AccountSearchResultMockMVN> results = controller.orderedResultList;

        System.assertEquals(3, results.size());
        System.assertEquals('Astlerberry Clinic', results[0].getAccount().Preferred_Full_Name_MRK__c);
        System.assertEquals('Astlerberry Facility', results[1].getAccount().Preferred_Full_Name_MRK__c);
        System.assertEquals('Astlerberry Hospital', results[2].getAccount().Preferred_Full_Name_MRK__c);       
    }

    public static void repEntersBusinessPhone(){
        System.assertNotEquals(null, controller.searchAccount, 'Why is searchAccount null?');
        controller.searchAccount.Phone = '9999999999';
    }

    @isTest static void canGoToAccountPage(){
        repReceivesCallAndOpensSearch();
        repSetsEmployeeInformation();
        repSetsTheTypeToEmployee();
        Test.startTest();
        searchTheEmployeeAccount();
        employeeFound();
        repClicksOnSelectedAccount();
        theEmployeeIsAccountLink();
        Test.stopTest();
    }

    private static void repClicksOnSelectedAccount(){
        System.assertNotEquals(0, controller.resultMap.size());
        for (String reqId: controller.resultMap.keySet()){
            if(controller.resultMap.get(reqId).getAccountID() == employee.Id){
                controller.reqId = reqId;
            }            
        }


        System.assertNotEquals(null, controller.reqId);

        controller.goToAccountPage();
    }

    @isTest static void canCreateAffiliation(){
        accountsHaveMerckIds();
        repReceivesCallAndOpensSearch();
        repEntersContactInformation();
        searchTheAccounts();
        selectAnAccount();

        repSwitchesToBusiness();
        repEntersBusinessInformation();

        Test.startTest();
        searchTheAccounts();
        selectTheBusiness();
        repCreatesAffiliation();
        affiliationExists();
        Test.stopTest();
    }

    private static void theEmployeeIsAccountLink(){
        System.assertNotEquals(null, controller.accountLinkId);
        System.assertEquals([select FirstName from Account where Id = :controller.accountLinkId].FirstName, 'Johnny');
        System.assertEquals([select LastName from Account where Id = :controller.accountLinkId].LastName, 'Employee');
    }

    private static void accountsHaveMerckIds(){
        hcp.Merck_ID_MRK__c = 'testing1';
        business.Merck_ID_MRK__c = 'testing2';

        update hcp;
        update business;
    }

    private static void repCreatesAffiliation(){
        controller.setupAffiliateModal();
        System.assertNotEquals(null, controller.affiliation);
        controller.affiliation.Role_MRK__c = 'test role';
        controller.createAffiliation();
    }

    private static void affiliationExists(){
        List<Child_Account_vod__c> affiliations = [SELECT Id, Role_MRK__c FROM Child_Account_vod__c WHERE Role_MRK__c = 'test role'];
        System.assertEquals(1, affiliations.size());
    }

    /**
     * OTHER TESTS
     */

    @isTest static void testParameters(){
        repOpensSearchWithParameters();
        theParametersSetValues();
    }

    private static void repOpensSearchWithParameters(){
        //Create a new request and controller
        interaction = TestDataFactoryMVN.createTestCase();
        Test.setCurrentPage(new PageReference('/apex/AccountSearchMVN?caseId='+interaction.Id));

        ApexPages.currentPage().getParameters().put('isPersonSearch', '0');
        ApexPages.currentPage().getParameters().put('type', 'All');
        ApexPages.currentPage().getParameters().put('rt', 'All');
        ApexPages.currentPage().getParameters().put('name', 'Test name');
        ApexPages.currentPage().getParameters().put('lastName', 'test last name');
        ApexPages.currentPage().getParameters().put('firstName', 'test first name');
        ApexPages.currentPage().getParameters().put('phone', '5555555555');
        ApexPages.currentPage().getParameters().put('phoneSearch', '5555555555');
        ApexPages.currentPage().getParameters().put('employeeNumber', '123');
        ApexPages.currentPage().getParameters().put('customerNumber', '456');
        ApexPages.currentPage().getParameters().put('employeeNumberSearch', '123');
        ApexPages.currentPage().getParameters().put('customerNumberSearch', '456');
        ApexPages.currentPage().getParameters().put('city', 'a city');
        ApexPages.currentPage().getParameters().put('zip', '20905');
        ApexPages.currentPage().getParameters().put('country', 'USA');
        ApexPages.currentPage().getParameters().put('state', 'NC');

        ApexPages.standardController stdController = new ApexPages.standardController(interaction);
        controller = new AccountSearchControllerMVN(stdController);
    }

    private static void theParametersSetValues(){
        System.assertEquals(controller.isPersonSearch, false);
        System.assertEquals(controller.typeText, 'All');
        System.assertEquals(controller.searchName, 'Test name');
        System.assertEquals(controller.searchLastName, 'test last name');
        System.assertEquals(controller.searchFirstName, 'test first name');
        System.assertEquals(controller.searchAccount.Phone, '5555555555');
        System.assertEquals(controller.searchAccount.Phone, '5555555555');
        System.assertEquals(controller.searchAccount.MSD_CORE_Merck_Employee_ID__c, '123');
        System.assertEquals(controller.alternateId, '456');
        System.assertEquals(controller.searchAddress.City_vod__c, 'a city');
        System.assertEquals(controller.searchAddress.Zip_vod__c, '20905');
        System.assertEquals(controller.searchAddress.Country_vod__c, 'USA');
        System.assertEquals(controller.searchAddress.State_vod__c, 'NC');
    }

    @isTest static void testResultMock () { 
        AccountSearchResultMockMVN psr = new AccountSearchResultMockMVN(null);

        psr.getAccount().lastName = 'Smith';
        System.assertEquals('Smith',psr.getAccount().LastName);

        psr.setAddress(new Address_vod__c(Name='123 Main',City_vod__c='Chicago'));
        System.assertEquals('Chicago',psr.getAddress().City_vod__c);

        psr.setAccount(new Account(LastName='Jones'));
        System.assertEquals('Jones',psr.getAccount().lastName);

        psr.setAddress(new Address_vod__c(Name='123 Main'));
        System.assertEquals('123 Main', psr.getAddress().Name);
    }

    @isTest static void testStandAloneSearch(){ 
        Case interactionEmpty = new Case();
        ApexPages.standardController stdController = new ApexPages.standardController(interactionEmpty);
        controller = new AccountSearchControllerMVN(stdController);

        System.assertEquals(true, controller.standAloneSearch);
        System.assertEquals(new Case(), controller.cs);

        controller.searchLastName   = 'Employee';
        controller.searchFirstName  = 'Peter';
        controller.searchAccount.Fax  = '5555555';
        controller.searchName = '123 Test St';

        controller.updateNewAccount();
        controller.enterAccount();

        List<Case> noCase = [select Id from Case where AccountId = :controller.createAccount.Id];

        System.assertEquals(true, noCase.isEmpty());

    }

    @isTest static void shortPhoneSearch(){ 
        repReceivesCallAndOpensSearch();
        controller.searchAccount.Phone = '5';

        searchTheAccounts();

        System.assert(!ApexPages.getMessages().isEmpty());
    }

    @isTest static void doPhoneSearch(){ 
        interaction = TestDataFactoryMVN.createTestCase();
        Test.setCurrentPage(new PageReference('/apex/AccountSearchMVN?caseId='+interaction.Id+'&phoneSearch=true'));
        ApexPages.standardController stdController = new ApexPages.standardController(interaction);
        controller = new AccountSearchControllerMVN(stdController);
    }

    @isTest static void reachSearchLimit(){ 
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
        settings.Account_Search_Max_Results_MVN__c = 1;
        insert settings;

        repReceivesCallAndOpensSearch();
        repEntersContactInformation();
        searchTheAccounts();

        System.assert(!ApexPages.getMessages().isEmpty());
    }

    @isTest static void leadingTrailingWhiteSpaceSearch(){ 
        repReceivesCallAndOpensSearch();
        repEntersContactInformationWithAllSortsOfWhiteSpace();
        searchTheAccounts();
        allWhiteSpaceRemovedAndApostrophesHandled();
    }

    public static void allWhiteSpaceRemovedAndApostrophesHandled(){
        System.assertEquals('Test', controller.accountToSearch.Preferred_First_Name_MRK__c);
        System.assertEquals('Account', controller.accountToSearch.Preferred_Last_Name_MRK__c);
        System.assertEquals('St. apostrophe\'s Hospital', controller.searchName);
        System.assertEquals('San Fran*', controller.searchAddress.City_vod__c);
        System.assertEquals('9*', controller.searchAddress.Zip_vod__c);
    }

    @isTest static void testExceptions(){ 
        repReceivesCallAndOpensSearch();

        Test.setReadOnlyApplicationMode(true);
        controller.removeRequester();
        controller.removeReferredBy();
        controller.addReferredBy();

        repEntersContactInformation();
        searchTheAccounts();
        for (String reqId: controller.resultMap.keySet())
            controller.reqId = reqId;

        controller.updateCase();
        Test.setReadOnlyApplicationMode(false);

        controller.searchLastName   = 'Employee';
        controller.searchFirstName  = 'Peter';
        controller.searchAccount.Fax  = '5555555';
        controller.searchAccount.Phone  = '5555555';
        controller.searchName = '123 Test St';
        controller.searchAddress.City_vod__c = 'Chicago';

        controller.doSearch();

        controller.updateNewAccount();

        //Test no Employee record types for requester or referred by
        controller.createAccount.RecordTypeId = controller.employeeRecordTypeId;

        controller.enterAccount();

        System.assert(!ApexPages.getMessages().isEmpty());

        ApexPages.getMessages().clear();

        //Test no empty record type
        controller.createAccount.RecordTypeId = null;

        controller.enterAccount();

        System.assert(!ApexPages.getMessages().isEmpty());

        ApexPages.getMessages().clear();

        //Test bad email
        controller.searchAccount.PersonEmail  = 'asfljaksd';
        controller.createAccount.RecordTypeId = controller.hcpRecordTypeId;

        controller.enterAccount();

        System.assert(!ApexPages.getMessages().isEmpty());

        //Error creating Account
        controller.createAccount.FirstName = '';
        controller.createAccount.LastName = '';
        controller.searchAccount.PersonEmail  = 'test@test.com';
        controller.createAccount();

        //Search Term Required
        controller.searchAccount = new Account();
        controller.searchAddress = new Address_vod__c();

        controller.doSearch();
    }

    @isTest static void canSetSAPIds(){
        hcp.External_ID_vod__c = TestExternalID;
        update hcp;

        thereIsASearchResult();
        setSAPIds();
        wereSAPIdsSet();
    }

    @isTest static void getAccountIDReturnsExternalIDIfPresent(){
        hcp.External_ID_vod__c = TestExternalID;
        update hcp;
        
        thereIsASearchResult();
        getAccountIDReturnsExternalID();
    }

    private static void thereIsASearchResult(){
        searchResult = new AccountSearchResultMockMVN(hcp, null);
    }
    
    private static void setSAPIds(){
        searchResult.setSAPIds(TestSAPIDs);
    }

    private static void wereSAPIdsSet(){
        System.assertEquals(TestSAPIDs, searchResult.getSAPIds());
    }

    private static void getAccountIDReturnsExternalID(){
        System.assertEquals(TestExternalID, searchResult.getAccountID());
    }
}