@RestResource(urlMapping='/veeva/events-management/v2/attendees/*')
global without sharing class VeevaAttendeeRestControllerV2 {
    public VeevaAttendeeRestControllerV2() {}

    global class AttendeeResponse extends VeevaBaseResponse {
        private final List<EmOutsideTerritorySearch.OutsideSearchResult> data;

        private AttendeeResponse(List<EmOutsideTerritorySearch.OutsideSearchResult> searchResults) {
            this.data = searchResults;
        }

        public List<EmOutsideTerritorySearch.OutsideSearchResult> getData() { return this.data; }
    }

    @HttpGet
    global static VeevaBaseResponse getAttendees() {
        Map<String, String> queryParams = RestContext.request.params;

        String searchTerm = queryParams.get('searchTerm');
        String fields = queryParams.get('fields');
        String viewId = queryParams.get('viewId');
        String orderBy = queryParams.get('orderBy');
        String orderDirection = queryParams.get('orderDirection');
        String qLimit = queryParams.get('qLimit');
        String offset = queryParams.get('offset');
        String includeChildAccounts = queryParams.get('includeChildAccounts');
        String searchOutsideTerrRecordTypes = queryParams.get('searchOutsideTerrRecordTypes');
        String searchOutsideTerrCountries = queryParams.get('searchOutsideTerrCountries');

        List<String> recordTypes = parseListString(searchOutsideTerrRecordTypes);
        List<String> countries = parseListString(searchOutsideTerrCountries);
        List<String> fieldsToQuery = parseListString(fields);
        Boolean performChildAccountSearch = String.isNotBlank(includeChildAccounts) ? Boolean.valueOf(includeChildAccounts) : false;
        Integer qLimitNum = String.isNotBlank(qLimit) ? Integer.valueOf(qLimit) : 52;
        Integer offsetNum = String.isNotBlank(offset) ? Integer.valueOf(offset) : 0;

        EmAttendeeSelection.EmOutsideTerritoryRule ootRule = getOotRule(recordTypes, countries);

        VeevaBaseResponse response;
        RestResponse restResponse = RestContext.response;
        try {
            List<EmOutsideTerritorySearch.OutsideSearchResult> results = performChildAccountSearch ?
                EmOutsideTerritorySearch.getChildAccounts(searchTerm, fieldsToQuery, viewId, orderBy, orderDirection, qLimitNum, offsetNum, ootRule, true) :
                EmOutsideTerritorySearch.getAttendees(searchTerm, fieldsToQuery, viewId, orderBy, orderDirection, qLimitNum, offsetNum, ootRule, true, true);

            response = new AttendeeResponse(results);
            restResponse.statusCode = 200;
        } catch (Exception ex) {
            response = new VeevaBaseResponse('FAILURE', ex.getMessage());
            restResponse.statusCode = 400;
        }
        return response;
    }

    private static List<String> parseListString(String param) {
        return String.isNotBlank(param) ? param.split(',') : new List<String>();
    }

    private static EmAttendeeSelection.EmOutsideTerritoryRule getOotRule(List<String> recordTypes, List<String> countries) {
        EmAttendeeSelection.EmOutsideTerritoryRule ootRule = new EmAttendeeSelection.EmOutsideTerritoryRule();
        ootRule.enabled = true;
        ootRule.recordTypeDeveloperNames = recordTypes;
        ootRule.countryCodes = countries;
        return ootRule;
    }
}