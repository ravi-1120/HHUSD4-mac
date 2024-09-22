public with sharing class DataGridLoaderController {
    public DataGridLoaderController(ApexPages.StandardController controller) {
    }

    public DataGridLoaderController(ApexPages.StandardSetController controller) {
    }
    public DataGridLoaderController() {
    }

    public String getEngageUrl() {
       return Veeva_Common_vod__c.getValues('Main').Engage_Url_Prefix_vod__c + '/d.html';
    }
}