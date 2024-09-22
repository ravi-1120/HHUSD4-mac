/**
 * REST Web service providing API access to retrieve a mapping of all visible User's Id -> ProfileId
 * Provides an alternative to direct querying if the User doesn't have a license that has permission to View Profile.
 * Partly supporting the ability to read custom settings as userB while logged in as userA.
 * Users requiring external access then need to have access to this Apex class.
 **/
@RestResource(urlMapping='/veeva/user-profiles')
global with sharing class VeevaUserProfileService {

    @HttpGet
    global static Map<String, String> getUserProfileIdMap() {
        Map<String, String> userProfileIdMap = new Map<String, String>();
        List<User> users = [SELECT Id, ProfileId FROM User];
        for(User user : users) {
            userProfileIdMap.put(user.Id, user.ProfileId);
        }
        return userProfileIdMap;
    }

}