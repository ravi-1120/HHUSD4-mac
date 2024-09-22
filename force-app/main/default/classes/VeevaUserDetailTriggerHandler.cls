public without sharing class VeevaUserDetailTriggerHandler extends VeevaTriggerHandler {
    private List<User_Detail_vod__c> oldUserDetailList = new List<User_Detail_vod__c>();
    private List<User_Detail_vod__c> newUserDetailList = new List<User_Detail_vod__c>();
    private Map<ID, User_Detail_vod__c> oldUserDetailMap = new Map<ID, User_Detail_vod__c>();
    private Map<ID, User_Detail_vod__c> newUserDetailMap = new Map<ID, User_Detail_vod__c>();

    @testVisible protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newUserDetailList = (List<User_Detail_vod__c>) triggerNew;
        this.oldUserDetailList = (List<User_Detail_vod__c>) triggerOld;
        this.newUserDetailMap = (Map<ID, User_Detail_vod__c>) triggerNewMap;
        this.oldUserDetailMap = (Map<ID, User_Detail_vod__c>) triggerOldMap;
    }

    protected override String sObjectType() {
        return 'User_Detail_vod__c';
    }

    protected override void afterInsert() {
        groupNewUserDetailsAndPassToEngageConnect();
    }

    protected override void afterUpdate() {
        groupUpdateUserDetailsAndPassToEngageConnect();
    }

    private boolean isConnectCustomer() {
        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
        if (settings == null) {
            return false;
        }

        String url = settings.Engage_Connect_Server_vod__c;

        return url != null && url != '';
    }

    private void groupNewUserDetailsAndPassToEngageConnect() {
        if (isConnectCustomer()) {
            Set<ID> userDetailChange = filterInsertConnectRelevantUserDetails();

            if (userDetailChange.size() > 0) {
	            VeevaEngageConnectUserActions.passUserDetailsToConnectServer(userDetailChange);
            }
        }
    }

    private void groupUpdateUserDetailsAndPassToEngageConnect() {
        if (isConnectCustomer()) {
            Set<ID> userDetailChange = filterUpdateConnectRelevantUserDetails();

            if (userDetailChange.size() > 0) {
	            VeevaEngageConnectUserActions.passUserDetailsToConnectServer(userDetailChange);
            }
        }
    }

    @testVisible private Set<ID> filterInsertConnectRelevantUserDetails() {
        Set<ID> userDetailIds = new Set<ID>();

        for (User_Detail_vod__c userDetail : [SELECT ID, User_vod__r.isActive, User_vod__r.ID, User_vod__r.FirstName, User_vod__r.LastName, User_vod__r.Email,
                                              Digital_Business_Card_Phone_vod__c, Digital_Business_Card_Display_Name_vod__c, Digital_Business_Card_Title_vod__c
                                              FROM User_Detail_vod__c WHERE ID in :newUserDetailMap.keySet()]) {
            if (userDetail.User_vod__r.isActive && containsValidUserFields(userDetail) && insertContainsDigitalBusinessCardField(userDetail)) {
                userDetailIds.add(userDetail.Id);
            }
        }

        return userDetailIds;
    }

    @testVisible private Set<ID> filterUpdateConnectRelevantUserDetails() {
        Set<ID> userDetailIds = new Set<ID>();

        for (User_Detail_vod__c newUserDetail : [SELECT ID, User_vod__r.isActive, User_vod__r.ID, User_vod__r.FirstName, User_vod__r.LastName, User_vod__r.Email,
                                                 Digital_Business_Card_Phone_vod__c,Digital_Business_Card_Display_Name_vod__c, Digital_Business_Card_Title_vod__c
                                                 FROM User_Detail_vod__c WHERE ID in :newUserDetailMap.keySet()]) {
            User_Detail_vod__c oldUserDetail = oldUserDetailMap.get(newUserDetail.Id);
            if (newUserDetail.User_vod__r.isActive && containsValidUserFields(newUserDetail) && updateContainsDigitalBusinessCardFieldChange(oldUserDetail, newUserDetail)) {
                userDetailIds.add(newUserDetail.Id);
            }
        }

        return userDetailIds;
    }

    private boolean insertContainsDigitalBusinessCardField(User_Detail_vod__c userDetail) {
        return userDetail.Digital_Business_Card_Display_Name_vod__c != null ||
            userDetail.Digital_Business_Card_Phone_vod__c != null ||
            userDetail.Digital_Business_Card_Title_vod__c != null;
    }

    private boolean updateContainsDigitalBusinessCardFieldChange(User_Detail_vod__c oldUserDetail, User_Detail_vod__c newUserDetail) {
        return oldUserDetail.Digital_Business_Card_Display_Name_vod__c != newUserDetail.Digital_Business_Card_Display_Name_vod__c ||
            oldUserDetail.Digital_Business_Card_Phone_vod__c != newUserDetail.Digital_Business_Card_Phone_vod__c ||
            oldUserDetail.Digital_Business_Card_Title_vod__c != newUserDetail.Digital_Business_Card_Title_vod__c;
    }

    private boolean containsValidUserFields(User_Detail_vod__c userDetail) {
        return userDetail.User_vod__r.ID != null && userDetail.User_vod__r.FirstName != null && userDetail.User_vod__r.LastName != null
            && userDetail.User_vod__r.Email != null;
    }
}