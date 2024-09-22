@isTest
public class PDS_CustomMetadataHandlerTest {
    @isTest
    static void testGetApplicationSettings() {
        // Create a test custom metadata record
        PDS_Application_Setting__mdt testAppSetting = new PDS_Application_Setting__mdt(
            DeveloperName = 'Custom Metadata Record Name',
            MasterLabel = 'Label'
        );

        Test.startTest();
        Map<String, Object> settings = PDS_CustomMetadataHandler.getApplicationSettings('Custom Metadata Record Name');
        Test.stopTest();

        // Verify the cachedAppSettings map is not null
        System.assertNotEquals(null, settings, 'The cachedAppSettings map should not be null.');

        // Verify the settings map contains the expected fields
        Map<String, Schema.SObjectField> schemaFieldMap = Schema.SObjectType.PDS_Application_Setting__mdt.fields.getMap();
        

        
    }
}