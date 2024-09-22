@RestResource(urlMapping='/veeva/events-management/speakers/*')
global with sharing class EmSpeakerController {

    private class EmSpeaker {
        private String Id;

        private EmSpeaker(EM_Speaker_vod__c speaker) {
            this.Id = speaker.Id;
        }
    }

    global class EmSpeakersResponse extends VeevaBaseResponse {
        private final List<EmSpeaker> data;

        private EmSpeakersResponse(List<EM_Speaker_vod__c> speakers) {
            this.data = getEmSpeakersForResponse(speakers);
        }
    }

    @HttpGet
    global static VeevaBaseResponse getSpeakerIds() {
        Map<String, String> queryParams = RestContext.request.params;
        String searchTerm = queryParams.get('searchTerm');
    	String trainingsString = queryParams.get('trainings');
        String servicesString = queryParams.get('services');
        String statusString = queryParams.get('status');
        String tierString = queryParams.get('tier');
        String orderBy = queryParams.get('orderBy');
        String orderDirection = queryParams.get('orderDirection');
        List<String> fields = new List<String>{'Id'};
		List<String> trainings = parseListString(trainingsString);
        List<String> services = parseListString(servicesString);
        List<String> status = parseListString(statusString);
        List<String> tier = parseListString(tierString);
        Integer qLimit = 2000;
        Integer offset = 0;

        VeevaBaseResponse speakersResponse;
        RestResponse response = RestContext.response;
        try {
            List<EM_Speaker_vod__c> speakers;
            if (String.isBlank(searchTerm)) {
            	speakers = EmSpeakerSelection.querySpeakers(fields, services, trainings, status, tier, orderBy, orderDirection, qLimit, offset);
        	} else {
            	speakers = EmSpeakerSelection.searchSpeakers(searchTerm, fields, services, trainings, status, tier, orderBy, orderDirection, qLimit, offset);
        	}
            speakersResponse = new EmSpeakersResponse(speakers);
            response.statusCode = 200;
        } catch (Exception ex) {
            speakersResponse = new VeevaBaseResponse('FAILURE', ex.getMessage());
            response.statusCode = 400;
        }
        return speakersResponse;
    }

    private static List<String> parseListString(String param) {
        if (String.isNotBlank(param)) {
            return param.split(',');
        }
        return new List<String>();
    }

    private static List<EmSpeaker> getEmSpeakersForResponse(List<EM_Speaker_vod__c> speakers) {
        List<EmSpeaker> emSpeakerObjects = new List<EmSpeaker>();
        for (EM_Speaker_vod__c speaker : speakers) {
            emSpeakerObjects.add(new EmSpeaker(speaker));
        }
        return emSpeakerObjects;
    }
}