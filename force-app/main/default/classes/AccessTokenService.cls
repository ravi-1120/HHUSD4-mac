@RestResource(urlMapping='/veeva/AccessToken/*')
global with sharing class AccessTokenService {

    @HttpPost
    global static String getAccessToken(){
        Map<String, Object> queryParams = (Map<String, Object>)JSON.deserializeUntyped(RestContext.request.requestBody.toString());
        String authIdentifier = (String)queryParams.get('authIdentifier');
        String providerName = (String)queryParams.get('providerName');
        String oldToken = (String)queryParams.get('oldToken');

        RestResponse restResponse = RestContext.response;

        List<AuthProvider> providers = [Select Id from AuthProvider Where DeveloperName = :authIdentifier LIMIT 1];
        if (providers.size() < 1) {
            restResponse.statusCode = 400;
            return 'No Auth Providers found. Please confirm that you are using the DeveloperName of an existing Auth Provider.';
        }
        String providerId = providers.get(0).Id;

        String result = '';
        try {
            if (String.isBlank(oldToken)) {
                result = Auth.AuthToken.getAccessToken(providerId, providerName);
            } else {
                Map<String, String> refreshResponse = Auth.AuthToken.refreshAccessToken(providerId, providerName, oldToken);
                String refreshError = refreshResponse.get('RefreshError');
                if (refreshError == null) {
                    result = refreshResponse.get('AccessToken');
                } else {
                    restResponse.statusCode = 400;
                    result = refreshError;
                }
            }
            if (String.isBlank(result)) {
                restResponse.statusCode = 400;
                result = 'No access token found. This can be caused by an incorrect provider name. Please confirm that the provider name is correct.';
            }
        } catch (Exception e) {
            restResponse.statusCode = 400;
            result = e.getMessage();
        }
        return result;
    }
}