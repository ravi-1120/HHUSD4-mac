public class UserLocationController {

    @AuraEnabled(cacheable=true)
    public static String fetchCountryFromApex(Double latitude, Double longitude) {
        // Fetch API key only once
        MSD_CORE_AMOCountry__mdt mapsAPI = getCountryRestrictions();
        
        if (mapsAPI == null || String.isBlank(mapsAPI.API_Key__c)) {
            return 'Invalid API Key';
        }
        
        // Fetch country using the optimized getCountry method
        return getCountry(latitude, longitude, mapsAPI.API_Key__c);
    }

    @AuraEnabled(cacheable=true)
    public static MSD_CORE_AMOCountry__mdt getCountryRestrictions() {
        // Query custom metadata only once and use it in multiple methods
        return [SELECT AllowedCountries__c, API_Key__c 
                FROM MSD_CORE_AMOCountry__mdt 
                WHERE DeveloperName = 'Default_Restrictions' LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static String getCountry(Double latitude, Double longitude, String mapsAPIKey) {
        // Early exit if no API key
        if (String.isBlank(mapsAPIKey)) {
            return 'Invalid API Key';
        }
        
        String geocodingEndpoint = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=' + latitude + ',' + longitude + '&key=' + mapsAPIKey;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(geocodingEndpoint);
        request.setMethod('GET');

        try {
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                // Deserialize only the needed part of the JSON response
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<Object> resultsList = (List<Object>) responseBody.get('results');

                if (resultsList != null && !resultsList.isEmpty()) {
                    Map<String, Object> firstResult = (Map<String, Object>) resultsList[0];
                    List<Object> addressComponents = (List<Object>) firstResult.get('address_components');

                    for (Object component : addressComponents) {
                        Map<String, Object> addressComponent = (Map<String, Object>) component;
                        List<Object> typesList = (List<Object>) addressComponent.get('types');

                        // Check if 'country' is one of the types
                        if (typesList != null && typesList.contains('country')) {
                            return (String) addressComponent.get('long_name');
                        }
                    }
                }
            } else {
                return 'Geocoding API Error: ' + response.getStatusCode();
            }
        } catch (Exception e) {
            // Use better exception handling
            return 'Exception in Geocoding API: ' + e.getMessage();
        }

        return 'Invalid country';
    }
}