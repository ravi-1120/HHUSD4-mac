/*
 * DocumentSearchUtilityMVN
 * Created by: Vincent Reeder
 * Created Date: Dec 3, 2013
 * Description: This interface is designed to allow the Knowledge Search Utility 
 * 				and the Vault Search Utility to be integrated seamlessly into 
 *				the KnowledgeSearchController.
 * Change Log: 	KRB REL 9.0 CR 3/13/2017 - Article Search will now be based on either the Customer 
                Type or (new for REL 9.0) the referredBy Customer Type. Inserted code to handle the
                referredBy Customer Type. 
 */

public class DocumentSearchUtilityMVN {

	//Required fields, never delete them ever
	public String documentSearchText;
	public String productId;
	public String customerType;
    
    //KRB REL 9.0 3/13/2017
    public String referringCustomerType;
    
    //KRB REL 10.0 7/13/2017
    public String searchTypeOverride;   
    
	public Case_Document_MVN__c searchDocument;
	public Set<String> documentIds = new Set<String>();
	public List<DocumentSearchFilterUtilityMVN.DocumentSearchFilterWrapperMVN> additionalSearchParams; 

    public interface searchInterface {

    	String buildDownloadURL(Case_Document_MVN__c cad);

    	String buildLinkURL(Case_Document_MVN__c cad);

	    String buildViewerURL(Case_Document_MVN__c cad);

	    List<Case_Document_MVN__c> search(DocumentSearchUtilityMVN searchUtility, Id caseID, Boolean isQuickSearch);   

	    List<Case_Document_MVN__c> selectDocument(Case_Document_MVN__c selectedDocument, Id caseId);
    }
}