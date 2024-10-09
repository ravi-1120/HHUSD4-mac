public class ReportingDataModelHelper {
    public static void upsertShadowContentDocument(List<ContentDocument> lstOfContentDocs) {
        // This method gets the Content Documents inserted or Updated, retrieves the Content Version from them which is 
        // latest and based on that Shadow Content Document is created.
        System.debug('### 0 upsertShadowContentDocument Started '+lstOfContentDocs);
        List<MSD_CORE_HEQ_Shadow_Content_Document__c> lstOfRecToBeUpserted = new List<MSD_CORE_HEQ_Shadow_Content_Document__c>();
        Set<Id> setOfLatestVersionIds = new Set<Id>();
        Map<Id, ContentVersion> mapOfContentDocIDAndVersions = new Map<Id, ContentVersion>();
        
        for(ContentDocument rec : lstOfContentDocs) {
            setOfLatestVersionIds.add(rec.LatestPublishedVersionId);
        }
        System.debug('### 1 setOfLatestVersionIds '+setOfLatestVersionIds);
        try {
            
            List<ContentVersion> lstOfContentVersion = new List<ContentVersion>();
            lstOfContentVersion = [SELECT Id, MSD_CORE_HEQ_Resource_Type__c, MSD_CORE_Status__c, MSD_CORE_Topic__c, ContentDocumentId, 
                                   MSD_CORE_Therapeutic_Area__c , MSD_CORE_Intended_use__c, MSD_CORE_Fulfillment_Method__c, 
                                   MSD_CORE_Approved_Disseminate_ATD_Date__c, MSD_CORE_Language__c,MSD_CORE_Resource_Code__c, 
                                   MSD_CORE_Print_Spec_Code__c, MSD_CORE_Expiration_Date__c, MSD_CORE_Delivery_Platform__c, ContentDocument.Title,
                                   ContentDocument.LatestPublishedVersionId, MSD_CORE_HEQ_URL__c
                                   FROM ContentVersion where ID IN: setOfLatestVersionIds
                                  ];
            System.debug('### 2 lstOfContentVersion '+lstOfContentVersion);
            for(ContentVersion rec : lstOfContentVersion) {
                MSD_CORE_HEQ_Shadow_Content_Document__c recToBeUpserted = new MSD_CORE_HEQ_Shadow_Content_Document__c();
                recToBeUpserted.MSD_CORE_HEQ_Title__c = rec.ContentDocument.Title;
                recToBeUpserted.MSD_Core_HEQ_LatestPublishedVersionId__c = rec.ContentDocument.LatestPublishedVersionId;
                System.debug('### 3 lstOfContentVersion '+lstOfContentVersion);
                if(lstOfContentVersion.size() > 0) {
                    recToBeUpserted.MSD_Core_HEQ_Resource_Type__c = rec.MSD_CORE_HEQ_Resource_Type__c;
                    recToBeUpserted.MSD_Core_HEQ_Status__c = rec.MSD_CORE_Status__c;
                    if((rec.MSD_CORE_Topic__c)!= NULL) {
                        recToBeUpserted.MSD_CORE_HEQ_Topic__c = (rec.MSD_CORE_Topic__c).length()>255?(rec.MSD_CORE_Topic__c).substring(0,254):(rec.MSD_CORE_Topic__c);
                    }
                    recToBeUpserted.MSD_CORE_HEQ_Intended_Use__c = rec.MSD_CORE_Intended_use__c;
                    recToBeUpserted.MSD_CORE_HEQ_Fulfillment_Method__c = rec.MSD_CORE_Fulfillment_Method__c;
                    recToBeUpserted.MSD_CORE_HEQ_Language__c = rec.MSD_CORE_Language__c;
                    recToBeUpserted.MSD_CORE_HEQ_Print_Spec_Code__c = rec.MSD_CORE_Print_Spec_Code__c;
                    recToBeUpserted.MSD_CORE_HEQ_Delivery_Platform__c = rec.MSD_CORE_Delivery_Platform__c;
                    recToBeUpserted.Approved_Disseminate_ATD_Date__c = rec.MSD_CORE_Approved_Disseminate_ATD_Date__c;
                    if((rec.MSD_CORE_Therapeutic_Area__c)!= NULL) {
                        recToBeUpserted.MSD_CORE_HEQ_Therapeutic_Area__c = (rec.MSD_CORE_Therapeutic_Area__c).length()>255?(rec.MSD_CORE_Therapeutic_Area__c).substring(0,254):(rec.MSD_CORE_Therapeutic_Area__c);
                    }                    
                    recToBeUpserted.MSD_CORE_HEQ_CDL_Salesforce_Id__c = rec.ContentDocumentId; 
                    recToBeUpserted.MSD_CORE_HEQ_Resource_Code__c = rec.MSD_CORE_Resource_Code__c;
                    recToBeUpserted.Expiration_Date__c = rec.MSD_CORE_Expiration_Date__c;
                    recToBeUpserted.MSD_CORE_HEQ_URL__c = rec.MSD_CORE_HEQ_URL__c;
                }
                System.debug('### 4 recToBeUpserted '+recToBeUpserted);
                lstOfRecToBeUpserted.add(recToBeUpserted);
            }
            System.debug('### 5 lstOfRecToBeUpserted '+lstOfRecToBeUpserted.size());
            UPSERT lstOfRecToBeUpserted MSD_CORE_HEQ_Shadow_Content_Document__c.MSD_CORE_HEQ_CDL_Salesforce_Id__c;
        } catch (Exception e) {
            System.debug('Exception Occurred : ' +e.getMessage());
            System.debug('Exception Stack Trace : ' +e.getStackTraceString());                
        }        
    }
    
    public static void createShadowContentDocumentLink(List<ReportingDataModelHelper.ReportingDataModelWrapper> lstofContentDocLinks) {
        List<MSD_CORE_HEQ_Shadow_ContentDocumentLink__c> lstOfShadowContDocLink = new List<MSD_CORE_HEQ_Shadow_ContentDocumentLink__c>();
        Set<Id> setOfAccIds = new Set<Id>();
        Map<Id, Id> mapOfAccIdAndUserId = new Map<Id, Id>();
        Set<Id> setOfContentDocIds = new Set<Id>();
        Map<Id, MSD_CORE_HEQ_Shadow_Content_Document__c> mapOfContentDocIdAndShadowContentDoc = new Map<Id, MSD_CORE_HEQ_Shadow_Content_Document__c>();
        System.debug('### 0 createShadowContentDocumentLink Started '+lstofContentDocLinks);
        try {
            
            for(ReportingDataModelHelper.ReportingDataModelWrapper rec : lstofContentDocLinks) {
                setOfContentDocIds.add(rec.contentDocLink.ContentDocumentId);
            }
            System.debug('### 1 setOfContentDocIds '+setOfContentDocIds);
            for(MSD_CORE_HEQ_Shadow_Content_Document__c rec : [SELECT Id, MSD_CORE_HEQ_CDL_Salesforce_Id__c  FROM MSD_CORE_HEQ_Shadow_Content_Document__c WHERE MSD_CORE_HEQ_CDL_Salesforce_Id__c IN :setOfContentDocIds ]) {
                mapOfContentDocIdAndShadowContentDoc.put(rec.MSD_CORE_HEQ_CDL_Salesforce_Id__c, rec);
            }
            System.debug('### 2 mapOfContentDocIdAndShadowContentDoc '+mapOfContentDocIdAndShadowContentDoc);
            for(ReportingDataModelHelper.ReportingDataModelWrapper rec : lstofContentDocLinks) {
                if(String.valueOf(rec.contentDocLink.LinkedEntityId).startsWith('001')) {
                    MSD_CORE_HEQ_Shadow_ContentDocumentLink__c recToBeCreated = new MSD_CORE_HEQ_Shadow_ContentDocumentLink__c();
                    recToBeCreated.Account__c = rec.contentDocLink.LinkedEntityId;
                    recToBeCreated.MSD_CORE_HEQ_Collection__c = String.valueOf(rec.collectionId);
                    recToBeCreated.MSD_CORE_HEQ_Shadow_Content_Document__c = mapOfContentDocIdAndShadowContentDoc.get(rec.contentDocLink.ContentDocumentId).Id;
                    recToBeCreated.MSD_CORE_HEQ_SF_CDL_ID__c = rec.contentDocLink.Id+'-'+String.valueOf(rec.collectionId);
                    recToBeCreated.MSD_CORE_HEQ_Type__c = 'Resource Shared via Collection';
                    System.debug('### 3 recToBeCreated '+recToBeCreated);
                    setOfAccIds.add(rec.contentDocLink.LinkedEntityId);    
                    lstOfShadowContDocLink.add(recToBeCreated);
                }                
            }            
            System.debug('### 4 lstOfShadowContDocLink '+lstOfShadowContDocLink);
            System.debug('### 4.a lstOfShadowContDocLink size '+lstOfShadowContDocLink.size());
            
            for(User rec : [SELECT Id, AccountId FROM User where AccountId in:setOfAccIds ]) {
                mapOfAccIdAndUserId.put(rec.AccountId, rec.Id);
            }
            System.debug('### 5 mapOfAccIdAndUserId '+mapOfAccIdAndUserId);
            for(MSD_CORE_HEQ_Shadow_ContentDocumentLink__c rec : lstOfShadowContDocLink) {
                rec.MSD_CORE_HEQ_User__c = mapOfAccIdAndUserId.get(rec.Account__c);
            }
            System.debug('### 6 lstOfShadowContDocLink '+lstOfShadowContDocLink);
            if(lstOfShadowContDocLink.size()>0) {
                UPSERT lstOfShadowContDocLink MSD_CORE_HEQ_SF_CDL_ID__c;    
            }
            
            
        } catch( Exception e ) {
            System.debug('Exception Occurred : ' +e.getMessage());
            System.debug('Exception Stack Trace : ' +e.getStackTraceString());  
        }
        
    }
    
    public static void createUserActivity(String contentDocRecId, String userId, Boolean isDownloaded) {
        List<MSD_CORE_HEQ_User_Activity__c> lstOfUserActivity = new List<MSD_CORE_HEQ_User_Activity__c>();
        String personAccId = '';
        System.debug('### 0 createUserActivity Started '+contentDocRecId);
        System.debug('### 0 createUserActivity Started '+userId);
        System.debug('### 0 createUserActivity Started '+isDownloaded);
        try {
            List<User> lstOfUsers = [SELECT Id, AccountId FROM User WHERE Id=:userId];
            personAccId = lstOfUsers.size()>0?lstOfUsers[0].AccountId:'';
            List<MSD_CORE_HEQ_Shadow_ContentDocumentLink__c> lstOfShadowContentDocLink = new List<MSD_CORE_HEQ_Shadow_ContentDocumentLink__c>();
            lstOfShadowContentDocLink = [SELECT Id, MSD_CORE_HEQ_User_Activity__c, MSD_CORE_HEQ_Number_Of_Times_Downloaded__c
                                         , MSD_CORE_HEQ_Last_Download_Date__c, MSD_CORE_HEQ_Last_Accessed_Date__c
                                         FROM MSD_CORE_HEQ_Shadow_ContentDocumentLink__c
                                         WHERE Account__c =:personAccId AND MSD_CORE_HEQ_Shadow_Content_Document__r.MSD_CORE_HEQ_CDL_Salesforce_Id__c = :contentDocRecId];
            System.debug('### 2 lstOfShadowContentDocLink '+lstOfShadowContentDocLink);
            if(lstOfUsers.size()>0 && lstOfShadowContentDocLink.size()>0) {
                for(MSD_CORE_HEQ_Shadow_ContentDocumentLink__c rec : lstOfShadowContentDocLink) {
                    if(isDownloaded) {
                        rec.MSD_CORE_HEQ_Last_Download_Date__c = DateTime.Now();
                        rec.MSD_CORE_HEQ_Number_Of_Times_Downloaded__c = rec.MSD_CORE_HEQ_Number_Of_Times_Downloaded__c+1;
                    }
                    rec.MSD_CORE_HEQ_Last_Accessed_Date__c = DateTime.Now();
                }
                System.debug('### 3 lstOfShadowContentDocLink '+lstOfShadowContentDocLink);
                UPDATE lstOfShadowContentDocLink;    
            }            
                       
        } catch( Exception e ) {
            System.debug('Exception Occurred : ' +e.getMessage());
            System.debug('Exception Stack Trace : ' +e.getStackTraceString());  
        }
        
    }
    
    public static void createUnSavedSearchCriteria(String searchCriteria, Integer recReturned, Id personAccId) {
        try {
            System.debug('### 0 createUnSavedSearchCriteria Started '+searchCriteria);
            System.debug('### 0 createUnSavedSearchCriteria Started '+recReturned);
            System.debug('### 0 createUnSavedSearchCriteria Started '+personAccId);
            List<User> lstOfRelatedUsers = new List<User>();
            lstOfRelatedUsers = [SELECT Id FROM User WHERE AccountId =:personAccId ];
            MSD_CORE_HEQ_Un_Saved_Search_Criteria__c rec = new MSD_CORE_HEQ_Un_Saved_Search_Criteria__c();
            rec.MSD_CORE_HEQ_Account__c = personAccId;
            if(lstOfRelatedUsers.size()>0) {
                rec.MSD_CORE_HEQ_User__c = lstOfRelatedUsers[0].Id;    
            }
            rec.MSD_CORE_HEQ_Records_Returned__c = recReturned;
            rec.MSD_CORE_HEQ_Search_Criteria__c = searchCriteria;
            INSERT rec;   
            System.debug('### 1 rec '+rec);
        } catch( Exception e ) {
            System.debug('Exception Occurred : ' +e.getMessage());
            System.debug('Exception Stack Trace : ' +e.getStackTraceString());  
        }
        
    }
    
    public static void deleteShadowCDL(Id collectionId, Id userId) {
        try {
            System.debug('### 0 deleteShadowCDL Started '+collectionId);
            System.debug('### 0 deleteShadowCDL Started '+userId);
            
            List<User> lstOfUsers = new List<User>();
            lstOfUsers = [SELECT Id, AccountId 
                          FROM User 
                          WHERE Id =:userId];
            System.debug('### 1 lstOfUsers '+lstOfUsers);
            if(lstOfUsers.size()>0 && lstOfUsers[0].AccountId != NULL) {
                List<MSD_CORE_HEQ_Shadow_ContentDocumentLink__c> lstOfShadowContDocLink = new List<MSD_CORE_HEQ_Shadow_ContentDocumentLink__c>();
                lstOfShadowContDocLink = [SELECT Id 
                                          FROM MSD_CORE_HEQ_Shadow_ContentDocumentLink__c
                                          WHERE MSD_CORE_HEQ_Collection__c =: collectionId AND Account__c =: lstOfUsers[0].AccountId];
                System.debug('### 2 lstOfShadowContDocLink '+lstOfShadowContDocLink);
                if(lstOfShadowContDocLink.size()>0) {
                    DELETE lstOfShadowContDocLink;
                }
            }
            
        } catch( Exception e ) {
            System.debug('Exception Occurred : ' +e.getMessage());
            System.debug('Exception Stack Trace : ' +e.getStackTraceString());  
        }
        
    }
    
    public static void deleteShadowCDLForSingleResource(String collectionId, String contentDocumentId) {
        try {
            System.debug('### 0 deleteShadowCDLForSingleResource Started '+collectionId);
            System.debug('### 0 deleteShadowCDLForSingleResource Started '+contentDocumentId);
            
            List<MSD_CORE_HEQ_Shadow_ContentDocumentLink__c> lstOfShadowContDocLink = new List<MSD_CORE_HEQ_Shadow_ContentDocumentLink__c>();
            lstOfShadowContDocLink = [SELECT Id 
                                      FROM MSD_CORE_HEQ_Shadow_ContentDocumentLink__c
                                      WHERE MSD_CORE_HEQ_Collection__c =: collectionId AND MSD_CORE_HEQ_Shadow_Content_Document__r.MSD_CORE_HEQ_CDL_Salesforce_Id__c =:contentDocumentId];
            System.debug('### 1 lstOfShadowContDocLink '+lstOfShadowContDocLink);
            if(lstOfShadowContDocLink.size()>0) {
                DELETE lstOfShadowContDocLink;
            }
            
            
        } catch( Exception e ) {
            System.debug('Exception Occurred : ' +e.getMessage());
            System.debug('Exception Stack Trace : ' +e.getStackTraceString());  
        }
        
    }
    
    public static void linkShadowContentDocumentToCollection(List<ContentDocumentLink> lstofContentDocLinks) {
        Map<Id, MSD_CORE_HEQ_Shadow_Content_Document__c> mapOfContentDocIdAndShadowContentDoc = new Map<Id, MSD_CORE_HEQ_Shadow_Content_Document__c>();
        Set<Id> setOfContentDocIds = new Set<Id>();
        List<MSD_CORE_HEQ_Shadow_ContentDocumentLink__c> lstOfShadowContDocLink = new List<MSD_CORE_HEQ_Shadow_ContentDocumentLink__c>();
        try {
            for(ContentDocumentLink rec : lstofContentDocLinks) {
                setOfContentDocIds.add(rec.ContentDocumentId);
            }
            
            for(MSD_CORE_HEQ_Shadow_Content_Document__c rec : [SELECT Id, MSD_CORE_HEQ_CDL_Salesforce_Id__c  FROM MSD_CORE_HEQ_Shadow_Content_Document__c WHERE MSD_CORE_HEQ_CDL_Salesforce_Id__c IN :setOfContentDocIds ]) {
                mapOfContentDocIdAndShadowContentDoc.put(rec.MSD_CORE_HEQ_CDL_Salesforce_Id__c, rec);
            }
            
            for(ContentDocumentLink rec : lstofContentDocLinks) {
                if(String.valueOf(rec.LinkedEntityId).startsWith(Schema.getGlobalDescribe().get('MSD_CORE_HEQ_Collection__c').getDescribe().getKeyPrefix())) {
                    MSD_CORE_HEQ_Shadow_ContentDocumentLink__c recToBeCreated = new MSD_CORE_HEQ_Shadow_ContentDocumentLink__c();
                    recToBeCreated.MSD_CORE_HEQ_Collection__c = String.valueOf(rec.LinkedEntityId);
                    recToBeCreated.MSD_CORE_HEQ_Shadow_Content_Document__c = mapOfContentDocIdAndShadowContentDoc.get(rec.ContentDocumentId).Id;
                    recToBeCreated.MSD_CORE_HEQ_SF_CDL_ID__c = rec.Id;
                    recToBeCreated.MSD_CORE_HEQ_Type__c = 'Resource Added in Collection';
                    lstOfShadowContDocLink.add(recToBeCreated);
                }
                
            }
            INSERT lstOfShadowContDocLink;
            
            
        } catch(Exception e) {
            System.debug('Exception Occurred : ' +e.getMessage());
            System.debug('Exception Stack Trace : ' +e.getStackTraceString());  
        }
    }
    
    public static void deleteShadowCDLOnDeletingCollection(Id collectionId) {
        try {
            System.debug('### 0 deleteShadowCDLOnDeletingCollection Started '+collectionId);
            
            if(collectionId != NULL) {
                List<MSD_CORE_HEQ_Shadow_ContentDocumentLink__c> lstOfShadowContDocLink = new List<MSD_CORE_HEQ_Shadow_ContentDocumentLink__c>();
                lstOfShadowContDocLink = [SELECT Id 
                                          FROM MSD_CORE_HEQ_Shadow_ContentDocumentLink__c
                                          WHERE MSD_CORE_HEQ_Collection__c =: collectionId];
                System.debug('### 2 lstOfShadowContDocLink '+lstOfShadowContDocLink);
                if(lstOfShadowContDocLink.size()>0) {
                    DELETE lstOfShadowContDocLink;
                }
            }
            
        } catch( Exception e ) {
            System.debug('Exception Occurred : ' +e.getMessage());
            System.debug('Exception Stack Trace : ' +e.getStackTraceString());  
        }
        
    }
    public class ReportingDataModelWrapper {
        public ContentDocumentLink contentDocLink;
        public Id collectionId;
    }
        
}