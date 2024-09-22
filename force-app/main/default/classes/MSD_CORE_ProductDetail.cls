/**
    * @description MSD_CORE_ProductDetail
    * Created By:          Focal CXM
*/
public without sharing class MSD_CORE_ProductDetail {
    /**
    * @description getCatalogsByOffset
    * @return catalogwrap
        * @param prodId, userId, pageSize, pageNumber
    */
    @AuraEnabled(cacheable=true)
    public static catalogwrap getCatalogsByOffset(String prodId, String userId,String pageSize,String pageNumber){
        
        Integer ps = Integer.valueOf(pageSize);
        Integer pn = Integer.valueOf(pageNumber) - 1;
        Integer offsetValue = ps * pn;

        try {
            Id loggedinuserid = [SELECT Id, ContactId FROM User WHERE Id = :userId].ContactId;
            
            Contact con;
            if(loggedinuserid!=null) {
                con = [SELECT Id, Name, MSD_CORE_Health_Care_Decision_Maker__c  FROM Contact WHERE Id = :loggedinuserid AND MSD_CORE_Health_Care_Decision_Maker__c = TRUE ]; 
            }
            catalogwrap wrap = new catalogwrap();
            if(con != null){
                MSD_CORE_Eligibility__c eligibility = [SELECT Id ,Name,MSD_CORE_Organization_Type__c FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Payor__c =: userId];
                List<MSD_CORE_Content_Permission_Mapping__c> mappings = new List<MSD_CORE_Content_Permission_Mapping__c>();
                mappings = [SELECT MSD_CORE_Content_Type__c FROM MSD_CORE_Content_Permission_Mapping__c WHERE MSD_CORE_Organization_Type__c =: eligibility.MSD_CORE_Organization_Type__c AND MSD_CORE_Active__c = TRUE];
                
                List<String> contenttypes = new List<String>();
                For(MSD_CORE_Content_Permission_Mapping__c mapping : mappings){
                	Contenttypes.add(mapping.MSD_CORE_Content_Type__c);
                }

                List<MSD_CORE_Catalog__c> allCatalogs = [SELECT Id,MSD_CORE_Filter__c, Name, MSD_CORE_Resource_Title__c, MSD_CORE_Description__c, MSD_CORE_Show_Read_More__c, MSD_CORE_Product_Payor__c, MSD_CORE_Row_Order__c, MSD_CORE_Delivery_Framework__c,MSD_CORE_Document_Rendition__c, MSD_CORE_Post_Presentation__c, 
                                                        MSD_CORE_Expiration_Date__c, MSD_CORE_Read__c, MSD_CORE_Leave_Behind__c, MSD_CORE_Content_Type__c,Parent_Resource__c, 
                                                        (SELECT Id FROM Libraries__r WHERE MSD_CORE_Payor__c =: userId ) FROM MSD_CORE_Catalog__c WHERE MSD_CORE_Content_Type__c in: contenttypes AND
                                                        MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Product_Payor__c =: prodId  AND MSD_CORE_Resource_Status__c = 'Published' AND MSD_CORE_Document_Status__c != 'Expired' AND MSD_CORE_Expiration_Date__c >= TODAY AND
                                                        (MSD_CORE_Post_Presentation__c = false OR (MSD_CORE_Post_Presentation__c = true AND MSD_CORE_Payor__c =: userId)) ]; 
                
                /** Find if any static leave behind post presenttion resource exists for payor. If exist remove original resource from the list */
                // Added Condition for View Upon Request
                Set<Id> parentResourceId = new Set<Id>();
                for(MSD_CORE_Catalog__c catalog : allCatalogs){
                    if((catalog.Parent_Resource__c != null && catalog.MSD_CORE_Leave_Behind__c == 'Static Leave Behind') || (catalog.Parent_Resource__c != null && catalog.MSD_CORE_Delivery_Framework__c == 'View Immediately' && catalog.MSD_CORE_Leave_Behind__c == NULL)){
                        parentResourceId.add(catalog.Parent_Resource__c);
                    }
                }

                List<MSD_CORE_Catalog__c> catalogslst = [SELECT Id, MSD_CORE_Filter__c, Name, MSD_CORE_Resource_Title__c, MSD_CORE_Content_Type__c, MSD_CORE_Description__c, MSD_CORE_Show_Read_More__c, MSD_CORE_Product_Payor__c, MSD_CORE_Row_Order__c, MSD_CORE_Delivery_Framework__c,MSD_CORE_Document_Rendition__c, MSD_CORE_Post_Presentation__c, MSD_CORE_Expiration_Date__c, MSD_CORE_Read__c, MSD_CORE_Leave_Behind__c, 
                                                        (SELECT Id FROM Libraries__r WHERE MSD_CORE_Payor__c =: userId) FROM MSD_CORE_Catalog__c WHERE MSD_CORE_Content_Type__c in: contenttypes AND
                                                        MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Content_Type__c != 'Coming Soon' AND MSD_CORE_Product_Payor__c =: prodId AND MSD_CORE_Resource_Status__c = 'Published' AND MSD_CORE_Document_Status__c != 'Expired' AND MSD_CORE_Expiration_Date__c >= TODAY AND
                                                        (MSD_CORE_Post_Presentation__c = false OR (MSD_CORE_Post_Presentation__c = true AND MSD_CORE_Payor__c =: userId)) AND
                                                        Id NOT IN : parentResourceId  
                                                        ORDER BY MSD_CORE_Row_Order__c ASC LIMIT : ps OFFSET : offsetValue];
                if(!catalogslst.isEmpty()){
                      wrap.cataloglst = catalogslst;
                }else {
                    List<MSD_CORE_Catalog__c> cmscatalogslst = [SELECT Id, MSD_CORE_Filter__c, Name, MSD_CORE_Resource_Title__c, MSD_CORE_Content_Type__c, MSD_CORE_Description__c, MSD_CORE_Show_Read_More__c, MSD_CORE_Product_Payor__c, MSD_CORE_Row_Order__c, MSD_CORE_Delivery_Framework__c,MSD_CORE_Document_Rendition__c, MSD_CORE_Post_Presentation__c, MSD_CORE_Expiration_Date__c, MSD_CORE_Read__c, MSD_CORE_Leave_Behind__c, 
                                                        (SELECT Id FROM Libraries__r WHERE MSD_CORE_Payor__c =: userId) FROM MSD_CORE_Catalog__c WHERE MSD_CORE_Content_Type__c in: contenttypes AND
                                                        MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Content_Type__c = 'Coming Soon' AND MSD_CORE_Product_Payor__c =: prodId AND MSD_CORE_Resource_Status__c = 'Published' AND MSD_CORE_Document_Status__c != 'Expired' AND MSD_CORE_Expiration_Date__c >= TODAY AND
                                                        (MSD_CORE_Post_Presentation__c = false OR (MSD_CORE_Post_Presentation__c = true AND MSD_CORE_Payor__c =: userId)) AND
                                                        Id NOT IN : parentResourceId  
                                                        ORDER BY MSD_CORE_Row_Order__c ASC LIMIT : ps OFFSET : offsetValue];
                      wrap.cataloglst = cmscatalogslst;
                }

                
                wrap.catalogcount = [SELECT Id, (SELECT Id FROM Libraries__r WHERE MSD_CORE_Payor__c =: userId) FROM  MSD_CORE_Catalog__c WHERE MSD_CORE_Content_Type__c in: contenttypes AND
                                     MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Content_Type__c != 'Coming Soon' AND MSD_CORE_Product_Payor__c =: prodId  AND MSD_CORE_Resource_Status__c = 'Published' AND MSD_CORE_Document_Status__c != 'Expired' AND MSD_CORE_Expiration_Date__c >= TODAY AND
                                     (MSD_CORE_Post_Presentation__c = false OR (MSD_CORE_Post_Presentation__c = true AND MSD_CORE_Payor__c =: userId)) AND Id NOT IN : parentResourceId].size();

                return wrap;  
            } else {
                return null;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,e.getLineNumber());  /*RT*/
            System.debug(LoggingLevel.WARN,e.getMessage());     /*RT*/
            return null;
        }
    }
    /**
        * @description getproduct
        * @return MSD_CORE_Product_Payor__c
        * @param prodId
    */  
    @AuraEnabled(cacheable=true)
    public static MSD_CORE_Product_Payor__c getproduct(String prodId){
        try {
            
            MSD_CORE_Product_Payor__c prod = [SELECT Id, Name, MSD_CORE_Instructions_For_Use_Label__c, MSD_CORE_Instructions_For_Use_Link__c, MSD_CORE_Product_Labeling__c, MSD_CORE_Generic_Name__c, MSD_CORE_Dosage_Form_and_Strength__c, MSD_CORE_Information_About_Product__c, MSD_CORE_HCP_site__c, MSD_CORE_Patient_information__c,MSD_CORE_Prescribing_Information__c, MSD_CORE_Medication_Guide__c, MSD_CORE_Job_code__c, MSD_CORE_Show_Popup__c FROM MSD_CORE_Product_Payor__c WHERE Id =: prodId AND Related_System__c  = 'MFR' ]; //Modified by Sabari - : [E2ESE-1770] Patient Information button
            return prod;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,e);
            return null;
        }
    }
    /**
        * @description getproductFilter
        * @return filter
        * @param prodId
    */  
    @AuraEnabled(cacheable=true)
    public static List<MSD_CORE_Filter__c> getproductFilter(String prodId ){
        
        try {
            List<MSD_CORE_Filter__c> filter = [SELECT Id, Name, MSD_CORE_description__c, MSD_CORE_Content_Details__c, MSD_CORE_Filter_Order__c FROM MSD_CORE_Filter__c WHERE MSD_CORE_Product_Payor__c=:prodId ORDER BY MSD_CORE_Filter_Order__c ASC];
            return filter;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,e.getLineNumber());
            System.debug(LoggingLevel.WARN,e.getMessage());
            return null;
        }
    }
    /**
        * @description getCatalogsFilter
        * @return catalogslst
        * @param prodId, userId, criteria
    */  
    @AuraEnabled
    public static List<MSD_CORE_Catalog__c> getCatalogsFilter(String prodId, String userId, List<String> criteria ){
        try {
            MSD_CORE_Eligibility__c eligibility = [SELECT Id ,Name,MSD_CORE_Organization_Type__c FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Payor__c =: userId];
            List<MSD_CORE_Content_Permission_Mapping__c> mappings = [SELECT MSD_CORE_Content_Type__c FROM MSD_CORE_Content_Permission_Mapping__c WHERE MSD_CORE_Organization_Type__c  =: eligibility.MSD_CORE_Organization_Type__c AND MSD_CORE_Active__c = TRUE];
            
            List<String> contenttypes = new List<String>();
            For(MSD_CORE_Content_Permission_Mapping__c mapping : mappings){
                contenttypes.add(mapping.MSD_CORE_Content_Type__c);
            }

            Id loggedinuserid = [SELECT Id,ContactId FROM User WHERE Id = :userId].ContactId;
            Contact con;
            if( loggedinuserid!=null ){
                con = [SELECT Id, Name, MSD_CORE_Health_Care_Decision_Maker__c FROM Contact WHERE Id = :loggedinuserid ];
            }

            if(con!=null){
                List<Id> catalogIds = new List<Id>();
                for( MSD_CORE_Catalog__c objCatalog: [SELECT Id, MSD_CORE_Filter__c FROM MSD_CORE_Catalog__c WHERE MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Product_Payor__c =: prodId  ] ){
                    if(!criteria.isEmpty() && criteria != null){
                        for(String cval: criteria ){
                            if((objCatalog.MSD_CORE_Filter__c!=null)){
                                String[] filters = objCatalog.MSD_CORE_Filter__c.split(';');
                                if(filters.contains( cval)){
                                    catalogIds.add(objCatalog.Id);
                                }
                            }
                        }
                    }else{
                        catalogIds.add(objCatalog.Id);
                    }
                }
                // List<MSD_CORE_Catalog__c> catalogslst = [SELECT Id,MSD_CORE_Filter__c, Name, MSD_CORE_Description__c, MSD_CORE_Product_Payor__c, MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c, MSD_CORE_Product_Payor__r.MSD_CORE_Prescribing_Information__c, MSD_CORE_Product_Payor__r.Name, MSD_CORE_Product_Payor__r.MSD_CORE_Information_About_Product__c,MSD_CORE_Product_Payor__r.MSD_CORE_HCP_site__c,MSD_CORE_Row_Order__c, MSD_CORE_Product_Payor__r.MSD_CORE_Medication_Guide__c, MSD_CORE_Delivery_Framework__c, 
                //                                         (SELECT Id FROM Libraries__r WHERE MSD_CORE_Payor__c =: userId ) 
                //                                         FROM  MSD_CORE_Catalog__c WHERE MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Product_Payor__c =: prodId AND Id IN : catalogIds 
                //                                         ORDER BY MSD_CORE_Row_Order__c ASC];
                List<MSD_CORE_Catalog__c> catalogslst = [SELECT Id,MSD_CORE_Filter__c, Name, MSD_CORE_Resource_Title__c, MSD_CORE_Description__c, MSD_CORE_Show_Read_More__c, MSD_CORE_Product_Payor__c, MSD_CORE_Row_Order__c, MSD_CORE_Delivery_Framework__c,MSD_CORE_Document_Rendition__c, MSD_CORE_Post_Presentation__c, 
                                                         MSD_CORE_Expiration_Date__c, MSD_CORE_Read__c, MSD_CORE_Leave_Behind__c, MSD_CORE_Content_Type__c,Parent_Resource__c, 
                                                         (SELECT Id FROM Libraries__r WHERE MSD_CORE_Payor__c =: userId ) 
                                                         FROM MSD_CORE_Catalog__c WHERE MSD_CORE_Content_Type__c IN : contenttypes AND Id IN : catalogIds AND 
                                                         MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Product_Payor__c =: prodId  AND MSD_CORE_Resource_Status__c = 'Published' AND MSD_CORE_Document_Status__c != 'Expired' AND MSD_CORE_Expiration_Date__c >= TODAY AND
                                                         (MSD_CORE_Post_Presentation__c = false OR (MSD_CORE_Post_Presentation__c = true AND MSD_CORE_Payor__c =: userId)) ]; 
                
                System.debug(LoggingLevel.WARN,catalogslst);
                return catalogslst;  
            }
            else{
                return null;
            }
            
        } catch (Exception e) {
            return null;
        }
    }
    /**
        * @description getcontentconnector
        * @return strval
        * @param docurl
    */  
    @AuraEnabled
    public static string getcontentconnector(String docurl){
        try {
            String strval = MSD_CORE_MFR_AWSController.generateSingedURL(docurl);
            return strval;
        } catch (Exception e) {
            return e.getMessage();
        }
    }
    /**
        * @description updateReadCheck
        * @return catalogid
        * @param returnval
    */  
    @AuraEnabled
    public static string updateReadCheck(String catalogid){
        String returnval = '';
        try {
            MSD_CORE_Catalog__c catalog = [SELECT Id, Name, MSD_CORE_Resource_Title__c, MSD_CORE_Read__c FROM MSD_CORE_Catalog__c WHERE Id =: catalogId];
            catalog.MSD_CORE_Read__c = true;
            update catalog;
            returnval = 'Success';
            return returnval;
        } catch (Exception e) {
            returnval = e.getMessage();
            return returnval;
        }
    }
    /**
        * @description removeCatalogs
        * @param recId, userId
    */  
    @AuraEnabled
    public static void removeCatalogs(String recId,String userId){

        List<MSD_CORE_Library__c> deleteLibratyLst = [Select Id, MSD_CORE_catalog__c, MSD_CORE_catalog__r.Name, MSD_CORE_catalog__r.MSD_CORE_Resource_Title__c, MSD_CORE_Product_Payor__c, MSD_CORE_Product_Payor__r.Name From MSD_CORE_Library__c where MSD_CORE_catalog__c=: recId AND MSD_CORE_Payor__c=:userId];
        delete deleteLibratyLst;

        MSD_CORE_Notification__c mfrn = new MSD_CORE_Notification__c();
        mfrn.MSD_CORE_Read__c = false;
        Mfrn.MSD_CORE_Payor__c = userId;
        mfrn.MSD_CORE_Resource__c = recId;
        mfrn.MSD_CORE_Product_Payor__c = deleteLibratyLst[0].MSD_CORE_Product_Payor__c;
        mfrn.MSD_CORE_Activity__c = '<p style="font-size: 18px; color: #333333; font-family: Invention;font-weight: 700; line-height: 27px;font-style: normal;">You have removed <a  href='+ System.Label.MerckProductDetail+ deleteLibratyLst[0].MSD_CORE_Product_Payor__c+' target="_self" style="color: rgb(0, 133, 124);text-decoration: underline;text-decoration-color: rgb(0, 133, 124); font-size: 18px;font-weight: 700; line-height: 27px;font-style: normal;"><style="font-size: 18px;font-family: Invention; color: rgb(0, 133, 124); font-family: Invention;font-weight: 700; line-height: 27px;font-style: normal;">'+deleteLibratyLst[0].MSD_CORE_catalog__r.MSD_CORE_Resource_Title__c+'</a><style="font-size: 18px; color: #333333; font-family: Invention;font-weight: 700; line-height: 27px;font-style: normal;"> for your library.</p>';
        insert mfrn;
    }
    /**
        * @description catalogwrap
    */  
    public class catalogwrap {
        
        @AuraEnabled
        public List<MSD_CORE_Catalog__c> cataloglst{get;set;}
        @AuraEnabled
        public Integer catalogcount{get;set;}
    }
}