/*
 * AttachedDocumentsControllerMVN
 * Created By:      Roman Lerman
 * Created Date:    4/25/2013
 * Modified By:     Samuel Rosen
 * Modified On:     Oct 2013
 * Description:     Displays the Knowledge Articles attached to the Requests
 */
public with sharing class AttachedDocumentsControllerMVN {
	public Boolean	showAttachedDocuments {get;set;}
    public Case 	documentCase{get; set;}
    public Id       attachedDocumentId {get;set;}
    public List<CaseDocumentMockMVN> attachedDocumentList;

    private DocumentSearchUtilityMVN.searchInterface documentSearchUtility;

    public AttachedDocumentsControllerMVN(){

        // Dynamically define the DocumentSearchUtility based on custom settings
        Type t = Type.forName(Service_Cloud_Settings_MVN__c.getInstance().Document_Search_Utility_Class_MVN__c);
        documentSearchUtility = (DocumentSearchUtilityMVN.searchInterface) t.newInstance();

        String caseId = ApexPages.CurrentPage().getParameters().get('id');

        if(String.isBlank(caseId)){
            caseId = ApexPages.CurrentPage().getParameters().get('caseId'); 
        }

    	documentCase = [select Id, IsClosed, MSD_CORE_Is_Submitted__c from Case where Id = :caseId];
    }

    public List<CaseDocumentMockMVN> getAttachedDocumentList() {
    	showAttachedDocuments = false;

        List<Case_Document_MVN__c> attachedDocuments = [SELECT Id, Document_Title_MVN__c, Document_Number_MVN__c, Document_Language_MVN__c,
                                                        Document_Summary_MVN__c, Document_Type_MVN__c, Document_ID_MVN__c,
                                                        Document_Major_Version_MVN__c, Document_Minor_Version_MVN__c, Knowledge_Article_Version_Id_MVN__c,
                                                        CreatedBy.Name, CreatedDate, Document_Subtype_MVN__c
                                                        FROM Case_Document_MVN__c where Case_MVN__c = :documentCase.Id];
        attachedDocumentList = new List<CaseDocumentMockMVN>();
        if(attachedDocuments.size() > 0){
        	showAttachedDocuments = true;
            for(Case_Document_MVN__c cd : attachedDocuments) {
                attachedDocumentList.add(new CaseDocumentMockMVN(cd));
            }
        }

        return attachedDocumentList;
    }

    public PageReference removeDocument() {
        for(CaseDocumentMockMVN cad : attachedDocumentList) {
            if(cad.caseDocument.Id == attachedDocumentId) {
                try {
                    delete cad.caseDocument;
                } catch (Exception e) {
                    ApexPages.addMessages(e);
                }
            }
        }

        return null;
    }
}