public with sharing class MRK_CommunicationEventTargetViewCtrl {

  public ApexPages.StandardController sc { get; set; }
  public final sObject targetRecord;
  private String objectTypeName;
  private String objectLabel;
  private String parentObjectFieldName;
  private String parentObjectRelationshipName;
  public String parentObjectLabel { get; set; }
  public String parentObjectName { get; set; }
  public String title { get; set; }
  public String eventType { get; set; }

  public String productNames { get; set; }
  public String teamNames { get; set; }

	public MRK_CommunicationEventTargetViewCtrl(ApexPages.StandardController stdController) {
    objectTypeName = ApexPages.currentPage().getUrl().contains('MRK_CommunicationEventTargetView') ? 'Communication_Event_Target_MRK__c' : 'Communication_Target_MRK__c';
    parentObjectFieldName = (objectTypeName == 'Communication_Target_MRK__c') ? 'Communication_MRK__c' : 'Communication_Event_MRK__c';
    parentObjectRelationshipName = parentObjectFieldName.replace('__c', '__r');
    parentObjectLabel = (objectTypeName == 'Communication_Target_MRK__c') ? 'Communication' : 'Communication Event';
    objectLabel = (objectTypeName == 'Communication_Target_MRK__c') ? 'Communication' : 'Communication Event';
    title = objectLabel + ' Target';    

    this.sc = stdController;

    sc.addFields(new List<String>{'Name', 'OwnerId', 'CreatedById', 'CreatedDate', 'LastModifiedById', 'LastModifiedDate', 'Type_MRK__c' ,'Profile_MRK__c', 'Product_MRK__c', 'Team_MRK__c', parentObjectFieldName});
        
    this.targetRecord = stdController.getRecord();

    List<Product_vod__c> sourceProducts = [select Id, External_ID_vod__c, Name, Active_MRK__c from Product_vod__c where Active_MRK__c = true and External_ID_vod__c != null and Product_Type_vod__c = 'Detail'];
    List<String> productIDList = ((String)targetRecord.get('Product_MRK__c')).split(';');
    List<String> productNameList = new List<String>();
    for (String productID : productIDList) {
    	for (Product_vod__c p : sourceProducts) {
    		if (p.External_ID_vod__c == productID) {
    			productNameList.add(p.Name);
    		}
    	}
    }
    productNames = string.join(productNameList, ';');

		List<Sales_Team_MRK__c> sourceTeams = [select Active_MRK__c, CreatedById, CreatedDate, Id, LastModifiedById, LastModifiedDate, Name, OwnerId, Sales_Team_Code_MRK__c from Sales_Team_MRK__c where Active_MRK__c = true];    
    sourceTeams.add(new Sales_Team_MRK__c(Sales_Team_Code_MRK__c='000', Name='MERCK & CO.'));
    List<String> teamIDList = ((String)targetRecord.get('Team_MRK__c')).split(';');
    List<String> teamNameList = new List<String>();
    for (String teamID : teamIDList) {
    	for (Sales_Team_MRK__c t : sourceTeams) {
    		if (t.Sales_Team_Code_MRK__c == teamID) {
    			teamNameList.add(t.Name);
    		}
    	}
    }    
    teamNames = string.join(teamNameList, ';');
	}

  public Boolean getIsCommunicationTarget() {
    return parentObjectFieldName == 'Communication_MRK__c';
  }

  public Boolean getIsCommunicationEventTarget() {
    return parentObjectFieldName == 'Communication_Event_MRK__c';
  }

  public Communication_Event_Target_MRK__c getCommunicationEventTargetRecord() {
    return (Communication_Event_Target_MRK__c)targetRecord;
  }

  public Communication_Target_MRK__c getCommunicationTargetRecord() {
    return (Communication_Target_MRK__c)targetRecord;
  }

  public PageReference doEdit() {
    return sc.edit();
  }

  public PageReference doDelete() {
    return sc.delete();
  }

}