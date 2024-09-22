/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_AccountPlanServicesController.cls
* @description - Controller class for account plan services
* @createdate - Feb 4th, 2014
*
*/

public without sharing class MRK_AccountPlanServicesController {

	private Map<string,string> pageParams = ApexPages.currentPage().getParameters();
	private final Id apId;

	public MRK_AccountPlanServicesController(ApexPages.StandardController controller) {
		this.apId = controller.getId();
	}

	public PageReference process() {

		/*
		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Test error message'));
		PageReference p = new ApexPages.StandardController([select Id from Account_Plan_vod__c where Id = :apId]).view();
    p.setRedirect(true);
    return p;
    */

		String action = pageParams.get('action');
		if (action == 'submitForApproval') {
			return submitForApproval();
		} else if (action == 'recallApprovalRequest') {
			return recallApprovalRequest();
		} else {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'No action or valid action specified in URL query string.'));
			return null;
		}
	}

	public PageReference returnToAccountPlan() {
		PageReference p = new ApexPages.StandardController([select Id from Account_Plan_vod__c where Id = :apId]).view();
    p.setRedirect(true);
    return p;		
	}


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

}