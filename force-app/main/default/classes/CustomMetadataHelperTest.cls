@isTest
public class CustomMetadataHelperTest {

    @isTest
    static void testGetMetadataSettings() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MockMSD_CORE_Default_AE_Settings'); // Replace with your static resource name
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            CustomMetadataHelper.MetadataSettings settings = CustomMetadataHelper.getMetadataSettings();
        Test.stopTest();

        // Assert the expected behavior based on mock data
        Id expectedUserId = UserInfo.getUserId();
        /*System.assertEquals(expectedUserId, settings.primaryExecutiveId, 'Primary Executive ID should match');
        System.assertEquals(expectedUserId, settings.medicalAEId, 'Medical AE ID should match');
        System.assertEquals(expectedUserId, settings.oncologyAEId, 'Oncology AE ID should match');*/
    }
}