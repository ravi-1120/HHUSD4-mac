/**
* Component Name:      MSD_CORE_HEQ_CollectionController
* Created By:          Gopi Chintamaneni (Focal CXM)
* Created Date:        7th Aug 2024
* @description:        This controller manages CRUD operations for HEQ collections and the resources within those collections.
* Test Class:          MSD_CORE_HEQ_CollectionControllerTest
*/

public without sharing class MSD_CORE_HEQ_CollectionController {

    @AuraEnabled
    public static String createCollection(String name, String imageUrls, String resourceId) {
        String message;
        try {
            List<MSD_CORE_HEQ_Collection__c> existingCollections = [
                SELECT Id 
                FROM MSD_CORE_HEQ_Collection__c 
                WHERE MSD_CORE_Collection_Name__c = :name and MSD_CORE_Account_Executive__c = :UserInfo.getUserId()
            ];
            
            if (!existingCollections.isEmpty()) {
                message = System.Label.MSD_CORE_Name_already_used;
                return message;
            }
            
            MSD_CORE_HEQ_Collection__c newCollection = new MSD_CORE_HEQ_Collection__c(
                MSD_CORE_Collection_Name__c = name,
                MSD_CORE_Header_Image_Link__c = imageUrls,
                MSD_CORE_Account_Executive__c = UserInfo.getUserId()
            );
            insert newCollection;

            if(resourceId != null) {
                List<ContentVersion> cvlist = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: resourceId];
                ContentDocumentLink cdlink = new ContentDocumentLink();
                cdlink.LinkedEntityId = newCollection.Id;
                cdlink.ContentDocumentId = cvlist[0].ContentDocumentId;
                insert cdlink;
            } 

            message = 'Success';
        } catch (DmlException e) {
            return 'DML Error: ' + e.getMessage();
        } catch (Exception e) {
            return 'Unexpected error: ' + e.getMessage();
        }
        
        return message;
    }
    
    @AuraEnabled
    public static List<CollectionWrapper> getCollections() {
        
        List<CollectionWrapper> result = new List<CollectionWrapper>();
        try {

            User user = [SELECT Profile.Name, AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Id accountId = user.AccountId;

            if (user.Profile.Name == System.Label.MSD_CORE_HEQ_CustomerProfile){
                return getCustomerCollections(null);
            }

            if (user.Profile.Name == System.Label.MSD_CORE_HEQ_AEProfile) {

                // Query to get collections
                List<MSD_CORE_HEQ_Collection__c> collections = [
                    SELECT Id,
                    MSD_CORE_Collection_Name__c, 
                    MSD_CORE_Header_Image_Link__c, 
                    LastModifiedDate
                    FROM MSD_CORE_HEQ_Collection__c
                    WHERE MSD_CORE_Account_Executive__c = :UserInfo.getUserId() 
                    AND MSD_CORE_Status__c = true
                ];
                
                // Create a list to store all collection IDs
                Set<Id> collectionIds = new Set<Id>();
                for (MSD_CORE_HEQ_Collection__c collection : collections) {
                    collectionIds.add(collection.Id);
                }
                
                // Query to get all ContentDocumentLinks for these collections
                Map<Id, List<Id>> collectionToCdlMap = new Map<Id, List<Id>>();
                
                List<ContentDocumentLink> contentLinks = [ SELECT Id, LinkedEntityId
                                                        FROM ContentDocumentLink
                                                        WHERE LinkedEntityId IN :collectionIds ];
                
                // Populate the map with CDL Ids for each collection Id
                for (ContentDocumentLink cdl : contentLinks) {
                    if (!collectionToCdlMap.containsKey(cdl.LinkedEntityId)) {
                        collectionToCdlMap.put(cdl.LinkedEntityId, new List<Id>());
                    }
                    collectionToCdlMap.get(cdl.LinkedEntityId).add(cdl.Id);
                }
                
                // Loop through results and populate CollectionWrapper objects
                for (MSD_CORE_HEQ_Collection__c collection : collections) {
                    CollectionWrapper wrapper = new CollectionWrapper();
                    wrapper.id = collection.Id;
                    wrapper.name = collection.MSD_CORE_Collection_Name__c;
                    wrapper.imageUrl = collection.MSD_CORE_Header_Image_Link__c;
                    wrapper.createdDate = collection.LastModifiedDate.format('MM/dd/yyyy hh:mm:ss a');
                    wrapper.resourceCount = collectionToCdlMap.containsKey(collection.Id)?collectionToCdlMap.get(collection.Id).size():0;
                    
                    
                    Integer sharedCount = [
                        SELECT COUNT()
                        FROM MSD_CORE_HEQ_Customer_Collection__c
                        WHERE MSD_CORE_Collection_Id__c = :collection.Id
                        AND MSD_CORE_isActive__c = true
                    ];
                    wrapper.sharedCollectionCount = sharedCount;
                    
                    result.add(wrapper);
                }
            }
        } catch (Exception e) {
            System.debug('Error in getCollections: ' + e.getMessage());
        }
        return result;
    }
    
    @AuraEnabled
    public static List<CollectionWrapper> getCustomerCollections(Id collectionId) {
        
        List<CollectionWrapper> result = new List<CollectionWrapper>();
        try {
            User user = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Id accountId = user.AccountId;
            
            String query = 'SELECT Id, LastModifiedDate, ' + 
                'MSD_CORE_Collection_Id__c, ' +
                'MSD_CORE_Collection_Id__r.MSD_CORE_Collection_Name__c, ' +
                'MSD_CORE_Collection_Id__r.MSD_CORE_Account_Executive__r.FirstName, ' +
                'MSD_CORE_Collection_Id__r.MSD_CORE_Account_Executive__r.LastName, ' +
                'MSD_CORE_Collection_Id__r.MSD_CORE_Header_Image_Link__c ' +
                'FROM MSD_CORE_HEQ_Customer_Collection__c ' +
                'WHERE MSD_CORE_Customer_Id__c = :accountId ' +
                'AND MSD_CORE_isActive__c = true ' +
                'AND MSD_CORE_Collection_Id__r.MSD_CORE_Status__c = true ';
            
            if (collectionId != null) {
                query += 'AND MSD_CORE_Collection_Id__c = :collectionId ';
            }
            
            List<MSD_CORE_HEQ_Customer_Collection__c> customerCollections = Database.query(query);

            List<Id> collectionIds = new List<Id>();
            for (MSD_CORE_HEQ_Customer_Collection__c col : customerCollections) {
                collectionIds.add(col.MSD_CORE_Collection_Id__c);
            }
 
            Map<Id, List<Id>> collectionToCdlMap = new Map<Id, List<Id>>();
                
            List<ContentDocumentLink> contentLinks = [ SELECT Id, LinkedEntityId
                                                    FROM ContentDocumentLink
                                                    WHERE LinkedEntityId IN :collectionIds ];
            
            for (ContentDocumentLink cdl : contentLinks) {
                if (!collectionToCdlMap.containsKey(cdl.LinkedEntityId)) {
                    collectionToCdlMap.put(cdl.LinkedEntityId, new List<Id>());
                }
                collectionToCdlMap.get(cdl.LinkedEntityId).add(cdl.Id);
            }
            
            for (MSD_CORE_HEQ_Customer_Collection__c customerCollection : customerCollections) {
                CollectionWrapper wrapper = new CollectionWrapper();
                wrapper.id = customerCollection.MSD_CORE_Collection_Id__c;
                wrapper.name = customerCollection.MSD_CORE_Collection_Id__r.MSD_CORE_Collection_Name__c;
                wrapper.imageUrl = customerCollection.MSD_CORE_Collection_Id__r.MSD_CORE_Header_Image_Link__c;
                wrapper.createdDate = customerCollection.LastModifiedDate.format('MM/dd/yyyy');
                wrapper.sharedBy = customerCollection.MSD_CORE_Collection_Id__r.MSD_CORE_Account_Executive__r.FirstName + ' ' + customerCollection.MSD_CORE_Collection_Id__r.MSD_CORE_Account_Executive__r.LastName;
                wrapper.resourceCount = collectionToCdlMap.containsKey(customerCollection.MSD_CORE_Collection_Id__c)?collectionToCdlMap.get(customerCollection.MSD_CORE_Collection_Id__c).size():0;
                result.add(wrapper);
            }
            
            if(collectionId != null){
                Integer resultCount = [ SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :collectionId ];
                result[0].resourceCount = resultCount;
            }
            
        } catch (Exception e) {
            System.debug('Error in getCustomerCollections: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        
        return result;
    }
    
    @AuraEnabled
    public static CollectionWrapper getCollectionRecord(Id collectionId, Id userId) {
        CollectionWrapper wrapper = new CollectionWrapper();
        try {
            if (collectionId == null || userId == null) {
                throw new AuraHandledException('Invalid parameters.');
            }
            
            Boolean recordAccess = MSD_CORE_HEQ_CollectionController.checkCollectionAccess(userId, collectionId);
            if (recordAccess) {
                MSD_CORE_HEQ_Collection__c collection = [
                    SELECT Id, 
                    MSD_CORE_Collection_Name__c, 
                    MSD_CORE_Header_Image_Link__c, 
                    CreatedDate 
                    FROM MSD_CORE_HEQ_Collection__c 
                    WHERE Id = :collectionId 
                    LIMIT 1
                ];
                
                wrapper.id = collection.Id;
                wrapper.name = collection.MSD_CORE_Collection_Name__c;
                wrapper.imageUrl = collection.MSD_CORE_Header_Image_Link__c;
                wrapper.createdDate = collection.CreatedDate.format('MM-dd-yyyy hh:mm:ss');
            } else {
                throw new AuraHandledException('Insufficient Access');
            }
        } catch (Exception e) {
            System.debug('Error in getCollectionRecord: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        
        return wrapper;
    }
    
    @AuraEnabled
    public static List<ResourceWrapper> getResourcesFromCollection(String collectionId) {
        List<ResourceWrapper> result = new List<ResourceWrapper>();
        
        /* Check if the user has access to the collection */
        Boolean recordAccess = MSD_CORE_HEQ_CollectionController.checkCollectionAccess(UserInfo.getUserId(), collectionId);
        if (!recordAccess) {
            return result;
        }
        
        if (String.isNotBlank(collectionId)) {
            try {
                String fields = 'ContentDocumentId, MSD_CORE_Expiration_Date__c, MSD_CORE_Fulfillment_Method__c, MSD_CORE_Therapeutic_Area__c, Id, Title, FileExtension';
                Set<Id> documentIds = new Set<Id>();
                
                List<ContentDocumentLink> cdlinkcd = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :collectionId];
                
                /* Collect ContentDocumentIds linked to the collection */
                for (ContentDocumentLink cd : cdlinkcd) {
                    documentIds.add(cd.ContentDocumentId);
                }
                
                /* If there are document IDs, fetch details from ContentVersion */
                if (!documentIds.isEmpty()) {
                    String[] fieldList = fields.split(',');
                    List<ContentVersion> contentVersions = [SELECT Id, Title, MSD_CORE_Resource_Code__c, MSD_CORE_Video_Resource__c, FileExtension, ContentDocumentId, MSD_CORE_Expiration_Date__c, MSD_CORE_Fulfillment_Method__c, MSD_CORE_Therapeutic_Area__c, MSD_CORE_Topic__c 
                                                            FROM ContentVersion 
                                                            WHERE ContentDocumentId IN :documentIds 
                                                            AND MSD_CORE_Is_Active__c = true 
                                                            AND MSD_CORE_Is_Thumbnail__c = false];
                    
                    for (ContentVersion cv : contentVersions) {
                        ResourceWrapper wrapper = new ResourceWrapper();
                        wrapper.id = cv.Id;
                        wrapper.docId = cv.ContentDocumentId;
                        wrapper.videoLink = cv.MSD_CORE_Video_Resource__c;
                        wrapper.title = cv.Title;
                        wrapper.fileType = cv.FileExtension;
                        wrapper.description = cv.Title;
                        Date today = Date.today();
                        //wrapper.expiryDate = cv.MSD_CORE_Expiration_Date__c != null ? today.daysBetween(cv.MSD_CORE_Expiration_Date__c) : 0;
                        wrapper.expiryDate = DateTime.newInstance(cv.MSD_CORE_Expiration_Date__c, Time.newInstance(0, 0, 0, 0)).format('MM/dd/yyyy');
                        wrapper.jobCode = cv.MSD_CORE_Resource_Code__c;
                        wrapper.therapeuticArea = cv.MSD_CORE_Therapeutic_Area__c;
                        wrapper.topic = cv.MSD_CORE_Topic__c;
                        
                        result.add(wrapper);
                    }
                }
            } catch (Exception e) {
                throw new CustomException('Error retrieving resources: ' + e.getMessage());
            }
        }
        return result;
    }
    
    
    @AuraEnabled
    public static boolean saveResourcesInCollection(String collectionId, List<String> documentIds){
        try {
            
            if(collectionId != null && collectionId != '' && !documentIds.isEmpty()){
                
                Map<String,String> mapOfContentDocumentIds = new Map<String,String>();
                for(ContentDocumentLink contentD: [SELECT Id,ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =: collectionId]){
                    mapOfContentDocumentIds.put(contentD.ContentDocumentId,contentD.Id);
                }
                
                List<MSD_CORE_HEQ_Customer_Collection__c> customercoll = [SELECT Id, Name, MSD_CORE_Collection_Id__c, MSD_CORE_Customer_Id__c FROM MSD_CORE_HEQ_Customer_Collection__c WHERE MSD_CORE_Collection_Id__c =: collectionId];
                List<Id> acclist = new List<Id>();
                for (MSD_CORE_HEQ_Customer_Collection__c cust : customercoll) { 
                    acclist.add(cust.MSD_CORE_Customer_Id__c);
                }
                
                List<ContentDocumentLink> cdlinklist = [
                    SELECT Id, LinkedEntityId, ContentDocumentId 
                    FROM ContentDocumentLink 
                    WHERE ContentDocumentId IN :documentIds
                ];
                
                Map<Id, List<ContentDocumentLink>> accountContentDocumentLinkMap = new Map<Id, List<ContentDocumentLink>>();
                
                for (ContentDocumentLink cdl : cdlinklist) {
                    if (accountContentDocumentLinkMap.containsKey(cdl.LinkedEntityId)) {
                        accountContentDocumentLinkMap.get(cdl.LinkedEntityId).add(cdl);
                    } else {
                        accountContentDocumentLinkMap.put(cdl.LinkedEntityId, new List<ContentDocumentLink>{cdl});
                    }
                }
                
                List<ContentDocumentLink> cdl = new List<ContentDocumentLink>();
                
                for (Id accountId : acclist) {
                    List<ContentDocumentLink> relatedContentDocs = accountContentDocumentLinkMap.get(accountId);
                    
                    if (relatedContentDocs == null || relatedContentDocs.isEmpty()) {
                        for (Id documentId : documentIds) {
                            ContentDocumentLink newLink = new ContentDocumentLink(
                                LinkedEntityId = accountId,
                                ContentDocumentId = documentId
                            );
                            cdl.add(newLink);
                        }
                    }
                }
                for(String s: documentIds){
                    ContentDocumentLink cd = new ContentDocumentLink();
                    cd.LinkedEntityId = collectionId;
                    cd.ContentDocumentId = s;
                    if(!mapOfContentDocumentIds.containsKey(s)){
                        cdl.add(cd);
                    }
                }
                if(!cdl.isEmpty()){
                    insert cdl;
                    return true;
                }
            }
            
            return false;
            
        } catch (Exception e) {
            System.debug('Error in saveResourcesInCollection: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static boolean removeResourceFromCollection(String contentDocumentId,String collectionId){
        try {
            if (String.isBlank(collectionId) || String.isBlank(contentDocumentId)) {
                return false;
            }
            
            List<MSD_CORE_HEQ_Customer_Collection__c> customerColl = [
                SELECT MSD_CORE_Customer_Id__c
                FROM MSD_CORE_HEQ_Customer_Collection__c
                WHERE MSD_CORE_Collection_Id__c = :collectionId
            ];
            
            Set<Id> accIdSet = new Set<Id>();
            if (!customerColl.isEmpty()) {
                for (MSD_CORE_HEQ_Customer_Collection__c cust : customerColl) {
                    accIdSet.add(cust.MSD_CORE_Customer_Id__c);
                }
            }
            
            List<ContentDocumentLink> documentLinksToDelete = [
                SELECT Id
                FROM ContentDocumentLink
                WHERE (LinkedEntityId IN :accIdSet OR LinkedEntityId = :collectionId)
                AND ContentDocumentId = :contentDocumentId
            ];
            
            if (!documentLinksToDelete.isEmpty()) {
                delete documentLinksToDelete;
                return true;
            }
            
            return false;
            
        } catch (DmlException dmlEx) {
            throw new AuraHandledException('Error deleting ContentDocumentLinks: ' + dmlEx.getMessage());
            
        } catch (Exception e) {
            throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean checkCollectionAccess(Id userId, Id collectionId) {
        try{
            User user = [SELECT Profile.Name, AccountId FROM User WHERE Id = :userId LIMIT 1];
            
            if (user.Profile.Name == System.Label.MSD_CORE_HEQ_AEProfile) {
                MSD_CORE_HEQ_Collection__c collection = [SELECT Id FROM MSD_CORE_HEQ_Collection__c WHERE Id = :collectionId AND MSD_CORE_Account_Executive__c = :userId LIMIT 1];
                return collection != null;
            }
            if (user.Profile.Name == System.Label.MSD_CORE_HEQ_CustomerProfile){
                MSD_CORE_HEQ_Customer_Collection__c customerCollections = [
                    SELECT Id FROM MSD_CORE_HEQ_Customer_Collection__c WHERE MSD_CORE_Customer_Id__c = :user.AccountId 
                    AND MSD_CORE_Collection_Id__c = :collectionId 
                    AND MSD_CORE_isActive__c = true
                    AND MSD_CORE_Collection_Id__r.MSD_CORE_Status__c = true
                ];
                return customerCollections != null;
            }
        }catch(Exception e){
            System.debug('Error in checkUserAccess: ' + e.getMessage());
        }
        return false;
    }
    
    @AuraEnabled
    public static String deleteCollection(Id collectionId) {
        String message;
        try {
            // Find the collection by Id
            MSD_CORE_HEQ_Collection__c collectionToDelete = [
                SELECT Id 
                FROM MSD_CORE_HEQ_Collection__c 
                WHERE Id = :collectionId AND MSD_CORE_Account_Executive__c = :UserInfo.getUserId() 
                LIMIT 1
            ];
            
            List<MSD_CORE_HEQ_Customer_Collection__c> customercoll = [SELECT Id, Name, MSD_CORE_Collection_Id__c, MSD_CORE_Customer_Id__c FROM MSD_CORE_HEQ_Customer_Collection__c WHERE MSD_CORE_Collection_Id__c =: collectionId];
            List<Id> acclist = new List<Id>();
            for (MSD_CORE_HEQ_Customer_Collection__c cust : customercoll) { 
                acclist.add(cust.MSD_CORE_Customer_Id__c);
            }
            List<User> userlist = [SELECT Id, Name, AccountId FROM User WHERE AccountId =: acclist];
            String str = '';
            for (User us : userlist) {
                str = MSD_CORE_HEQ_CollectionController.unShareCollection(us.Id,collectionId);
            }
            
            if (collectionToDelete != null) {
                delete collectionToDelete;
                message = 'Collection deleted successfully';
            } else {
                message = 'Collection not found or not authorized to delete';
            }
        } catch (DmlException e) {
            message = 'DML Error: ' + e.getMessage();
        } catch (Exception e) {
            message = 'Unexpected error: ' + e.getMessage() + ' -- '+e.getLineNumber();
        }
        return message;
    }
    
    @AuraEnabled
    public static String updateCollection(String collectionId, String name, String imageUrls) {
        String message;
        try {
            // Fetch the collection to be updated
            MSD_CORE_HEQ_Collection__c collectionToUpdate = [
                SELECT Id, MSD_CORE_Collection_Name__c, MSD_CORE_Header_Image_Link__c, MSD_CORE_Account_Executive__c
                FROM MSD_CORE_HEQ_Collection__c
                WHERE Id = :collectionId AND MSD_CORE_Account_Executive__c = :UserInfo.getUserId()
                LIMIT 1
            ];
            
            if (collectionToUpdate == null) {
                message = 'Collection not found or does not belong to the current user.';
                return message;
            }
            
            List<MSD_CORE_HEQ_Collection__c> existingCollections = [
                SELECT Id
                FROM MSD_CORE_HEQ_Collection__c
                WHERE MSD_CORE_Collection_Name__c = :name AND Id != :collectionId AND MSD_CORE_Account_Executive__c = :UserInfo.getUserId()
            ];
            
            if (!existingCollections.isEmpty()) {
                message = 'Repeated Name';
                return message;
            }
            
            // Update collection fields
            collectionToUpdate.MSD_CORE_Collection_Name__c = name;
            collectionToUpdate.MSD_CORE_Header_Image_Link__c = imageUrls;
            
            update collectionToUpdate;
            message = 'Success';
        } catch (DmlException e) {
            return 'DML Error: ' + e.getMessage();
        } catch (Exception e) {
            return 'Unexpected error: ' + e.getMessage();
        }
        
        return message;
    }
    
    @AuraEnabled 
    public static Map<String, Object> duplicateCollection(String collectionId, String newName, String versionId) {
        Map<String, Object> result = new Map<String, Object>();
        List<String> newResourceIds = new List<String>();
        try {
            // Query the original collection to duplicate
            MSD_CORE_HEQ_Collection__c originalCollection = [
                SELECT Id, MSD_CORE_Collection_Name__c, MSD_CORE_Header_Image_Link__c, MSD_CORE_Account_Executive__c
                FROM MSD_CORE_HEQ_Collection__c
                WHERE Id = :collectionId AND MSD_CORE_Account_Executive__c = :UserInfo.getUserId()
                LIMIT 1
            ];
            
            // Check if the original collection exists
            if (originalCollection == null) {
                throw new AuraHandledException('Original collection not found or does not belong to the current user.');
            }
            
            // Check for existing collections with the new name
            List<MSD_CORE_HEQ_Collection__c> existingCollections = [
                SELECT Id
                FROM MSD_CORE_HEQ_Collection__c
                WHERE MSD_CORE_Collection_Name__c = :newName AND MSD_CORE_Account_Executive__c = :UserInfo.getUserId()
            ];
            
            if (!existingCollections.isEmpty()) {
                throw new AuraHandledException('A collection with the provided name already exists.');
            }
            
            // Create a new collection with the specified name and image URLs
            MSD_CORE_HEQ_Collection__c newCollection = new MSD_CORE_HEQ_Collection__c(
                MSD_CORE_Collection_Name__c = newName,
                MSD_CORE_Header_Image_Link__c = versionId,
                MSD_CORE_Account_Executive__c = originalCollection.MSD_CORE_Account_Executive__c
            );
            
            // Insert the new collection record
            insert newCollection;
            
            // Query to get ContentDocumentIds linked to the original collection
            List<ContentDocumentLink> originalDocLinks = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :collectionId
            ];
            
            // Extract ContentDocumentIds
            Set<Id> contentDocumentIds = new Set<Id>();
            for (ContentDocumentLink cdl : originalDocLinks) {
                contentDocumentIds.add(cdl.ContentDocumentId);
            }
            
            // Create new ContentDocumentLinks for the new collection
            List<ContentDocumentLink> newCDLs = new List<ContentDocumentLink>();
            for (Id docId : contentDocumentIds) {
                ContentDocumentLink cdl = new ContentDocumentLink(
                    LinkedEntityId = newCollection.Id,
                    ContentDocumentId = docId,
                    ShareType = 'V'
                );
                newCDLs.add(cdl);
                newResourceIds.add(cdl.Id);
            }
            
            // Insert new ContentDocumentLinks
            insert newCDLs;
            
            
            result.put('success', true);
            result.put('message', 'Success: New collection created with ID ' + newCollection.Id + ' and ' + contentDocumentIds.size() + ' resources linked.');
            result.put('newCollectionId', newCollection.Id);
            result.put('newResourceIds', new List<Id>(contentDocumentIds));
            
        } catch (Exception e) {
            result.put('success', false);
            result.put('message', 'Error: ' + e.getMessage());
        }
        
        return result;
    }
    
    @AuraEnabled
    public static Integer getExistingCopiesCount(String nameLike) {
        String likePattern = 'Copy of ' + nameLike + '%';
        List<MSD_CORE_HEQ_Collection__c> collections = [
            SELECT Id 
            FROM MSD_CORE_HEQ_Collection__c 
            WHERE MSD_CORE_Collection_Name__c LIKE :likePattern 
            AND MSD_CORE_Account_Executive__c = :UserInfo.getUserId()
        ];
        return collections.size();
    }

    /**
    * Method Name  :   addResourceToCollection
    * @description :   Use to add resources to the collection
    * @return      :   String
    * Created By   :   Ravi Modi (Focal CXM)
    * Created Date :   13th Sep 2024
    */
    @AuraEnabled
    public static string addResourceToCollection(String collectionId, String resourceId){
        try {
            MSD_CORE_HEQ_Collection__c collection = [SELECT Id, Name, MSD_CORE_Collection_Name__c FROM MSD_CORE_HEQ_Collection__c WHERE Id =: collectionId LIMIT 1];

            List<ContentDocumentLink> cdlinklist = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =: collection.Id AND ContentDocumentId =: resourceId];

            if (cdlinklist.size()>0) {
                System.debug('Already Linked');
            } else {
                ContentDocumentLink cdlink = new ContentDocumentLink();
                cdlink.LinkedEntityId = collection.Id;
                cdlink.ContentDocumentId = resourceId;
                insert cdlink;
            }
            return collection.MSD_CORE_Collection_Name__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() +'----'+ e.getLineNumber());
        }
    }
    
    
    /**
    * Method Name  :   getSharedCustomer
    * @description :   Use to get shared customer
    * @return      :   List<User>
    * Created By   :   Ravi Modi (Focal CXM)
    * Created Date :   23th August 2024
    */
    @AuraEnabled
    public static List<User> getSharedCustomer(String collectionId) {
        List<User> returnuser;
        try {
            List<MSD_CORE_HEQ_Customer_Collection__c> customercollection = [SELECT Id, Name, MSD_CORE_isActive__c, MSD_CORE_Collection_Id__c, MSD_CORE_Customer_Id__c FROM MSD_CORE_HEQ_Customer_Collection__c WHERE MSD_CORE_Collection_Id__c =: collectionId AND MSD_CORE_isActive__c = true];
            List<Id> personaccids = new List<Id>();
            if (customercollection.size() > 0) {
                for (MSD_CORE_HEQ_Customer_Collection__c col : customercollection) {
                    personaccids.add(col.MSD_CORE_Customer_Id__c);
                }
                returnuser = [SELECT Id, Name, FirstName, LastName, Email, AccountId FROM User WHERE AccountId =: personaccids];
            }
        } catch (Exception e) {
            System.debug('Error getSharedCustomer ::>'+e.getMessage() +'---'+e.getLineNumber());
            returnuser = new List<User>();
        }
        return returnuser;
    }
    
    /**
    * Method Name  :   shareCollection
    * @description :   Use to share the collection
    * @return      :   String
    * Created By   :   Ravi Modi (Focal CXM)
    * Created Date :   23th August 2024
    */
    @AuraEnabled
    public static String shareCollection(List<Id> customerIds, String collectionId) {
        String returnmessage = '';
        try {
            List<User> userlist = [SELECT Id, Firstname, Lastname, Name, Email, AccountId FROM User WHERE Id =: customerIds];
            System.debug('userlist::>'+userlist);
            
            List<MSD_CORE_HEQ_Customer_Collection__c> collectionlist = new List<MSD_CORE_HEQ_Customer_Collection__c>();
            List<Id> accountIds = new List<Id>();
            
            for (User user : userlist) {
                List<MSD_CORE_HEQ_Customer_Collection__c> extcol = [SELECT Id, MSD_CORE_Collection_Id__c, MSD_CORE_Customer_Id__c FROM MSD_CORE_HEQ_Customer_Collection__c WHERE MSD_CORE_Collection_Id__c =: collectionId AND MSD_CORE_Customer_Id__c =: user.AccountId];
                if(extcol.size()>0) {
                    System.debug('already exists');
                    extcol[0].MSD_CORE_isActive__c = true;
                    update extcol;
                } else {
                    MSD_CORE_HEQ_Customer_Collection__c collection = new MSD_CORE_HEQ_Customer_Collection__c();
                    collection.MSD_CORE_Collection_Id__c = collectionId;
                    collection.MSD_CORE_Customer_Id__c = user.AccountId;
                    collection.MSD_CORE_isActive__c = true;
                    collectionlist.add(collection);
                }
                accountIds.add(user.AccountId);
            }
            
            if(collectionlist.size()>0){
                insert collectionlist;
            }
            
            List<String> resourceName = new List<String>();
            
            List<ContentDocumentLink> documents = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: collectionId];
            List<Id> contentdoocumentIds = new List<Id>();
            for (ContentDocumentLink doc : documents) {
                contentdoocumentIds.add(doc.ContentDocumentId);
            }
            
            for (ContentVersion cv : [SELECT Id, Title FROM ContentVersion WHERE ContentDocumentId =: contentdoocumentIds]) {
                resourceName.add(cv.Title);
            }
            
            List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();
            
            for (Id accountId : accountIds) {
                for (Id documentId : contentdoocumentIds) {
                    List<ContentDocumentLink> cdlinklist = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: accountId AND ContentDocumentId =: documentId LIMIT 1];
                    if (cdlinklist.size()>0) {
                        System.debug('already exists');
                    } else {
                        ContentDocumentLink docLink = new ContentDocumentLink();
                        docLink.LinkedEntityId = accountId;
                        docLink.ContentDocumentId = documentId;
                        documentLinks.add(docLink);
                    }
                }
            }
            
            if (!documentLinks.isEmpty()) {
                insert documentLinks;
            }
            
            String resourceNamesFormatted = '<ul>';
            for (String res : resourceName) {
                resourceNamesFormatted += '<li>' + res + '</li>';
            }
            resourceNamesFormatted += '</ul>';
            
            /* Fetch Health EQ Application Settings */
            MSD_CORE_HEQ_Portal_Setting__mdt[] heqSettings = [select id, MSD_CORE_HEQ_ORG_Wide_Address__c, DeveloperName from MSD_CORE_HEQ_Portal_Setting__mdt where DeveloperName='MSD_CORE_Health_EQ_Portal'];
            String orgwideadd = heqSettings[0].MSD_CORE_HEQ_ORG_Wide_Address__c;
            
            String collectionname = [SELECT Id, MSD_CORE_Collection_Name__c FROM MSD_CORE_HEQ_Collection__c WHERE Id =: collectionId LIMIT 1].MSD_CORE_Collection_Name__c;
            
            EmailTemplate emailTemplate = [SELECT Id, Body, Subject, HtmlValue FROM EmailTemplate WHERE Name = 'MSD_CORE_HEQ_Share_Collection'  LIMIT 1];
            if (emailTemplate == null) {
                return 'Email template not found.';
            } else {
                
                User aeuser = [SELECT Id, Name, Firstname, Lastname FROM User WHERE Id=: UserInfo.getUserId() LIMIT 1];
                for(User us : userlist) {
                    String emailBody = emailTemplate.HtmlValue
                        .replace('{aeName}', aeuser.FirstName + ' ' +aeuser.LastName)
                        .replace('{customerName}', us.FirstName + ' ' +us.LastName)
                        .replace('{resourceName}', resourceNamesFormatted)
                        .replace('{collectionName}', collectionname)
                        .replace('{loginBtn}', '<a href="' + System.Label.MSD_CORE_HEQ_PortalLogin + '" style="display: inline-block; color: #FFFFFF; text-decoration: none; font-size: 14px; font-weight: 700; line-height: 20px; text-align: center; background-color: #00857C; padding: 8px 16px; border-radius: 5px; font-family: Arial, sans-serif;">Login</a>')
                        .replace('{privacyLink}', '<a href="' + System.Label.MSD_CORE_HEQ_PrivacyLink + '"> Merck Privacy Statement. </a>');
                    
                    String formattedSubject = emailTemplate.Subject.replace('{aeName}', aeUser.Name);
                    
                    /* Send the email */
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new String[] {us.Email});
                    email.setSubject(formattedSubject);
                    email.setHtmlBody(emailBody);
                    email.setSaveAsActivity(false);
                    
                    OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :orgwideadd LIMIT 1];
                    if (!owea.isEmpty()) {
                        email.setOrgWideEmailAddressId(owea[0].Id);
                    }
                    
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
                }
            }
            
            returnmessage = 'Success';
        } catch (Exception e) {
            System.debug('Error shareCollection ::>'+e.getMessage() +'---'+e.getLineNumber());
            returnmessage = 'Error ::>' +e.getMessage() + '---' +e.getLineNumber();
        }
        return returnmessage;
    }
    
    /**
    * Method Name  :   unShareCollection
    * @description :   Use to get shared customer
    * @return      :   String
    * Created By   :   Ravi Modi (Focal CXM)
    * Created Date :   24th August 2024
    */
    @AuraEnabled
    public static String unShareCollection(String customerId, String collectionId) {
        String returnmessage;
        try {
            System.debug('****unShareCollection*****');
            // Person Account
            Id personAccount = [SELECT Id, AccountId FROM User WHERE Id =: customerId].AccountId;
            
            // Customer Collection
            MSD_CORE_HEQ_Customer_Collection__c extcol = [SELECT Id, MSD_CORE_Collection_Id__c, MSD_CORE_Customer_Id__c, MSD_CORE_isActive__c FROM MSD_CORE_HEQ_Customer_Collection__c WHERE MSD_CORE_Collection_Id__c =: collectionId AND MSD_CORE_Customer_Id__c =: personAccount LIMIT 1];
            extcol.MSD_CORE_isActive__c = false;
            
            // Storing All Collection id except collectionId(mycollection)
            Set<Id> setOfCollIdsExceptUnshareCollection = new Set<Id>();
            for(MSD_CORE_HEQ_Collection__c col: [SELECT Id, Name FROM MSD_CORE_HEQ_Collection__c WHERE Id !=:collectionId]){
                setOfCollIdsExceptUnshareCollection.add(col.Id);
            }
            
            // Getting all the shared customer collection except unshare collection with personaccoumt
            Set<Id> setOfCollIdsExceptUnshareCollectionFinal = new Set<Id>();
            for(MSD_CORE_HEQ_Customer_Collection__c rec : [SELECT Id, MSD_CORE_Collection_Id__c, MSD_CORE_Customer_Id__c, MSD_CORE_isActive__c FROM MSD_CORE_HEQ_Customer_Collection__c WHERE MSD_CORE_Collection_Id__c IN: setOfCollIdsExceptUnshareCollection AND MSD_CORE_Customer_Id__c =: personAccount AND MSD_CORE_isActive__c = true]) {
                setOfCollIdsExceptUnshareCollectionFinal.add(rec.MSD_CORE_Collection_Id__c);
            }
            System.debug('### setOfCollIdsExceptUnshareCollectionFinal '+setOfCollIdsExceptUnshareCollectionFinal);
            
            Set<Id> allDocLinksWithUser = new Set<Id>();
            if (setOfCollIdsExceptUnshareCollectionFinal.size() > 0) {
                Set<Id> mainDocLinks = new Set<Id>();
                for(ContentDocumentLink rec : [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN : setOfCollIdsExceptUnshareCollectionFinal]) {
                    mainDocLinks.add(rec.ContentDocumentId);
                    System.debug('### rec.ContentDocumentId '+rec.ContentDocumentId);                
                }
                System.debug('### mainDocLinks '+mainDocLinks);
                
                for(ContentDocumentLink rec : [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId = :mainDocLinks and linkedEntityid =:personAccount]) {
                    allDocLinksWithUser.add(rec.ContentDocumentId);                
                }
            }
            
            Set<Id> setOfUserCollDocLinks = new Set<Id>();
            for(ContentDocumentLink rec : [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :collectionId ]) {
                setOfUserCollDocLinks.add(rec.ContentDocumentId);
            }
            System.debug('### setOfUserCollDocLinks '+setOfUserCollDocLinks);
            
            Set<Id> deleteidset = new Set<Id>();
            
            for(Id idVal : allDocLinksWithUser){                 //(R1, R3, R4, R5, R6)... 100s
                if(setOfUserCollDocLinks.contains(idVal)){            //(R1, R2, R7, R9, R3)
                    deleteidset.add(idVal);
                    setOfUserCollDocLinks.remove(idVal);
                }
            }
            System.debug('deleteidset>>>'+deleteidset);
            System.debug('setOfUserCollDocLinks>>'+setOfUserCollDocLinks);
            
            List<ContentDocumentLink> lstOfDocLinksToBeDeleted = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId = :setOfUserCollDocLinks and linkedEntityid =:personAccount];
            System.debug('lstOfDocLinksToBeDeleted>>'+lstOfDocLinksToBeDeleted);
            if(lstOfDocLinksToBeDeleted.size() > 0) {
                Database.Delete (lstOfDocLinksToBeDeleted, false);
            }
            if(extcol != NULL) {
                update extcol;
            }            
            returnmessage = 'Success';
        } catch (Exception e) {
            System.debug('Error shareCollection ::>'+e.getMessage() +'---'+e.getLineNumber());
            returnmessage = 'Error ::>' +e.getMessage() + '---' +e.getLineNumber();
        }
        return returnmessage;
    }
    
    @AuraEnabled
    public static List<ContentWrapper> getImages() {
        List<ContentWrapper> result = new List<ContentWrapper>();
        try {
            List<ContentVersion> images = [
                SELECT Id, Title, FileType
                FROM ContentVersion 
                WHERE (FileType = 'PNG' OR FileType = 'JPG') AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false
            ];
            for (ContentVersion image : images) {
                ContentWrapper wrapper = new ContentWrapper();
                wrapper.id = image.Id;
                wrapper.title = image.Title;
                result.add(wrapper);
            }
        } catch (Exception e) {
            System.debug('Error in getImages: ' + e.getMessage());
        }
        return result;
    }
    
    @AuraEnabled
    public static List<Map<String, String>> getResourceTitlesAndCodes(String collectionId) {
        try {
            // Prepare the result list
            List<Map<String, String>> result = new List<Map<String, String>>();
            
            // Check if the collectionId is valid
            if (String.isNotBlank(collectionId)) {
                // Get all ContentDocumentIds linked to the collection
                Set<Id> documentIds = new Set<Id>();
                for (ContentDocumentLink cd : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: collectionId]) {
                    documentIds.add(cd.ContentDocumentId);
                }
                
                // If there are document IDs, proceed to query ContentVersion
                if (!documentIds.isEmpty()) {
                    // Query only the Title and Resource Code for each ContentVersion
                    for (ContentVersion cv : [
                        SELECT ContentDocumentId, Title, MSD_CORE_Resource_Code__c 
                        FROM ContentVersion 
                        WHERE ContentDocumentId IN :documentIds 
                        AND MSD_CORE_Is_Active__c = true 
                        AND MSD_CORE_Is_Thumbnail__c = false
                    ]   ) {
                        // Prepare the map for each result
                        Map<String, String> recordMap = new Map<String, String>();
                        recordMap.put('Title', cv.Title);
                        recordMap.put('ResourceCode', cv.MSD_CORE_Resource_Code__c);
                        result.add(recordMap);
                    }
                }
            }
            
            // Return the result list
            return result;
            
        } catch (Exception e) {
            throw new CustomException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ContentVersion getResourceData(String resourceId) {
        return [SELECT Id, Description, Title, ContentDocumentId, FileType, MSD_CORE_IsNewItem__c, MSD_CORE_Is_Thumbnail__c, MSD_CORE_Is_Active__c, MSD_CORE_Therapeutic_Area__c, MSD_CORE_Topic__c, MSD_CORE_Video_Resource__c, MSD_CORE_Expiration_Date__c, LastModifiedDate, MSD_CORE_Resource_Code__c, MSD_CORE_Fulfillment_Method__c FROM ContentVersion WHERE Id =: resourceId LIMIT 1];
    }
    
    @AuraEnabled
    public static List<MSD_CORE_HEQ_Collection__c> getCollectionList(String collectionId) {
        return [SELECT Id, MSD_CORE_Collection_Name__c, MSD_CORE_Header_Image_Link__c, LastModifiedDate FROM MSD_CORE_HEQ_Collection__c WHERE MSD_CORE_Account_Executive__c = :UserInfo.getUserId() AND MSD_CORE_Status__c = true];
    }
    
    /* Wrapper class */
    public class ContentWrapper {
        @AuraEnabled
        public Id id { get; set; }
        @AuraEnabled
        public String title { get; set; }
        @AuraEnabled
        public String fileType { get; set; }
    }
    
    public class ResourceWrapper {
        @AuraEnabled
        public Id id { get; set; }
        @AuraEnabled
        public String title { get; set; }
        @AuraEnabled
        public Id docId { get; set; }
        @AuraEnabled
        public String fileType { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public String expiryDate { get; set; }
        @AuraEnabled
        public String videoLink { get; set; }
        @AuraEnabled
        public String jobCode { get; set; }
        @AuraEnabled
        public String therapeuticArea { get; set; }
        @AuraEnabled
        public String topic { get; set; }
    }
    
    public class CollectionWrapper {
        @AuraEnabled
        public Id id { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String imageUrl { get; set; }
        @AuraEnabled
        public String createdDate { get; set; } 
        @AuraEnabled
        public Integer resourceCount { get; set; }
        @AuraEnabled
        public String sharedBy { get; set; }
        @AuraEnabled
        public Integer sharedCollectionCount { get; set; }
    }
    
    public class CustomException extends Exception {}
}