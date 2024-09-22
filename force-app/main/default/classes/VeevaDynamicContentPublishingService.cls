@RestResource(urlMapping='/veeva/dynamic-content-publishing')
global with sharing class VeevaDynamicContentPublishingService {

    @HttpPost
    global static VeevaContentPublishResponse publishVeevaContent() {
        VeevaContentPublishResponse veevaContentPublishResponse;

        RestResponse response = RestContext.response;
        RestRequest request = RestContext.request;

        try {
            VeevaContentPublishRequest publishRequest = (VeevaContentPublishRequest) JSON.deserialize(request.requestBody.toString(), VeevaContentPublishRequest.class);
            // validate request parameters
            validateRequest(publishRequest);
            // build/ create veeva content
            Veeva_Content_vod__c veevaContent = createVeevaContent(publishRequest);
            // link veeva content with the ContentDocument associated with the provided ContentVersion Id
            linkFileWithVeevaContent(veevaContent, publishRequest.contentVersionId);
            // update veeva content record to trigger publishing process
            triggerVeevaContentPublishingForDistribution(veevaContent);
            // return veeva content id
            veevaContentPublishResponse = success(veevaContent.Id);
            response.statusCode = 200;
        } catch(IllegalArgumentException e) {
            veevaContentPublishResponse = failure(e.getMessage());
            response.statusCode = 400; // bad request
        } catch(Exception e) {
            veevaContentPublishResponse = failure(e.getMessage());
            response.statusCode = 500; // internal server error
        }

        return veevaContentPublishResponse;
    }

    @TestVisible
    private static void validateRequest(VeevaContentPublishRequest publishRequest) {
        requireNonNull(publishRequest, 'publishRequest');
        requireStringNotBlank(publishRequest.fileName, 'fileName');
        requireStringNotBlank(publishRequest.vaultInstance, 'vaultInstance');
        requireStringNotBlank(publishRequest.vaultDocId, 'vaultDocId');
        requireIdNotBlank(publishRequest.accountId, 'accountId');
        requireNonNull(publishRequest.allowDownload, 'allowDownload');
        requireIdNotBlank(publishRequest.contentVersionId, 'contentVersionId');
    }

    private static void requireStringNotBlank(String value, String parameterName) {
        if(String.isBlank(value)) {
            throw new IllegalArgumentException(parameterName + ' must not be blank.');
        }
    }

    private static void requireIdNotBlank(String value, String parameterName) {
        requireStringNotBlank(value, parameterName);
        try {
            Id.valueOf(value);
        } catch(StringException e) {
            throw new IllegalArgumentException(parameterName + ' is not a valid id.');
        }
    }

    private static void requireNonNull(Object value, String parameterName) {
        if(value == null) {
            throw new IllegalArgumentException(parameterName + ' must not be null.');
        }
    }

    @TestVisible
    private static Veeva_Content_vod__c createVeevaContent(VeevaContentPublishRequest publishRequest) {
        // retrieve Dynamic_Content_vod record type id
        Id dynamicContentRecordType = getVeevaContentDynamicContentRecordTypeId();
        requireNonNull(dynamicContentRecordType, 'dynamicContentRecordType');
        // calculate expiration date
        Date expirationDate = calculateExpirationDate(Date.today(), publishRequest.expiryPeriod);
        // build/ upsert veeva content
        Veeva_Content_vod__c veevaContent = new Veeva_Content_vod__c(
            Name = publishRequest.fileName,
            RecordTypeId = dynamicContentRecordType,
            Dynamic_Content_Vault_Instance_ID_vod__c = publishRequest.vaultInstance,
            Dynamic_Content_Vault_Doc_ID_vod__c = publishRequest.vaultDocId,
            Account_vod__c = publishRequest.accountId,
            Allow_Source_Download_vod__c = publishRequest.allowDownload,
            Expiration_Date_vod__c = expirationDate
        );
        insert veevaContent;
        return veevaContent;
    }

    private static Id getVeevaContentDynamicContentRecordTypeId(){
        RecordType recordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Veeva_Content_vod__c' AND DeveloperName = 'Dynamic_Content_vod' AND IsActive = true];
        return recordType != null ? recordType.Id : null;
    }

    @TestVisible
    private static Date calculateExpirationDate(Date fromDate, Integer expiryPeriod) {
        if(fromDate != null && expiryPeriod != null && expiryPeriod > 0) {
            return fromDate.addDays(expiryPeriod);
        }
        return null;
    }

    @TestVisible
    private static void linkFileWithVeevaContent(Veeva_Content_vod__c veevaContent, Id contentVersionId) {
        // find ContentDocument.Id of associated to the contentVersionId
        ContentVersion contentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId];
        requireNonNull(contentVersion, 'contentVersion');
        Id contentDocumentId = contentVersion.ContentDocumentId;
        requireNonNull(contentDocumentId, 'contentDocumentId');
        // create ContentDocumentLink to link file with Veeva Content
        ContentDocumentLink documentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = veevaContent.Id
        );
        insert documentLink;
    }

    @TestVisible
    private static void triggerVeevaContentPublishingForDistribution(Veeva_Content_vod__c veevaContent) {
        veevaContent.Content_Status_vod__c = 'Approved_vod';
        veevaContent.Publish_for_Distribution_vod__c = true;
        update veevaContent;
    }

    private static VeevaContentPublishResponse failure(String errorMessage) {
        return new VeevaContentPublishResponse('FAILURE', errorMessage);
    }

    private static VeevaContentPublishResponse success(Id veevaContentId) {
        return new VeevaContentPublishResponse(veevaContentId);
    }

    global class VeevaContentPublishRequest {
        public String fileName;
        public String vaultInstance;
        public String vaultDocId;
        public String accountId;
        public Boolean allowDownload;
        public Integer expiryPeriod; // only optional parameter
        public String contentVersionId;
    }

    global class VeevaContentPublishResponse extends VeevaBaseResponse {
        public final Id data; // Id of the newly created Veeva_Content_vod
        public VeevaContentPublishResponse(Id veevaContentId) {
            super();
            this.data = veevaContentId;
        }
        public VeevaContentPublishResponse(String status, String message) {
            super(status, message);
        }
    }
}