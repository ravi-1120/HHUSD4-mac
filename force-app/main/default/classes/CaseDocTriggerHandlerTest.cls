@isTest(SeeAllData=true) 
public class CaseDocTriggerHandlerTest {
	private static Case request;
    private static List<Case_Document_MVN__c> articlesList;
    private static Knowledge__kav kRecord;
    static {
        Case interaction = TestDataFactoryMVN.createTestCase();
        request = TestDataFactoryMVN.createTestRequest(interaction);
        
        kRecord = new Knowledge__kav();
        kRecord.Title = 'Testing the Knowledge Comment and Conversation flow.';
        kRecord.UrlName = 'Testing-the-Knowledge-Comment-and-Conversation-flow';
        kRecord.MSD_CORE_Audience__c = 'CONSUMER';
        kRecord.MSD_CORE_KnwlArtCat__c = 'NSC';
        kRecord.MSD_CORE_General_Cmnt__c = 'This is  a Generic comment used for testing.';        
        kRecord.MSD_CORE_After_Call_Work_Cmnt__c = 'This is a After Call Work comment used for testing.';
        kRecord.MSD_CORE_Information_Cmnt__c = 'This is a Information comment used for testing.';
        kRecord.MSD_CORE_Instruction_Comment__c = 'This is a Instruction comment used for testing.';
        kRecord.MSD_CORE_Preview_Cmnt__c = 'This is a Preview comment used for testing.';
        kRecord.MSD_CORE_Questions_Comment__c = 'This is a Questions comment used for testing.';
        insert kRecord;
        
		articlesList = new List<Case_Document_MVN__c>();
        for(Integer i = 0;i<5;i++) {
            Case_Document_MVN__c cad = new Case_Document_MVN__c();
            cad.Case_MVN__c = request.Id;
            cad.Document_ID_MVN__c = '123456789876543212';
            cad.Knowledge_Article_Version_ID_MVN__c = 'KAV ID';
            //cad.Document_Major_Version_MVN__c = '1';
            //cad.Document_Minor_Version_MVN__c = '1';
            //cad.Document_File_Extension_MVN__c = '.doc';
            //cad.Document_Title_MVN__c = 'Cholecap Package Insert';
            //cad.Document_Type_MVN__c = 'FAQ';
            articlesList.add(cad);
        }
        insert articlesList;
    }
    
    static testMethod void updateCaseCategoryTestCase() {
        Test.startTest();
            CaseDocTriggerHandler.updateCaseCategory(articlesList);
        Test.stopTest();
    }
}