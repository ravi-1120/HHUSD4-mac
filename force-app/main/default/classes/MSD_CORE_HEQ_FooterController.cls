/**
* Component Name:      MSD_CORE_HEQ_FooterController
* Created By:          Shravan (Focal CXM)
* Created Date:        7th Sep 2024
* @description:        This class fetches the footer configuration data and returns back to HealthEQ portal
* Test Class:          MSD_CORE_HEQ_FooterControllerTest
*/

public with sharing class MSD_CORE_HEQ_FooterController {

    @AuraEnabled(cacheable=true)
    public static FooterDataWrapper getFooterConfig() {
        try {
            List<MSD_CORE_HEQ_Footer_Config__mdt> footerConfigs = [
                SELECT DeveloperName, Label, MSD_CORE_Display_On_UI__c, MSD_CORE_Footer_Type__c, MSD_CORE_IsActive__c, MSD_CORE_URL__c, MSD_CORE_Order__c, MSD_CORE_Custom_Label__c
                FROM MSD_CORE_HEQ_Footer_Config__mdt
                WHERE MSD_CORE_IsActive__c = true AND MSD_CORE_Display_On_UI__c = true ORDER BY MSD_CORE_Order__c ASC
            ];

            List<FooterLinkWrapper> footerLinks = new List<FooterLinkWrapper>();
            List<FooterLinkWrapper> additionalMerckSites = new List<FooterLinkWrapper>();

            for (MSD_CORE_HEQ_Footer_Config__mdt footer : footerConfigs) {
                String customLabel = System.Label.get('', footer.MSD_CORE_Custom_Label__c, '');
                FooterLinkWrapper wrapper = new FooterLinkWrapper(footer.DeveloperName, customLabel, footer.MSD_CORE_URL__c, footer.MSD_CORE_Footer_Type__c);
                if (footer.MSD_CORE_Footer_Type__c == 'Footer Links') {
                    footerLinks.add(wrapper);
                } else if (footer.MSD_CORE_Footer_Type__c == 'Additional Merck sites') {
                    additionalMerckSites.add(wrapper);
                }
            }
            return new FooterDataWrapper(footerLinks, additionalMerckSites);

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving footer config: ' + e.getMessage());
        }
    }
    
    public class FooterLinkWrapper {
        @AuraEnabled public String developerName;
        @AuraEnabled public String label;
        @AuraEnabled public String url;
        @AuraEnabled public String footerType;

        public FooterLinkWrapper(String developerName, String label, String url, String footerType) {
            this.developerName = developerName;
            this.label = label;
            this.url = url;
            this.footerType = footerType;
        }
    }

    public class FooterDataWrapper {
        @AuraEnabled public List<FooterLinkWrapper> footerLinks;
        @AuraEnabled public List<FooterLinkWrapper> additionalMerckSites;

        public FooterDataWrapper(List<FooterLinkWrapper> footerLinks, List<FooterLinkWrapper> additionalMerckSites) {
            this.footerLinks = footerLinks;
            this.additionalMerckSites = additionalMerckSites;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<HelpLinkWrapper> getHelpLinks() {
        try {
            List<MSD_CORE_HEQ_HelpLinks_Config__mdt> helpLinksConfig = [
                SELECT DeveloperName, Label, MSD_CORE_Display_On_UI__c, MSD_CORE_IsActive__c, MSD_CORE_URL__c, MSD_CORE_Order__c, MSD_CORE_Custom_Label__c, MSD_CORE_InterstitialPopup__c
                FROM MSD_CORE_HEQ_HelpLinks_Config__mdt
                WHERE MSD_CORE_IsActive__c = true AND MSD_CORE_Display_On_UI__c = true
                ORDER BY MSD_CORE_Order__c ASC
            ];

            List<HelpLinkWrapper> helpLinks = new List<HelpLinkWrapper>();

            for (MSD_CORE_HEQ_HelpLinks_Config__mdt linkConfig : helpLinksConfig) {
                String customLabel = System.Label.get('', linkConfig.MSD_CORE_Custom_Label__c, '');
                helpLinks.add(new HelpLinkWrapper(customLabel, linkConfig.MSD_CORE_URL__c, linkConfig.MSD_CORE_InterstitialPopup__c));
            }

            return helpLinks;

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving help links: ' + e.getMessage());
        }
    }

    public class HelpLinkWrapper {
        @AuraEnabled public String name;
        @AuraEnabled public String url;
        @AuraEnabled public Boolean interstitialPopup;

        public HelpLinkWrapper(String name, String url, Boolean interstitialPopup) {
            this.name = name;
            this.url = url;
            this.interstitialPopup = interstitialPopup;
        }
    }
}