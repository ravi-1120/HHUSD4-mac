public with sharing class VOD_EMBED_CONTROLLER {

    public String veevaModuleName {get;set;}

    public String veevaPageName {get;set;}

    public String veevaObjectType {get;set;}

    public String veevaParams {get; set;}

    public String recordType18Digit {get; set;}

    public String veevaMcEngine {get;set;}

    public String getTranslatedOk() {
        return VOD_VEEVA_MESSAGE.getMsgWithDefault('OK', 'Common', 'Ok');    
    }
    
    public String getTranslatedCancel() {
        return VOD_VEEVA_MESSAGE.getMsgWithDefault('CANCEL', 'Common', 'Cancel');
    }

    private static final List<String> LGT_RESKIN_MODULES = new List<String>{'call','em','ae','pl'};

    public VOD_EMBED_CONTROLLER(ApexPages.StandardController controller) {
    }

    public VOD_EMBED_CONTROLLER(ApexPages.StandardSetController controller) {
    }

    public VOD_EMBED_CONTROLLER() {
    }

    public String getLgtReskinClass() {
        String className = '';
        if (getLightningMode()) {
            className += 'veeva-lgtn';
            if (LGT_RESKIN_MODULES.contains(veevaModuleName)) {
                className += ' lgt-reskin';
            }
        }
        return className;
    }

    public Boolean getLightningMode() {
        String uiTheme = UserInfo.getUIThemeDisplayed();
        return uiTheme == 'Theme4d' || uiTheme == 'Theme4u';
    }

    public String getVodUrl () {
        // "Dev Mode": developers should be able to point any page to "localhost"
        String devModeUrl = getQueryParam('url');
        if (devModeUrl != null) {
			String prot = null;
			if (devModeUrl == 'local') {
				prot = 'http';
			} else if (getDevUrlsSet().contains(devModeurl)) {
				prot = 'https';
			}
			if (prot != null) {
				String port = getQueryParam('port');
				String version = getQueryParam('version');

				// Default to "8080" if the dev didn't specify a query parameter, or if the parameter doesn't contain only numeric characters
                if (port == null || !isValidNumber(port)) {
                    port = '8080';
                }
				// Default to "main" if the dev didn't specify a query parameter.
				if (version == null) {
					if(veevaMcEngine != null && veevaMcEngine.equals('true')) {
						version = 'multichannel';
					} else {
						version = 'main';
					}
				}

				String server = (devModeUrl == 'qa') ? '://qa.vod309.com' :
                    (devModeUrl == 'veevacrmqa') ? '://crm-app-us.veevacrmqa.com' :
                    (devModeUrl == 'locals' || devModeUrl == 'local') ? ('://localhost:' + port) :
                    '://localhost:8080';
				return prot + server + '/' + EncodingUtil.urlEncode(version, 'UTF-8');
			}
        }

        if(veevaMcEngine != null && veevaMcEngine.equals('true')) {
	        return getMcUrl();
        } else {
	        return VOD_Common.VOD_URL;
        }
    }

	private Boolean isValidNumber(String str) {
        return Pattern.matches('^[0-9]+$', str);
    }

	//for MC Engine
    public String getMcUrl(){
    	return Veeva_Common_vod__c.getValues('Main').Multichannel_Server_vod__c + '/' + Veeva_Common_vod__c.getValues('Main').Multichannel_Context_Root_vod__c;
   	}

    //for Anotes server
    public String getAnotesUrl(){
        Map <String, Object> fields = Veeva_Common_vod__c.getValues('Main').getPopulatedFieldsAsMap();
        if (fields.containsKey('Anotes_Server_vod__c')) {
            return fields.get('Anotes_Server_vod__c').toString();
        }
        return '';
    }

    public Integer getVodVersion() {
        String version = Veeva_Common_vod__c.getValues('Main').Veeva_Version_vod__c;
        return getVersion(version);
    }

    public Integer getMcVersion() {
        String version = Veeva_Common_vod__c.getValues('Main').Multichannel_Context_Root_vod__c;
        // check if version starts with 'mc' prefix
        if(version.startsWith('mc')) {
            return getVersion(version.substring(2));
        } else {
            return getVersion(version);
        }

    }

    private Integer getVersion(String version) {
        List<String> parts = version.split('\\.|\\-');
        if(parts.size() < 3) {
            // could be 'multichannel' or 'main' or some other context root
            // use a very large version (99.99.99) to represent the latest
        	return 999999;
        } else {
            // convert version string into a number: 24.0.1 => 240001
			Integer value = Integer.valueOf(parts[0] + zeroPad(parts[1]) + zeroPad(parts[2]));
            return value;
        }
    }

    private String zeroPad(String source) {
        if(source.length() == 1) {
            return '0' + source;
        }
        return source;
    }

    public String getStaticDir() {
        if(veevaMcEngine != null && veevaMcEngine.equals('true')) {
	        return '';
        } else {
	        return 'static/';
        }
    }

    public String getExtraFile() {
        if(veevaMcEngine != null && veevaMcEngine.equals('true')) {
	        return 'lib' + getMiniString() +'.js';
        } else {
	        return 'templates.js';
        }
    }

    public String getCssString() {
        if(veevaMcEngine != null && veevaMcEngine.equals('true')) {
	        return 'app.css';
        } else {
	        return 'app.min.css';
        }
    }

    public static String getMiniString() {
        // By default, use minified files in production.
        boolean useMinFiles = true;

        // When the developer turns on "Dev Mode", turn off minified files by default.
        if (getQueryParam('url') != null) {
            useMinFiles = false;

            // If the developer turns on "Dev Mode", he should be able to minify the files again.
            if (getQueryParam('min') == '1') {
                useMinFiles = true;
            }
        }

        return useMinFiles ? '.min' : '';
    }

    /**
     * Tiny helper method to grab the current VF page's query params.
     */
    private static String getQueryParam(String key) {
        return ApexPages.currentPage().getParameters().get(key);
    }

    public static String getSfSession() {
        return UserInfo.getSessionId();
    }

    public static String getSfEndpoint() {
        // crmdev overwrites client provided api versions with the server version
        return URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/54.0/' + UserInfo.getOrganizationId();
    }

    public static String getSfdcAuth() {
        Blob authHeader = Blob.valueOf(UserInfo.getUserName() + ':pwDoesntMatter');
        return 'Basic ' + EncodingUtil.base64Encode(authHeader);
    }

    public String getVeevaPageUrl() {
        return getVodUrl() + '/app/' + veevaModuleName + '/' + veevaPageName;
    }

    public String getUserId() {
        return UserInfo.getUserId();
    }

    public String getUserLocale() {
        return UserInfo.getLocale();
    }

    public String getUserLanguage() {
      return UserInfo.getLanguage();
    }

    public String getUserTimezone() {
        return UserInfo.getTimeZone().getID();
    }

    public String getOrgDomain() {
        return URL.getSalesforceBaseUrl().toExternalForm();
    }

    private Set<String> getDevUrlsSet() {
        if (devUrlsSet == null) {
            devUrlsSet = new Set<String>(devUrls);
        }
        return devUrlsSet;
    }

    private Set<String> devUrlsSet;

    private static List<String> devUrls = new String[]{'qa','veevacrmqa','locals'};
}