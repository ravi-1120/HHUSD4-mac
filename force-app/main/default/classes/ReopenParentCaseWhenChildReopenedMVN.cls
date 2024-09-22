/*
* ReopenParentCaseWhenChildReopenedMVN
* Created By:  Thomas Hajcak
* Created Date: 6/19/2013
* Description:  This class handles reopening a parent case when a child 
* 				case is reopened. It looks at the cases that are updated and
* 				if the case has a Parent, its new status is not an 'isClosed'
* 				status, and the old status is an 'isClosed' status, then we'll
* 				update the parent to also be open.
*/
public with sharing class ReopenParentCaseWhenChildReopenedMVN implements TriggersMVN.HandlerInterface {
	public void execute(Map<Id, Case> newCases, Map<Id, Case> oldCases) {
		Set<Case> parentsToReopen = new Set<Case>();
		
		for (Case thisCase : newCases.values()) {
			if (thisCase.ParentId != null 
				&& UtilitiesMVN.matchCaseRecordTypeIdToName(thisCase.RecordTypeId, Service_Cloud_Settings_MVN__c.getInstance().Request_Record_Type_MVN__c)
				&& thisCase.isClosed == false 
				&& thisCase.isClosed != oldCases.get(thisCase.Id).isClosed)
			{
				parentsToReopen.add(new Case(Id = thisCase.ParentId, Status=Service_Cloud_Settings_MVN__c.getInstance().Open_Status_MVN__c));
			}
		}
		
		if(parentsToReopen != null && parentsToReopen.size() > 0){
			List<Case> parentCaseList = new List<Case>();
			parentCaseList.addAll(parentsToReopen);
			update parentCaseList;
		}
	}

	public void handle() {
		execute((Map<Id, Case>) trigger.newMap, (Map<Id, Case>) trigger.oldMap);
	}
}