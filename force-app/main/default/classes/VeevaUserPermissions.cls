// THIS CLASS MUST BE DEPLOYED WITH API 25 OR HIGHER.
// While this class still builds and runs with API versions 22-24, the queries used only directly accesses the Profile's granted
// permissions when the API version is set to 25 or higher.

// See http://www.salesforce.com/us/developer/docs/api/Content/sforce_api_objects_permissionset.htm:
// In API version 25 and later, every profile is associated with a permission set that stores the profile’s user, object, and field permissions,
// as well as setup entity access settings. Permission sets that are owned by profiles can be queried but not modified.

// Salesforce enables in  permission-set assignment expiration in Winter ’23. For that reason, adding a new Rest Endpoint into the existing SOAP endpoint class.
// New method (getUserPermissions) returns minimum expiration date of PermissionSetAssignment and  list of ids (PermissionSetAssignment Ids + UserPackageLicense Ids).
// If there is no expiration date, it will return the expiration date as null.

@RestResource(urlMapping='/veeva/permissions/*')
global without sharing class VeevaUserPermissions{

    global class UserPermission {

        global Datetime expirationDate {get; set;}
        global List<String> ids {get; set;}
    }

    webService static List<String> listPermissionSets() {
        //This method returns BOTH Permission Set IDs and User Package License IDs
        final String assignee = UserInfo.getUserId();
        List<PermissionSetAssignment> assignments = getAssignments(assignee);

        List<UserPackageLicense> licenses = getLicenses(assignee);

        return combineAssignmentsAndLicenses(assignee, assignments, licenses);
    }

    webService static boolean checkPermission(final String permissionName) {
        final String assignee = UserInfo.getUserId();
        final String permissionColumnName = 'Permissions' + String.escapeSingleQuotes(permissionName);

        final String query = 'Select COUNT() FROM PermissionSet ' +
            'WHERE Id IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :assignee) AND ' +
            permissionColumnName + ' = true';

        // Return true if the user has at least one PermissionSet (including the profile's) that grants this permission
        try {
            return Database.countQuery(query) != 0;
        } catch(System.QueryException e) {
            return false;
        }
    }

    @HttpGet
    global static UserPermission getUserPermissions() {
        final String assignee = UserInfo.getUserId();

        List<PermissionSetAssignment> assignments = getAssignments(assignee);
        DateTime expirationDate = getExpirationDate(assignments);
        List<UserPackageLicense> licenses = getLicenses(assignee);

        UserPermission userPermission = new UserPermission();
        userPermission.expirationDate = expirationDate;
        userPermission.ids = combineAssignmentsAndLicenses(assignee, assignments, licenses);

        return userPermission;
    }

    private static List<PermissionSetAssignment> getAssignments(String assignee) {
        return [SELECT PermissionSetId, ExpirationDate FROM PermissionSetAssignment
            WHERE AssigneeId = :assignee
            ORDER BY PermissionSetId ASC];
    }

    private static List<UserPackageLicense> getLicenses(String assignee) {
        return [SELECT PackageLicenseId FROM UserPackageLicense
            WHERE UserId =: assignee
            ORDER BY PackageLicenseId ASC];
    }


    private static final String SF_CONTENT_USER_FIELD = 'UserPermissionsSFContentUser';

    //If UserPermissionsSFContentUser field exists in user object and set to true a string value (SFContentUser) is added
    //to the list of ids (PermissionSetAssignment Ids + UserPackageLicense Ids) being returned with listPermissionSets method.
    //This value helps differentiating two users with same permission sets and one of the users assigned with Salesforce CRM Content license.
    private static void checkAndAddSFContentUser(String assignee, List<String> result){
        User user;
        Map<String, Schema.SObjectField> userFieldMap = Schema.SObjectType.User.fields.getMap();
        //Hard coded reference to field results in deployment failure if the field does not exist, hence checking describe by name.
        String sfContentUserField = userFieldMap?.get(SF_CONTENT_USER_FIELD)?.getDescribe()?.getName();
        if(String.isNotBlank(sfContentUserField)){
            user = Database.Query('SELECT ' + sfContentUserField + ' FROM User WHERE Id =: assignee');
        }

        if(user != null && (boolean)user.get(sfContentUserField)) {
            result.add('SFContentUser');
        }
    }

    private static List<String> combineAssignmentsAndLicenses(String assignee, List<PermissionSetAssignment> assignments, List<UserPackageLicense> licenses) {
        List<String> result = new List<String>();

        for(PermissionSetAssignment assignment : assignments) {
            result.add(assignment.PermissionSetId);
        }

        for(UserPackageLicense license : licenses) {
            result.add(license.PackageLicenseId);
        }

        checkAndAddSFContentUser(assignee, result);

        return result;
    }

    private static Datetime getExpirationDate(List<PermissionSetAssignment> assignments) {
        DateTime earliestExpiration = null;
        List<DateTime> expirations = new List<DateTime>();
        for (PermissionSetAssignment assignment : assignments) {
            DateTime expiration = assignment.ExpirationDate;
            if (expiration != null) {
                expirations.add(expiration);
            }
        }
        if (expirations.size() > 0) {
            expirations.sort();
            earliestExpiration = expirations.get(0);
        }
        return earliestExpiration;

    }
}