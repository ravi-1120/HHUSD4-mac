/**
 * Component Name: MSD_CORE_MerckSites
 * Created By: Focal CXM
 * Description: Serverside controller for mSD_CORE_OtherMerckSite LWC component
 * Test class : MSD_CORE_MerckSitesTest
 * @description MSD_CORE_MerckSites
 */
public with sharing class MSD_CORE_MerckSites {
       @AuraEnabled(cacheable=true)
        /**
        * @description getMerckSites
        * @return getMerckSites
        */
        public static List<MSD_CORE_OtherMercksites__mdt> getMerckSites(){
            List<MSD_CORE_OtherMercksites__mdt> merckSites =[SELECT Id,MSD_CORE_Description__c,	
            MSD_CORE_Header1__c,
            MSD_CORE_Header2__c,MSD_CORE_Header1_Index1__c,MSD_CORE_Header1_Index2__c,MSD_CORE_Site__c From  MSD_CORE_OtherMercksites__mdt];
            System.debug(LoggingLevel.WARN,'MerckSites');
            System.debug(LoggingLevel.WARN,MerckSites);
            return merckSites;
        }
    }