/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_CommunicationTargetHandler.cls
* @description - processing logic for the Communication_Target_MRK__c object
* @createdate - Sept. 22nd, 2014
*
*/

public class MRK_CommunicationTargetHandler implements MRK_ITrigger {
	
	private Map<String,String> productIdToNameMap = new Map<String,String>();
	private Map<String,String> teamIdToNameMap = new Map<String,String>();
	private List<Communication_Target_MRK__c> commTargetUpdateList = new List<Communication_Target_MRK__c>();

	public MRK_CommunicationTargetHandler() {
		
	}

	public void bulkBefore() {

		List<Product_vod__c> productList = [select Id, Name, External_ID_vod__c, Active_MRK__c from Product_vod__c where External_ID_vod__c != null and Active_MRK__c = true and Product_Type_vod__c = 'Detail' order by Name];
		for (Product_vod__c product : productList) {
			productIdToNameMap.put(product.External_ID_vod__c, product.Name);
		}

    Sales_Team_MRK__c allSalesTeam = new Sales_Team_MRK__c(Sales_Team_Code_MRK__c='000', Name='MERCK & CO.');
    List<Sales_Team_MRK__c> sourceTeams = [select Active_MRK__c, CreatedById, CreatedDate, Id, LastModifiedById, LastModifiedDate, Name, OwnerId, Sales_Team_Code_MRK__c from Sales_Team_MRK__c where Active_MRK__c = true order by Name];    
    List<Sales_Team_MRK__c> allSalesTeams = new List<Sales_Team_MRK__c>();
    allSalesTeams.add(allSalesTeam);
    allSalesTeams.addAll(sourceTeams);
		for (Sales_Team_MRK__c salesTeam : allSalesTeams) {
			teamIdToNameMap.put(salesTeam.Sales_Team_Code_MRK__c, salesTeam.Name);
		}

	}
	
	public void bulkAfter() {}
	public void beforeInsert(SObject so) {
		Communication_Target_MRK__c obj = (Communication_Target_MRK__c)so;
		obj.Product_MRK__c = getNamesList(obj.Product_IDs_MRK__c, productIdToNameMap);
		obj.Team_MRK__c = getNamesList(obj.Team_IDs_MRK__c, teamIdToNameMap);
	}
	
	public void beforeUpdate(SObject oldSo, SObject so) {
		Communication_Target_MRK__c newObj = (Communication_Target_MRK__c)so;
		Communication_Target_MRK__c oldObj = (Communication_Target_MRK__c)oldSo;

		newObj.Product_MRK__c = getNamesList(newObj.Product_IDs_MRK__c, productIdToNameMap);
		newObj.Team_MRK__c = getNamesList(newObj.Team_IDs_MRK__c, teamIdToNameMap);
	}
	
	public void beforeDelete(SObject so) {}

	public void afterInsert(SObject so) {}
	public void afterUpdate(SObject oldSo, SObject so) {}
	public void afterDelete(SObject so) {}
	public void andFinally() {}

	private String getNamesList(String delimitedIdString, Map<String,String> idToNameMap) {
		List<String> names = new List<String>();
		for ( String objectId : delimitedIdString.split(';') ) {
			names.add( idToNameMap.get(objectId) );
		}
		return String.join(names, ';');
	}

}