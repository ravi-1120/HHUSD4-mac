/**
* @File Name : MSD_CORE_HEQ_AE_REPORTING_Handler.cls
* @Description :
* @Author : Rohan Dham
* @Last Modified By :
* @Last Modified On : October 7, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 7, 2024 |   | Initial Version
**/

public class MSD_CORE_HEQ_AE_REPORTING_Handler {
	@AuraEnabled(cacheable=true)
	public static List<MSD_CORE_HEQ_AE_REPORTING_Handler.ReturnWrapper> getAssetList(){
		Id userId = UserInfo.getUserId();
		List<MSD_CORE_HEQ_Shadow_ContentDocumentLink__c> lstContentShadowDocLink = new List<MSD_CORE_HEQ_Shadow_ContentDocumentLink__c>();
		lstContentShadowDocLink = [SELECT id, MSD_CORE_HEQ_Type__c, MSD_CORE_HEQ_Asset_Name__c, MSD_CORE_HEQ_Collection__r.CreatedById,
									MSD_CORE_HEQ_Collection_Name__c, MSD_CORE_HEQ_Collection_Created_Date__c,
									MSD_CORE_HEQ_Collection__c, MSD_CORE_HEQ_Asset_Status__c, MSD_CORE_HEQ_Asset_Type__c, 
									MSD_CORE_HEQ_Collection__r.owner.name, MSD_CORE_HEQ_Shared_User_Name__c, 
									MSD_CORE_HEQ_Last_Download_Date__c, MSD_CORE_HEQ_Number_Of_Times_Downloaded__c, MSD_CORE_HEQ_Last_Accessed_Date__c  
									FROM MSD_CORE_HEQ_Shadow_ContentDocumentLink__c 
									WHERE MSD_CORE_HEQ_Collection__r.CreatedById = '005VC00000AWBUcYAP'];//:userId];
		
		List<MSD_CORE_HEQ_AE_REPORTING_Handler.ReturnWrapper> lstOfReportsToBeReturned = new List<MSD_CORE_HEQ_AE_REPORTING_Handler.ReturnWrapper>();
		
		MSD_CORE_HEQ_AE_REPORTING_Handler.ReturnWrapper recToBeCreatedReport1 = new MSD_CORE_HEQ_AE_REPORTING_Handler.ReturnWrapper();
		MSD_CORE_HEQ_AE_REPORTING_Handler.ReturnWrapper recToBeCreatedReport2 = new MSD_CORE_HEQ_AE_REPORTING_Handler.ReturnWrapper();
		
		recToBeCreatedReport1.reportName = 'Assets in My Collection Report';
		recToBeCreatedReport1.lstOfFieldsToBeShown = new List<String>();
		recToBeCreatedReport1.lstContentShadowDocLinkWrapper = new List<MSD_CORE_HEQ_Shadow_ContentDocumentLink__c>();
		recToBeCreatedReport1.lstOfFieldsToBeShown.addAll(new List<String>{'Collection Name;MSD_CORE_HEQ_Collection_Name__c', 'Collection Created Date;MSD_CORE_HEQ_Collection_Created_Date__c', 'Asset Name;MSD_CORE_HEQ_Asset_Name__c','Asset Status;MSD_CORE_HEQ_Asset_Status__c','Asset Type;Asset Type' });
		
		recToBeCreatedReport2.reportName = 'My Shared Collections Report';
		recToBeCreatedReport2.lstOfFieldsToBeShown = new List<String>();
		recToBeCreatedReport2.lstContentShadowDocLinkWrapper = new List<MSD_CORE_HEQ_Shadow_ContentDocumentLink__c>();
		recToBeCreatedReport2.lstOfFieldsToBeShown.addAll(new List<String>{'Collection Name;MSD_CORE_HEQ_Collection_Name__c','Asset Name;MSD_CORE_HEQ_Asset_Name__c','Shared With;MSD_CORE_HEQ_Shared_User_Name__c','Last Accessed;MSD_CORE_HEQ_Last_Accessed_Date__c','Last Downloaded;MSD_CORE_HEQ_Last_Download_Date__c','Number of times downloaded;MSD_CORE_HEQ_Number_Of_Times_Downloaded__c'});
		
		for( MSD_CORE_HEQ_Shadow_ContentDocumentLink__c rec : lstContentShadowDocLink) {
			if(rec.MSD_CORE_HEQ_Type__c == 'Resource Added in Collection') {
				recToBeCreatedReport1.lstContentShadowDocLinkWrapper.add(rec);
			} else if(rec.MSD_CORE_HEQ_Type__c =='Resource Shared via Collection') {
				recToBeCreatedReport2.lstContentShadowDocLinkWrapper.add(rec);				
			}
		}
		lstOfReportsToBeReturned.add(recToBeCreatedReport2);
		lstOfReportsToBeReturned.add(recToBeCreatedReport1);
		return lstOfReportsToBeReturned;
	}
	
	public class ReturnWrapper {
		@AuraEnabled
		public List<MSD_CORE_HEQ_Shadow_ContentDocumentLink__c> lstContentShadowDocLinkWrapper;
		@AuraEnabled
		public List<String> lstOfFieldsToBeShown;
		@AuraEnabled
		public String reportName; 
	}


}