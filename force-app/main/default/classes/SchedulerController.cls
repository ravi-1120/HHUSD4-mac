/*
    Created by -  RK Koluri
    Description - Controller class to query existing Schedulers and to create new Source Link or iFrame
*/
public with sharing class SchedulerController {

    @AuraEnabled
    public static Map<String,SiteDetail> getSchedulerLink(Id schedulerId, String type){
        try {
            Map<String,SiteDetail> siteDetailMap=new Map<String,SiteDetail>();

            Site sObj2 = [select Id from Site where Name = 'AMO' LIMIT 1];
            SiteDetail sdObj2 = [select SecureURL from SiteDetail where DurableId =: sObj2.Id LIMIT 1];

            Scheduler_Configuration__c scObj = new Scheduler_Configuration__c(Id = schedulerId);
            if(type == 'source'){
                scObj.IFrame_Source_Link__c = sdObj2.SecureURL.removeEnd('vforcesite')+'?schedulerId='+schedulerId;
            }else if(type == 'iframe'){
                scObj.IFrame_Source_Link__c ='<iframe src='+'\"'+sdObj2.SecureURL.removeEnd('vforcesite')+'?schedulerId='+schedulerId+'\"'+'></iframe>';
            }

            update scObj;
            siteDetailMap.put('exp',sdObj2);
            return siteDetailMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}