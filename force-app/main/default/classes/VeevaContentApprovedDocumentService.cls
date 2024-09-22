global with sharing class VeevaContentApprovedDocumentService {

    public static void createApprovedDocumentFragments(Set<Id> newFragmentsNeeded, Map<Id, Id> mostRecentAssociatedFiles) {
        if (System.isFuture() || System.isBatch()) {
            createApprovedDocumentFragmentsNow(newFragmentsNeeded, mostRecentAssociatedFiles);
        } else {
            createApprovedDocumentFragmentsFuture(newFragmentsNeeded, mostRecentAssociatedFiles);
        }
    }

    @future (callout = true)
    public static void createApprovedDocumentFragmentsFuture(Set<Id> newFragmentsNeeded, Map<Id, Id> mostRecentAssociatedFiles){
        createApprovedDocumentFragmentsNow(newFragmentsNeeded, mostRecentAssociatedFiles);
    }

    private static void createApprovedDocumentFragmentsNow(Set<Id> newFragmentsNeeded, Map<Id, Id> mostRecentAssociatedFiles) {
        List<Veeva_Content_vod__c> relatedVeevaContents =[SELECT Id, Status_Details_vod__c FROM Veeva_Content_vod__c WHERE Id IN: newFragmentsNeeded];
        Http http = new Http();
        HttpRequest req = buildFragmentCreationRequest(newFragmentsNeeded, mostRecentAssociatedFiles);
        Set<Id> failedRecordIds = executeFragmentCreationAndParseResponse(req, newFragmentsNeeded);
        setProcessingErrors(relatedVeevaContents, failedRecordIds);
    }

    @TestVisible
    private static HttpRequest buildFragmentCreationRequest(Set<Id> newFragmentsNeeded, Map<Id, Id> mostRecentAssociatedFiles) {
        List<VeevaContentFragmentRequest> payload = new List<VeevaContentFragmentRequest>();
        for(Id newVeevaContentId : newFragmentsNeeded) {
            VeevaContentFragmentRequest request = new VeevaContentFragmentRequest();
            request.veevaContentId = newVeevaContentId;
            request.contentDocumentId = mostRecentAssociatedFiles.get(newVeevaContentId);
            payload.add(request);
        }
        String body = JSON.serialize(payload);

        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
        String url = settings.Multichannel_Server_vod__c + '/' + settings.Multichannel_Context_Root_vod__c +
                        '/api/v1/veeva-contents/fragments';
        String auth = VOD_EMBED_CONTROLLER.getSfdcAuth();
    	String sfSession = VOD_EMBED_CONTROLLER.getSfSession();
	    String sfEndpoint = VOD_EMBED_CONTROLLER.getSfEndpoint();

        HttpRequest req = new HttpRequest();
        req.setMethod('POST');

        // Need salesforce session, endpoint, request type and content-type headers
        req.setHeader('sfSession', sfSession);
        req.setHeader('sfEndpoint', sfEndpoint);
        req.setHeader('content-type', 'application/json');
        req.setEndpoint(url);
        req.setBody(body);
        return req;
    }

    @TestVisible
    private static Set<Id> executeFragmentCreationAndParseResponse(HttpRequest req, Set<Id> newFragmentsNeeded) {
        Http http = new Http();
        Set<Id> failedRecordIds = new Set<Id>();
        try {
            HttpResponse response = http.send(req);
            if(response.getStatusCode() == 200) {
                // ensure each veeva content id has an approved document id returned
                String bodyStr = response.getBody();
                FragmentCreationResponse responseBody = (FragmentCreationResponse) JSON.deserialize(bodyStr, FragmentCreationResponse.class);
                Map<Id, Id> createdApprovedDocuments = responseBody.data;
                for(Id newVeevaContentId : newFragmentsNeeded) {
                    Id createdFragment = createdApprovedDocuments != null? createdApprovedDocuments.get(newVeevaContentId) : null;
                    if(createdFragment == null) {
                        failedRecordIds.add(newVeevaContentId);
                    }
                }
            } else {
                // set error for all veeva contents
                failedRecordIds.addAll(newFragmentsNeeded);
            }
        } catch (Exception e) {
            // set error for all veeva contents
            failedRecordIds.addAll(newFragmentsNeeded);
        }
        return failedRecordIds;
    }

    @TestVisible
    private static void setProcessingErrors(List<Veeva_Content_vod__c> relatedVeevaContents, Set<Id> failedRecordIds) {
        if(relatedVeevaContents != null && !relatedVeevaContents.isEmpty()) {
            List<Veeva_Content_vod__c> toUpdate = new List<Veeva_Content_vod__c>();
            String processingErrorMessage = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('VEEVA_CONTENT_ERROR_PROCESSING', 'Multichannel',
                'An error occurred while processing the content. Please save the record again to retry processing.');
            for(Veeva_Content_vod__c veevaContent : relatedVeevaContents) {
                String existingStatusDetail = veevaContent.Status_Details_vod__c;
                boolean failed = failedRecordIds.contains(veevaContent.Id);
                if(failed && !processingErrorMessage.equals(existingStatusDetail)) {
                    // if failed and we need to update status detail
                    veevaContent.Status_Details_vod__c = processingErrorMessage;
                    toUpdate.add(veevaContent);
                } else if(!failed && String.isNotBlank(existingStatusDetail)) {
                    // if success and we need to clear status detail field
                    veevaContent.Status_Details_vod__c = '';
                    toUpdate.add(veevaContent);
                }
            }
            update toUpdate;
        }
    }

    global class FragmentCreationResponse extends VeevaBaseResponse {
        public final Map<Id, Id> data;

        public FragmentCreationResponse(Map<Id, Id> createdFragmentsMap) {
            data = createdFragmentsMap;
        }
    }

    private class VeevaContentFragmentRequest {
        public Id veevaContentId;
        public Id contentDocumentId;
    }

}