/**
 * Component Name:      ContentDocumentLinkTriggerHandlerTest
 * Created By:          Ravi Modi (Focal CXM)
 * @Description ContentDocumentLinkTriggerHandlerTest is Test Class for ContentDocumentLinkTriggerHandler and ContentDocumentLinkTrigger
 */

@isTest
public class ContentDocumentLinkTriggerHandlerTest {

    /**
     * @description testUpdateUserVisibility is Test nmethod for UpdateUserVisibility method
     * @return Void
    */
    @isTest static void testUpdateUserVisibility() {

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

        System.assert([SELECT Visibility FROM ContentDocumentLink WHERE Id = :cdl.Id].Visibility == 'AllUsers', 'All Users not associated before test');


        test.startTest();

        cdl.Visibility = 'InternalUsers';
        update cdl;
        System.assert([SELECT Visibility FROM ContentDocumentLink WHERE Id = :cdl.Id].Visibility == 'InternalUsers', 'Internal Users association Failed');
        delete cdl;

        System.assert([SELECT COUNT() FROM ContentDocumentLink WHERE Id = :cdl.Id] == 0, 'Content Document Link deletion failed.');
        test.stopTest();
    }

    public static ContentDocumentLink createTestContentDocumentLink(Id parentId, Id contentDocumentId) {
        ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = parentId;
            cdl.ContentDocumentId = contentDocumentId;
            cdl.Visibility = 'AllUsers'; // Set visibility as needed
            return cdl;
    }

//     static testMethod void testHandleAfterInsert_Positive() {
        
//         MSD_CORE_Disease_Information__c diseaseInfo = new MSD_CORE_Disease_Information__c();
//             diseaseInfo.Name = 'Test Disease'; 
//             insert diseaseInfo;

//         ContentVersion cv = new ContentVersion();
//             cv.Title = 'Test Document';
//             cv.PathOnClient = 'TestDocument.pdf';
//             cv.VersionData = Blob.valueOf('Test Content');
//             cv.IsMajorVersion = true;
//             Insert cv;

//         Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        
//         PW_Robot_User__c rob = new PW_Robot_User__c();
//             rob.Name = 'RobotUserSetting';
//             rob.External_ID__c = 'MSD-000001';
//             rob.Robot_User__c = 'testuser@merck.com.invalid';
//             insert rob;

//         ContentDocumentLink cdl = New ContentDocumentLink();
//             cdl.LinkedEntityId = rob.Id;
//             cdl.ContentDocumentId = conDocId;
//             cdl.shareType = 'V';
//             Insert cdl;
        
//         ContentDistribution testContentDistribution = new ContentDistribution();
//             testContentDistribution.Name = 'Test Distribution';
//             testContentDistribution.ContentVersionId = cv.Id;
//             testContentDistribution.PreferencesAllowViewInBrowser = true;
//             insert testContentDistribution;

//         list<ContentDocumentLink> testCDL = new list<ContentDocumentLink> ();
//             testCDL.add(cdl);
        

//         Test.startTest();
//             ContentDocumentLinkTriggerHandler trghandl = new ContentDocumentLinkTriggerHandler(testCDL, true); 
//         Test.stopTest();
// }

static testMethod void testHandleAfterInsert_Positive() {
        
    MSD_CORE_Disease_Information__c diseaseInfo = new MSD_CORE_Disease_Information__c();
        diseaseInfo.Name = 'Test Disease'; 
        insert diseaseInfo;
    
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
        Insert cv;

    Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
    
    

    ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = diseaseInfo.Id;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;
    
   /* ContentDocumentLink cdl1 = New ContentDocumentLink();
        cdl1.LinkedEntityId = diseaseInfo.Id;
        cdl1.ContentDocumentId = conDocId;
        cdl1.shareType = 'V';
        Insert cdl1;*/
    
    ContentDistribution testContentDistribution = new ContentDistribution();
        testContentDistribution.Name = 'Test Distribution';
        testContentDistribution.ContentVersionId = cv.Id;
        testContentDistribution.PreferencesAllowViewInBrowser = true;
        //insert testContentDistribution;

    list<ContentDocumentLink> testCDL = new list<ContentDocumentLink> ();
        testCDL.add(cdl);
    

    Test.startTest();
        ContentDocumentLinkTriggerHandler trghandl = new ContentDocumentLinkTriggerHandler(testCDL, true); 
    Test.stopTest();
}

}