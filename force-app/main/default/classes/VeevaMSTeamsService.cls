public with sharing class VeevaMSTeamsService {
    private String sessionId;

    public VeevaMSTeamsService() {
        this(SessionVod.getSessionId());
    }

    public VeevaMSTeamsService(String sessionId) {
        this.sessionId = sessionId;
    }

    public Boolean updateMSTeamsRemoteMeeting(Remote_Meeting_vod__c remoteMeeting, Datetime startDate, Integer duration) {
        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
        String crmUrl = settings.Veeva_Server_vod__c + '/' + settings.Veeva_Version_vod__c + '/api/v1/hcp-proxy/engage-meeting/remote-meetings/';
        crmUrl += remoteMeeting.VExternal_Id_vod__c; 
        HttpRequest request = new HttpRequest();
        request.setEndpoint(crmUrl);
        request.setMethod('PUT');
        request.setHeader('Content-Type', 'application/json; charset=UTF-8');
        request.setHeader('Authorization', VOD_EMBED_CONTROLLER.getSfdcAuth());
        request.setHeader('sfSession', this.sessionId);
        request.setHeader('sfEndpoint', VOD_EMBED_CONTROLLER.getSfEndpoint());
        request.setTimeout(30000);

        Map<String, Object> body = new Map<String, Object>();
        String description = remoteMeeting.Meeting_Name_vod__c;
        if (description.length() > 256) {
            description = description.substring(0, 256);
        }
        body.put('description', description);
        body.put('scheduledStart', startDate);
        body.put('scheduledDurationMinutes', duration);
        request.setBody(JSON.serialize(body));

        try {
            HttpResponse response = new Http().send(request);
            return response.getStatusCode() == 200;
        } catch (CalloutException e) {
            return false;
        }
    }
}