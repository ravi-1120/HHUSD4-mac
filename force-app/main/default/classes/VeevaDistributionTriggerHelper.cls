public class VeevaDistributionTriggerHelper extends VeevaTriggerHandler{
    
  	private List<Veeva_Distribution_vod__c> newRecords = new List<Veeva_Distribution_vod__c>();
    private List<Veeva_Distribution_vod__c> oldRecords = new List<Veeva_Distribution_vod__c>();
    private Map<Id, Veeva_Distribution_vod__c> newRecordsMap = new Map<Id, Veeva_Distribution_vod__c>();
    private Map<Id, Veeva_Distribution_vod__c> oldRecordsMap = new Map<Id, Veeva_Distribution_vod__c>();
    private static final String PUB_READY = 'Ready_to_Publish_vod';
    private static final String PUB_PROGRESS = 'Publish_In_Progress_vod';
    private static final String PUB_FAILED = 'Failed_to_Publish_vod';
    private static final String WD_READY = 'Ready_to_Withdraw_vod';
    private static final String WD_PROGRESS = 'Withdraw_In_Progress_vod';
    private static final String WD_FAILED = 'Failed_to_Withdraw_vod';
    private static final String SUCCESS = 'Success_vod';    
   
    @testVisible protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        this.newRecords = (List<Veeva_Distribution_vod__c>) triggerNew;
        this.oldRecords = (List<Veeva_Distribution_vod__c>) triggerOld;
        this.newRecordsMap = (Map<Id, Veeva_Distribution_vod__c>) triggerNewMap;
        this.oldRecordsMap = (Map<Id, Veeva_Distribution_vod__c>) triggerOldMap;
    }

    protected override String sObjectType() {
        return 'Veeva_Distribution_vod__c';
    }

    protected override void afterInsert() {
        handleUpsert();
    }
    protected override void afterUpdate() {
        handleUpsert();
    }

    @TestVisible
    private static void checkForInvalidStatusTransitions(Map<Id, Veeva_Distribution_vod__c> oldMap, Map<Id, Veeva_Distribution_vod__c> newMap, String errorMessageTemplate){
        for(Id tempId : oldMap.keySet()){
            Veeva_Distribution_vod__c oldRecord = oldMap.get(tempId);
            Veeva_Distribution_vod__c newRecord = newMap.get(tempId);
            if (checkRecordForInvalidStatusTransition(oldRecord, newRecord)) {
                String oldStatus = oldRecord.Processing_Status_vod__c == null ? 'null' : oldRecord.Processing_Status_vod__c;
                String newStatus = newRecord.Processing_Status_vod__c == null ? 'null' : newRecord.Processing_Status_vod__c;
            	String errorMessage = errorMessageTemplate.replace('{0}',oldStatus).replace('{1}',newStatus);    
            	newRecord.addError(Veeva_Distribution_vod__c.Processing_Status_vod__c, errorMessage);
        	}
        }
    }
    
    @TestVisible
	private static boolean checkRecordForInvalidStatusTransition(Veeva_Distribution_vod__c oldRecord, Veeva_Distribution_vod__c newRecord) {
		String oldStatus = oldRecord.Processing_Status_vod__c;
    	String newStatus = newRecord.Processing_Status_vod__c;
 		return (invalidInitialStatus(oldStatus, newStatus) || invalidStatusChange(oldStatus, newStatus));
	}

    private static boolean invalidInitialStatus(String oldStatus, String newStatus){
        if(oldStatus == null && (newStatus !=null && !newStatus.equals(PUB_READY))){
            return true;
        }
        return false;
    }
    
    private static boolean invalidStatusChange(String oldStatus, String newStatus) {
        return bothNotSameOrNull(oldStatus, newStatus) && 
            ( notTransitionFrom(oldStatus, PUB_READY, newStatus, PUB_PROGRESS, PUB_FAILED)
             || notTransitionFrom(oldStatus, WD_READY, newStatus, WD_PROGRESS, WD_FAILED)
             || notTransitionFrom(oldStatus, PUB_PROGRESS, newStatus, SUCCESS, PUB_FAILED)
             || notTransitionFrom(oldStatus, WD_PROGRESS, newStatus, SUCCESS, WD_FAILED)
             || notTransitionFrom(oldStatus, SUCCESS, newStatus, PUB_READY, WD_READY)
             || notTransitionFrom(oldStatus, PUB_FAILED, newStatus, PUB_READY, WD_READY)
             || notTransitionFrom(oldStatus, WD_FAILED, newStatus, PUB_READY, WD_READY));
    }
    
    private static boolean bothNotSameOrNull(String oldStatus, String newStatus) {
        return !((oldStatus == null && newStatus == null) || (newStatus != null && newStatus.equals(oldStatus)));
    }
    
    private static boolean notTransitionFrom(String oldStatus, String oldValue, String newStatus, String allowed1, String allowed2) {
    	return oldValue.equals(oldStatus) && !(new Set<String>{allowed1, allowed2}).contains(newStatus);
    }
    
    protected override void beforeUpdate(){
        String errorMessageTemplate = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('ERROR_INVALID_PROCESSING_STATUS','Multichannel', 'Failed to process record due to invalid value for Processing_Status_vod. Old value is {0}. New value is {1}.');
    	checkForInvalidStatusTransitions(oldRecordsMap, newRecordsMap, errorMessageTemplate);
    }

    protected override void beforeDelete(){
        String deleteError = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('ERROR_CANNOT_DELETE_PUBLISHED_CONTENT', 'Multichannel', 'Content is published for this record. Please withdraw content before deleting.');
        for(Veeva_Distribution_vod__c v : oldRecords){
            if(v.CDN_Status_vod__c != null){
                if(v.CDN_Status_vod__c.equals('Published_vod')){
                	v.addError(deleteError);
            	}
            }
         }
    }
    
    private void handleUpsert(){
        List<ID> listOfVeevaDistributionIDs = new List<ID>();
        for(Veeva_Distribution_vod__c v : newRecords){
            if(v.Processing_Status_vod__c != null){
                if(v.Processing_Status_vod__c.equals(PUB_READY) ||  v.Processing_Status_vod__c.equals(WD_READY)){
                    listOfVeevaDistributionIDs.add(v.Id);
                }
            }
        }
        if(listOfVeevaDistributionIDs.size() > 0){
            VeevaDistributionTriggerHelper.sendRequestToServer(listOfVeevaDistributionIDs);
        }
    }
   
    public static void sendRequestToServer(List<ID> listOfVeevaDistributionIDs) {
        if (System.isFuture() || System.isBatch()) {
            sendRequestToServerNow(listOfVeevaDistributionIDs);
        } else {
            sendRequestToServerFuture(listOfVeevaDistributionIDs);
        }
    }
    
    @future (callout = true)
    public static void sendRequestToServerFuture(List<ID> listOfVeevaDistributionIDs){
        sendRequestToServerNow(listOfVeevaDistributionIDs);
    }
    
    public static void sendRequestToServerNow(List<ID> listOfVeevaDistributionIDs){
        List<Veeva_Distribution_vod__c> toPublishOrWithdraw = [Select Id, Processing_Status_vod__c FROM Veeva_Distribution_vod__c WHERE Id in :listOfVeevaDistributionIDs AND 
                                                               (Processing_Status_vod__c = :PUB_READY OR Processing_Status_vod__c = :WD_READY)];
        
        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main'); 
        String url = settings.CRM_CDN_Server_vod__c +'/api/v1/salesforce-integration/messages';
        String auth = VOD_EMBED_CONTROLLER.getSfdcAuth();
    	String sfSession = VOD_EMBED_CONTROLLER.getSfSession();
	    String sfEndpoint = VOD_EMBED_CONTROLLER.getSfEndpoint();
        
        
        // Building request 
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');

        // Need salesforce session, endpoint, request type and content-type headers
        req.setHeader('sfSession', sfSession);
        req.setHeader('sfEndpoint', sfEndpoint);
        req.setHeader('type', 'USER');
        req.setHeader('content-type', 'application/json');
        req.setHeader('version',settings.CRM_CDN_Version_vod__c);
        req.setEndpoint(url);
        req.setBody(createBodyForRequest(toPublishOrWithdraw));

        HttpResponse response = http.send(req);
        // handle response codes. 200 means Request Sent, >= 400 means Request Timeout
        if (response.getStatusCode() != 200) {
         	updateFailedRecords(toPublishOrWithdraw);
        }

    }
    
    public static void updateFailedRecords(List<Veeva_Distribution_vod__c> toPublishOrWithdraw){
        for(Veeva_Distribution_vod__c v: toPublishOrWithdraw){
            if(v.Processing_Status_vod__c.equals(PUB_READY)){
                v.Processing_Status_vod__c = PUB_FAILED;
                v.Status_Details_vod__c = 'Publish failed due to a connection issue';
            }
            else if(v.Processing_Status_vod__c.equals(WD_READY)){
                v.Processing_Status_vod__c = WD_FAILED;
                v.Status_Details_vod__c = 'Withdraw failed due to a connection issue';
            }
        }
        update toPublishOrWithdraw;
    }
    
    public static String createBodyForRequest(List<Veeva_Distribution_vod__c> toPublishOrWithdraw){
        JSONGenerator json = JSON.createGenerator(true);
        json.writeStartObject();
        json.writeFieldName('data');
        json.writeStartArray();
		
        for(Veeva_Distribution_vod__c v : toPublishOrWithdraw){
            json.writeStartObject();
            json.writeObjectField('id', v.Id);
            json.writeObjectField('processingStatus', v.Processing_Status_vod__c);
            json.writeEndObject();
        }
        json.writeEndArray();
        json.writeEndObject();

        // Get JSON string
        return json.getAsString();
    }
}