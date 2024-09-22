/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_ApprovalProcessServicesController.cls
* @description - Controller class for approval process services
* @createdate - Mar 31st, 2014
*
*/

public without sharing class MRK_ApprovalProcessServicesController {

	private Map<string,string> pageParams = ApexPages.currentPage().getParameters();
	private final Id recordId;
	private final String objectTypeName;
	private final String objectLabel;

	public MRK_ApprovalProcessServicesController() {
		this.recordId = (Id)pageParams.get('id');
		this.objectLabel = ((Id)this.recordId).getSObjectType().getDescribe().getLabel();
		this.objectTypeName = ((Id)this.recordId).getSObjectType().getDescribe().getName();
	}

	public String getReturnToRecordLabel() {
		return 'Return to ' + objectLabel;
	}

	public PageReference process() {

		/*
		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Test error message'));
		PageReference p = new ApexPages.StandardController([select Id from Account_Plan_vod__c where Id = :apId]).view();
    p.setRedirect(true);
    return p;
    */

		String action = pageParams.get('action');
		if (action == 'recallApprovalRequest') {
			try {
				MRK_ApprovalProcessServices.getInstance().recallApprovalRequest(this.recordId);
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Approval request successfully recalled.'));						
			} catch (Exception e) {
				ApexPages.addMessages(e);	
			}
			return null;
		} else {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'No action or valid action specified in URL query string.'));
			return null;
		}
	}

	public PageReference returnToRecord() {
		PageReference p = new ApexPages.StandardController( Database.query('select Id from ' + this.objectTypeName + ' where Id = \'' + this.recordId + '\'') ).view();
		//PageReference p = new ApexPages.StandardController([select Id from Account_Plan_vod__c where Id = :this.recordId]).view();
    p.setRedirect(true);
    return p;		
	}

	/*
	public PageReference submitForApproval() {
		List<ApexPages.Message> messageList = MRK_AccountPlanServices.getInstance().validate(apId);
		if (messageList.size() > 0) {
			for (ApexPages.Message m : messageList) {
				ApexPages.addMessage(m);	
			}
			return null;			
		}

		String userid = pageParams.get('userid');
		if (userid == null) {
			userid = UserInfo.getUserId();
		}
		PageReference p = new PageReference('/apex/MRK_ApproverSelector?id=' + apId + '&userid=' + userid);
    p.setRedirect(true);
    return p;


		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'submitForApproval here'));
		return null;
	}

	public PageReference recallApprovalRequest() {
		try {
			MRK_ApprovalProcessServices.getInstance().recallApprovalRequest(apId);
			return returnToAccountPlan();
		} catch (Exception e) {
			ApexPages.addMessages(e);	
		}
		
		return null;
	}

	public PageReference validate() {
		return null;
	}
	*/

}