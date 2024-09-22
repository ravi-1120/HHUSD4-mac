/**
 * Component Name :MFR_ContentConnector
 * Created By : Focal CXM
 * @description MFR_ContentConnector
 */
@RestResource(urlMapping='/ResourceMetaData/*')
global with sharing class MFR_ContentConnector {
  /**
   * @description doPost
   * @return res.Id
   */
  @HttpPost
    global static String doPost(){
    RestRequest req = RestContext.request;
    Blob body = req.requestBody;
    String requestString = body.toString();
    //Now as you have the request string You can parse it in APex
    MFR_ContentConnectorWrapper rw = (MFR_ContentConnectorWrapper)JSON.deserialize(requestString,MFR_ContentConnectorWrapper.class);
        MSD_CORE_Catalog__c res = new 	MSD_CORE_Catalog__c();
        List<MSD_CORE_Catalog__c> resource = new List<MSD_CORE_Catalog__c>();
        String GlobalID = rw.globalId;
        if(GlobalID != null){
            resource = [SELECT Id FROM 	MSD_CORE_Catalog__c WHERE MSD_CORE_Global_ID__c=:GlobalID];
        }
        if (resource.size()>0){
            System.debug(LoggingLevel.WARN,resource[0].Id);
            res = resource[0];
        }
         try{
		res.MSD_CORE_Document_ID__c = Integer.valueOf(rw.documentId);
		res.MSD_CORE_Document_Number__c = rw.documentNumber;
        res.MSD_CORE_HCEI_Status__c = Boolean.valueOf(rw.HCEIStatus);
        res.MSD_CORE_Document_Status__c = rw.documentStatus;
        res.MSD_CORE_Expiration_Date__c = date.valueOf(rw.expirationDate);
        res.MSD_CORE_Global_ID__c = GlobalID;
        res.MSD_CORE_GlobalVersion_ID__c = rw.globalVersionId;
        if (rw.audience.size()>0){
            res.MSD_CORE_Audience__c = rw.audience[0];
        }
        if (rw.methodOfDelivery.size()>0){
            res.MSD_CORE_Method_Of_Delivery__c = rw.methodOfDelivery[0];
        }
        if (rw.deliveryPlatform.size()>0){
            res.MSD_CORE_Delivery_Platform__c = rw.deliveryPlatform[0];
        }
        if (rw.productId.size()>0){
            res.MSD_CORE_Product_ID__c = rw.productId[0];
        }
        if (rw.productFamilyId.size()>0){
            res.MSD_CORE_Product_Family_ID__c = rw.productFamilyId[0];
        }

        if (rw.owner.users.size()>0){
            res.MSD_CORE_Document_Owner__c = rw.owner.users[0];
        }
        res.MSD_CORE_Document_Version__c = rw.version;
             
        if (rw.name != null && rw.name.length() > 80) {// #1625 - Truncating name upto 80 characters
            res.Name = rw.name.substring(0, 80);
        } else {
            res.Name = rw.name;
        }

        if (resource.isEmpty()) { // #1625 - To Bypass title update for existing resources
            if (rw.name != null && rw.name.length() > 255) {
            	res.MSD_CORE_Resource_Title__c = rw.name.substring(0, 255);
            } else {
                res.MSD_CORE_Resource_Title__c = rw.name;
            }
        }
        res.MSD_CORE_Description__c = rw.resourceTitle;
        if(rw.documentVersionViewableRenditions.size()>0){
            System.debug(LoggingLevel.WARN,'https://'+ rw.documentVersionViewableRenditions[0].bucket+'/'+ rw.documentVersionViewableRenditions[0].key);
            res.MSD_CORE_Document_Rendition__c =rw.documentVersionViewableRenditions[0].key;
        }
        }catch(Exception e){
            System.debug(LoggingLevel.WARN,'content connector api');
            return e.getStackTraceString();
        }
        Upsert res;
        System.debug(LoggingLevel.WARN,'content connector api');
 		return res.Id;
    }
}