/*
* ReopenParentCaseWhenFulfillReopenedMVN
* Created By:    Roman Lerman
* Created Date:  6/21/2013
* Description:   This class handles reopening a parent case when a Fulfillment 
* 				 is reopened. It looks at the Fulfillments that are reopened and
* 				 and reopens the corresponding Interaction.
*
* *** NOTE: Currently not used for the Merck implementation. ***
*/
public with sharing class ReopenParentCaseWhenFulfillReopenedMVN implements TriggersMVN.HandlerInterface {
	
	/*
	 * This trigger handles reopening a parent case when a Fulfillment 
	 * is reopened. It looks at the Fulfillments that are updated and
	 * if the Fulfillment is related to a Case and is no longer closed
	 * then we'll update the parent to open.
	 */

	public void execute(Map<Id, Fulfillment_MVN__c> newFulfillments, Map<Id, Fulfillment_MVN__c> oldFulfillments) {
		Set<Case> parentsToReopen = new Set<Case>();
		
		for (Fulfillment_MVN__c fulfillment : newFulfillments.values()) {
			if (fulfillment.Case_MVN__c != null 
				&& fulfillment.Is_Closed_MVN__c == false 
				&& fulfillment.Is_Closed_MVN__c != oldFulfillments.get(fulfillment.Id).Is_Closed_MVN__c)
			{
				parentsToReopen.add(new Case(Id = fulfillment.Case_MVN__c, Status=Service_Cloud_Settings_MVN__c.getInstance().Open_Status_MVN__c, RecordTypeId = TestDataFactoryMVN.interactionRecordTypeId));
			}
		}
		
		if(parentsToReopen != null && parentsToReopen.size() > 0){
			List<Case> parentCaseList = new List<Case>();
			parentCaseList.addAll(parentsToReopen);
			update parentCaseList;
		}
	}

	public void handle() {
		execute((Map<Id, Fulfillment_MVN__c>) trigger.newMap, (Map<Id, Fulfillment_MVN__c>) trigger.oldMap);
	}
}