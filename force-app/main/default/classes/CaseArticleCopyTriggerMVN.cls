/*
* CaseArticleCopyTriggerMVN
* Created By: Kai Amundsen
* Created Date: April 23, 2013
* Modified By: Samuel Rosen
* Modified On: October 2013
* Description: Trigger to copy the Knowledge Article information onto the CaseArticleData shadow object from the
*			   Knowledge Article attached to the Request
*/
public with sharing class CaseArticleCopyTriggerMVN implements TriggersMVN.HandlerInterface {

	public void handle() {
		if(UtilitiesMVN.knowledgeInstalled)
		{
			Map<Case_Document_MVN__c,SObject> caseArticles = new Map<Case_Document_MVN__c,SObject>();
			List<Case_Document_MVN__c> articleData = (List<Case_Document_MVN__c>) Trigger.new;

			//Populate Case Article Data
			for(Case_Document_MVN__c cad : articleData) {
				if(String.isNotBlank(cad.Knowledge_Article_Version_ID_MVN__c)) {

					// Create Case Article, if duplicate, fail out
					SObject cs = Schema.getGlobalDescribe().get('CaseArticle').newSObject();

					// Copy CaseArticle Fields: cs.CaseId
					if(cad.Document_Major_Version_MVN__c != null) {
						cs.put('ArticleVersionNumber',Integer.valueOf(cad.Document_Major_Version_MVN__c));
					}
					cs.put('KnowledgeArticleId',cad.Document_ID_MVN__c);
					cs.put('ArticleLanguage',cad.Document_Language_MVN__c);
					cs.put('CaseId',cad.Case_MVN__c);

					caseArticles.put(cad,cs);
				}
			}

			if(!caseArticles.isEmpty()) {
                try{
                    insert caseArticles.values();
    
                    for(Case_Document_MVN__c cad : caseArticles.keySet()) {
                        cad.Knowledge_CaseArticle_ID_MVN__c = caseArticles.get(cad).Id;
                    }
                }
                catch(Exception e)
                {
                    System.debug('e -->'+e);
                }
			}
		}
	}
}