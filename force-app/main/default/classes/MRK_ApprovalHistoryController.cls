/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_ApprovalHistoryController.cls
* @description - Controller class for approval history page(s)
* @createdate - Mar 25th, 2014
*
*/

public without sharing class MRK_ApprovalHistoryController {

	private Map<string,string> pageParams = ApexPages.currentPage().getParameters();
	private final Id recordId;

	public List<ProcessInstance> processInstanceList {set;get;}
	public Boolean hasApprovalHistoryRecords {set; get;}

	public List<Map<String, String>> approvalHistoryRecordList {set; get;}
	
	public Boolean showButtons {set; get;}

	public Boolean showSubmitForApprovalButton {set; get;}
  public String submitForApprovalOnClickJS {set; get;}

	public Boolean showRecallApprovalRequestButton {set; get;}
	public String recallApprovalRequestOnClickJS {set; get;}

	public Boolean showApproveRejectButton {set; get;}
	public String approveRejectOnClickJS {set; get;}

	public List<String> noRecordsToDisplay {set;get;}

	public MRK_ApprovalHistoryController(ApexPages.StandardController controller) {
		this.recordId = controller.getId();

		this.noRecordsToDisplay = new List<String>();
        
    this.submitForApprovalOnClickJS = getNavigateToLinkWithConfirmationJS( getSubmitForApprovalLink(), 'Once you submit this record for approval, you might not be able to edit it or recall it from the approval process depending on your settings. Continue?' );
		this.showSubmitForApprovalButton = MRK_ApprovalProcessServices.getInstance().allowSubmitForApproval(this.recordId, getUserId());    

    this.recallApprovalRequestOnClickJS = getNavigateToLinkWithConfirmationJS( getRecallApprovalRequestLink(), 'Are you sure you want to recall this approval request?' );
		this.showRecallApprovalRequestButton = MRK_ApprovalProcessServices.getInstance().allowRecallApprovalRequest(this.recordId, getUserId());    
    
    this.approveRejectOnClickJS = getNavigateToLinkJS( getApproveRejectLink() );
		this.showApproveRejectButton = MRK_ApprovalProcessServices.getInstance().allowApproveReject(this.recordId, getUserId());
		
		this.showButtons = this.showSubmitForApprovalButton || this.showRecallApprovalRequestButton || this.showApproveRejectButton;

		this.approvalHistoryRecordList = MRK_ApprovalProcessServices.getInstance().getApprovalHistoryRecordList(this.recordId);
		this.hasApprovalHistoryRecords = this.approvalHistoryRecordList.size() > 0;
	}

	private String getNavigateToLinkJS(String url) {
		return 'top.location = "' + url + '"';
	}

	private String getNavigateToLinkWithConfirmationJS(String url, String confirmMessage) {
		return '(function () { var resp = confirm(\'' + confirmMessage + '\');if (resp) { top.location = "' + url + '"; } })();';
	}
    
  private String getSubmitForApprovalLink() {
		return '/apex/MRK_ApproverSelector?id=' + this.recordId + '&userid=' + getUserId();
  }

  private String getRecallApprovalRequestLink() {
  	return '/apex/MRK_ApprovalProcessServices?action=recallApprovalRequest&id=' + this.recordId + '&userid=' + getUserId();
  }

  private String getApproveRejectLink() {
  	String url = '';

  	List<ProcessInstance> processInstanceList = [select Id from ProcessInstance where TargetObjectId = :this.recordId order by LastModifiedDate desc limit 1];
		
		if (processInstanceList.size() > 0) {
			Id processInstanceId = processInstanceList[0].Id;

			List<ProcessInstanceWorkitem> processInstanceWorkitemList = new List<ProcessInstanceWorkitem>();
			processInstanceWorkitemList = [select Id, ProcessInstanceId from ProcessInstanceWorkitem where ProcessInstanceId =: processInstanceId limit 1];
			
			if (processInstanceWorkitemList.size() > 0) {
				Id processInstanceWorkitemId = processInstanceWorkitemList[0].Id;
				url = '/p/process/ProcessInstanceWorkitemWizardStageManager?id=' + processInstanceWorkitemId;		
			}
			
		}

		return url;
  }

  private Id getUserId() {
		String userid = pageParams.get('userid');
		if (userid == null) {
			userid = UserInfo.getUserId();
		}
		return userid; 	
  }

}