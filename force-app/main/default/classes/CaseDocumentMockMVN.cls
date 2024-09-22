/*
* CaseDocumentMockMVN
* Created By: Kai Amundsen
* Created Date: April 5, 2013
* Description: Mock class used to store search results for Knowledge Articles.
*              The results are assembled in the DocumentSearchControllerMVN class
*              and are displayed to the end user in the DocumentSearchMVN page.
*/
public class CaseDocumentMockMVN {

	private static DocumentSearchUtilityMVN.searchInterface documentSearchUtility;
	
    @AuraEnabled
	public Case_Document_MVN__c caseDocument {get; set;}
    @AuraEnabled
	public Boolean isAttached {get;set;}

	static {
        // Dynamically define the DocumentSearchUtility based on custom settings
        Type t = Type.forName(Service_Cloud_Settings_MVN__c.getInstance().Document_Search_Utility_Class_MVN__c);
        documentSearchUtility = (DocumentSearchUtilityMVN.searchInterface) t.newInstance();
	}

	public CaseDocumentMockMVN(Case_Document_MVN__c cd) {
		caseDocument = cd;
		isAttached = false;
	}

	public string getViewerURL () {
		String result = documentSearchUtility.buildViewerURL(caseDocument);
		return result;
	}
	public string getLinkURL () {
		String result = documentSearchUtility.buildLinkURL(caseDocument);
		return result;
	}
	public string getDownloadURL () {
		String result = documentSearchUtility.buildDownloadURL(caseDocument);
		return result;
	}
}