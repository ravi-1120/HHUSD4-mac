/*
* KnowledgeSearchUtilityMVN
* Created By: Roman Lerman
* Created Date: 3/12/2013
* Modified On: September 11, 2015
* Description: This class is used for building out the queries for the Knowledge Search
* Change Log:   KRB REL 9.0 CR 3/13/2017 - Article Search will now be based on either the Customer 
                Type or (new for REL 9.0) the referredBy Customer Type. If the referredBy Customer Type is 
                present, use this, else use the standard Customer Type. 
*/
public with sharing class KnowledgeSearchUtilityMVN implements DocumentSearchUtilityMVN.searchInterface{
    /*private static final String StandardFields = 'ArticleNumber, UrlName, Title, KnowledgeArticleId, Id, Language, Summary, ArticleType, VersionNumber';*/
    private static final String StandardFields = 'ArticleNumber, UrlName, Title, KnowledgeArticleId, toLabel(Language), Summary, VersionNumber';
    private static final Map<String,Case_Document_Fields_MVN__c> documentFields = Case_Document_Fields_MVN__c.getAll();

    private static List<String> documentTypes;
    private static Service_Cloud_Settings_MVN__c serviceCloudCustomSettings;
    private static Integer maximumResults;

    static {
        serviceCloudCustomSettings = Service_Cloud_Settings_MVN__c.getInstance();
        maximumResults = (Integer)serviceCloudCustomSettings.Document_Search_Max_Results_MVN__c;
        documentTypes = new List<String>();
        
        List<Schema.PicklistEntry> picklistValues = Case_Document_MVN__c.Document_Type_MVN__c.getDescribe().getPicklistValues();
        for(Schema.PicklistEntry type : picklistValues){
            if(type.getValue().endsWith('_kav')) {
                documentTypes.add(type.getValue());
            }
        }
    }

    public static String buildDownloadURL(Case_Document_MVN__c cad){
        String urlString = '/' + cad.Knowledge_Article_Version_ID_MVN__c;

        return urlString;
    }

    public static String buildLinkURL(Case_Document_MVN__c cad){
        String urlString = '/' + cad.Knowledge_Article_Version_ID_MVN__c;
        return urlString;
    }

    public static String buildViewerURL(Case_Document_MVN__c cad){
        String urlString = '/' + cad.Knowledge_Article_Version_ID_MVN__c;
        return urlString;
    }

    public List<Case_Document_MVN__c> search(DocumentSearchUtilityMVN searchUtility, ID caseID, Boolean isQuickSearch){
        System.debug('searchUtility -->'+searchUtility);
        String documentSearchText = searchUtility.documentSearchText;
        String language = searchUtility.searchDocument.Document_Language_MVN__c;
        String queryString = buildQueryString(searchUtility, caseID);
        if(String.isBlank(queryString)) {
            return null;
        }
        List<Case_Document_MVN__c> knowledgeList = new List<Case_Document_MVN__c>();
        
        List<SObject> allResults = new List<SObject>();
        
        String tempQueryString = queryString.substring(0, queryString.lastIndexOf('AND'));
        List<String> searchTxt = documentSearchText != null ? documentSearchText.split(' ') : new List<String>();
        List<String> lstFinalSearchTxt = new List<String>();
        List<String> lstFinalSearchTxtToCompare = new List<String>();        
        
        for(String s : searchTxt){
            lstFinalSearchTxt.add('%'+s+'%');
            lstFinalSearchTxtToCompare.add(s);
        }
                 
        List<String> lstRTtoExclude = new List<String>{'DDP_Email_Templates','NSC_Addl_Info','PCC_Addl_Info'};
        String strUserProfile = UserInfo.getProfileId();
        String strProfileName = [SELECT Name FROM Profile WHERE Id = :strUserProfile].Name;
        if(strProfileName.contains('MSD_CORE Contact Center - PCC Agent'))
        {
            lstRTtoExclude.add('NSC_Standard');
            lstRTtoExclude.add('NSC_Medical');
            lstRTtoExclude.add('NSC_Quick_Info');
            lstRTtoExclude.add('NSC_Addl_Info');            
        }
        if(strProfileName.contains('MSD_CORE Contact Center - Contact Center Agent') || strProfileName.contains('MSD_CORE Contact Center - Article Manager'))
        {
            lstRTtoExclude.add('PCC_FAQ');
            lstRTtoExclude.add('PCC_Quick_Info');
            lstRTtoExclude.add('PCC_Addl_Info');
            lstRTtoExclude.add('PCC_Standard');
        }
        String articleLimit = Label.MSD_CORE_CC_Knowledge_Search_Article_Limit;
        if(!lstFinalSearchTxt.isEmpty())
        {
            queryString = tempQueryString + ' AND MSD_CORE_KnwlArtCat__c EXCLUDES (\'RMPDC\') AND RecordType.DeveloperName NOT IN :lstRTtoExclude AND Title LIKE :lstFinalSearchTxt LIMIT '+articleLimit;        
        }
        else{
            queryString = tempQueryString + ' AND MSD_CORE_KnwlArtCat__c EXCLUDES (\'RMPDC\') AND RecordType.DeveloperName NOT IN :lstRTtoExclude LIMIT '+articleLimit;
        }
          
        try {
            if(!lstFinalSearchTxt.isEmpty() || !isQuickSearch){
                System.debug('KRB: queryString: ' + queryString);
                allResults = Database.query(queryString);
            }
            else{
                return knowledgeList;
            }
        } catch (Exception e) {
            System.debug('Error message -->'+e);
            throw new AuraHandledException('Error : '+ e.getMessage());   
        }
        
        List<sobject> lstMostUsed = new List<sobject>();
        List<sobject> lstNonMostUsed = new List<sobject>();        
        Set<Id> lstAttachedArticles = new Set<Id>();
        Set<Id> setMostUsedArticles = new Set<Id>();
        
        System.debug('allResults size -->'+allResults.size());
        Map<Integer, List<SObject>> mapKnowledge = new Map<Integer, List<SObject>>();
        if(!lstFinalSearchTxtToCompare.isEmpty())
        {
            for(SObject sobj : allResults) {
                Integer count = 0;
                
                for(String s : lstFinalSearchTxtToCompare)
                {
                    Set<String> setUnique = new Set<String>();
                    setUnique.addAll(String.valueOf(sobj.get('Title')).toLowerCase().split(' '));
                    for(String s2 : setUnique){
                        if(s2.startsWith(s.toLowerCase()))
                        {
                            count++;
                        }
                    }
                }
                System.debug('matching words -->'+count+' Title -->'+sobj.get('Title'));
                if(count != 0)
                {
                    if(mapKnowledge.containsKey(count))
                    {
                        List<Sobject> lstKnowledge = mapKnowledge.get(count);
                        lstKnowledge.add(sobj);
                        mapKnowledge.put(count, lstKnowledge);
                    }
                    else{
                        mapKnowledge.put(count, new List<SObject>{sobj});
                    }
                } 
            }
            
            List<Integer> lstSortCount = new List<Integer>();
            lstSortCount.addAll(mapKnowledge.keyset());
            lstSortCount.sort();
            List<sobject> lstSortedKnowledgeList = new List<sobject>();
            lstSortedKnowledgeList.addAll(lstMostUsed);
            List<Integer> lstSortCountDesc = new List<Integer>();
            for(Integer i = lstSortCount.size()-1; i>=0; i--)
            {
                lstSortCountDesc.add(lstSortCount.get(i));
            }
            if(lstSortCount.size() > 0)
            {
                if(lstSortCount.size() == 1)
                {
                    Integer count = (new list<Integer>(mapKnowledge.keyset()))[0];
                    lstSortedKnowledgeList.addAll(mapKnowledge.get(count));
                }
                else{
                    for(integer i : lstSortCountDesc)
                    {
                        if(lstSortCount.contains(i))
                        {
                            try{
                                lstSortedKnowledgeList.addAll(mapKnowledge.get(i));
                            }
                            catch(Exception e){
                                System.debug(' i -->'+i);
                                System.debug('Exception -->'+e.getMessage());
                            }
                        }
                    }
                }
            }
            List<sobject> lstSortedKnowledgeListToReturn = new List<sobject>();
            for(Sobject obj : lstSortedKnowledgeList)
            {
                Case_Document_MVN__c result = createCaseDocument(caseID, obj);
                try{
                System.debug('result preview -->'+(String)result.get('MSD_CORE_Document_Preview__c'));
                }
                catch(exception e)
                {
                    continue;
                }
                lstSortedKnowledgeListToReturn.add(result);
            }
            
          	List<TopicAssignment> lstTopics = [SELECT Id, TopicId, EntityId FROM TopicAssignment WHERE Topic.Name LIKE :lstFinalSearchTxt LIMIT 1000];
            Set<Id> setKAId = new Set<Id>();
            for(TopicAssignment t : lstTopics)
            {
                setKAId.add(t.EntityId);
            }
            String queryStringOnTopics = queryString.substring(0, queryString.lastIndexOfIgnoreCase('AND'));
            queryStringOnTopics = queryStringOnTopics + ' AND MSD_CORE_KnwlArtCat__c EXCLUDES (\'RMPDC\') AND Id IN :setKAId AND RecordType.DeveloperName NOT IN :lstRTtoExclude LIMIT 50';
            list<SObject> articlesOnTopics = Database.query(queryStringOnTopics);
            for (SObject obj : articlesOnTopics) {
                if(!setMostUsedArticles.contains((Id)obj.get('Id'))){
                   Case_Document_MVN__c result = createCaseDocument(caseID, obj);
                   lstSortedKnowledgeListToReturn.add(result);
                }
            }
            return lstSortedKnowledgeListToReturn;
        }
        else
        {
            if(!isQuickSearch)
            {
                for(Sobject obj : allResults)
                {
                    Case_Document_MVN__c result = createCaseDocument(caseID, obj);
                    knowledgeList.add(result);
                }
                return knowledgeList;
            }            
        }
        return knowledgeList;
    }

    private String buildQueryString(DocumentSearchUtilityMVN searchUtility, ID caseID){
        
        /*
           SELECT <Fields>
           FROM   xxx
           WHERE  conditions
           AND    Title includes ();
          
         
         */
        
        String documentType = searchUtility.searchDocument.Document_Type_MVN__c;
        System.debug('documentType -->'+documentType);
        String documentSubType = searchUtility.searchDocument.Document_Subtype_MVN__c; 
        String documentSearchText = searchUtility.documentSearchText;
        String productId = searchUtility.productId;
        String language = searchUtility.searchDocument.Document_Language_MVN__c;
        String customerType = searchUtility.customerType;
        
        //KRB REL 9.0 3/13/2017
        String referringCustomerType = searchUtility.referringCustomerType;
        
        //KRB REL 10.0 7/13/2017 Start
        String searchTypeOverride = searchUtility.searchTypeOverride;
        System.debug('KRB: searchTypeOverride='+ searchTypeOverride);
        //KRB REL 10.0 7/13/2017 End
        
        boolean firstReturningClause = true;
        boolean isAll = documentType == 'All';
        
        //KRB 1/25/2017
        System.debug('KRB: in buildQueryString... '); 
        System.debug('KRB: documentType=' + documentType);
        System.debug('KRB: documentSubType=' + documentSubType);
        System.debug('KRB: documentSearchText=' + documentSearchText);
        System.debug('KRB: productId=' + productId);
        System.debug('KRB: language=' + language);
        System.debug('KRB: customerType=' + customerType);
        System.debug('KRB: isAll=' + isAll);
        System.debug('KRB: referringCustomerType='+ referringCustomerType);
        
        //KRB REL 10.0 7/13/2017 - in -  added searchTypeOverride
        String whereClause = buildWhereClause(searchUtility, language, productId, customerType, referringCustomerType, searchTypeOverride);
        
        System.debug('whereClause -->'+whereClause);
        //KRB REL 10.0 7/13/2017 - out
        //KRB REL 9.0 3/17/2017 - in -  added referringCustomerType
        //String whereClause = buildWhereClause(searchUtility, language, productId, customerType, referringCustomerType);
        //KRB REL 9.0 3/17/2017 - out
        //String whereClause = buildWhereClause(searchUtility, language, productId, customerType);
        
        if(String.isBlank(documentSearchText) && String.isNotBlank(productId) && productId != 'All'){
            documentSearchText = [select Name from Product_vod__c where External_Id_vod__c = :productId].Name;
        } else if( String.isBlank(documentSearchText) && String.isNotBlank(documentSubType)) {
            documentSearchText = documentSubType;
        }
        //documentType = 'Knowledge__kav';
        String findQuery = 'find :documentSearchText';
        for(String aType : documentTypes) {
            if (String.isBlank(documentType) || isAll || documentType.equalsIgnoreCase(aType)) {
                if (firstReturningClause) {
                    findQuery += ' returning ';
                    firstReturningClause = false;
                } else {
                    findQuery += ', ';
                }

                String typeFields = buildTypeFields(aType);

                findQuery += aType + ' (' + StandardFields + typeFields + whereClause + ')';
            }
        }

        findQuery += ' limit ' + maximumResults;
        
        // KRB REL 9.0 1/25/2017 - New Search Query documentType
        String SOQLQuery = 'SELECT Id, MSD_CORE_Questions__c, MSD_CORE_Preview__c, MSD_CORE_GenCatgry__c, MSD_CORE_Subtype__c, ' + StandardFields + ' ' + buildTypeFields(documentType) + ' FROM ' + documentType + ' ' + whereClause;
        SOQLQuery += ' AND Title LIKE ' + '\'%' + documentSearchText + '%\'';
        SOQLQuery += ' limit ' + maximumResults;
        
        system.debug('KRB: old Find Query: '+findquery);

        system.debug('KRB: new SOQL Query: '+ SOQLQuery);
        //KRB REL 9.0 1/25/2017 - out
        //return findQuery;        
        //KRB REL 9.0 1/25/2017 - in
        return SOQLQuery; 
    }

    private String buildTypeFields(String documentType) {
        String typeFields = '';

        for(Case_Document_Fields_MVN__c caf: documentFields.values()) {

            if(String.isNotBlank(caf.Document_Type_MVN__c) && documentType.equalsIgnoreCase(caf.Document_Type_MVN__c)) {
                typeFields += ', ';
                typeFields += caf.Document_Field_MVN__c;
            }
        }

        return typeFields;
    }
    
    //KRB REL 9.0 3/17/2017 - added referringCustomerType
    private String buildWhereClause(DocumentSearchUtilityMVN searchUtility, 
                                    String language, 
                                    String productId,
                                    String customerType
                                    ,String referringCustomerType
                                    ,String searchTypeOverride
                                   ) {
        String whereClause;
        if(!Test.isRunningTest()){
            whereClause = ' where PublishStatus = \'Online\' and IsLatestVersion=true ';
        }else{
            whereClause = ' where PublishStatus = \'Draft\' and IsLatestVersion=true ';
        }

        if(language != null && language != '') {
            whereClause += ' and Language = :language';
        }
        /*
        if(!String.isBlank(productId) && productId != 'All') {
            whereClause += ' and (Product_ID_MVN__c like \'%'+productId+'%\'';
            whereClause += ' or Product_ID_MVN__c = \'\'';
            whereClause += ')';
        }
                                      
        if(!String.isBlank(productId) && productId != 'All') {
            whereClause += ' and (Product_Therapeutic_Area__c = \''+productId+'\'';
            whereClause += ' or Product_Therapeutic_Area__c = null ';
            whereClause += ')';
        }
		*/
                                       
       if(!String.isBlank(productId) && productId != 'All') {
            whereClause += ' and (MSD_CORE_Product_ID__c like \'%'+productId+'%\'';
            whereClause += ' or MSD_CORE_Product_ID__c = \'\'';
            whereClause += ')';
        }
                                               
        if(!String.isBlank(searchUtility.searchDocument.Country_MVN__c)) {
            whereClause += ' and MSD_CORE_GenCntry__c includes (\'' + searchUtility.searchDocument.Country_MVN__c + '\')';
            //whereClause += ' and General_MVN_MSD_CORE_Country__c includes (\'AY\')';
        }

        
        //KRB REL 9.0 3/17/2017 - OUT
        //whereClause += ' and MSD_CORE_Customer_Type__c includes (\'' + customerType + '\')';

        
        //KRB REL 10.0 7/13/2017 - out                               
        ////KRB REL 9.0 3/17/2017 - IN 
        //if(!String.isBlank(referringCustomerType)) {
        //  whereClause += ' and MSD_CORE_Customer_Type__c includes (\'' + referringCustomerType + '\')';                                  
        //}else{
        //  whereClause += ' and MSD_CORE_Customer_Type__c includes (\'' + customerType + '\')';  
        //}
           
        //KRB REL 10.0 7/13/2017 - In                               
        if(searchTypeOverride == 'Customer') {
             whereClause += ' and MSD_CORE_Audience__c includes (\'' + customerType + '\')';  
        }else if(searchTypeOverride == 'Referred By'){
             whereClause += ' and MSD_CORE_Audience__c includes (\'' + referringCustomerType + '\')';            
        }else{
           if(!String.isBlank(referringCustomerType)) {
             whereClause += ' and MSD_CORE_Audience__c includes (\'' + referringCustomerType + '\')';                                  
           }else{
             whereClause += ' and MSD_CORE_Audience__c includes (\'' + customerType + '\')';  
           }
        }                               
                                       
                                       
        // Include additional query parameters specified in the custom setting Account_Type_Document_Filters_MVN__c
        List<DocumentSearchFilterUtilityMVN.DocumentSearchFilterWrapperMVN> additionalQueryParams = searchUtility.additionalSearchParams;
        
        if(additionalQueryParams != null) {
            for(Integer i=0; i < additionalQueryParams.size(); i++) {
                if(!additionalQueryParams[i].isCustomFilter) {                
                    whereClause += ' and '+additionalQueryParams[i].documentSearchField+'='+additionalQueryParams[i].filterValue+' ';
                } else {
                    whereClause += ' and ('+additionalQueryParams[i].customFilterLogic+') ';
                }            
            } 
        }            

        System.debug('KRB: KnowledgeSearchUtility: buildWhereClause: whereClause='+whereClause);

        return whereClause;
    }

    public List<Case_Document_MVN__c> selectDocument(Case_Document_MVN__c selectedDocument, Id caseId){
        List<Case_Document_MVN__c> attachedKnowledgeList = [SELECT Id,Document_ID_MVN__c
                                                            FROM Case_Document_MVN__c where Case_MVN__c = :caseId];
        
        SavePoint sp = Database.setSavePoint();
        try {
            Case_Document_MVN__c selDocToInsert = selectedDocument.clone(true, false);
            insert selDocToInsert;
            if(attachedKnowledgeList.isEmpty())
            {                
                Knowledge__kav kav = [SELECT MSD_CORE_Case_Type__c, MSD_CORE_Case_Category__c FROM Knowledge__kav WHERE KnowledgeArticleId = :selectedDocument.Document_ID_MVN__c LIMIT 1];
                
                if(kav.MSD_CORE_Case_Type__c != null){
                    Case caseObj = [Select RecordType.Name, First_Attached_Article__c FROM Case WHERE Id = :caseId];
                    String caseRT = caseObj.RecordType.Name;
                    if(caseRT.startsWith('Request') && caseObj.First_Attached_Article__c == null)
                    {
                        Case objCase = new Case();
                        objCase.Id = caseId;
                        objCase.Type = kav.MSD_CORE_Case_Type__c;
                        objCase.Category_MVN__c = kav.MSD_CORE_Case_Category__c;
                        objCase.First_Attached_Article__c = selDocToInsert.Id;                        
                        update objCase;
                    }
                }                
            }
        } catch (Exception e) {
            Database.rollback(sp);
            // Lightning // ApexPages.addMessages(e);
            System.debug('Error message --->'+e);
            throw new AuraHandledException('Error : '+ e.getMessage()); 
        }

        return null;
    }

    // Populates a new case document but does not insert it
    public static Case_Document_MVN__c createCaseDocument(Id caseID, SObject theKav) {
        // Make sure the KAV is of a valid type
        Case_Document_MVN__c cad = new Case_Document_MVN__c();
        cad = fillCaseDocument(cad,caseID,theKav);
        
        return cad;
    }

    private static Case_Document_MVN__c fillCaseDocument(Case_Document_MVN__c cad,Id caseID, SObject theKav) {

        // Standard fields
        cad.Case_MVN__c = caseID;
        cad.Document_ID_MVN__c = (Id) theKav.get('KnowledgeArticleId');
        cad.Knowledge_Article_Version_ID_MVN__c = (Id) theKav.Id;
        cad.MSD_CORE_Questions__c = (String) theKav.get('MSD_CORE_Questions__c');

        //cad.Document_Major_Version_MVN__c = String.valueOf((Integer) theKav.get('VersionNumber'));
        //cad.Document_Type_MVN__c = (String) theKav.get('ArticleType');
        cad.Document_Language_MVN__c = (String) theKav.get('Language');
        cad.Document_Number_MVN__c = (String) theKav.get('ArticleNumber');
        cad.Document_Title_MVN__c = (String) theKav.get('Title');
        cad.Document_Summary_MVN__c = (String) theKav.get('Summary');
        //cad.MSD_CORE_Document_Preview__c = (String) theKav.get('MSD_CORE_Disclaimer__c');
        //cad.MSD_CORE_Document_Preview__c = (String) theKav.get('Preview_MVN__c');
        System.debug('Title -->'+(String) theKav.get('Title')+'preview -->'+(String) theKav.get('MSD_CORE_Preview__c'));
        cad.MSD_CORE_Document_Preview__c = (String) theKav.get('MSD_CORE_Preview__c');
        cad.Document_Subtype_MVN__c = (String) theKav.get('MSD_CORE_Subtype__c');
        cad.MSD_CORE_Category__c = (String) theKav.get('MSD_CORE_GenCatgry__c');
        // Handle custom fields
        for(Case_Document_Fields_MVN__c caf : documentFields.values()) {
            try {
                if(cad.Document_Type_MVN__c == caf.Document_Type_MVN__c) {
                    cad.put(caf.Case_Document_Field_MVN__c,theKav.get(caf.Document_Field_MVN__c));
                }
            } catch (Exception e) {
                // Don't need to do anything, a bad custom field will not prevent the copy
            }
        }
        return cad;
    }
}