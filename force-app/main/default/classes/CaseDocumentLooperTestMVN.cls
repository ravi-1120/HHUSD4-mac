/*
* CaseDocumentLooperTestMVN
* Created By: Kai Amundsen
* Created Date: May 14, 2014
* Description: This class is a helper class for Drawloop to be able to inlcude Veeva Vault documents in the merge
*     ****** NOTE:  Only works for Vault.  Case_Document_MVN__c records refering to Knowledge CaseArticles will cause an error ********
*/

@isTest
private class CaseDocumentLooperTestMVN {
    static Case request;
    static List<Id> knowledgeArticles;

    static {
        TestDataFactoryMVN.createSettings(true);
        Case interaction = TestDataFactoryMVN.createTestCase();
        request = TestDataFactoryMVN.createTestRequest(interaction);

        List<Case_Document_MVN__c> articles = new List<Case_Document_MVN__c>();
        for(Integer i = 0;i<5;i++) {
            Case_Document_MVN__c cad = new Case_Document_MVN__c();
            cad.Case_MVN__c = request.Id;
            cad.Document_ID_MVN__c = '1234';
            cad.Document_Major_Version_MVN__c = '1';
            cad.Document_Minor_Version_MVN__c = '1';
            cad.Document_File_Extension_MVN__c = '.doc';
            cad.Document_Title_MVN__c = 'Cholecap Package Insert';
            cad.Document_Type_MVN__c = 'FAQ';
            articles.add(cad);
        }

        insert articles;
    }

    @isTest static void testAllFilesReturned() {


        CaseDocumentLooperMVN cadm = new CaseDocumentLooperMVN();

        Test.startTest();
        List<Loop.AdHoc.Attachment> result = cadm.getAttachments(null,null,null,new Set<Id>{request.Id});
        Test.stopTest();

        system.assertEquals(5,result.size());

    }
}