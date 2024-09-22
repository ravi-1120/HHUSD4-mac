@RestResource(urlMapping='/veeva/events-management/attendees/*')
global without sharing class VeevaAttendeeRestController {

    global class ChildAccountResponse extends VeevaBaseResponse {
        private final List<VeevaAttendeeService.SearchResult> data;

        private ChildAccountResponse(List<VeevaAttendeeService.SearchResult> searchResults) {
            this.data = searchResults;
        }
    }

    @HttpGet
    global static VeevaBaseResponse getChildAccounts() {
        Map<String, String> queryParams = RestContext.request.params;

        String stringIsCJK = queryParams.get('isCJK');

        Boolean isCJK = Boolean.valueOf(stringIsCJK) == null ? false : Boolean.valueOf(stringIsCJK);
        String name = queryParams.get('name');
        String configured = queryParams.get('configured');
        String city = queryParams.get('city');
        String state = queryParams.get('state');
        String zip = queryParams.get('zip');
        String configuredFieldName = queryParams.get('configuredFieldName');
        String searchOutsideTerrRecordTypes = queryParams.get('searchOutsideTerrRecordTypes');
        String searchOutsideTerrCountries = queryParams.get('searchOutsideTerrCountries');


        VeevaBaseResponse childAccountResponse;
        RestResponse response = RestContext.response;
        try {
            VeevaAttendeeService attendeeService = new VeevaAttendeeService();
            List<VeevaAttendeeService.SearchResult> searchResults = new List<VeevaAttendeeService.SearchResult>();
            searchResults = attendeeService.searchChildAccounts(isCJK, name, configured, city, state, zip, configuredFieldName, searchOutsideTerrRecordTypes, searchOutsideTerrCountries);
            childAccountResponse = new ChildAccountResponse(searchResults);
            response.statusCode = 200;
        } catch (Exception ex) {
            childAccountResponse = new VeevaBaseResponse('FAILURE', ex.getMessage());
            response.statusCode = 400;
        }
        return childAccountResponse;
    }
}