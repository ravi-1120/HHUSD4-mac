/**
 *  DocumentSearchFilterUtilityMVN
 *  Created By: Brian Aggen
 *  Created: July 1, 2014
 *  Description: This class is responsible for querying additional parameters specified in the Case_Document_Additional_Search_Fields field set
 *               (user defined search) and the Account_Type_Document_Filters_MVN__c custom setting (admin defined search).
 *				 The Account_Type_Document_Filters_MVN__c custom setting allows an admin to filter search results based on the Case account RT.
 *
 *               Use Case for Case_Document_Additional_Search_Fields field set: Give the user a way to dynamically search against other fields. Any
 *               fields added to the field set must also have a corresponding field mapping in the Case_Document_Fields_MVN__c custom setting.
 *
 *				 Use Case for Account_Type_Document_Filters_MVN__c custom setting: Patient account RTs should only return search documents where 
 *               "off label" is No
 **/
public with sharing class DocumentSearchFilterUtilityMVN {  

    public Map<String,Id> acctRTMap;
    public Map<String,Case_Document_Fields_MVN__c> caseDocumentFieldMap;
    public Map<String,Account_Type_Document_Filters_MVN__c> acctRTSearchFilters;

    public DocumentSearchFilterUtilityMVN() {
        acctRTMap            = new Map<String,Id>();
        caseDocumentFieldMap = new Map<String,Case_Document_Fields_MVN__c>();
        acctRTSearchFilters  = new Map<String,Account_Type_Document_Filters_MVN__c>();        
        
        // get all account RTs
        for(RecordType rt : [select Id, DeveloperName from RecordType where SobjectType = 'Account']) {
            acctRTMap.put(rt.DeveloperName,rt.Id);
        }

        // get all the case document fields and store in a map
        for(Case_Document_Fields_MVN__c cdf : Case_Document_Fields_MVN__c.getAll().values()) {
            caseDocumentFieldMap.put(cdf.Case_Document_Field_MVN__c,cdf);
        }

        // get the filter options
        for(Account_Type_Document_Filters_MVN__c filter : Account_Type_Document_Filters_MVN__c.getAll().values()) {
            acctRTSearchFilters.put(filter.Case_Document_Field_MVN__c,filter);
        }       
    }

    public List<DocumentSearchFilterWrapperMVN> getAdditionalDocumentSearchParams(Case_Document_MVN__c searchDocument, Id caseId) {  
        System.debug('searchDocument -->'+searchDocument);
        Id caseAcctRTId = [select Account.RecordTypeId from Case where Id = :caseId][0].Account.RecordTypeId;
        List<DocumentSearchFilterWrapperMVN> dsfwList = new List<DocumentSearchFilterWrapperMVN>();
        SObject searchDocSObject = searchDocument;        

        // additional user search fields are added to Case_Document_Additional_Search_Fields field set
        for(Schema.FieldSetMember f : SObjectType.Case_Document_MVN__c.FieldSets.Case_Document_Additional_Search_Fields.getFields()) {            
            // check the field type to see if it is a text type
            Boolean fieldTypeIsText  = (Schema.DisplayType.Picklist == f.getType() || Schema.DisplayType.String == f.getType() || 
                                        Schema.DisplayType.TextArea == f.getType() || Schema.DisplayType.Email  == f.getType() || 
                                        Schema.DisplayType.Phone    == f.getType() || Schema.DisplayType.ID     == f.getType()) ? true : false;   
            String fieldAPIName = f.getFieldPath();     
            String fieldValue;
            
            if(searchDocSObject.get(fieldAPIName) != null) {
                // add single quotes to text fields
                fieldValue = (fieldTypeIsText) ? '\''+(String)searchDocSObject.get(fieldAPIName)+'\'' : (String)searchDocSObject.get(fieldAPIName);
            } 

            // check to see if there is a corresponding Document_Field_MVN__c mapping and that the fieldValue is not null
            if(caseDocumentFieldMap.containsKey(fieldAPIName) && fieldValue != null) {
                DocumentSearchFilterWrapperMVN dsfw = new DocumentSearchFilterWrapperMVN();
                dsfw.caseDocumentField              = fieldAPIName;
                dsfw.documentSearchField            = caseDocumentFieldMap.get(fieldAPIName).Document_Field_MVN__c;
                dsfw.filterValue                    = fieldValue;                
                dsfw.isCustomFilter                 = false;

                dsfwList.add(dsfw); 
            }            
        }

        // the Account_Type_Document_Filters_MVN__c custom setting allows an admin to filter search results based on the Case account RT.
        for(Account_Type_Document_Filters_MVN__c filter : acctRTSearchFilters.values()) {          
            // check against the Case account RT to determine if the search filter is applicable
            if(acctRTMap.containsKey(filter.Account_Record_Type_MVN__c) && acctRTMap.get(filter.Account_Record_Type_MVN__c) == caseAcctRTId) {              
                // check to see if there is a corresponding Document_Field_MVN__c mapping
                if(caseDocumentFieldMap.containsKey(filter.Case_Document_Field_MVN__c)) {
                    DocumentSearchFilterWrapperMVN dsfw = new DocumentSearchFilterWrapperMVN();
                    dsfw.caseDocumentField              = filter.Case_Document_Field_MVN__c;
                    dsfw.documentSearchField            = caseDocumentFieldMap.get(filter.Case_Document_Field_MVN__c).Document_Field_MVN__c;
                    dsfw.filterValue                    = filter.Search_Filter_Value_MVN__c;
                    dsfw.customFilterLogic              = filter.Custom_Filter_Logic_MVN__c;
                    dsfw.acctRecordTypeDeveloperName    = filter.Account_Record_Type_MVN__c;
                    dsfw.documentType                   = caseDocumentFieldMap.get(filter.Case_Document_Field_MVN__c).Document_Type_MVN__c;
                    dsfw.isCustomFilter                 = (filter.Custom_Filter_Logic_MVN__c != null) ? true : false;

                    dsfwList.add(dsfw);                    
                }
            }
        }
        return dsfwList;
    }

    public Set<String> fieldsFilteredByCaseAcctRT(Id caseId) {
        Set<String> fieldsFilteredByCaseAcctRT = new Set<String>();
        Id caseAcctRTId = [select Account.RecordTypeId from Case where Id = :caseId][0].Account.RecordTypeId;        

        for(Account_Type_Document_Filters_MVN__c filter : acctRTSearchFilters.values()) {
            if(acctRTMap.containsKey(filter.Account_Record_Type_MVN__c) && acctRTMap.get(filter.Account_Record_Type_MVN__c) == caseAcctRTId) {
                fieldsFilteredByCaseAcctRT.add(filter.Case_Document_Field_MVN__c);
            }
        }
        return fieldsFilteredByCaseAcctRT;
    }

    // document search wrapper class
    public class DocumentSearchFilterWrapperMVN {
        public String caseDocumentField;                // Case_Document_MVN__c api field name
        public String documentSearchField;              // Knowledge/Vault api field name mapped to the Case_Document_MVN__c api field name in Case_Document_Fields_MVN__c custom settings
        public String filterValue;                      // Filter value in the document search
        public String customFilterLogic;                // Custom filter used for more sophisticated search logic
        public String acctRecordTypeDeveloperName;      // DeveloperName of the Case Account Record Type
        public String documentType;                     // API name of the document type that has this field. Required for Knowledge and is the Knowledge Article Type that ends in __kav. Not required when using Vault
        public boolean isCustomFilter; 		            // Boolean that is true when custome filter logic is used

        public DocumentSearchFilterWrapperMVN() {}

    }
}