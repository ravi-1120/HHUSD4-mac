public with sharing class VeevaUserInterfaceAPI {
    @testVisible
    private final static List<String> ALLOWED_PATHS = new List<String>{
        '/ui-api/actions/record',
        '/ui-api/layout',
        '/ui-api/lookups',
        '/ui-api/object-info',
        '/ui-api/records',
        '/ui-api/record-defaults',
        '/ui-api/related-list-info',
        '/ui-api/nav-items',
        '/ui-api/list-ui',
        '/ui-api/list-info',
        '/ui-api/list-records',
        '/ui-api/mru-list-info',
        '/ui-api/mru-list-records',
        '/search/layout',
        '/sobjects'
    };

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getInfo(String path) {
        return request(path);
    }

    @AuraEnabled
    public static Map<String, String> getData(String path) {
        return request(path);
    }

    private static Map<String, String> request(String path) {
        Boolean isValid = false;

        for (String allowedPath : VeevaUserInterfaceAPI.ALLOWED_PATHS) {
            if (path.startsWith(allowedPath)) {
                isValid = true;
                break;
            }
        }

        if (!isValid) {
            String exceptionMessage = 'Access to ' + path + ' is not allowed.';
            AuraHandledException e = new AuraHandledException(exceptionMessage);
            e.setMessage(exceptionMessage);
            throw e;
        }

        String session = SessionVod.getSessionId();
        Map<String, String> result = new Map<String, String>();
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(System.URL.getOrgDomainUrl().toExternalForm() + '/services/data/v57.0' + path);
        request.setMethod('GET');
        request.setHeader('Authorization', 'OAuth ' + session);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('X-Chatter-Entity-Encoding', 'false');
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            result.put('data', response.getBody());
        } else {
            result.put('errorData', response.getBody());
            result.put('errorStatus', response.getStatus());
        }
        return result;
    }
}