/**
 * Name:                MSD_CORE_StudyDetailControllerTest
 * @auther:             Ravi Modi (Focal CXM)
 * @description:        Test class for MSD_CORE_StudyDetailController Controller class in Study Detail Page
 * Created Date:        15th March 2023
 */

@isTest
public class MSD_CORE_StudyDetailControllerTest {

    /**
     * @description: Cover testGetStudyDetail method
     * @return; void
    */
    @isTest
    static void testGetStudyDetail() {
        // Create test data
        MSD_CORE_Study_detail__c study = new MSD_CORE_Study_detail__c(
            Name = 'Test Study',
            MSD_CORE_Phase__c = 'Phase2',
            MSD_CORE_Therapeutic__c = 'Oncology',
            MSD_CORE_Clinical_Links__c = 'Test Clinical Links',
            MSD_CORE_Clinical_URL__c = 'http://testclinicalurl.com',
            MSD_CORE_Compound__c = 'Investigational Product',
            MSD_CORE_Compound_Warning__c = 'This information concerns investigational products. The safety and effectiveness of these investigational products has not been established.'
        );
        insert study;

        Test.startTest();

        // Call the method being tested
        MSD_CORE_Study_detail__c result = MSD_CORE_StudyDetailController.getStudyDetail(study.Id);

        Test.stopTest();

        // Verify the results
        System.assertEquals(study.Id, result.Id);
        System.assertEquals(study.Name, result.Name);
        System.assertEquals(study.MSD_CORE_Phase__c, result.MSD_CORE_Phase__c);
        System.assertEquals(study.MSD_CORE_Therapeutic__c, result.MSD_CORE_Therapeutic__c);
        System.assertEquals(study.MSD_CORE_Clinical_Links__c, result.MSD_CORE_Clinical_Links__c);
        System.assertEquals(study.MSD_CORE_Clinical_URL__c, result.MSD_CORE_Clinical_URL__c);
        System.assertEquals(study.MSD_CORE_Compound__c, result.MSD_CORE_Compound__c);
        System.assertEquals(study.MSD_CORE_Compound_Warning__c, result.MSD_CORE_Compound_Warning__c);
    }

    /**
     * @description: Cover testGetStudyDetailException method
     * @return; void
    */
    @isTest
    static void testGetStudyDetailException() {
        try {

            Test.startTest();
            // Call the method being tested with an invalid record ID
            MSD_CORE_Study_detail__c result = MSD_CORE_StudyDetailController.getStudyDetail('1234567890');
            Test.stopTest();

            // Verify that null is returned when an exception occurs
            System.assertEquals(null, result);   
        } catch (Exception e) {
            System.debug('Error-->'+e.getMessage());
        }
    }

    /**
     * @description: Cover testGetCarouselImage method
     * @return; void
    */
    @isTest 
    static void testGetCarouselImage() {
        // Test data setup
        MSD_CORE_Study_detail__c sd = new MSD_CORE_Study_detail__c(
            Name = 'Test Study',
            MSD_CORE_Phase__c = 'Phase2',
            MSD_CORE_Therapeutic__c = 'Oncology',
            MSD_CORE_Clinical_Links__c = 'Test Clinical Links',
            MSD_CORE_Clinical_URL__c = 'http://testclinicalurl.com',
            MSD_CORE_Compound__c = 'Investigational Product',
            MSD_CORE_Compound_Warning__c = 'This information concerns investigational products. The safety and effectiveness of these investigational products has not been established.'
        );
        insert sd;
        String recordId = sd.Id;

        PW_Robot_User__c rob = new PW_Robot_User__c();
        rob.Name = 'RobotUserSetting';
        rob.External_ID__c = 'MSD-000001';
        rob.Robot_User__c = 'testuser@merck.com.invalid';
        insert rob;

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        cv.origin = 'H';        
        Insert cv;

        List<ContentDocument> documents = [SELECT Id, Title, FileExtension, LatestPublishedVersionId FROM ContentDocument];

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = sd.Id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.Visibility = 'AllUsers';
        insert cdl;
        
        // Call the method to be tested
        Test.startTest();
        List<MSD_CORE_StudyDetailController.contentdata> result = MSD_CORE_StudyDetailController.getCarouselImage(recordId);
        Test.stopTest();
        
        // Verify the results
        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
        MSD_CORE_StudyDetailController.contentdata content = result[0];
        System.assertEquals(0, content.Order);
    }
}