/*
* CaseArticleDeleteTriggerMVN
* Created By: Kai Amundsen
* Created Date: April 18, 2013
* Modified By: Samuel Rosen
* Modified On: October 2013
* Description: Delete associated Case Articles when the Case Article Data object is deleted
*/

public with sharing class CaseArticleDeleteTriggerMVN implements TriggersMVN.HandlerInterface{
	public CaseArticleDeleteTriggerMVN() {

	}

	public void handle() {
		Set<Id> articleIds = new Set<Id>();

		for(Case_Document_MVN__c cad : (List<Case_Document_MVN__c>) Trigger.old) {
			if(String.isNotBlank(cad.Knowledge_CaseArticle_ID_MVN__c)) {
				articleIds.add(cad.Knowledge_CaseArticle_ID_MVN__c);
			}
		}

		if (!articleIds.isEmpty()) {
			List<SObject> delArticles = Database.query('select Id from CaseArticle where Id in :articleIds');

			delete delArticles;
		}
	}
}