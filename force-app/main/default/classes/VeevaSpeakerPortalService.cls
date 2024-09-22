public without sharing class VeevaSpeakerPortalService {

    private static final Integer MAX_SPEAKER_BATCH_SIZE = 500;
    private static final String SPEAKER_ENDPOINT = '/api/v1/speaker-portal/sf/speakers';
    private static final String SPEAKER_INVITATION_ENDPOINT = SPEAKER_ENDPOINT + '/invitation';

    public static final Map<String,String> SPEAKER_BODY_FIELD_MAP = new Map<String, String> {
        'Id' => 'id',
        'Speaker_Formatted_Name_vod__c' => 'speakerFormattedName',
        'Email_vod__c' => 'email',
        'Portal_Access_vod__c' => 'portalAccess',
        'Language_vod__c' => 'language'
    };

    public static void updateSpeakers(Map<ID,String> speakerToChangedFieldsMap) {
        if (System.isFuture() || System.isBatch()) {
            updateSpeakersNow(speakerToChangedFieldsMap);
        } else {
            updateSpeakersFuture(speakerToChangedFieldsMap);
        }
    }

    @future(callout=true)
    public static void updateSpeakersFuture(Map<ID,String> speakerToChangedFieldsMap) {
        updateSpeakersNow(speakerToChangedFieldsMap);
    }

    public static void updateSpeakersNow(Map<ID,String> speakerToChangedFieldsMap) {
        String url = VOD_Common.SPEAKER_PORTAL_SERVER + SPEAKER_ENDPOINT;
        Set<ID> speakerIds = speakerToChangedFieldsMap.keySet();
        List<EM_Speaker_vod__c> speakers = Database.query('SELECT ' + String.join(new List<String>(SPEAKER_BODY_FIELD_MAP.keySet()), ',')
                                                          + ' FROM EM_Speaker_vod__c WHERE Id IN :speakerIds');
        for (Integer i = 0; i < speakers.size(); i += MAX_SPEAKER_BATCH_SIZE) {
            List<EM_Speaker_vod__c> speakersSubList = getSubListSpeakers(speakers, i, Math.min(i+MAX_SPEAKER_BATCH_SIZE, speakers.size()));
            HttpRequest request = createRequest('PUT', url, createSpeakerUpdateBody(speakersSubList, speakerToChangedFieldsMap));
            new Http().send(request);
        }
    }

    private static String createSpeakerUpdateBody(List<EM_Speaker_vod__c> speakers, Map<ID,String> speakerToChangedFieldsMap) {
        List<Map<String,String>> body = new List<Map<String,String>>();
        for (EM_Speaker_vod__c speaker : speakers) {
            Map<String,String> speakerBody = new Map<String,String>();
            speakerBody.put(SPEAKER_BODY_FIELD_MAP.get('Id'), speaker.Id);
            for (String changedSpeakerField : speakerToChangedFieldsMap.get(speaker.Id).split(',')) {
                if (SPEAKER_BODY_FIELD_MAP.containsKey(changedSpeakerField)) {
                    speakerBody.put(SPEAKER_BODY_FIELD_MAP.get(changedSpeakerField), (String) speaker.get(changedSpeakerField));
                }
            }
            body.add(speakerBody);
        }
        return JSON.serialize(body);
    }

    public static void deleteSpeakers(Set<ID> speakerIds) {
        if (System.isFuture() || System.isBatch()) {
            deleteSpeakersNow(speakerIds);
        } else {
            deleteSpeakersFuture(speakerIds);
        }
    }

    @future(callout=true)
    public static void deleteSpeakersFuture(Set<ID> speakerIds) {
        deleteSpeakersNow(speakerIds);
    }

    public static void deleteSpeakersNow(Set<ID> speakerIds) {
        String url = VOD_Common.SPEAKER_PORTAL_SERVER + SPEAKER_ENDPOINT;

        List<ID> speakerIdsList = new List<ID>(speakerIds);
        for (Integer i = 0; i < speakerIdsList.size(); i += MAX_SPEAKER_BATCH_SIZE) {
            List<ID> speakerIdsSubList = getSubListIds(speakerIdsList, i, Math.min(i+MAX_SPEAKER_BATCH_SIZE, speakerIdsList.size()));
            HttpRequest request = createRequest('DELETE', url, createSpeakerIdsBody(speakerIdsSubList));
            new Http().send(request);
        }
    }

    public static void sendSpeakerInvitations(Set<ID> speakerIds) {
        if (System.isFuture() || System.isBatch()) {
            sendSpeakerInvitationsNow(speakerIds);
        } else {
            sendSpeakerInvitationsFuture(speakerIds);
        }
    }

    @future(callout=true)
    public static void sendSpeakerInvitationsFuture(Set<ID> speakerIds) {
        sendSpeakerInvitationsNow(speakerIds);
    }

    public static void sendSpeakerInvitationsNow(Set<ID> speakerIds) {
        Events_Management_Settings_vod__c emSettings = Events_Management_Settings_vod__c.getInstance();

        if (emSettings.ENABLE_SPEAKER_PORTAL_VOD__c == false) {
            return;
        }

        String url = VOD_Common.SPEAKER_PORTAL_SERVER + SPEAKER_INVITATION_ENDPOINT;

        List<ID> speakerIdsList = new List<ID>(speakerIds);
        for (Integer i = 0; i < speakerIdsList.size(); i += MAX_SPEAKER_BATCH_SIZE) {
            List<ID> speakerIdsSubList = getSubListIds(speakerIdsList, i, Math.min(i+MAX_SPEAKER_BATCH_SIZE, speakerIdsList.size()));
            HttpRequest request = createRequest('POST', url, createSpeakerIdsBody(speakerIdsSubList));
            new Http().send(request);
        }
    }

    private static HttpRequest createRequest(String method, String url, String body) {
        String sfSession = VOD_EMBED_CONTROLLER.getSfSession();
        String sfEndpoint = VOD_EMBED_CONTROLLER.getSfEndpoint();

        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setHeader('sfSession', sfSession);
        request.setHeader('sfEndpoint', sfEndpoint);
        request.setHeader('content-type', 'application/json');
        request.setEndpoint(url);
        request.setBody(body);

        return request;
    }

    private static String createSpeakerIdsBody(List<String> speakerIds) {
        Map<String,Object> body = new Map<String,Object>();
        body.put('ids', speakerIds);
        return JSON.serialize(body);
    }

    private static List<ID> getSubListIds(List<ID> values, Integer fromIndex, Integer toIndex) {
        List<ID> subList = new List<ID>();
        for (Integer i = fromIndex; i < toIndex; i++) {
            subList.add(values.get(i));
        }
        return subList;
    }

    private static List<EM_Speaker_vod__c> getSubListSpeakers(List<EM_Speaker_vod__c> values, Integer fromIndex, Integer toIndex) {
        List<EM_Speaker_vod__c> subList = new List<EM_Speaker_vod__c>();
        for (Integer i = fromIndex; i < toIndex; i++) {
            subList.add(values.get(i));
        }
        return subList;
    }
}