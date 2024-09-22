public without sharing class VeevaUserTriggerHandler extends VeevaTriggerHandler {
    private List<ID> usersForEngageServer = new List<ID>();
    private List<User> oldUsers = new List<User>();
    private List<User> newUsers = new List<User>();
    private Map<ID, User> oldUsersMap = new Map<ID, User>();
    private Map<ID, User> newUsersMap = new Map<ID, User>();

    @testVisible protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newUsers = (List<User>) triggerNew;
        this.oldUsers = (List<User>) triggerOld;
        this.newUsersMap = (Map<ID, User>) triggerNewMap;
        this.oldUsersMap = (Map<ID, User>) triggerOldMap;
    }

    protected override String sObjectType() {
        return 'User';
    }

    protected override void afterInsert() {
        groupNewUsersAndPassToEngageConnect();
        groupNewUsersAndPassToEngage();
    }

    protected override void beforeUpdate() {
        logUserObjectChanges();
    }

    protected override void afterUpdate() {
        disableMobileDeviceAccess();
        groupUpdateUsersAndPassToEngageConnect();
        groupUpdatedUsersAndPassToEngage();
    }

    private void logUserObjectChanges() {
        Map<String, Schema.SObjectField> userFields = Schema.SObjectType.User.fields.getMap();

        for (Integer i = 0; i < newUsers.size(); i++) {
            SObject oldUserObject = oldUsers.get(i);
            SObject newUserObject = newUsers.get(i);

            for (String fieldName : userFields.keySet()) {
                System.debug(fieldName);
                if (VEEVA_USER_SYNC_FIELDS.EXCLUDE_FIELDS.contains(fieldName.toLowerCase())) {
                    System.debug('Skipping field ' + fieldName + ' because it is explicitly excluded.');
                    continue;
                }

                Schema.SObjectField userField = userFields.get(fieldName);
                Schema.SoapType fieldType = userField.getDescribe().getSOAPType();
                if (fieldType == Schema.SoapType.ADDRESS || fieldType == Schema.SoapType.LOCATION) {
                    System.debug('Skipping field ' + fieldName + ' because it is of unuspported type ' + fieldType + '.');
                    continue;
                }

                if (oldUserObject.get(fieldName) != newUserObject.get(fieldName)) {
                    System.debug ('Field  :' + fieldName + ' has Changed. old:' + oldUserObject.get(fieldName) + ' new: ' + newUserObject.get(fieldName));
                    newUsers.get(i).Override_SystemModstamp_Timestamp_vod__c = System.now();
                    break;
                }

            }
        }
    }

    private boolean isConnectCustomer() {
        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
        if( settings == null ) {
            return false;
        }
        String url = settings.Engage_Connect_Server_vod__c;
        return url != null && url != '';
    }

    private void groupNewUsersAndPassToEngageConnect() {
        if (isConnectCustomer()) {
            Set<ID> groupChange = new Set<ID>();
            Set<ID> otherChange = new Set<ID>();
            if (filterConnectRelevantUsers(true, groupChange, otherChange)) {
	            VeevaEngageConnectUserActions.passUsersToConnectServer(groupChange, otherChange);
            }
        }
    }

    private void groupUpdateUsersAndPassToEngageConnect() {
        if (isConnectCustomer()) {
            Set<ID> groupChange = new Set<ID>();
            Set<ID> otherChange = new Set<ID>();
            if (filterConnectRelevantUsers(false, groupChange, otherChange)) {
	            VeevaEngageConnectUserActions.passUsersToConnectServer(groupChange, otherChange);
            }
        }
    }

    private void groupNewUsersAndPassToEngage() {
        for (integer i = 0; i < newUsers.size(); i++) {
            User changedUser = newUsers.get(i);
            //add to list if group request not equal to group and group request not null
            if (changedUser.Engage_Group_Request_vod__c != changedUser.Engage_Group_vod__c && changedUser.Engage_Group_Request_vod__c != null) {
                usersForEngageServer.add(changedUser.ID);
            }
        }
        //send to engage HA server
        if (usersForEngageServer.size() > 0) {
       	    VeevaEngageUserActions.passUsersToEngageServer(usersForEngageServer);
        }
    }

    private void groupUpdatedUsersAndPassToEngage() {
        for (integer i = 0; i < oldUsers.size(); i++) {
            //check each user and add to batch
            User changedUser = newUsers.get(i);
            if (userEngageGroupRequestOrProvisioningStatusCheck(oldUsers.get(i), changedUser)) {
                usersForEngageServer.add(changedUser.ID);
            }
        }
        //send to engage HA server
        if (usersForEngageServer.size() > 0) {
            VeevaEngageUserActions.passUsersToEngageServer(usersForEngageServer);
        }
    }

    private boolean userEngageGroupRequestOrProvisioningStatusCheck(User originalUser, User updatedUser) {
        return (originalUser.Engage_Group_Request_vod__c != updatedUser.Engage_Group_Request_vod__c
            || (updatedUser.Engage_Group_Provisioning_Status_vod__c == 'Retry_Request_vod' && originalUser.Engage_Group_Provisioning_Status_vod__c != updatedUser.Engage_Group_Provisioning_Status_vod__c))
            && updatedUser.Engage_Group_Request_vod__c != updatedUser.Engage_Group_vod__c;
    }

    private void disableMobileDeviceAccess() {
        List<Id> userIds = new List<Id>();
        // Handle for deactived User
        for (User user : newUsers) {
            if(user.IsActive == false || user.Mobile_CRM_App_Access_Disabled_vod__c == true) {
                // When user is deactivated
                userIds.add(user.Id);
            }
        }
        if(!userIds.isEmpty()) {
            // Insert with @future method
            VOD_MobileDeviceUtils.modifyMobileDeviceRecords(userIds);
        }
    }

    private String changedConnectRelevantFields(ID userId) {
        User oldUser = oldUsersMap.get(userId);
        User newUser = newUsersMap.get(userId);

        if (newUser.Engage_Connect_Group_Request_vod__c != oldUser.Engage_Connect_Group_Request_vod__c
            || newUser.Engage_Connect_Group_Status_vod__c == 'Retry_Request_vod') {
            	return 'group';
        } else if (oldUser.isActive != newUser.isActive) {
                return 'other';
        } else if (newUser.IsActive == true && (oldUser.FirstName != newUser.FirstName
                || oldUser.LastName != newUser.LastName
                || oldUser.Email != newUser.Email
                || oldUser.Country_Code_vod__c != newUser.Country_Code_vod__c
                || oldUser.User_Type_vod__c != newUser.User_Type_vod__c)) {
            	return 'other';
        }

        return null;
    }

    @testVisible private boolean filterConnectRelevantUsers(boolean isInsertEvent, Set<ID> groupChange, Set<ID> otherChange) {
        for (User newUser: newUsers) {
            if (isInsertEvent) {
                if (newUser.isActive) {
                    if (newUser.Engage_Connect_Group_Request_vod__c != null) {
                    	groupChange.add(newUser.Id);
                    } else {
                    	otherChange.add(newUser.Id);
                    }
                }
            }
            else {
                String delta = changedConnectRelevantFields(newUser.Id);

                if (delta == 'group') {
                    groupChange.add(newUser.Id);
                } else if (delta == 'other') {
                    otherChange.add(newUser.Id);
                }
            }
        }
        return groupChange.size() > 0 || otherChange.size() > 0;
    }
}