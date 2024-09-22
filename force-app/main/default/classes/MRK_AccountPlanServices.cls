/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_AccountPlanServices.cls
* @description - Services class for Account Plans
* @createdate - Feb 4th, 2014
*
*/

public class MRK_AccountPlanServices {

	public static final String SETTING_NAME = 'ACCOUNT_PLANNING';
	private static MRK_AccountPlanServices instance = null;

	public static MRK_AccountPlanServices getInstance() {
		if (instance == null) {
			instance = new MRK_AccountPlanServices();
		}
		return instance;
	}

	public List<ApexPages.Message> validate(Id apId) {
		// template
		// String settingValue = MRK_Setting.getString(SETTING_NAME, 'setting id');
		List<ApexPages.Message> messageList = new List<ApexPages.Message>();
		messageList.add( new ApexPages.message(ApexPages.severity.ERROR, 'An account plan must contain at least one Customer Organizational Goal') );
		return messageList;
	}

	private Account_Plan_vod__c getAccountPlanAndAllRelatedChildRecords(Id recordId) {
		Account_Plan_vod__c rec = [select Id, Name, RecordTypeId, (select Id, RecordTypeId, Name from Goals_Opportunities__r), (select Id, RecordTypeId, Name from Objectives__r), (select Id, RecordTypeId, Name from Account_Tactic_vod__r) from Account_Plan_vod__c where Id =: recordId];
		return rec;		
	}

	private Goal_Opportunity_MRK__c getGoalOpportunityAndAllRelatedChildRecords(Id recordId) {
		Goal_Opportunity_MRK__c rec = [select Id, (select Id from Objectives__r), (select Id from Account_Tactics__r) from Goal_Opportunity_MRK__c where Id =: recordId];
		return rec;		
	}

	private Objective_MRK__c getObjectiveAndAllRelatedChildRecords(Id recordId) {
		Objective_MRK__c rec = [select Id, (select Id from Account_Tactics__r) from Objective_MRK__c where Id =: recordId];
		return rec;		
	}

	public void deleteAccountPlanChildRecords(Id recordId) {
		Account_Plan_vod__c rec = getAccountPlanAndAllRelatedChildRecords(recordId);
		delete rec.Account_Tactic_vod__r;
		delete rec.Objectives__r;
		delete rec.Goals_Opportunities__r;
	}

	public void deleteGoalOpportunityChildRecords(Id recordId) {
		Goal_Opportunity_MRK__c rec = getGoalOpportunityAndAllRelatedChildRecords(recordId);
		delete rec.Account_Tactics__r;
		delete rec.Objectives__r;
	}

	public void deleteObjectiveChildRecords(Id recordId) {
		Objective_MRK__c rec = getObjectiveAndAllRelatedChildRecords(recordId);
		delete rec.Account_Tactics__r;
	}

	public void updateAccountPlanAndChildObjectRecordTypesForStatus(Id recordId, String status) {
		Account_Plan_vod__c record = getAccountPlanAndAllRelatedChildRecords(recordId);
		record.RecordTypeId = getRecordTypeIdForObjectHavingStatus('Account_Plan_vod__c', status);
		update record;

		updateChildObjectRecordTypesForStatus(recordId, status);
	}

	public void updateChildObjectRecordTypesForStatus(Id recordId, String status) {

		// get all Organization Goal, Objective, and Tactic records for this Account Plan
		Account_Plan_vod__c record = getAccountPlanAndAllRelatedChildRecords(recordId);

		List<Goal_Opportunity_MRK__c> organizationalGoalList = new List<Goal_Opportunity_MRK__c>();
		Id organizationalGoalRecordTypeId = getRecordTypeIdForObjectHavingStatus('Goal_Opportunity_MRK__c', status);
		for (Goal_Opportunity_MRK__c rec : record.Goals_Opportunities__r) {
			rec.RecordTypeId = organizationalGoalRecordTypeId;
			organizationalGoalList.add(rec);
		}

		List<Objective_MRK__c> objectiveList = new List<Objective_MRK__c>();
		Id objectiveRecordTypeId = getRecordTypeIdForObjectHavingStatus('Objective_MRK__c', status);
		for (Objective_MRK__c rec : record.Objectives__r) {
			rec.RecordTypeId = objectiveRecordTypeId;
			objectiveList.add(rec);
		}

		List<Account_Tactic_vod__c> accountTacticList = new List<Account_Tactic_vod__c>();
		Id accountTacticRecordTypeId = getRecordTypeIdForObjectHavingStatus('Account_Tactic_vod__c', status);
		for (Account_Tactic_vod__c rec : record.Account_Tactic_vod__r) {
			rec.RecordTypeId = accountTacticRecordTypeId;
			accountTacticList.add(rec);
		}


		// TODO: check what user gets used for LastUpdatedBy field.  May need to change to "with sharing"
		try {
			if (organizationalGoalList.size() >0 ) {
				update organizationalGoalList;
			}

			if (objectiveList.size() >0 ) {
				update objectiveList;
			}

			if (accountTacticList.size() > 0) {
				update accountTacticList;
			}

		} catch (Exception e) {

		}
	}

	public Boolean goalOpportunityHasAssociatedObjectives(Id recordId) {
		Goal_Opportunity_MRK__c rec = [select Id, (select Id from Objectives__r) from Goal_Opportunity_MRK__c where Id =: recordId];
		return rec.Objectives__r.size() > 0;
	}

	public Boolean allowDeleteAccountPlanOrChildRecords(Id recordId) {
		Account_Plan_vod__c rec = [select Id, Status__c from Account_Plan_vod__c where Id = :recordId];
		return ( (rec.Status__c != 'Approved') && (rec.Status__c != 'Submitted') );
	}

	private Id getRecordTypeIdForObjectHavingStatus(String objectName, String status) {
		Map<String,Object> statusToRecordTypeNameObjectMaps = (Map<String, Object>)MRK_Setting.getObject(SETTING_NAME, 'statusToRecordTypeNameObjectMaps');
		Map<String,Object> statusToRecordTypeNameMap = (Map<String,Object>)statusToRecordTypeNameObjectMaps.get(objectName);
		String recordTypeName = (String)statusToRecordTypeNameMap.get(status);
		return [select Id, SObjectType, DeveloperName from RecordType where DeveloperName = :recordTypeName].Id;
	}

	public void testUpdateChildObjectRecordTypesForStatus() {
		//updateChildObjectRecordTypesForStatus('a0CZ000000PHoRS', 'Draft');
		//updateChildObjectRecordTypesForStatus('a0CZ000000PHoRS', 'Submitted');
		//updateChildObjectRecordTypesForStatus('a0CZ000000PHoRS', 'Revisions Required');
		updateChildObjectRecordTypesForStatus('a0CZ000000PHoRS', 'Approved');
	}

	public void deleteTestAccountPlans() {
		List<Account_Plan_vod__c> accountPlanList = [select Id, Name, Status__c, RecordTypeId from Account_Plan_vod__c where Name like 'AP%'];
		for (Account_Plan_vod__c ap : accountPlanList) {
			ap.Status__c = 'Draft';
		}
		update accountPlanList;
		delete accountPlanList;
	}

}