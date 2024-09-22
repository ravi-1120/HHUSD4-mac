/**
 * Component Name:      MSD_CORE_HEQ_PreviewController
 * Created By:          Ravi Modi (Focal CXM)
 * Created Date:        31th July 2024
 * @description:        Server side controller for hEQ_Preview LWC component
 * Test Class:          MSD_CORE_HEQ_PreviewControllerTest
 */

public without sharing class MSD_CORE_HEQ_PreviewController {
    
    private final String versionData;

    public class ResourceDataWrapper {
        @AuraEnabled
        public String message { get; set; }
        
        @AuraEnabled
        public ContentVersion contentVersion { get; set; }

        public ResourceDataWrapper(String message, ContentVersion contentVersion) {
            this.message = message;
            this.contentVersion = contentVersion;
        }
    }

    
    /**
     * Method Name  :   getVersionData
     * @description :   Use to get Resource VersionData 
     * @return      :   VersionData
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   5th August 2024
     */
    public String getVersionData() {
        return versionData;
    }
    
    /**
     * Method Name  :   getBusinessRule
     * @description :   Use to get BusinessRule
     * @return      :   BusinessRule
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   07th Aug 2024
     */
    // @AuraEnabled(cacheable=true)
    // public static MSD_CORE_Business_Rules__c getBusinessRule() {
    //     Group usergroup = [SELECT Id,Name, DeveloperName FROM Group WHERE Id IN (SELECT GroupId FROM GroupMember WHERE UserOrGroupId =: UserInfo.getUserId()) LIMIT 1];
    //     return [SELECT Id, Name, MSD_CORE_Can_Download__c, MSD_CORE_User_Group__c	 FROM MSD_CORE_Business_Rules__c WHERE MSD_CORE_User_Group__c =: usergroup.DeveloperName  LIMIT 1];
    // }

    /**
     * Method Name  :   getResourceData
     * @description :   Use to get Resource data
     * param        :   recordId 
     * @return      :   ContentVersion
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   30th July 2024
     */
    @AuraEnabled
    public static ResourceDataWrapper getResourceData(String recordId) {
        String userId = UserInfo.getUserId();
        try {
            ContentVersion cv = [
                SELECT Id, Title, FileType, ContentSize, ContentDocumentId, VersionData, MSD_CORE_Video_Resource__c 
                FROM ContentVersion 
                WHERE Id = :recordId AND MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false
                LIMIT 1
            ];

            user a = [SELECT AccountId, Profile.Name FROM User WHERE Id = :userId LIMIT 1];
            Id accountId = a.AccountId;

            if(a.Profile.Name == 'HEQ Customer'){
                userId =  accountId;
            }

            if (cv != null) {
                Integer linkCount = [
                    SELECT COUNT() 
                    FROM ContentDocumentLink 
                    WHERE LinkedEntityId = :userId 
                    AND ContentDocumentId = :cv.ContentDocumentId
                ];

                if (linkCount > 0) {
                    return new ResourceDataWrapper(null, cv);
                } else {
                    return new ResourceDataWrapper('Access denied', null);
                }
            } else {
                return new ResourceDataWrapper('Content not found', null);
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
            return new ResourceDataWrapper(e.getMessage(), null);
        }
    }
}