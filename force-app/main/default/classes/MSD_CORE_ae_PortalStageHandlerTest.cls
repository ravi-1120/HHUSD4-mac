@isTest(SeeAllData=true)
public class MSD_CORE_ae_PortalStageHandlerTest {

    private static SObject createTestRecord(String objectApiName, String fieldApiName, String picklistValue) {
        SObject testRecord = Schema.getGlobalDescribe().get(objectApiName).newSObject();
        testRecord.put(fieldApiName, picklistValue);
        insert testRecord;
        return testRecord;
    }

    @isTest static void testGetPicklist() {
        String objectApiName = 'Case';
        String fieldApiName = 'MSD_CORE_AE_Is_Patient_Pregnant__c';
        String picklistValue = 'Yes';
        SObject testRecord = createTestRecord(objectApiName, fieldApiName, picklistValue);
        Test.startTest();
        List<MSD_CORE_ae_PortalStageHandler.PicklistOption> picklistOptions = 
            MSD_CORE_ae_PortalStageHandler.getPicklist(objectApiName, fieldApiName);
        Test.stopTest();
        System.assertNotEquals(null, picklistOptions, 'Picklist options should not be null');
        System.assertNotEquals(0, picklistOptions.size(), 'Picklist options should not be empty');
        Boolean isValuePresent = false;
        for (MSD_CORE_ae_PortalStageHandler.PicklistOption option : picklistOptions) {
            if (option.value.equals(picklistValue)) {
                isValuePresent = true;
                break;
            }
        }
        System.assertEquals(true, isValuePresent, 'Expected picklist value not found in the options');
    }

  

 

    @isTest static void testGetEmployeeDetails() {
        Account testAcc = MSD_CORE_ae_TestDataFactoryPortal.setupEmployee();
        Test.startTest();
        List<MSD_CORE_ae_Wrapper> wrappers = MSD_CORE_ae_PortalStageHandler.getEmployeeDetails('WIN-6341251', 'TestLastName');
        Test.stopTest();
        System.assertNotEquals(null, wrappers.size(), 'The wrapper list should not be null.');
        System.assertEquals(1, wrappers.size(), 'There should be exactly one wrapper matching the details.');
        MSD_CORE_ae_Wrapper wrapper = wrappers[0];
        System.assertEquals(testAcc.Preferred_First_Name_MRK__c, wrapper.FirstName, 'First Name should match.');
        System.assertNotEquals(null, wrapper.MaskedFirstName, 'Masked First Name should not be null.');
        System.assertNotEquals(null, wrapper.MaskedPhone, 'Masked Phone should not be null.');
        System.assertNotEquals(null, wrapper.MaskedEmail, 'Masked Email should not be null.');
    }


  
    /*@isTest static void testGetEmployeeDetails() {
        Account testAcc = MSD_CORE_ae_TestDataFactoryPortal.setupEmployee();        
        Test.startTest();
        List<Account> accounts = MSD_CORE_ae_PortalStageHandler.getEmployeeDetails('6341251');
        Test.stopTest();
        System.assertNotEquals(null, accounts.size(), 'The account list should not be null.');
        System.assertEquals(1, accounts.size(), 'There should be exactly one account matching the details.');
        System.assertEquals(testAcc.Preferred_First_Name_MRK__c, accounts[0].Preferred_First_Name_MRK__c, 'First Name should match.');
    }*/

 
    @isTest static void testGetProducts() {
        String searchTerm = 'ket';
        List<String> productTypes = new List<String>{'Family','Strength'};
        Test.startTest();
        List<Product_vod__c> products = MSD_CORE_ae_PortalStageHandler.getProducts(searchTerm,productTypes);
        Test.stopTest();
        System.assertNotEquals(null, products, 'Products list is null');
        System.assertNotEquals(0, products.size(), 'Products list is empty');
    }
    
    @isTest
    static void testPicklistOptions() {
        MSD_CORE_ae_PortalSetting__mdt portalSetting = MSD_CORE_ae_PortalStageHandler.picklistOptions();
    }
    
     @isTest
    static void testGetCredentials() {
        Test.startTest();
        List<MSD_CORE_AE_Contact__c> result = MSD_CORE_ae_PortalStageHandler.getCredentials('Test');
        Test.stopTest();
    }
}