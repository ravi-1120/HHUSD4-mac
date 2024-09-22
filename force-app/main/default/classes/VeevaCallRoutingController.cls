public with sharing class VeevaCallRoutingController {

    private static String CALL_OBJECT = 'Call2_vod__c';
    private static String ENABLE_CRM_DESKTOP_OVERRIDE_FIELD = 'Enable_CRM_Desktop_Override_vod__c';

    public String veevaModuleName {get;set;}

    public String veevaPageName {get;set;}

    public String veevaObjectType {get;set;}

    public String veevaParams {get; set;}

    public VeevaCallRoutingController(ApexPages.StandardController controller) {
    }

    public VeevaCallRoutingController() {
    }

    public boolean getEnableDesktopCall() {
        return getCRMDesktopObjectList().contains(CALL_OBJECT);
    }

    public boolean getIsDesktopCallMode() {
        return getEnableDesktopCall();
    }

    public boolean getNotDesktopCallMode() {
        return !getEnableDesktopCall();
    }

    public String getEngageUrl(){
        return Veeva_Common_vod__c.getValues('Main').Engage_Url_Prefix_vod__c + '/d.html';
    }

    private List<String> getCRMDesktopObjectList() {
        // CRM-321721 Unsupported feature: Allow setting override for Enable_CRM_Desktop in an optional field of the User object
        VeevaBaseObject user = VeevaBaseObject.create('User');
        if( user != null ) {
            SObjectField crmDesktopOverrideField = user.getField(ENABLE_CRM_DESKTOP_OVERRIDE_FIELD);
            if( crmDesktopOverrideField != null ) {
                Id userId = UserInfo.getUserId();
                String userQuery = 'SELECT ' + ENABLE_CRM_DESKTOP_OVERRIDE_FIELD + ' FROM User WHERE Id = :userId';
                SObject currentUser = Database.query(userQuery);
                String crmDesktopOverride = (String) currentUser?.get(ENABLE_CRM_DESKTOP_OVERRIDE_FIELD);
                if( !String.isBlank(crmDesktopOverride) ) {
                    return crmDesktopOverride.split(',');
                }
            }
        }

        Veeva_Settings_vod__c settings = Veeva_Settings_vod__c.getInstance();
        if (settings == null || settings.Enable_CRM_Desktop_vod__c == null) {
            return new List<String>();
        }
        List<String> crmDesktopObjectList = settings.Enable_CRM_Desktop_vod__c.split(',');
        if(crmDesktopObjectList == null){
            crmDesktopObjectList = new List<String>();
        }
        return crmDesktopObjectList;
    }
}