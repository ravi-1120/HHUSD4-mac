/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_ApproverSelectorController.cls
* @description - Controller class for user approval selection
* @createdate - Feb 4th, 2014
*
*/
public without sharing class MRK_ApproverSelectorController {

	private Map<string,string> pageParams = ApexPages.currentPage().getParameters();
	private Id objectId, submitterUserId;
    private String objectTypeName;
	public List<MRK_SelectedUserWrapper> availableApproversList { get; set; }
	public String userPrompt {get; set;}


	public MRK_ApproverSelectorController() {
		objectId = pageParams.get('id');
		objectTypeName = ((Id)objectId).getSObjectType().getDescribe().getName();
		String objectName = (String)Database.query('select Name from ' + objectTypeName + ' where Id = :objectId')[0].get('Name');
		userPrompt = 'Select Approver for ' + objectName;

		this.submitterUserId = pageParams.get('userid');
		// set userid to current user id not provided in URL query params
		if (submitterUserId == null) {
			submitterUserId = UserInfo.getUserId();
		}
		
		availableApproversList = MRK_ApprovalProcessServices.getInstance().getAvailableApprovers(submitterUserId, objectId);
		
	}

	public PageReference submitForApproval() {

		// get selected user
		Id selectedUserId = null;
		for (MRK_SelectedUserWrapper uw : availableApproversList) {
			if (uw.selected) {
				selectedUserId = uw.u.Id;
			}
		}

		// ensure a user is selected
		if (selectedUserId == null) {
			// TODO: put message to user in MRK_Settings 
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'You must select an approver before submitting'));
			system.debug(Logginglevel.INFO, 'bp - approver not selected');			
			return null;
		}

		// submit for approval
		try {
			MRK_ApprovalProcessServices.getInstance().submitForApproval(objectId, submitterUserId, selectedUserId);
		} catch (Exception e) {
			ApexPages.addMessages(e);
			return null;
		}

		// insert share record
		//
		// if (user does not have visibility to record)
		//     grant visibility - use *_Share for top level, ATL for Account
		//     delegate this work out to a Provider class to encapsulate the
		//     specifics of sharing for a particular object

		// fetch post submit for approval redirect page.  may vary depending on object type
		String redirectURL = MRK_ApprovalProcessServices.getInstance().getPostSubmitForApprovalRedirectURL(objectId, submitterUserId);
		return new PageReference(redirectURL);
	}

	public PageReference cancel() {
		return new PageReference('/' + objectId);
	}

}