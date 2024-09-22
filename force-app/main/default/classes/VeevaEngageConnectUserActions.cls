public without sharing class VeevaEngageConnectUserActions {

    public static void passUsersToConnectServer(Set<ID> groupChange, Set<ID> otherChange) {
        if (System.isFuture() || System.isBatch()) {
            try {
                passUsersToConnectServerNow(groupChange, otherChange);
            } catch(Exception e) {
                System.debug(':::Failed to send Users to Engage Connect, cause: ' + e.getMessage());
            }
        } else {
            passUsersToConnectServerFuture(groupChange, otherChange);
        }
    }

    @future(callout=true)
    public static void passUsersToConnectServerFuture(Set<ID> groupChange, Set<ID> otherChange) {
        passUsersToConnectServerNow(groupChange, otherChange);
    }

    public static void passUsersToConnectServerNow(Set<ID> groupChange, Set<ID> otherChange) {
        List<User> users = [Select ID, FirstName, LastName, Email, IsActive, Engage_Connect_Group_Request_vod__c,
                            Country_Code_vod__c, User_Type_vod__c, Engage_Connect_Group_Status_vod__c
                            FROM User WHERE ID in :groupChange or ID in :otherChange];

        String requestBody = createBodyForUserConnectRequest(users);

        HttpResponse response = passDataToConnectServer(requestBody);

        if (response.getStatusCode() == 200) {
            setEngageConnectGroupProvisioningStatus(users, groupChange, 'Request_Sent_vod');
        } else {
            setEngageConnectGroupProvisioningStatus(users, groupChange, 'Request_Failed_vod');
        }
    }

    public static void passUserDetailsToConnectServer(Set<ID> detailsChanged) {
        if (System.isFuture() || System.isBatch()) {
            try {
                passUserDetailsToConnectServerFuture(detailsChanged);
            } catch(Exception e) {
                System.debug(':::Failed to send User_Detail_vod to Engage Connect, cause: ' + e.getMessage());
            }
        } else {
            passUserDetailsToConnectServerFuture(detailsChanged);
        }
    }

    @future(callout=true)
    public static void passUserDetailsToConnectServerFuture(Set<ID> detailsChange) {
        passUserDetailsToConnectServerNow(detailsChange);
    }

    public static void passUserDetailsToConnectServerNow(Set<ID> detailsChange) {
        List<User_Detail_vod__c> userDetails = [Select User_vod__r.Id, User_vod__r.FirstName, User_vod__r.LastName, User_vod__r.Email,
                                                User_vod__r.isActive, User_vod__r.Country_Code_vod__c, User_vod__r.User_Type_vod__c,
                                                Digital_Business_Card_Title_vod__c, Digital_Business_Card_Phone_vod__c, Digital_Business_Card_Display_Name_vod__c
                                                FROM User_Detail_vod__c WHERE ID in :detailsChange];

        String requestBody = createBodyForUserDetailsConnectRequest(userDetails);

        passDataToConnectServer(requestBody);
    }

    private static HttpResponse passDataToConnectServer(String jsonBody) {
        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
        String connectHost = settings.Engage_Connect_Server_vod__c;
        String url = connectHost + '/admin/sf/v2/org/users';
        String sfSession = VOD_EMBED_CONTROLLER.getSfSession();

        if (sfSession == null) {
            System.debug('No valid Salesforce Session found');
            HttpResponse response = new HttpResponse();
            response.setStatusCode(400);
            return response;
        }

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('sfSession', sfSession);
        req.setEndpoint(url);

        req.setBody(jsonBody);

        return http.send(req);
    }

    private static void setEngageConnectGroupProvisioningStatus(List<User> users, Set<ID> forIds, String status) {
        for(User user: users) {
            if (forIds.contains(user.ID)) {
	            user.Engage_Connect_Group_Status_vod__c = status;
            }
        }

        update users;
    }

    private static String createBodyForUserConnectRequest(List<User> users) {
        JSONGenerator json = JSON.createGenerator(true);

        json.writeStartObject();
        json.writeFieldName('users');
        json.writeStartArray();

        for (User user : users) {
            json.writeStartObject();

            json.writeObjectField('userId', user.ID);
            json.writeObjectField('firstName', user.FirstName != null ? user.FirstName : '');
            json.writeObjectField('lastName', user.LastName);
            json.writeObjectField('email', user.Email);
            json.writeObjectField('active', user.IsActive);
            json.writeObjectField('groupRequest', user.Engage_Connect_Group_Request_vod__c != null ? user.Engage_Connect_Group_Request_vod__c : '');
            json.writeObjectField('countryCode', user.Country_Code_vod__c != null ? user.Country_Code_vod__c : '');
            json.writeObjectField('userType', user.User_Type_vod__c != null ? user.User_Type_vod__c : '');

            json.writeEndObject();
        }

        json.writeEndArray();
        json.writeEndObject();

        //get JSON string
        return json.getAsString();
    }

    private static String createBodyForUserDetailsConnectRequest(List<User_Detail_vod__c> userDetails) {
        JSONGenerator json = JSON.createGenerator(true);

        json.writeStartObject();
        json.writeFieldName('users');
        json.writeStartArray();

        for (User_Detail_vod__c userDetail : userDetails) {
            String firstName = userDetail.User_vod__r.FirstName;
            String countryCode = userDetail.User_vod__r.Country_Code_vod__c;
            String userType = userDetail.User_vod__r.User_Type_vod__c;
            String title = userDetail.Digital_Business_Card_Title_vod__c;
            String phoneNumber = userDetail.Digital_Business_Card_Phone_vod__c;
            String displayName = userDetail.Digital_Business_Card_Display_Name_vod__c;

            json.writeStartObject();

            json.writeObjectField('userId', userDetail.User_vod__r.Id);
            json.writeObjectField('firstName', firstName != null ? firstName : '');
            json.writeObjectField('lastName', userDetail.User_vod__r.LastName);
            json.writeObjectField('email', userDetail.User_vod__r.Email);
            json.writeObjectField('active', userDetail.User_vod__r.isActive);
            json.writeObjectField('countryCode', countryCode != null ? countryCode : '');
            json.writeObjectField('userType', userType != null ? userType : '');
            json.writeObjectField('title', title != null ? title : '');
            json.writeObjectField('phoneNumber', phoneNumber != null ? phoneNumber : '');
            json.writeObjectField('displayName', displayName != null ? displayName : '');

            json.writeEndObject();
        }

        json.writeEndArray();
        json.writeEndObject();

        return json.getAsString();
    }

}