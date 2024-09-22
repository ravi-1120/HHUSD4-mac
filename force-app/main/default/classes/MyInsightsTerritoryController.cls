/**
 * REST Web service providing API access user assigned territories.
 **/
@RestResource(urlMapping='/veeva/territory/user-territory')
global with sharing class MyInsightsTerritoryController {

    @HttpGet
    global static List<Map<String,String>> getUserTerritories() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        Map<String, String> params = request.params;
        Boolean includeChildren = false;
        if (params != null && params.size() != 0 && params.containsKey('includeChildren')) {
            includeChildren = Boolean.valueOf(params.get('includeChildren'));
        }

        if (includeChildren) {
          return MyInsightsService.getUserTerritoryHierarchy();
        } else {
          return MyInsightsService.getUserTerritories();
        }
    }
}