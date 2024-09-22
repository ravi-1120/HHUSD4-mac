public with sharing class VeevaMetricsController {
    /**
     * Determines the appropriate URL for Horus Metrics endpoint.
     * Bases decision on org's base Veeva server URL.
     */
    @AuraEnabled(cacheable=true)
    public static String getMetricUrl() {
        String veevaServerUrl = VOD_Common.VOD_SERVER_URL;
        String baseUrl = new URL(veevaServerUrl).getHost();

        // find second-level domain from baseUrl
        String domain = '';
        List<String> validDomains = new List<String>{'.veevacrmdev.com', '.veevacrmdi.com', '.veevacrmstage.com', '.veevacrmdemo.com', '.veevacrmqa.com', '.veevacrm.com'};
        for(Integer i = 0; i < validDomains.size(); i++) {
            if(baseUrl.endsWith(validDomains.get(i))) {
                domain = validDomains.get(i);
                break;
            }
        }
        
        // did not find valid domain
        if (String.isEmpty(domain)) {
            return null;
        }

        // find region from baseUrl
        String region = '';
        List<String> regions = new List<String>{'us', 'eu', 'ap'};
        for (Integer i = 0; i < regions.size(); i++) {
            if (baseUrl.contains('-' + regions.get(i))) {
                region = regions.get(i);
                break;
            }
        }
        
        // determine if we need the rel tag in the endpoint if qa server
        String rel = '';
        if (domain.endsWith('veevacrmqa.com') && baseUrl.contains('-rel-')) {
            rel = 'rel-';
        }
        
        return formatUrl(rel, region, domain);
    }
    
    private static String formatUrl(String rel, String region, String domain) {
        return String.format('https://horus-{0}collector-{1}{2}/api/v1/observations', new String []{rel, region, domain});
    }
}