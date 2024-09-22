/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_GoalOpportunityHandler.cls
* @description - processing logic for the Goal_Opportunity_MRK__c object
* @createdate - Apr 1st, 2014
*
*/

public class MRK_GoalOpportunityHandler implements MRK_ITrigger {
	
	public MRK_GoalOpportunityHandler() {
		
	}

	public void bulkBefore() {}
	public void bulkAfter() {}
	public void beforeInsert(SObject so) {}

	public void beforeUpdate(SObject oldSo, SObject so) {

		Goal_Opportunity_MRK__c goSo = (Goal_Opportunity_MRK__c)so;
		Goal_Opportunity_MRK__c oldGo = (Goal_Opportunity_MRK__c)oldSo;
		
		Account_Plan_vod__c ap = [select Id, Status__c, CreatedById from Account_Plan_vod__c where Id =: goSo.Account_Plan_MRK__c];

		if (goSo.Account_Plan_MRK__c != oldGo.Account_Plan_MRK__c) {
			so.addError('Cannot change the Account Plan once an Organizational Goal is created.');
		}

		if ( (ap.Status__c == 'Approved') && (goSo.Name != oldGo.Name) ) {
			so.addError('Cannot change the name of an Organizational Goal on an approved Account Plan.');
		}

		if ( (oldGo.Area_of_Collaboration_MRK__c == true) &&
			(goSo.Area_of_Collaboration_MRK__c == false) ) {

			// prevent unchecking Area of Collaboration while child objective records exist
			if (MRK_AccountPlanServices.getInstance().goalOpportunityHasAssociatedObjectives(goSo.Id)) {
				so.addError('Merck Objectives can only be associated to Customer Organizational Goals that are Areas of Collaboration. If this is not an Area of Collaboration, please remove all Merck Objectives and Merck Tactics prior to unchecking Area of Collaboration.');	
			} else {
				// clear the Merck Priority field
				goSo.Merck_Priority_MRK__c = null;
			}
		}

		if ( (ap.Status__c == 'Submitted') && (goSo.Name != oldGo.Name) && (ap.CreatedById == UserInfo.getUserId()) ) {
			so.addError('Cannot change an Organizational Goal on a submitted Account Plan.');
		}

	}
	
	public void beforeDelete(SObject so) {

		Goal_Opportunity_MRK__c goSo = (Goal_Opportunity_MRK__c)so;
		if ( !MRK_AccountPlanServices.getInstance().allowDeleteAccountPlanOrChildRecords(goSo.Account_Plan_MRK__c) ) {
			so.addError('Cannot delete an Organizational Goal from an Approved or Submitted Account Plan');
		} else {
			try {
				MRK_AccountPlanServices.getInstance().deleteGoalOpportunityChildRecords(so.Id);
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