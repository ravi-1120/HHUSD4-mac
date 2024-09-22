/*
* DocumentSearchControllerMVN
* Created By: Vincent Reeder
* Created Date: January 20, 2012
* Modified On: September 11, 2015
* Description: Controller for the Document Search page.
*              This class facilitates searching Knowledge Articles
*              based on different search parameters such as:
*              search term, type, subtype, product, country and language.
*              I also provides the ability to select a document indicating
*              that the document is being used in response to a request.
* Change Log: 
* 				KRB REL 9.0 CR 3/13/2017 - Article Search will now be based on either the Customer 
                Type or (new for REL 9.0) the referredBy Customer Type. For this Class, set up the 
                searchParams to include the Current Case's Referred by Customer Type. 



*/

public with sharing class DocumentSearchControllerMVN {

    public String               productId {get;set;}
    public String               documentSearchText {get;set;}
    public Case_Document_MVN__c searchDocument {get;set;}
    public String               selectedDocumentId {get;set;}
    public List<SelectOption>   countries {get; private set;}

    public List<CaseDocumentMockMVN> documentList{get; private set;}

    private Case                 currentCase;
    private String               familyType;
    private String               otherType;
    private String               defaultLanguage;
    private String               customerType;
    
    //KRB REL 9.0 3/17/2017 
    private String               referredByCustomerType;
    
    //KRB REL 10.0 7/13/2017 START
    public String searchTypeOverride{get;set;}
    public List<SelectOption> getsearchTypeOverrideTypes() {
        List<SelectOption> searchTypeOverrideTypes = new List<SelectOption>();
        searchTypeOverrideTypes.add(new SelectOption('','-None-'));
        searchTypeOverrideTypes.add(new SelectOption('Customer','Customer'));
        searchTypeOverrideTypes.add(new SelectOption('Referred By','Referred By'));
 
        return searchTypeOverrideTypes;
    }
    //KRB REL 10.0 7/13/2017 END
    
    
    
    
    private DocumentSearchUtilityMVN.searchInterface documentSearchUtility;

    private Map<String, String> productMap = new Map<String, String>();

    public DocumentSearchControllerMVN(ApexPages.StandardController controller) {
        Service_Cloud_Settings_MVN__c serviceCloudCustomSettings = Service_Cloud_Settings_MVN__c.getInstance();
        familyType = serviceCloudCustomSettings.Document_Search_Family_Type_MVN__c;
        otherType = serviceCloudCustomSettings.MSD_CORE_Document_Search_Other_Type__c;

        // Dynamically define the DocumentSearchUtility based on custom settings
        Type t = Type.forName(Service_Cloud_Settings_MVN__c.getInstance().Document_Search_Utility_Class_MVN__c);
        documentSearchUtility = (DocumentSearchUtilityMVN.searchInterface) t.newInstance();

        documentList = new List<CaseDocumentMockMVN>();

        Id caseId = ApexPages.currentPage().getParameters().get('caseId');
        System.debug('KRB: CaseId:' + caseId);
                
        currentCase = [SELECT Id, Subject, Customer_Type_MVN__c, isClosed, CaseNumber, 
                        AccountId, Product_MVN__c, Product_MVN__r.External_Id_vod__c,
                        Product_MVN__r.Parent_Product_vod__r.External_Id_vod__c
                        
                        //KRB REL 9.0 3/13/2017
                        , MSD_CORE_Referred_By_Customer_Type__c 
                       
                        FROM Case where Id = :caseId];

        defaultLanguage = [select Default_Document_Search_Language_MVN__c from User where Id = :UserInfo.getUserId()].Default_Document_Search_Language_MVN__c;

        List<Schema.PicklistEntry> countryList = Case_Document_MVN__c.Country_MVN__c.getDescribe().getPickListValues();
        countries = new List<SelectOption>();
        countries.add(new SelectOption('', Label.Document_Search_Article_All_Option));
        
        for (Schema.PicklistEntry entry : countryList) {
            if(entry.isActive()){
                string label = entry.getLabel();
                string value = entry.getValue();
                countries.add(new SelectOption(value, label));
            }
        }

        clearSearchFilters();
    }

    public PageReference clearSearchFilters() {
        searchDocument = new Case_Document_MVN__c();
        searchDocument.Document_Language_MVN__c = defaultLanguage;
        searchDocument.Country_MVN__c = [select MSD_CORE_Country_Code__c from User where Id =: UserInfo.getUserId()].MSD_CORE_Country_Code__c;
                
        customerType = currentCase.Customer_Type_MVN__c;
        System.debug('KRB: clearSearchFilters: customerType= ' + customerType);
        productId = currentCase.Product_MVN__r.External_Id_vod__c;
        
        //KRB Rel 9.0 3/13/2017
        referredByCustomerType = currentCase.MSD_CORE_Referred_By_Customer_Type__c;
        System.debug('KRB in clearSearchFilters: referredByCustomerType=' + referredByCustomerType);
        
        if(!String.isBlank(currentCase.Product_MVN__r.Parent_Product_vod__r.External_Id_vod__c)){
            productId = currentCase.Product_MVN__r.Parent_Product_vod__r.External_Id_vod__c;
        }
        
        return null;
    }

    public List<SelectOption> documentTypes {
        get {
            if(documentTypes == null || documentTypes.isEmpty()) {
                documentTypes = new List<SelectOption>();

                documentTypes.add(new SelectOption('All', Label.Document_Search_Article_All_Option));

                List<Schema.PicklistEntry> picklistValues = Case_Document_MVN__c.Document_Type_MVN__c.getDescribe().getPicklistValues();
                for(Schema.PicklistEntry type : picklistValues) {
                    documentTypes.add(new SelectOption(type.getValue(), type.getLabel()));
                }
            }

            return documentTypes;
        }
        private set;
    }

    public List<SelectOption> products {
        get {
            if(products == null || products.isEmpty()) {
                List<Product_vod__c> productList = [SELECT Id, Name, External_Id_vod__c 
                                                        FROM Product_vod__c 
                                                        where ((Product_Type_vod__c = :familyType and Company_Product_vod__c = true)
                                                                or Product_Type_vod__c = :otherType) 
                                                        and Active_MRK__c = true
                                                        order by Name];
                
                products = new List<SelectOption>();
                products.add(new SelectOption('',Label.Document_Search_Article_All_Option));
                
                for (Product_vod__c p : productList){
                    products.add(new SelectOption(p.External_Id_vod__c, p.Name));
                    productMap.put(p.External_Id_vod__c, p.Name);
                }
            }

            return products;
        }
        private set;
    }

    public PageReference selectDocument(){
        for(CaseDocumentMockMVN ksr : documentList) {
            if(ksr.caseDocument.Document_ID_MVN__c == selectedDocumentId) {
                documentSearchUtility.selectDocument(ksr.caseDocument, currentCase.Id);
                ksr.isAttached = true;
                /*if(ApexPages.getMessages() != null && ApexPages.getMessages().size() == 0){    
                    ksr.isAttached = true;
                }*/
            }
        }
        return null;
    }

    // Additional document search fields controlled by the Case_Document_Additional_Search_Fields field set
    public list<DocumentSearchFieldWrapperMVN> documentSearchFields {
        get {
            if(documentSearchFields == null) {
                documentSearchFields = new list<DocumentSearchFieldWrapperMVN>();
                Set<String> fieldsFilteredByCaseAcctRT = new DocumentSearchFilterUtilityMVN().fieldsFilteredByCaseAcctRT(currentCase.Id);

                // Get the fields from the field set and return a list of DocumentSearchFieldWrappers
                for(Schema.FieldSetMember f : SObjectType.Case_Document_MVN__c.FieldSets.Case_Document_Additional_Search_Fields.getFields()) {
                    DocumentSearchFieldWrapperMVN documentSearchField = new DocumentSearchFieldWrapperMVN();
                    documentSearchField.fieldAPIName = f.getFieldPath();
                    documentSearchField.fieldLabel   = f.getLabel();

                    // If the field is already filtered by the Record Type of the Account on the Case, 
                    // then don't display the field on page
                    documentSearchField.renderField  = !fieldsFilteredByCaseAcctRT.contains(f.getFieldPath());          

                    documentSearchFields.add(documentSearchField);
                }
            }
            return documentSearchFields;
        }
        set;
    }

    public PageReference search(){
        documentSearchText = String.escapeSingleQuotes(documentSearchText);
        system.debug('documentSearchText -->'+documentSearchText);
        system.debug('searchDocument -->'+searchDocument);
        system.debug('caseId -->'+currentcase.id);
        system.debug('searchTypeOverride -->'+searchTypeOverride);
        system.debug('productId -->'+productId);

        DocumentSearchUtilityMVN searchParams = new DocumentSearchUtilityMVN();
        searchParams.documentSearchText = documentSearchText;

        if(String.isBlank(documentSearchText) && !String.isBlank(productId) && productMap != null) {
            searchParams.documentSearchText = productMap.get(productId);
        } else if (String.isNotBlank(searchDocument.Document_Subtype_MVN__c) && String.isBlank(documentSearchText)) {
            searchParams.documentSearchText = searchDocument.Document_Subtype_MVN__c; 
        }

        searchParams.productId = productId;
        searchParams.searchDocument = searchDocument;
        searchParams.customerType = customerType;
        System.Debug('KRB: searchParams.customerType: ' + customerType);
        
        //KRB REL 9.0 3/13/2017
        searchParams.referringCustomerType = referredByCustomerType;
        System.Debug('KRB: referringCustomerType: ' + referredByCustomerType);
        
        //KRB REL 10.0 7/17/2017 - Start
        searchParams.searchTypeOverride = searchTypeOverride;
        System.Debug('KRB: searchTypeOverride: ' + searchTypeOverride);
        //KRB REL 10.0 7/17/2017 - End
        
        searchParams.additionalSearchParams = new DocumentSearchFilterUtilityMVN().getAdditionalDocumentSearchParams(searchDocument, currentCase.Id);

        List<Case_Document_MVN__c> resultList = documentSearchUtility.search(searchParams,currentCase.Id,false);
        documentList = new List<CaseDocumentMockMVN>();

        List<Case_Document_MVN__c> attachedDocuments = [SELECT Id,Document_ID_MVN__c
                                                        FROM Case_Document_MVN__c where Case_MVN__c = :currentCase.Id];

        Set<String> attachedDocumentIds = new Set<String>();

        for(Case_Document_MVN__c attachedDocument : attachedDocuments){
            attachedDocumentIds.add(attachedDocument.Document_ID_MVN__c);
        }

        if(resultList != null) {
            for(Case_Document_MVN__c cd : resultList) {
                CaseDocumentMockMVN mock = new CaseDocumentMockMVN(cd);
                if(attachedDocumentIds.contains(cd.Document_ID_MVN__c)){
                    mock.isAttached = true;
                }
                documentList.add(mock);
            }
        }

        return null;
    }

    public void processAttachedDocuments(){
        List<Case_Document_MVN__c> attachedDocuments = [select Id, Document_ID_MVN__c
                                                        from Case_Document_MVN__c 
                                                        where Case_MVN__c = :currentCase.Id];

        Set<String> attachedDocumentIds = new Set<String>();

        for(Case_Document_MVN__c attachedDocument : attachedDocuments){
            attachedDocumentIds.add(attachedDocument.Document_ID_MVN__c);
        }
        
        for(CaseDocumentMockMVN document : documentList) {
            if(attachedDocumentIds.contains(document.caseDocument.Document_ID_MVN__c)){
                document.isAttached = true;
            } else{
                document.isAttached = false;
            }
        }
    }

    // Wrapper used in page repeat tag to display fields from the field set
    public class DocumentSearchFieldWrapperMVN {
        public String fieldAPIName { get; set; }
        public String fieldLabel { get; set; }
        public Boolean renderField { get; set; }

        public DocumentSearchFieldWrapperMVN() {}
    }
}