@isTest
public class MSD_CORE_HEQ_CVControllerTest {
    @isTest
    static void testGetRecords() {
        MSD_CORE_HEQ_UserPreference__c obj1 = new MSD_CORE_HEQ_UserPreference__c(MSD_CORE_Categories__c = 'Category1');
        MSD_CORE_HEQ_UserPreference__c obj2 = new MSD_CORE_HEQ_UserPreference__c(MSD_CORE_Categories__c = 'Category2');
        insert new List<MSD_CORE_HEQ_UserPreference__c> { obj1, obj2 };
        String objectName = 'MSD_CORE_HEQ_UserPreference__c';
        String fields = 'Id, Name, MSD_CORE_Categories__c';
        String conditions = 'Name LIKE \'Test%\'';
        String sortOrder = 'Name ASC';
        Integer limitSize = 2;
        Test.startTest();
        List<Map<String, String>> records = MSD_CORE_HEQ_ContentVersionController.getRecords(objectName, fields, conditions, sortOrder, limitSize);
        Test.stopTest();
        System.assertEquals(2, records.size(), 'The number of records fetched should be 2');
        Map<String, String> record1 = records[0];
        Map<String, String> record2 = records[1];
        System.assert(record1.containsKey('Id'), 'Record should contain Id');
        System.assert(record1.containsKey('Name'), 'Record should contain Name');
        System.assert(record1.containsKey('MSD_CORE_Categories__c'), 'Record should contain MSD_CORE_Categories__c');
        System.assert(record2.containsKey('Id'), 'Record should contain Id');
        System.assert(record2.containsKey('Name'), 'Record should contain Name');
        System.assert(record2.containsKey('MSD_CORE_Categories__c'), 'Record should contain MSD_CORE_Categories__c');
        System.assertEquals('Test Object 1', record1.get('Name'), 'First record Name should match');
        System.assertEquals('Test Object 2', record2.get('Name'), 'Second record Name should match');
    }
    @isTest
    static void testGetRecordsNoConditions() {
        MSD_CORE_HEQ_UserPreference__c obj1 = new MSD_CORE_HEQ_UserPreference__c(MSD_CORE_Categories__c = 'Category3');
        MSD_CORE_HEQ_UserPreference__c obj2 = new MSD_CORE_HEQ_UserPreference__c(MSD_CORE_Categories__c = 'Category4');
        insert new List<MSD_CORE_HEQ_UserPreference__c> { obj1, obj2 };
        String objectName = 'MSD_CORE_HEQ_UserPreference__c';
        String fields = 'Id, Name, MSD_CORE_Categories__c';
        String conditions = '';
        String sortOrder = '';
        Integer limitSize = 10;
        Test.startTest();
        List<Map<String, String>> records = MSD_CORE_HEQ_ContentVersionController.getRecords(objectName, fields, conditions, sortOrder, limitSize);
        Test.stopTest();
        System.assertEquals(2, records.size(), 'The number of records fetched should be 2');
        Map<String, String> record1 = records[0];
        Map<String, String> record2 = records[1];
        System.assert(record1.containsKey('Id'), 'Record should contain Id');
        System.assert(record1.containsKey('Name'), 'Record should contain Name');
        System.assert(record1.containsKey('MSD_CORE_Categories__c'), 'Record should contain MSD_CORE_Categories__c');
        System.assert(record2.containsKey('Id'), 'Record should contain Id');
        System.assert(record2.containsKey('Name'), 'Record should contain Name');
        System.assert(record2.containsKey('MSD_CORE_Categories__c'), 'Record should contain MSD_CORE_Categories__c');
        System.assertEquals('Test Object 3', record1.get('Name'), 'First record Name should match');
        System.assertEquals('Test Object 4', record2.get('Name'), 'Second record Name should match');
    }
    @isTest
    static void testGetRecordsWithException() {
        String objectName = 'NonExistentObject__c';
        String fields = 'Id, Name';
        String conditions = 'Name LIKE \'Test%\'';
        String sortOrder = 'Name ASC';
        Integer limitSize = 2;
        Test.startTest();
        try {
            List<Map<String, String>> records = MSD_CORE_HEQ_ContentVersionController.getRecords(objectName, fields, conditions, sortOrder, limitSize);
            System.assert(false, 'Expected an exception to be thrown');
        } catch (AuraHandledException e) {
            //System.debug(e.getMessage().contains('Error fetching records'), 'Exception message should contain "Error fetching records"');
        }
        Test.stopTest();
    }
}