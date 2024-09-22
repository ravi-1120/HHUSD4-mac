/**
 * Component Name:      MSD_CORE_StudyDetailController
 * Created By:          Ravi Modi (Focal CXM)
 * Created Date:        13th March 2023
 * @description:        Server side controller for mSD_CORE_StudyDetail LWC component
 * Test Class:          MSD_CORE_StudyDetailControllerTest
 */

public without sharing class MSD_CORE_StudyDetailController {
    
    /**
     * Method Name  :   getStudyDetail
     * @param       :   recordId - Study detail record Id
     * @description :   Use to get Study Detail record
     * @return      :   MSD_CORE_Study_detail__c
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   13th March 2023
     */
    @AuraEnabled(cacheable=true)
    public static MSD_CORE_Study_detail__c getStudyDetail(String recordId){
        try {
            return [SELECT Id, Name, MSD_CORE_Phase__c, MSD_CORE_Therapeutic__c, MSD_CORE_Clinical_Links__c, MSD_CORE_Clinical_URL__c, MSD_CORE_Compound__c, MSD_CORE_Compound_Warning__c, MSD_CORE_Tumor__c, MSD_CORE_Tumor__r.Name, MSD_CORE_Medical_Therapeutic_Area__r.MSD_CORE_Text_color__c, MSD_CORE_Medical_Therapeutic_Area__r.MSD_CORE_BG_color__c,
                    (SELECT Id, Name, MSD_CORE_Clinicaltrial_URL__c, MSD_CORE_Study_detail__c FROM Clinicaltrial_Links__r WHERE MSD_CORE_Study_detail__c =: recordId) 
                    FROM MSD_CORE_Study_detail__c WHERE Id =: recordId LIMIT 1];
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Method Name  :   getCarouselImage
     * @param       :   recordId - Study detail record Id
     * @description :   use for carousel image
     * @return      :   ContentVersion
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   27th March 2023
     */
    @AuraEnabled(cacheable=true)
    public static List<Contentdata> getCarouselImage(String recordId){
        try {

            List<ContentDocumentLink> cdlinks = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: recordId];

            List<Contentdata> cnwraplst = new List<Contentdata>();
            Set<Id> cnIds = new Set<Id>();

            if(cdlinks.size() > 0){
                for (ContentDocumentLink cdlnk : cdlinks) {
                    cnIds.add(cdlnk.ContentDocumentId);
                }
                List<ContentVersion> versionlst = [SELECT Id, ContentDocumentId, Order__c, VersionData, FirstPublishLocationId FROM ContentVersion WHERE ContentDocumentId In : cnIds ORDER BY Order__c];
                Integer count = 0;
                for (ContentVersion cv : versionlst) {
                    Contentdata cndata = new Contentdata();
                    cndata.versionData = EncodingUtil.base64Encode(cv.VersionData);
                    cndata.order = count++;
                    cnwraplst.add(cndata);
                }
                return cnwraplst;
            }else{
                return null;
            }

            
        } catch (Exception e) {
            return null;
        }
    }
   
   /**
     * @description Contentdata
     */
    public class Contentdata {
           /**
         * @description versionData
         * @return versionData
         */
        @AuraEnabled
        public string versionData{get;set;}
           /**
         * @description order
         * @return order
         */
        @AuraEnabled
        public Decimal order{get;set;}
	}
}