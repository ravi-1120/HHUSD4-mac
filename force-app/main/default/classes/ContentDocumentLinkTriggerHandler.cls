/**
 * Component Name:      ContentDocumentLinkTriggerHandler
 * Created By:          Ravi Modi (Focal CXM)
 * @Description  ContentDocumentLinkTriggerHandler Used for updating permission of ContentDocumentLink
 * Test Class:          ContentDocumentLinkTriggerHandlerTest
 */

 public class ContentDocumentLinkTriggerHandler { 
    List<ContentDocumentLink> recordNewList = new List<ContentDocumentLink>();
    Boolean isInsert = false;
    public static boolean recursionController = true;
    /* 
    * Component Name:      ContentDocumentLinkTriggerHandler
    @Description ContentDocumentLinkTriggerHandler used for assigining the values 
    */
    public ContentDocumentLinkTriggerHandler(List<ContentDocumentLink> newList, boolean isInsert) {
        this.recordNewList = newList;
        this.isInsert = isInsert;
    }
    
    /**
     * @description beforeInsertEvent Called when record is created
     * @return Void
    */
    public void beforeInsertEvent(){
        updateUserVisibility();
        updateUserVisibilityHEQ();
    }

    /**
     * @description updateUserVisibility used for update user visibility access
     * @return Void
    */
    public void updateUserVisibility() {
        for (ContentDocumentLink cd : recordNewList) {
            String sdid = cd.LinkedEntityId;
            if (sdid.startsWith(MSD_CORE_Study_detail__c.sobjecttype.getDescribe().getKeyPrefix())) {
                cd.Visibility = 'AllUsers';
            }
        }
    }

    /**
     * @description updateUserVisibilityHEQ used for update user visibility access (HEQ Portal)
     * @return Void
    */
    public void updateUserVisibilityHEQ() {
        for (ContentDocumentLink cd : recordNewList) {
            String sdid = cd.LinkedEntityId;
            if (sdid.startsWith(MSD_CORE_HEQ_Search_Category__c.sobjecttype.getDescribe().getKeyPrefix()) || sdid.startsWith(MSD_CORE_HEQ_Collection__c.sobjecttype.getDescribe().getKeyPrefix()) || sdid.startsWith(Account.sobjecttype.getDescribe().getKeyPrefix())) {
                cd.Visibility = 'AllUsers';
            }
        }
    }

    /**
     * @description afterInsertEvent Called when record is created
     * @return Void
    */
    public void afterInsertEvent(){
        handleAfterInsert();
    }

    /**
    * description handleAfterInsert Called when record is created
    * return Void
    */
    public void handleAfterInsert(){
        Map<String, String> mapCdlEntity = new Map<String,String>();
        for(ContentDocumentLink cdl: this.recordNewList){
            Id cdlId = cdl.LinkedEntityId;
            System.debug('cd>>'+cdlId);
                        System.debug('cd 1>>'+String.valueOf(cdlId?.getsobjecttype()));
            if(cdlId != null && (String.valueOf(cdlId?.getsobjecttype()) == 'MSD_CORE_Disease_Information__c' )){
                //cdl.Visibility = 'AllUsers'; //RT
                if(!mapCdlEntity.containsKey(cdl.LinkedEntityId)){
                    mapCdlEntity.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
                }
            }
        }
        if(mapCdlEntity.values().size() > 0){
            Map<Id,ContentDocument> mapContentDocument = new Map<Id,ContentDocument>([Select Id, LatestPublishedVersionId from ContentDocument where Id IN:mapCdlEntity.values()]);
            List<MSD_CORE_Disease_Information__c> diseaselist = new List<MSD_CORE_Disease_Information__c>();
            for(String recId: mapCdlEntity.keyset()){
                //String url = '/sfc/servlet.shepherd/version/renditionDownload?rendition=SVGZ&versionId='+mapContentDocument.get(mapCdlEntity.get(recId)).LatestPublishedVersionId; //RT
                Id contentdocid = mapCdlEntity.get(recId);
                system.debug('çontentdocid>>>'+ contentdocid);

                ContentVersion cv = [SELECT Id, Title FROM ContentVersion WHERE ContentDocumentId = :contentdocid];
                system.debug('contentversion' + cv);

                ContentDistribution cd = new ContentDistribution();
                cd.Name = cv.Title;
                cd.ContentVersionId = cv.Id;
                cd.PreferencesAllowViewInBrowser= true;
                insert cd;
                
                ContentDistribution cdUrl = [select id, DistributionPublicUrl, ContentDownloadUrl from ContentDistribution WHERE Id =: cd.Id];
                system.debug('DistributionPublicUrl'+ cdUrl);

                string publicUrl = cdUrl.DistributionPublicUrl;
                system.debug('publicUrl'+ publicUrl);
                system.debug('contentdownloadurl>>' + cdUrl.ContentDownloadUrl);

                MSD_CORE_Disease_Information__c diseaseDetail = new MSD_CORE_Disease_Information__c();
                diseaseDetail.Id = recId;
                diseaseDetail.MSD_CORE_Resource_URL__c = publicUrl;
                diseaselist.add(diseaseDetail);
            }
            update diseaselist;

            
        }
    }
}