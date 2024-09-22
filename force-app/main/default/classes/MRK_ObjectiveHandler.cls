/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_ObjectiveHandler.cls
* @description - processing logic for the Objective_MRK__c object
* @createdate - Apr 1st, 2014
*
*/

public class MRK_ObjectiveHandler implements MRK_ITrigger {
	
	private Map<Id,String> accountPlanIdToStatusMap;
	private Map<Id,Id> accountPlanIdToCreatedByIdMap;

	public MRK_ObjectiveHandler() {
		
	}

	public void bulkBefore() {

		if (Trigger.isUpdate) {

			accountPlanIdToStatusMap = new Map<Id,String>();
			accountPlanIdToCreatedByIdMap = new Map<Id,Id>();

			Set<Id> accountPlanIdSet = new Set<Id>();
			for (Objective_MRK__c o : (List<Objective_MRK__c>)Trigger.new) {
				accountPlanIdSet.add(o.Account_Plan_MRK__c);
			}

			for (Account_Plan_vod__c ap : [select Id, Status__c, CreatedById from Account_Plan_vod__c where Id IN :accountPlanIdSet]) {
				accountPlanIdToStatusMap.put(ap.Id, ap.Status__c);
				accountPlanIdToCreatedByIdMap.put(ap.Id, ap.CreatedById);
			}

		}
	}

	public void bulkAfter() {}
	public void beforeInsert(SObject so) {}

	public void beforeUpdate(SObject oldSo, SObject so) {

		Objective_MRK__c oSo = (Objective_MRK__c)so;
		Objective_MRK__c oldO = (Objective_MRK__c)oldSo;

		String status = accountPlanIdToStatusMap.get(oSo.Account_Plan_MRK__c);
		Id accountPlanCreatedById = accountPlanIdToCreatedByIdMap.get(oSo.Account_Plan_MRK__c);

		if (oSo.Account_Plan_MRK__c != oldO.Account_Plan_MRK__c) {
			so.addError('Cannot change the Account Plan once a Merck Objective is created.');
		}

		if (oSo.Goal_Opportunity_MRK__c != oldO.Goal_Opportunity_MRK__c) {
			so.addError('Cannot change the Organizational Goal once a Merck Objective is created.');
		}


		if ( (status == 'Approved') && (oSo.Name != oldO.Name) ) {
			so.addError('Cannot change the name of a Merck Objective on an approved Account Plan.');
		}


		if ( (status == 'Submitted') && (oSo.Name != oldO.Name) && (accountPlanCreatedById == UserInfo.getUserId()) ) {
			so.addError('Cannot change a Merck Objective on a submitted Account Plan.');
		}


	}
	
	public void beforeDelete(SObject so) {

		Objective_MRK__c oSo = (Objective_MRK__c)so;
		if ( !MRK_AccountPlanServices.getInstance().allowDeleteAccountPlanOrChildRecords(oSo.Account_Plan_MRK__c) ) {
			so.addError('Cannot delete an Objective from an Approved or Submitted Account Plan');
		} else {
			try {
				MRK_AccountPlanServices.getInstance().deleteObjectiveChildRecords(oSo.Id);
			} catch (Exception e) {
				so.addError(e);
			}
		}

	}
	
	public void afterInsert(SObject so) {}
	public void afterUpdate(SObject oldSo, SObject so) {}
	public void afterDelete(SObject so) {}
	public void andFinally() {}

}