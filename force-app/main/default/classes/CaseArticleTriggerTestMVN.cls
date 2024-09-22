/*
* CaseArticleTriggerTestMVN
* Created By: Kai Amundsen
* Created Date: April 18, 2013
* Description: This is a test class for CaseArticleDeleteTriggerMVN and CaseArticleCopyTriggerMVN
*/
@isTest
private class CaseArticleTriggerTestMVN {
	private static Case theCase;
	private static List<SObject> faqs;
	private static List<SObject> medicalLetters;
	private static List<SObject> cas;
	private static List<ID> articleIds;

	static {
		if(UtilitiesMVN.knowledgeInstalled) {
			KnowledgeSearchUtilityTestMVN.createSettings();
			articleIds = KnowledgeSearchUtilityTestMVN.setupArticles();
			theCase = TestDataFactoryMVN.createTestCase();

			faqs = Database.query('select ArticleNumber, UrlName, Title, KnowledgeArticleId, Id, Language, Summary, ArticleType, VersionNumber from General_MVN__kav where Id in :articleIds');
		    medicalLetters = Database.query('select ArticleNumber, UrlName, Title, KnowledgeArticleId, Id, Language, Summary, ArticleType, VersionNumber from MSD_CORE_Review__kav where Id in :articleIds');
		}
	}

	@isTest static void testCaseArticleDeleted() {
		if(UtilitiesMVN.knowledgeInstalled) {
			Case_Document_MVN__c cad = KnowledgeSearchUtilityMVN.createCaseDocument(theCase.Id, faqs[1]);
			Id id = theCase.Id;
			insert cad;
			
			List<SObject> ca = Database.query('select Id from CaseArticle where CaseId = :id');

			System.assertEquals(1, ca.size());

			Test.startTest();
				delete cad;
			Test.stopTest();

			List<SObject> results = Database.query('select Id from CaseArticle where CaseId = :id');

			System.assertEquals(0, results.size());
		}
	}

	@isTest static void testAllCaseArticleDataFieldsPopulated() {
		if(UtilitiesMVN.knowledgeInstalled) {
			Case_Document_MVN__c cad = KnowledgeSearchUtilityMVN.createCaseDocument(theCase.Id, faqs[1]);

			Test.startTest();
				insert cad;
			Test.stopTest();

			Case_Document_MVN__c result = [select Id, Document_Title_MVN__c from Case_Document_MVN__c where Id = :cad.Id limit 1];

			System.debug('DOC TITLE: '+result.Document_Title_MVN__c);
			System.assert(result.Document_Title_MVN__c.contains('Test'));
		}
	}

	@isTest static void testMissingFields() {
		if(UtilitiesMVN.knowledgeInstalled) {
			SObject faq = Database.query('select KnowledgeArticleId, Id from General_MVN__kav where Id in :articleIds limit 1');
			Case_Document_MVN__c cad = new Case_Document_MVN__c();
			cad.Case_MVN__c = theCase.Id;

			String correcException = 'Wrong or no exception';

			Test.startTest();
				try {
					Database.SaveResult sr = Database.insert(cad);
				} catch (Exception e) {
					System.debug('!!! ' + e.getMessage());
					System.assert(e.getMessage().contains('Required'));
					correcException = 'Correct exception thrown';
				}
			Test.stopTest();
			Id id = theCase.Id;
			List<SObject> ca = Database.query('select Id from CaseArticle where CaseId = :id');

			System.assertEquals(0,ca.size());

			System.assertEquals('Correct exception thrown', correcException);
		}
	}
}