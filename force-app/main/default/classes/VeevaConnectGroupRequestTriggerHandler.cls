public with sharing class VeevaConnectGroupRequestTriggerHandler extends VeevaTriggerHandler {
    private List<Engage_Connect_Group_Request_vod__c> groupRequests = new List<Engage_Connect_Group_Request_vod__c>();

    protected override String sObjectType() {
        return 'Engage_Connect_Group_Request_vod__c';
    }

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.groupRequests = (List<Engage_Connect_Group_Request_vod__c>) triggerNew;
    }

    protected override void beforeInsert() {
        stripPoundSignFromHexCodes(this.groupRequests);
        stampInProcess(this.groupRequests);
    }

    protected override void beforeUpdate() {
        stripPoundSignFromHexCodes(this.groupRequests);
        stampInProcess(this.groupRequests);
    }

    protected override void afterInsert() {
        callEngageConnectGroupCreation();
    }

    protected override void afterUpdate() {
        callEngageConnectGroupCreation();
    }

    private void stripPoundSignFromHexCodes(List<Engage_Connect_Group_Request_vod__c> requests) {
        for (Engage_Connect_Group_Request_vod__c request : requests) {
            if (request.Primary_Color_vod__c != null) {
                request.Primary_Color_vod__c = request.Primary_Color_vod__c.remove('#');
            }
            if (request.Secondary_Color_vod__c != null) {
                request.Secondary_Color_vod__c = request.Secondary_Color_vod__c.remove('#');
            }
        }
    }

    private void stampInProcess(List<Engage_Connect_Group_Request_vod__c> requests) {
        for (Engage_Connect_Group_Request_vod__c request : requests) {
            if (String.isEmpty(request.Processing_Status_vod__c)) {
                request.Processing_Status_vod__c = 'In_Process_vod';
            }
        }
    }

    private static List<ID> toIdList(List<Engage_Connect_Group_Request_vod__c> groupRequests) {
        List<ID> ids = new List<ID>();
        for (Engage_Connect_Group_Request_vod__c g: groupRequests) {
            ids.add(g.ID);
        }
        return ids;
    }

    @TestVisible
    private static String buildGroupRequestPayload(List<Engage_Connect_Group_Request_vod__c> groups) {
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartObject();
        gen.writeFieldName('groups');
        gen.writeStartArray();
        for (Engage_Connect_Group_Request_vod__c gr : groups) {
            serializeGroupRequest(gen, gr);
        }
        gen.writeEndArray();
        gen.writeEndObject();
        return gen.getAsString();
    }

    @TestVisible
    private static void serializeGroupRequest(JSONGenerator gen, Engage_Connect_Group_Request_vod__c gr) {
        gen.writeStartObject();

        Map<String, Object> fields = gr.getPopulatedFieldsAsMap();
        for (String fieldName: fields.keySet()) {
            if (fields.get(fieldName) != null) {
                gen.writeStringField(fieldName, fields.get(fieldName).toString());
            }
        }

        gen.writeEndObject();
    }

    private void callEngageConnectGroupCreation() {
        if (System.isFuture() || System.isBatch()) {
            callEngageConnectGroupCreationNow(toIdList(this.groupRequests));
        } else {
            callEngageConnectGroupCreationFuture(toIdList(this.groupRequests));
        }
    }

    @future(callout=true)
    public static void callEngageConnectGroupCreationFuture(List<ID> groupRequestIds) {
        callEngageConnectGroupCreationNow(groupRequestIds);
    }

    public static void callEngageConnectGroupCreationNow(List<ID> groupRequestIds) {
        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');

        // If no Engage Connect Server is set up, exit.
        if (settings == null || settings.Engage_Connect_Server_vod__c == null) return;

        Set<String> fieldNames = Engage_Connect_Group_Request_vod__c.sObjectType.getDescribe().fields.getMap().keySet();
        Map<Id, Engage_Connect_Group_Request_vod__c> groupRequests = new Map<Id, Engage_Connect_Group_Request_vod__c>(
            (Engage_Connect_Group_Request_vod__c[])Database.queryWithBinds(
            String.format(
                'SELECT {0} FROM Engage_Connect_Group_Request_vod__c WHERE Id IN :groupRequestIds ' +
                'AND Processing_Status_vod__c = \'In_Process_vod\'',
                new List<String>{String.join(new List<String>(fieldNames), ',')}),
            new Map<String, Object>{'groupRequestIds' => groupRequestIds},
            AccessLevel.SYSTEM_MODE
        ));

        if (groupRequests.isEmpty()) {
            // If there are no requests, we're done.
            return;
        }

        String connectHost = settings.Engage_Connect_Server_vod__c;
        String url = connectHost + '/admin/sf/v1/org/sf-group-requests';
        String sfSession = VOD_EMBED_CONTROLLER.getSfSession();

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('sfSession', sfSession);
        req.setEndpoint(url);
        String groupReqsJson = buildGroupRequestPayload(groupRequests.values());
        // System.debug(groupReqsJson);
        req.setBody(groupReqsJson);

        // Raise the request timeout to 50s. The EC api
        // returns 502 at 60s, so we want to cause the timeout
        // before that so we can write a more useful error.
        req.setTimeout(50000);

        HttpResponse response = null;
        try {
           response = http.send(req);
        } catch (CalloutException e) {
            stampErrorToAllAndUpdate(groupRequests.values(), e.getMessage());
            return;
        }

        // If not a 2XX response, stamp the code to all records
        if (response.getStatusCode() / 100 != 2) {
            String errCode = String.valueOf(response.getStatusCode());
            stampErrorToAllAndUpdate(groupRequests.values(), errCode);
            return;
        }


        List<Object> resGroups = null;
        try {
            Map<String, Object> rawJson = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            resGroups = (List<Object>) rawJson.get('groups');
            // If resGroups is null, raise the exception now, rather than in the for loop
            resGroups.size();
        } catch(Exception e) {
            // This is either JSONException if the JSON is malformed
            // or it is a NullPointerException if 'groups' is missing.
            // Stamp the JSON response to all items.
            stampErrorToAllAndUpdate(groupRequests.values(), response.getBody());
            return;
        }

        List<Engage_Connect_Group_Request_vod__c> ecUpdatedRequests = new List<Engage_Connect_Group_Request_vod__c>();
        for (Object rawResg : resGroups) {
            Map<String, Object> resg = (Map<String, Object>) rawResg;
            String itemJson = JSON.serialize(rawResg);

            String status = (String) resg.get('status');
            String corrId = (String) resg.get('correlationId');
            if (corrId == null) {
                // If we don't know the correlationId, then we can't stamp anything.
                continue;
            }

            Engage_Connect_Group_Request_vod__c gr = groupRequests.get(corrId);

            switch on status {
                when 'SUCCESS' {
                    String externalId = (String) resg.get('externalId');
                    stampSuccess(gr, externalId);
                }
                when 'ERROR' {
                    String errorMessage = (String) resg.get('errorMessage');
                    if (String.isEmpty(errorMessage)) {
                        errorMessage = itemJson;
                    }
                    stampError(gr, errorMessage);
                }
                when else {
                    // If we don't know the status, stamp failure and the raw json
                    stampError(gr, itemJson);
                }
            }
            ecUpdatedRequests.add(gr);
        }
        update ecUpdatedRequests;
    }

    private static void stampSuccess(Engage_Connect_Group_Request_vod__c gr, String externalId) {
        gr.Processing_Status_vod__c = 'Success_vod';
        gr.Error_Description_vod__c = null;
        gr.External_Id_vod__c = externalId;
    }

    private static void stampError(Engage_Connect_Group_Request_vod__c gr, String errorMessage) {
        gr.Processing_Status_vod__c = 'Failure_vod';
        gr.Error_Description_vod__c = errorMessage;
    }

    private static void stampErrorToAllAndUpdate(List<Engage_Connect_Group_Request_vod__c> groupRequests, String errorMessage) {
        for (Engage_Connect_Group_Request_vod__c g : groupRequests) {
            stampError(g, errorMessage);
        }
        update groupRequests;
    }
}