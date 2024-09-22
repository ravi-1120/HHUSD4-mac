/*
 * VaultSearchUtilityMVN
 * Created by:      Samuel Rosen
 * Created on:      10/7/2013
 * Description:     This class implements Vault Search and assembly
 *
 * *** NOTE: Currently not used for the Merck implementation. ***
 */
public with sharing class VaultSearchUtilityMVN implements DocumentSearchUtilityMVN.searchInterface {
    private static Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
    private static String additionalSearchFields;

    static {
        Set<String> additionalFields = new Set<String>();
        for(Case_Document_Fields_MVN__c cdf : Case_Document_Fields_MVN__c.getAll().values()) {
            additionalFields.add(cdf.Document_Field_MVN__c);
        }

        additionalSearchFields = '';
        for(String field : additionalFields) {
            additionalSearchFields += ',' + field;
        }
    }

    //interface methods
    public static String buildDownloadURL(Case_Document_MVN__c cad){
        String urlString = settings.Vault_Base_URL_MVN__c;
        urlString += '/api/' + settings.Vault_API_Version_MVN__c + '/objects/documents/';
        urlString += cad.Document_ID_MVN__c + '/versions/';
        urlString += cad.Document_Major_Version_MVN__c + '/' + cad.Document_Minor_Version_MVN__c;
        urlString += '/file';
        urlString += userSessionInformation(false);
        urlString += '&lockDocument=false';

        return urlString;
    }

    public static String buildLinkURL(Case_Document_MVN__c cad){
        String urlString = settings.Vault_Base_URL_MVN__c + '/ui/#doc_info/';
        urlString += cad.Document_ID_MVN__c + '/';
        urlString += cad.Document_Major_Version_MVN__c + '/' + cad.Document_Minor_Version_MVN__c;
        urlString += userSessionInformation(false);

        return urlString;
    }

    public static String buildViewerURL(Case_Document_MVN__c cad){
        String urlString = '';

        if(!settings.Vault_Viewer_Doc_Type_Exclusion_List_MVN__c.contains(cad.Document_Type_MVN__c))
        {
            urlString = settings.Vault_Base_URL_MVN__c + '/ui/doc_viewer/';
            urlString += cad.Document_ID_MVN__c + '/';
            urlString += cad.Document_Major_Version_MVN__c + '/' + cad.Document_Minor_Version_MVN__c;
            urlString += userSessionInformation(true);
        }

        return urlString;
    }

    public static String userSessionInformation(Boolean isViewer) {
        String authTokenParam = 'auth';
        if(isViewer) {
            authTokenParam = 'ext_tkn';
        }

        String session = '?' + authTokenParam + '=' + UserInfo.getSessionId();
        session += '&ext_url=' + System.Url.getSalesforceBaseUrl().toExternalForm();
        session += '&ext_ns=' + settings.Vault_Delegated_Auth_Source_MVN__c;
        return session;
    }

    public PageReference selectDocument(Case_Document_MVN__c selectedDocument, Id caseId){
        List<Case_Document_MVN__c> newDocuments = getRelatedArticles(selectedDocument);
        List<Case_Document_MVN__c> attachedDocumentList = [SELECT Id,Document_ID_MVN__c
                                                            FROM Case_Document_MVN__c where Case_MVN__c = :caseId];

        for (Case_Document_MVN__c kaa : attachedDocumentList) {
            if (kaa.Document_ID_MVN__c == selectedDocument.Document_ID_MVN__c) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.Document_Search_Article_Already_Attached));
                return null;
            }
            for(Integer i=0;i<newDocuments.size();i++) {
                Case_Document_MVN__c eachDoc = newDocuments[i];
                if (kaa.Document_ID_MVN__c == eachDoc.Document_ID_MVN__c) {
                    newDocuments.remove(i);
                    i--;
                }
            }
        }

        SavePoint sp = Database.setSavePoint();
        newDocuments.add(selectedDocument.clone(true, false));

        try {
            insert newDocuments;
        } catch (Exception e) {
            Database.rollback(sp);
            ApexPages.addMessages(e);
        }
        return null;
    }

    @TestVisible private List<Case_Document_MVN__c> getRelatedArticles(Case_Document_MVN__c cad) {
        List<String> relationships = UtilitiesMVN.splitCommaSeparatedString(settings.Vault_Relationship_Includes_MVN__c);
        if(!relationships.isEmpty()) {
            String rQuery = 'select target_doc_id__v from relationships where source_doc_id__v =\'' + cad.Document_ID_MVN__c +'\' and (';

            Boolean hasPrevious = false;
            for(String rs : relationships) {
                if(hasPrevious) {
                    rQuery += ' OR ';
                }
                rQuery += 'relationship_type__v=\'' + rs + '\'';
                hasPrevious = true;
            }

            rQuery += ')';
            rQuery = EncodingUtil.urlEncode(rQuery, 'UTF-8');

            String endpoint = settings.Vault_Base_URL_MVN__c + '/api/' + settings.Vault_API_Version_MVN__c + '/query';
            String query = 'q=' + rQuery;
            List<Map<String, Object>> documentResults = vaultQuery(endpoint,query);
            if(documentResults != null && documentResults.size() > 0) {
                DocumentSearchUtilityMVN relatedQuery = new DocumentSearchUtilityMVN();

                for(Map<String, Object> eachDoc : documentResults) {
                    if(eachDoc.get('target_doc_id__v') != null
                        && cad.Document_ID_MVN__c != returnAsString(eachDoc.get('target_doc_id__v'))) {
                        relatedQuery.documentIds.add(returnAsString(eachDoc.get('target_doc_id__v')));
                    }
                }

                if(relatedQuery.documentIds.size() > 0) {
                    return search(relatedQuery,cad.Case_MVN__c);
                }
            }
        }

        return new List<Case_Document_MVN__c>();
    }

    public String returnAsString(Object valAsObj){
        String value = '';
        if ( valAsObj == null ) {
            value = '';
        } else if ( valAsObj instanceOf List<Object> ) {
            List<String> strList = new List<String>();

            for (Object eachVal : (List<Object>)valAsObj) {
                strList.add((String)eachVal);
            }
            value  = String.join( strList, ',');
        } else if ( valAsObj instanceOf Integer ) {
            value = String.valueOf((Integer) valAsObj);
        } else if (valAsObj instanceOf Boolean) {
            if((Boolean) valAsObj) {
                value = 'true';
            } else {
                value = 'false';
            }
        } else {
            value = (String) valAsObj;
        }

        return value;
    }

    private String buildQueryString(DocumentSearchUtilityMVN searchUtility)
    {
        String documentType = searchUtility.searchDocument.Document_Type_MVN__c;
        String documentSearchText = searchUtility.documentSearchText;
        String productId = searchUtility.productId;
        String language = searchUtility.searchDocument.Document_Language_MVN__c;

        List<Vault_Value_Mapping_MVN__c> maps = Vault_Value_Mapping_MVN__c.getAll().values();

        String queryString = 'Select LATESTVERSION id, name__v, title__v, type__v, major_version_number__v, minor_version_number__v, status__v, size__v, format__v, subtype__v, classification__v, language__v, (select abbreviation__vs from document_country__vr), (select external_id__v from document_product__vr), country__v, product__v, document_number__v ';
        queryString += additionalSearchFields;
        queryString += ' FROM ALLVERSIONS documents ';

        if(String.isNotBlank(documentSearchText))
        {
            queryString = queryString + 'Find (\'' + documentSearchText + '\' scope all) ';
        }

        queryString = queryString + ' WHERE status__v = STEADYSTATE() ';

        if(documentType != null && !documentType.equals('All'))
        {
            queryString = queryString + 'AND type__v=\'' + documentType +'\' ';
        }

        if(String.isNotBlank(language)) {
            String mappedLanguage = '';
            for(Vault_Value_Mapping_MVN__c mapping: maps)
            {
                if(mapping.SFDC_Value_MVN__c.equals(language))
                {
                    mappedLanguage = mapping.Vault_Value_MVN__c;
                    break;
                }
            }
            queryString = queryString + 'AND language__v = \'' + mappedLanguage +'\' ';
        }

        if(String.isNotBlank(productId) && !productId.equals('All')) {
            queryString = queryString + 'AND product__v in (select id from document_product__vr where external_id__v = \'' + productId +'\') ';
        }

        if(String.isNotBlank(searchUtility.searchDocument.Country_MVN__c) && searchUtility.searchDocument.Country_MVN__c != 'All'){
            queryString = queryString + ' AND country__v in (select id from document_country__vr where abbreviation__vs = \'' + searchUtility.searchDocument.Country_MVN__c +'\') ';
        }

        //Include additional query parameters specified in the custom setting Account_Type_Document_Filters_MVN__c
        List<DocumentSearchFilterUtilityMVN.DocumentSearchFilterWrapperMVN> additionalQueryParams = searchUtility.additionalSearchParams;

        if(additionalQueryParams != null) {
            for(Integer i=0; i < additionalQueryParams.size(); i++) {
                if(!additionalQueryParams[i].isCustomFilter) {
                    queryString = queryString + ' AND '+additionalQueryParams[i].documentSearchField+'='+additionalQueryParams[i].filterValue+' ';
                } else {
                    queryString = queryString + ' AND ('+additionalQueryParams[i].customFilterLogic+') ';
                }
            }
        }

        //If a set of Ids are provided, limit the documents to those ids:
        if(!searchUtility.documentIds.isEmpty()) {
            queryString = queryString + ' AND (';
            
            Boolean hasPrevious = false;
            for(String docId : searchUtility.documentIds) {
                if(hasPrevious) {
                    queryString = queryString + 'OR id=\'' + docId + '\' ';
                } else {
                    queryString = queryString + 'id=\'' + docId + '\' ';
                    hasPrevious = true;
                }
            }

            queryString = queryString + ') ';
        }


        // Finally add the query limit
        Decimal queryLimit = settings.Document_Search_Max_Results_MVN__c;
        if(queryLimit != null)
        {
            Integer queryLimitModifier = Math.round(queryLimit);
            queryString = queryString + 'LIMIT ' + queryLimitModifier;
        }

        System.debug('\n~ Query String: '+queryString+' ~\n');
        return queryString;
    }

    public List<Case_Document_MVN__c> search(DocumentSearchUtilityMVN searchUtility, ID caseID)
    {
        String queryString = buildQueryString(searchUtility);
        if(String.isBlank(queryString)) {
            return null;
        }

        String s = EncodingUtil.urlEncode(queryString,'UTF-8');
        String endpoint = settings.Vault_Base_URL_MVN__c + '/api/' + settings.Vault_API_Version_MVN__c + '/query';
        String query = 'q=' + s;
        List<Map<String, Object>> documentResults = vaultQuery(endpoint,query);
        if(documentResults != null) {
            return createCaseDocumentList(documentResults, caseID);
        }

        return null;
    }

    private List<Case_Document_MVN__c> createCaseDocumentList(List<Map<String, Object>> vaultDocList, Id caseID)
    {
        List<Case_Document_MVN__c> documentList = new List<Case_Document_MVN__c> ();
        List<Vault_Value_Mapping_MVN__c> maps = Vault_Value_Mapping_MVN__c.getAll().values();
        
        for(Map<String, Object> eachDoc : vaultDocList) {
            Case_Document_MVN__c cad = new Case_Document_MVN__c();  
            cad.Document_ID_MVN__c = returnAsString(eachDoc.get('id'));
            cad.Document_Title_MVN__c = returnAsString(eachDoc.get('name__v'));
            cad.Document_Type_MVN__c = returnAsString(eachDoc.get('type__v'));
            cad.Document_Major_Version_MVN__c = returnAsString(eachDoc.get('major_version_number__v'));
            cad.Document_Minor_Version_MVN__c = returnAsString(eachDoc.get('minor_version_number__v'));
            cad.Document_File_Extension_MVN__c = returnAsString(eachDoc.get('format__v'));
            cad.Document_Subtype_MVN__c = returnAsString(eachDoc.get('subtype__v'));

            String language = returnAsString(eachDoc.get('language__v'));
            if(!String.isBlank(language)){
                for(Vault_Value_Mapping_MVN__c mapping: maps){
                    if(mapping.Vault_Value_MVN__c == language){
                        cad.Document_Language_MVN__c = mapping.SFDC_Value_MVN__c;
                        break;
                    }
                }
            }

            Map<String, Object> vaultCountryMap = (Map<String, Object>) eachDoc.get('document_country__vr');
            List<Object> countryList = (List<Object>) vaultCountryMap.get('data');
            List<Map<String, Object>> countryListOfMaps = new List<Map<String, Object>>();

            for(Object obj:countryList){
                countryListOfMaps.add((Map<String, Object>) obj);
            }

            String countryString = null;
            for(Map<String, Object> country:countryListOfMaps){
                if(String.isBlank(countryString)) {
                    countryString = returnAsString(country.get('abbreviation__vs'));
                } else {
                    countryString += ';' + returnAsString(country.get('abbreviation__vs'));
                }
            }

            cad.Country_MVN__c = countryString;

            Map<String, Object> vaultProductMap = (Map<String, Object>) eachDoc.get('document_product__vr');
            List<Object> productList = (List<Object>) vaultProductMap.get('data');
            List<Map<String, Object>> productListOfMaps = new List<Map<String, Object>>();

            for(Object obj:productList){
                productListOfMaps.add((Map<String, Object>) obj);
            }

            String productString = null;
            for(Map<String, Object> product:productListOfMaps){
                if(String.isBlank(productString)) {
                    productString = returnAsString(product.get('external_id__v'));
                } else {
                    productString += ';' + returnAsString(product.get('external_id__v'));
                }
            }
            cad.Product_ID_MVN__c = productString;

            for(Case_Document_Fields_MVN__c cdf : Case_Document_Fields_MVN__c.getAll().values()) {
                try{
                    String vaultValue = eachDoc.get(cdf.Document_Field_MVN__c) != null ? returnAsString(eachDoc.get(cdf.Document_Field_MVN__c)) : null;
                    if(String.isNotBlank(vaultValue)) {
                        cad.put(cdf.Case_Document_Field_MVN__c, vaultValue);
                    }
                } catch (Exception e) {
                    //don't need to do anything, a bad custom field will not prevent the copy
                }
            }

            cad.Case_MVN__c = caseID;
            documentList.add(cad);
        }

        if(documentList.size() >= settings.Document_Search_Max_Results_MVN__c)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, Label.Vault_to_many_records_being_returned));
        }

        return documentList;

    }

    private List<Map<String, Object>> vaultQuery (String endpoint,String body) {
        if(UserInfo.getSessionId() != null)
        {
            Http h = new Http();
            HttpRequest req = new HttpRequest();

            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Accept', 'application/json');
            req.setTimeout((Integer) settings.Vault_Timeout_MVN__c);
            req.setHeader('Authorization', UserInfo.getSessionId());
            req.setHeader('X-Auth-Host', System.Url.getSalesforceBaseUrl().toExternalForm());
            req.setHeader('X-Auth-Provider', settings.Vault_Delegated_Auth_Source_MVN__c);
            //req.setBody(body);
            req.setBody(body);

            System.debug('Request Body: '+body);

            try{
                HttpResponse res = h.send(req);
                System.debug('Body: '+res.getBody());
                try {
                    //Gets highest level map of field to value pairs. Depending on the field, the object might be a string or a list of maps
                    Map<String, Object> vaultResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    String responseStatus = (String) vaultResponse.get('responseStatus');
                    
                    if(responseStatus == 'SUCCESS')
                    {
                        List<Object> vaultResponseList = (List<Object>) vaultResponse.get('data');
                        List<Map<String, Object>> vaultResponseListOfMaps = new List<Map<String, Object>>();
                        for(Object obj:vaultResponseList){
                            vaultResponseListOfMaps.add((Map<String, Object>) obj);
                        }

                        return vaultResponseListOfMaps;
                    } else {
                        List<Object> allErrors = (List<Object>) vaultResponse.get('errors');
                       
                        Map<String,Object> errorStatus = (Map<String,Object>) allErrors[0];
                        String error  = (String) errorStatus.get('type');
                        if(error == 'INACTIVE_USER')
                        {
                            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Vault_Inactive_User_Error));
                            return null;

                        }else if(error == 'USER_LOCKED_OUT')
                        {
                            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,Label.User_Locked_Out_Vault_Error));
                            return null;

                        }else if(error == 'INVALID_SESSION_ID')
                        {
                            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,Label.Invalid_Session_Vault_Error));
                            return null;

                        }else if(error == 'INSUFFICIENT_ACCESS')
                        {
                            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,Label.Access_Privileges_Vault_Error));
                            return null;
                        }else{
                            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,Label.Other_Vault_Error));
                            return null;
                        }
                    }
                } catch (Exception e) {
                    System.debug('Deserialization Error: '+e.getMessage());

                    // If deserializing fails the json was not formated correctly
                    System.debug('Bad Json Response');
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Bad_Json_Vault_Error));
                    return null;
                }
            }catch(Exception e){
                System.debug(e);
                ApexPages.addMessages(e);
            }

        }

        return null;
    }
}