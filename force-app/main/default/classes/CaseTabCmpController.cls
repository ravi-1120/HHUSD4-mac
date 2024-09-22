public class CaseTabCmpController { 
    
    @AuraEnabled
    public static DocSearchWrapper getPage(){
        Map<String,Map<String,String>> optionsMap = new Map<String,Map<String,String>>();  
        optionsMap.put('Document_Language_MVN__c',new Map<String,String>());
        optionsMap.put('Country_MVN__c',new Map<String,String>()); 
        optionsMap.put('Product_vod__c',new Map<String,String>());         
        
        for(Schema.PicklistEntry pickListValFamily : Case_Document_MVN__c.Document_Language_MVN__c.getDescribe().getPicklistValues()){
            optionsMap.get('Document_Language_MVN__c').put(pickListValFamily.getvalue(),pickListValFamily.getlabel());
        }
        
        optionsMap.get('Country_MVN__c').put('',Label.Document_Search_Article_All_Option);
        for(Schema.PicklistEntry pickListValFamily : Case_Document_MVN__c.Country_MVN__c.getDescribe().getPicklistValues()){
            optionsMap.get('Country_MVN__c').put(pickListValFamily.getvalue(),pickListValFamily.getlabel());
        }
        
        Service_Cloud_Settings_MVN__c serviceCloudCustomSettings = Service_Cloud_Settings_MVN__c.getInstance();
        String familyType = serviceCloudCustomSettings.Document_Search_Family_Type_MVN__c;
        String otherType = serviceCloudCustomSettings.MSD_CORE_Document_Search_Other_Type__c;
        optionsMap.get('Product_vod__c').put(Label.Document_Search_Article_All_Option,Label.Document_Search_Article_All_Option);
        for(Product_vod__c objProd : [SELECT Id, Name, External_Id_vod__c 
                                                        FROM Product_vod__c 
                                                        where ((Product_Type_vod__c = :familyType and Company_Product_vod__c = true)
                                                                or Product_Type_vod__c = :otherType) 
                                                        and Active_MRK__c = true
                                                        order by Name]){
            if(objProd.External_Id_vod__c != null)                                                
            optionsMap.get('Product_vod__c').put(objProd.Name, objProd.External_Id_vod__c);
        }
        
        DocSearchWrapper wrap = new DocSearchWrapper();
        wrap.optionsMap = optionsMap;
        wrap.defaultLanguage = [select Default_Document_Search_Language_MVN__c from User where Id = :UserInfo.getUserId()].Default_Document_Search_Language_MVN__c;
        return wrap;
    }
    
    public class DocSearchWrapper{
        @AuraEnabled public Map<String,Map<String,String>> optionsMap;
        @AuraEnabled public String defaultLanguage;
    }
    
    @AuraEnabled 
    public static Map<String, List<String>> getDependentMap(sObject objDetail, string contrfieldApiName,string depfieldApiName) {
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();        
        Map<String,List<String>> objResults = new Map<String,List<String>>();        
        Schema.sObjectType objType = objDetail.getSObjectType();
        if (objType==null){
            return objResults;
        }
        
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            return objResults;     
        }
        
        Schema.SObjectField theField = objFieldMap.get(dependentField);
        Schema.SObjectField ctrlField = objFieldMap.get(controllingField);
        
        List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
        List<String> controllingValues = new List<String>();
        
        for (Schema.PicklistEntry ple : contrEntries) {
            String label = ple.getLabel();
            objResults.put(label, new List<String>());
            controllingValues.add(label);
        }
        
        for (PicklistEntryWrapper plew : depEntries) {
            String label = plew.label;
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    objResults.get(controllingValues.get(i)).add(label);
                }
            }
        }
        return objResults;
    }
    
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }
    
    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';
        
        String validForBits = '';
        
        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        
        return validForBits;
    }
    
    private static final String base64Chars = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';
    
    
    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }
       
    @AuraEnabled
    public static List<CaseDocumentMockMVN> search(String documentSearchText, Case_Document_MVN__c objDetail, String caseId, String searchTypeOverride, String productId, Boolean isQuickSearch){
        System.debug('documentSearchText -->'+documentSearchText);
        System.debug('objDetail -->'+objDetail);
        System.debug('caseId -->'+caseId);
        System.debug('searchTypeOverride -->'+searchTypeOverride);
        System.debug('productId -->'+productId);
        System.debug('isQuickSearch -->'+isQuickSearch);
        if(isQuickSearch)
        {
            productId = '';
        }
        List<CaseDocumentMockMVN> documentList = new List<CaseDocumentMockMVN>();
        try{
            Case_Document_MVN__c searchDocument = new Case_Document_MVN__c();
            if(String.isNotBlank(objDetail.Document_Type_MVN__c)){                
                searchDocument.Document_Type_MVN__c = 'Knowledge__kav';
            }
            if(String.isNotBlank(objDetail.Document_Subtype_MVN__c) && objDetail.Document_Subtype_MVN__c != '-- None --'){
                searchDocument.Document_Subtype_MVN__c = objDetail.Document_Subtype_MVN__c;
            }
            if(objDetail.Document_Subtype_MVN__c != '-- None --' && String.isNotBlank(objDetail.MSD_CORE_Category__c) && objDetail.MSD_CORE_Category__c != '-- None --' ){
                searchDocument.MSD_CORE_Category__c = objDetail.MSD_CORE_Category__c;
            }
            if(String.isNotBlank(objDetail.Country_MVN__c)){
                searchDocument.Country_MVN__c = objDetail.Country_MVN__c;
            }
            if(String.isNotBlank(objDetail.Document_Language_MVN__c)){
                searchDocument.Document_Language_MVN__c = objDetail.Document_Language_MVN__c;
            }
        
            documentSearchText = documentSearchText != null ? String.escapeSingleQuotes(documentSearchText) : '';
            //String productId  = searchDocument.Product_vod__c;
            Map<String, String> productMap = new Map<String, String>();
            Service_Cloud_Settings_MVN__c serviceCloudCustomSettings = Service_Cloud_Settings_MVN__c.getInstance();
            String familyType = serviceCloudCustomSettings.Document_Search_Family_Type_MVN__c;
            String otherType = serviceCloudCustomSettings.MSD_CORE_Document_Search_Other_Type__c;
            System.debug(serviceCloudCustomSettings);
            List<Product_vod__c> productList = [SELECT Id, Name, External_Id_vod__c 
                                                            FROM Product_vod__c 
                                                            where ((Product_Type_vod__c = :familyType and Company_Product_vod__c = true)
                                                                    or Product_Type_vod__c = :otherType) 
                                                            and Active_MRK__c = true
                                                            order by Name];                    
            
            for (Product_vod__c p : productList){
                productMap.put(p.External_Id_vod__c, p.Name);
            }
    
            DocumentSearchUtilityMVN searchParams = new DocumentSearchUtilityMVN();
            searchParams.documentSearchText = documentSearchText;
    
            if(String.isBlank(documentSearchText) && !String.isBlank(productId) && productMap != null) {
                searchParams.documentSearchText = productMap.get(productId);
            } else if (String.isNotBlank(searchDocument.Document_Subtype_MVN__c) && String.isBlank(documentSearchText)) {
                searchParams.documentSearchText = searchDocument.Document_Subtype_MVN__c; 
            }
    
            searchParams.productId = productId;
            searchParams.searchDocument = searchDocument;
            Case c = [SELECT Customer_Type_MVN__c, MSD_CORE_Referred_By_Customer_Type__c FROM Case WHERE Id = :caseId];
            searchParams.customerType = c.Customer_Type_MVN__c;
            System.Debug('KRB: searchParams.customerType: ' + c.Customer_Type_MVN__c);
            
            //KRB REL 9.0 3/13/2017
            searchParams.referringCustomerType = c.MSD_CORE_Referred_By_Customer_Type__c;
            System.Debug('KRB: referringCustomerType: ' + c.MSD_CORE_Referred_By_Customer_Type__c);
            
            //KRB REL 10.0 7/17/2017 - Start
            searchParams.searchTypeOverride = searchTypeOverride;
            System.Debug('KRB: searchTypeOverride: ' + searchTypeOverride);
            //KRB REL 10.0 7/17/2017 - End
            
            searchParams.additionalSearchParams = new DocumentSearchFilterUtilityMVN().getAdditionalDocumentSearchParams(searchDocument, c.Id);
            
            System.debug(searchParams);
            DocumentSearchUtilityMVN.searchInterface documentSearchUtility;
            Type t = Type.forName(Service_Cloud_Settings_MVN__c.getInstance().Document_Search_Utility_Class_MVN__c);
            documentSearchUtility = (DocumentSearchUtilityMVN.searchInterface) t.newInstance();
                
            List<Case_Document_MVN__c> resultList = documentSearchUtility.search(searchParams,c.Id, isQuickSearch);
            List<Case_Document_MVN__c> finalResultList = new List<Case_Document_MVN__c>();
            
            List<Case_Document_MVN__c> attachedDocuments = [SELECT Id,Document_ID_MVN__c
                                                            FROM Case_Document_MVN__c where Case_MVN__c = :c.Id];
    
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
            
            System.debug('documentList -->'+documentList);
            
            return documentList;           
        }
        catch(exception e){
            system.debug(e.getMessage() + e.getLineNumber() + e.getStackTraceString());
             //return e;
        }
       return documentList;
    }
    
    @AuraEnabled
    public static String getCustomerType(String caseId){
        return [SELECT Customer_Type_MVN__c FROM Case WHERE Id = :caseId].Customer_Type_MVN__c;
    }
    
    @AuraEnabled
    public static QuickSearchWrapper getCase(String caseId){
        QuickSearchWrapper wrap = new QuickSearchWrapper();
        wrap.objCase = [SELECT Interaction_Notes_MVN__c, Details_MVN__c, MSD_CORE_AE_Description__c, Description, Customer_Type_MVN__c, Status, RecordType.DeveloperName, First_Attached_Article__c FROM Case WHERE Id = :caseId];
        wrap.attachedArticles = getAttachedKnowledgeArticles(caseId);
        String profileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        if(profileName.contains('Read Only')){
            wrap.isReadOnlyUser = true;
        }
        else{
            wrap.isReadOnlyUser = false;
        }
        List<MSD_CORE_CC_ArticleSearchSetting__mdt> articleSettings = [SELECT MSD_CORE_CC_Enable_Auto_Search__c, MSD_CORE_CC_Delay_in_Millis__c, MSD_CORE_CC_Limit_Flag__c, MSD_CORE_CC_Limit_Words__c FROM MSD_CORE_CC_ArticleSearchSetting__mdt LIMIT 1];
        wrap.articleSettings = articleSettings[0];
        return wrap;
    }
    
    @AuraEnabled
    public static List<Case_Document_MVN__c> getAttachedKnowledgeArticles(String caseId){
        List<Case_Document_MVN__c> attachedDocuments = [SELECT Id, Case_MVN__c, Document_Title_MVN__c, Document_ID_MVN__c, Knowledge_Article_Version_ID_MVN__c, Document_Major_Version_MVN__c, Document_Language_MVN__c, Document_Number_MVN__c, MSD_CORE_Document_Preview__c
                                                        FROM Case_Document_MVN__c where Case_MVN__c = :caseId
                                                        Order By CreatedDate desc];
        
        List<CaseArticle> attachedArticles = [SELECT Id, CaseId, KnowledgeArticleId
                                              FROM CaseArticle 
                                              where CaseId = :caseId
                                              Order By CreatedDate desc];
        
        if(attachedDocuments.size() == attachedArticles.size())
        {
            for(integer i=0; i < attachedArticles.size(); i++)
            {
                attachedDocuments[i].Document_ID_MVN__c = attachedArticles[i].KnowledgeArticleId;
            }
        }
        
        return attachedDocuments;
    }
    
    public class QuickSearchWrapper{
        @AuraEnabled
        public Case objCase;
        @AuraEnabled
        public List<Case_Document_MVN__c> attachedArticles;
        @AuraEnabled
        public boolean isReadOnlyUser;
        @AuraEnabled
        public MSD_CORE_CC_ArticleSearchSetting__mdt articleSettings;
    }
        
    @AuraEnabled
    public static List<Case_Document_MVN__c> selectDocument(Case_Document_MVN__c selectedDocument, Id caseId){        
        selectedDocument.Document_Language_MVN__c = 'en_US';
        DocumentSearchUtilityMVN.searchInterface documentSearchUtility;
        Type t = Type.forName(Service_Cloud_Settings_MVN__c.getInstance().Document_Search_Utility_Class_MVN__c);
        documentSearchUtility = (DocumentSearchUtilityMVN.searchInterface) t.newInstance();
        documentSearchUtility.selectDocument(selectedDocument, caseId);
        return getAttachedKnowledgeArticles(caseId);
    }
    
    @AuraEnabled
    public static void deleteArticle(String caseDocId, Id caseId){
       
       Id firstAttachedArticle = [SELECT First_Attached_Article__c FROM Case WHERE Id = :caseId].First_Attached_Article__c;
        delete [SELECT Id FROM Case_Document_MVN__c where Id = :caseDocId];
        List<Case_Document_MVN__c> lstCaseDocs = [SELECT Id FROM Case_Document_MVN__c where Case_MVN__c = :caseId];
        if(firstAttachedArticle == caseDocId)
        {
            
            Case objCase = new Case();
            objCase.Id =  caseId;
            objCase.Type = '';
            objCase.Category_MVN__c = '';
            update objCase;
        }
    }
    
    public class PicklistEntryWrapper{
        public String active {get;set;}
        public String defaultValue {get;set;}
        public String label {get;set;}
        public String value {get;set;}
        public String validFor {get;set;}
        public PicklistEntryWrapper(){            
        }
        
    }
        
    @AuraEnabled
    public static String getFirstAttachedArticleId(Id caseId)
    {
        return [SELECT First_Attached_Article__c FROM Case WHERE Id = :caseId].First_Attached_Article__c;
    }
    /*
     * Description : Get Knowledge search settings
     * return : Knowledge search settings
     */
    @AuraEnabled
    public static GASSettings__c getCompanySetting(){
        System.debug('GASSettings__c.getInstance() => '+GASSettings__c.getInstance());
        return GASSettings__c.getInstance();
    }
}