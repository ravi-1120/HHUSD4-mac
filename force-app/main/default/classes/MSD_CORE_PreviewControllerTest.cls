/**
 * Component Name:      MSD_CORE_PreviewControllerTest
 * Created By:          Ravi Modi (Focal CXM)
 * Created Date:        01st Aug 2024
 * @description:        Test class of MSD_CORE_PreviewController
 */

@isTest
public class MSD_CORE_PreviewControllerTest {
    
    /**
     * @description: Cover getResourceData method
     * @return: void
    */
    @isTest
    static void testgetResourceData() {

        HEQ_Search_Category_1__c cat = new HEQ_Search_Category_1__c();
        cat.Name = 'Test';
        cat.HEQ_Order__c = 1;
        insert cat;
        
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
        cdl.LinkedEntityId = cat.Id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.Visibility = 'AllUsers';
        insert cdl;

        Test.startTest();
        ContentVersion result = MSD_CORE_PreviewController.getResourceData(cv.id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result should not be null');
    }
}