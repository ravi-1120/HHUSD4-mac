public without sharing class VeevaEngageUserActions {

    public static void passUsersToEngageServer(List<ID> usersForEngage) {
        if (System.isFuture() || System.isBatch()) {
            passUsersToEngageServerNow(usersForEngage);
        } else {
            passUsersToEngageServerFuture(usersForEngage);
        }
    }
    
    @future(callout=true)
    public static void passUsersToEngageServerFuture(List<ID> usersForEngage) {
        passUsersToEngageServerNow(usersForEngage);
    }
    
    public static void passUsersToEngageServerNow(List<ID> usersForEngage) {
        List<User> usersForServer = [Select ID, Username, Engage_Group_Request_vod__c FROM User WHERE ID in :usersForEngage];
        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
        String url = settings.HCP_Server_vod__c + '/api/v1/salesforce-integration/messages';
        String auth = VOD_EMBED_CONTROLLER.getSfdcAuth();
    	String sfSession = VOD_EMBED_CONTROLLER.getSfSession();
	    String sfEndpoint = VOD_EMBED_CONTROLLER.getSfEndpoint();
    
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');

        //need salesforce session, endpoint, request type and content-type headers
        req.setHeader('sfSession', sfSession);
        req.setHeader('sfEndpoint', sfEndpoint);
        req.setHeader('type', 'USER');
        req.setHeader('content-type', 'application/json');
        req.setEndpoint(url);
        req.setBody(createBodyForEngageRequest(usersForServer));

        HttpResponse response = http.send(req);
        //handle response codes. 200 means Request Sent, >= 400 means Request Timeout
        if (response.getStatusCode() == 200) {
            setEngageGroupProvisioningStatus(usersForServer, 'Request_Sent_vod');
        } else {
            setEngageGroupProvisioningStatus(usersForServer, 'Request_Failed_vod');
        }
    }

    private static void setEngageGroupProvisioningStatus(List<User> usersForUpdate, String provisioningStatus) {
            //set provisioning status and update salesforce
            for (User user: usersForUpdate) {
                user.Engage_Group_Provisioning_Status_vod__c = provisioningStatus;
            }

            update usersForUpdate;
    }

    private static String createBodyForEngageRequest(List<User> usersForUpdate) {
        // Create a JSONGenerator object.
        // Pass true to the constructor for pretty print formatting.
        JSONGenerator json = JSON.createGenerator(true);

        //write data to the JSON String
        json.writeStartObject();
        json.writeFieldName('data');
        json.writeStartArray();
        
        //write user id and remote meeting group ids to data field
        for (User user : usersForUpdate) {
            json.writeStartObject();
            json.writeObjectField('username', user.Username);
            json.writeObjectField('salesforceUserId', user.ID);
            json.writeObjectField('remoteMeetingGroupName', user.Engage_Group_Request_vod__c != null ? user.Engage_Group_Request_vod__c : '');
            json.writeEndObject();
        }
        json.writeEndArray();
        json.writeEndObject();

        //get JSON string
        return json.getAsString();
    }
}