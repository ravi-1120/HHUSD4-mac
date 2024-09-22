/**
 * Component Name:      MSD_CORE_PreviewController
 * Created By:          Ravi Modi (Focal CXM)
 * Created Date:        31th July 2024
 * @description:        Server side controller for hEQ_Preview LWC component
 * Test Class:          MSD_CORE_PreviewControllerTest
 */

public without sharing class MSD_CORE_PreviewController {
    
    private final String versionData;
    
    public MSD_CORE_PreviewController() {
        String recordId = ApexPages.currentPage().getParameters().get('recordId');
        ContentVersion cv = [SELECT Id, VersionData FROM ContentVersion WHERE Id =: recordId LIMIT 1];       
        versionData = EncodingUtil.base64Encode(cv.VersionData);
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
    @AuraEnabled(cacheable=true)
    public static ContentVersion getResourceData(String recordId) {
        ContentVersion cv = new ContentVersion();
        try {
            List<ContentDocumentLink> cdlink = new List<ContentDocumentLink>();
            cv = [SELECT Id, Title, FileType, ContentSize, ContentDocumentId, VersionData, MSD_CORE_Video_Resource__c FROM ContentVersion WHERE Id =: recordId];
            if(cv != null) {
                cdlink = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =: Userinfo.getUserId() AND ContentDocumentId =: cv.ContentDocumentId];
                if(cdlink.size()>0){
                    return cv;
                } else {
                    return null;
                }
            } else {
                return null;
            }
        } catch (Exception e) {
            System.debug('Error>'+e.getMessage()+'>>'+e.getLineNumber());
            return null;
        }
    }
}