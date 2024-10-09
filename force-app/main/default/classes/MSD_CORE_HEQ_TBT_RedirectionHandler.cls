/**
* @File Name : MSD_CORE_HEQ_TBT_RedirectionHandler.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 2, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 2, 2024 |   | Initial Version
**/

public class MSD_CORE_HEQ_TBT_RedirectionHandler {

    @AuraEnabled(cacheable=true)
    public static String getRedirectURL(string templateId, string job_code) {
        string iframeUrl = 'https://tbt-dev.healtheq.com/personalized-resource/';
        templateId = 'aAQVC0000001MZZ4A2';
        job_code = 'US-JRC-864';
        iframeUrl += templateId + '/' + job_code;

        return iframeUrl;
    }

}