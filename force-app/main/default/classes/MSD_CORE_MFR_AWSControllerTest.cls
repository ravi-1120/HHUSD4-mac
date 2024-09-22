@isTest
public with sharing class MSD_CORE_MFR_AWSControllerTest {


    @isTest
    public static void test1(){

        Test.startTest();

        MFR_Site__mdt mfr_Site = getSiteMedata('Content_Connector');
        MSD_CORE_MFR_AWSController.generateSingedURL('/133572_1_0_rendition_viewable_rendition__v.pdf');
        MSD_CORE_MFR_AWSController.loadContentConnectorDetails();

        Test.stopTest();
    }

    public static MFR_Site__mdt getSiteMedata(String devName) {
        MFR_Site__mdt mfrSite = [SELECT Id, CC_KEY_PAIR_ID__c ,CC_PRIVATE_KEY__c ,domainURL__c FROM MFR_Site__mdt LIMIT 1];
        mfrSite.DeveloperName = devName;
        return mfrSite;
    }
}