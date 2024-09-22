/**
* Component Name:      MSD_CORE_RedirectController
* Created By:          Focal CXM
* Description:         Server side controller for MSD_CORE_Redirect LWC
* Test Class:          MSD_CORE_RedirectControllerTest
*/
public without sharing class MSD_CORE_RedirectController {
    /**
    * Name         : getAccountLockStatus
    * return       : results
    * param        : userId
    * Description  : Method to check if logged in user eligibility is expired and account is locked
    */
    @AuraEnabled(Cacheable=true)
    public static Map<String,String> getAccountLockStatus(String userId){
        Map<String,String> results = new Map<String,String>();
        List<MSD_CORE_Eligibility__c> eligibility = [SELECT Id, MSD_CORE_Eligibility_Expired__c FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Payor__c =: userId];
        if(eligibility.size() > 0 && eligibility[0].MSD_CORE_Eligibility_Expired__c){
            results.put('siteName',MSD_CORE_MFRSitePageConfiguration.getSiteName('setting'));
            results.put('siteAPIName',MSD_CORE_MFRSitePageConfiguration.getSiteAPIName('setting'));
            results.put('accountStatus','Locked');
        }else{
            results.put('accountStatus','Unlocked');
        }
        
        System.debug(LoggingLevel.WARN,'pagenamedebuglog'+results);
        return results;
    }
    /**@description getNextDate 
     * @return eligibilitydate
    */
    @AuraEnabled(Cacheable=true)
    public static List<MSD_CORE_Eligibility__c> getNextDate(String userId){
        List<MSD_CORE_Eligibility__c> eligibilitydate = [SELECT Id,MSD_CORE_Last_Review_Date__c,MSD_CORE_Next_Review_Date__c,MSD_CORE_Eligibility_Expired__c FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Payor__c =: userId]; 
        return eligibilitydate;
    }
}