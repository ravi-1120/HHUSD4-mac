public inherited sharing class VeevaEngageService {
    private String sessionId;

    public VeevaEngageService() {
        this(SessionVod.getSessionId());
    }

    public VeevaEngageService(String sessionId) {
        this.sessionId = sessionId;
    }

    public Boolean updateEngageMeetingTimes(Id remoteMeetingId, Datetime startDate, Integer duration) {
        Remote_Meeting_vod__c remoteMeeting = [SELECT Id, Scheduled_DateTime_vod__c, Scheduled_vod__c, VExternal_Id_vod__c from Remote_Meeting_vod__c WHERE Id = :remoteMeetingId];
        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
        String crmUrl = settings.Veeva_Server_vod__c + '/' + settings.Veeva_Version_vod__c + '/api/v2/hcp-proxy/engage-meeting/meetings/';
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
        body.put('start', startDate);
        body.put('duration', duration);
        request.setBody(JSON.serialize(body));
        Boolean responseStatus = false;

        try {
            HttpResponse response = new Http().send(request);
            responseStatus = response.getStatusCode() == 200;
        } catch (CalloutException e) {
            System.debug(e);
        }
        return responseStatus;
    }

    @TestVisible
    public void updateEngageRemoteMeeting(Id remoteMeetingId, Boolean responseStatus, Map<String, String> result) {
        Remote_Meeting_vod__c remoteMeeting = [SELECT Id, Scheduled_DateTime_vod__c, Scheduled_vod__c, VExternal_Id_vod__c from Remote_Meeting_vod__c WHERE Id = :remoteMeetingId];
        if (responseStatus) {
            remoteMeeting.Scheduled_DateTime_vod__c = Datetime.now();
            remoteMeeting.Scheduled_vod__c = true;
            result.put('engageRemoteMeeting', 'success');
        } else {
            remoteMeeting.Scheduled_DateTime_vod__c = null;
            remoteMeeting.Scheduled_vod__c = false;
            result.put('engageRemoteMeeting', 'error');
        }
        update remoteMeeting;
    }
}