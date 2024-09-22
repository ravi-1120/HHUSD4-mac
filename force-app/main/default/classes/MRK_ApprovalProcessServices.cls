/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_ApprovalProcessServices.cls
* @description - Services class for Approval Processes
* @createdate - Feb 4th, 2014
*
*/

public class MRK_ApprovalProcessServices {

	public static final String SETTING_NAME = 'CUSTOM_APPROVAL_PROCESS';
	private static MRK_ApprovalProcessServices instance = null;
	private static Map<String, MRK_IApprovalProcessServices> objectNameToApprovalProcessServicesInstanceMap = new Map<String, MRK_IApprovalProcessServices>();

	public static MRK_ApprovalProcessServices getInstance() {
		if (instance == null) {
			instance = new MRK_ApprovalProcessServices();
		}
		return instance;
	}

	public MRK_IApprovalProcessServices getApprovalProcessServicesInstance(Id objectId) {
		String objectTypeName = ((Id)objectId).getSObjectType().getDescribe().getName();

		MRK_IApprovalProcessServices approvalProcessServicesInstance = objectNameToApprovalProcessServicesInstanceMap.get(objectTypeName);

		if (approvalProcessServicesInstance != null) {
			return approvalProcessServicesInstance;
		}
		

		Map<String, Object> objectNameToApprovalProcessServicesClassName = (Map<String, Object>)MRK_Setting.getObject(SETTING_NAME, 'object name to approval process services class name');
		String className = (String)objectNameToApprovalProcessServicesClassName.get(objectTypeName);

	  Type approvalProcessServicesType = System.Type.forName(className);

	  if(approvalProcessServicesType != null) {
	      try {
	     		approvalProcessServicesInstance = (MRK_IApprovalProcessServices) approvalProcessServicesType.newInstance();
	        objectNameToApprovalProcessServicesInstanceMap.put(objectTypeName, approvalProcessServicesInstance);
	      } catch(System.TypeException e) {
	          //resultMsg = customSettingValue + ' does not implement BATCH_SURVEY_PUBLISH_INTERFACE';
	      } catch(Exception e) {
	          // Specifically, this is for a thrown common.apex.runtime.impl.ExecutionException
	          //resultMsg = customSettingValue + ' does not have a no-args constructor';
	      }
	  } else {
	      // batchType is null if no Apex class with the given name is found.
	      //resultMsg = 'Could not find Apex class with name ' + customSettingValue;
	  }
	  return approvalProcessServicesInstance;
	}

	public List<MRK_SelectedUserWrapper> getAvailableApprovers(Id userid, Id objectId) {

		MRK_IApprovalProcessServices aps = getApprovalProcessServicesInstance(objectId);
		List<User> userList = aps.getAvailableApprovers(userid, objectId);
		User defaultApprover = aps.getDefaultApprover(userid, objectId);
		Boolean defaultApproverSelected = false;
		List<MRK_SelectedUserWrapper> availableApproversList = new List<MRK_SelectedUserWrapper>();

		for (User u : userList) {
			MRK_SelectedUserWrapper uw = new MRK_SelectedUserWrapper(u);
			if ( (defaultApprover != null) && (defaultApprover.Id == u.Id) ) {
				uw.selected = true;				
				defaultApproverSelected = true;
			}
			availableApproversList.add(uw);
		}

		// if default approver not set or available, set to first in list
		if (!defaultApproverSelected) {
				availableApproversList[0].selected = true;			
		}

		return availableApproversList;
	}

	public Boolean allowSubmitForApproval(Id objectId, Id requestorUserId) {
		MRK_IApprovalProcessServices aps = getApprovalProcessServicesInstance(objectId);
		return aps.allowSubmitForApproval(objectId, requestorUserId);
	}

	public Boolean allowRecallApprovalRequest(Id objectId, Id requestorUserId) {
		MRK_IApprovalProcessServices aps = getApprovalProcessServicesInstance(objectId);
		return aps.allowRecallApprovalRequest(objectId, requestorUserId);
	}

	public Boolean allowApproveReject(Id objectId, Id requestorUserId) {
		MRK_IApprovalProcessServices aps = getApprovalProcessServicesInstance(objectId);
		return aps.allowApproveReject(objectId, requestorUserId);
	}

	public void submitForApproval(Id objectId, Id submitterUserId, Id approverUserId) {
		// template
		// String settingValue = MRK_Setting.getString(SETTING_NAME, 'setting id');

		MRK_IApprovalProcessServices aps = getApprovalProcessServicesInstance(objectId);

		Boolean approverHasVisibility = aps.ensureApproverVisibiltyToObject(approverUserid, objectId);
		// TODO: what should happen if granting visibility fails?
		if (!approverHasVisibility) {

		}

    Approval.ProcessSubmitRequest req = 
        new Approval.ProcessSubmitRequest();
    //req.setComments('Submitting request for approval.');
    req.setObjectId(objectId);
		req.setNextApproverIds(new Id[] {approverUserId});
    
    // Submit the approval request
    Approval.ProcessResult result = Approval.process(req);

		if ( !result.isSuccess() ) {
			throw new ApplicationException('Failed to submit record with Id = "' + objectId + '" for approval');
		}


		// update the Last Selected Approver on the submitters User record
		try {
			User submitter = [select Id, Last_Selected_Approver_MRK__c from User where Id =: submitterUserid];
			
			// only update if it's changed
			if (submitter.Last_Selected_Approver_MRK__c != approverUserId) {
				submitter.Last_Selected_Approver_MRK__c = approverUserId;
				update submitter;				
			}
		} catch (Exception e) {
			throw new ApplicationException('Failed to set Last Selected Approver on record with Id = "' + objectId + '"');
		}

		// stamp the approver on the record
		String objectTypeName = ((Id)objectId).getSObjectType().getDescribe().getName();
 		sObject obj = Database.query('select Id, Approval_Submitter_MRK__c, Approval_Total_Submit_Count_MRK__c, Approval_Approver_MRK__c, Approval_Initial_Submit_Date_MRK__c, Approval_Latest_Submit_Date_MRK__c from ' + objectTypeName + ' where Id = :objectId')[0];
		obj.put('Approval_Submitter_MRK__c', submitterUserId);
		obj.put('Approval_Approver_MRK__c', approverUserId);

		// set initial submit date if it doesn't exist
		if (obj.get('Approval_Initial_Submit_Date_MRK__c') == null) {
			obj.put('Approval_Initial_Submit_Date_MRK__c', DateTime.now());			
		}

		obj.put('Approval_Latest_Submit_Date_MRK__c', DateTime.now());

		// increment submit count
		Decimal approvalTotalSubmitCount = (Decimal)obj.get('Approval_Total_Submit_Count_MRK__c');
		obj.put('Approval_Total_Submit_Count_MRK__c', (approvalTotalSubmitCount == null) ? 1 : (approvalTotalSubmitCount + 1) );

		try {
			update obj;
		} catch (Exception e) {
			throw new ApplicationException('Failed to set approver (Approver_MRK__c) on record with Id = "' + objectId + '"');
		}

	}

	public String getPostSubmitForApprovalRedirectURL(Id objectId, Id submitterUserId) {
		MRK_IApprovalProcessServices aps = getApprovalProcessServicesInstance(objectId);
		return aps.getPostSubmitForApprovalRedirectURL(objectId, submitterUserId);
	}

	public void testSubmitForApproval() {
		Id objectId = 'a0CZ000000PHlTe';
		Id approverUserId = [select Id from User where Username = 'jennifer.lee4@merck.com.hhusd1' limit 1].Id;
		Id submitterUserId = [select Id from User where Username = 'account.executive@merck.com.hhusd1' limit 1].Id;
		submitForApproval(objectId, submitterUserId, approverUserId);
	}

	public void recallApprovalRequest(String objectId) {
		// find approval process work item
		List<ProcessInstanceWorkitem> workItemList = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :objectId AND ProcessInstance.Status = 'Pending'];
		if (workItemList.size() == 0) {
			// no pending approval request for the specified objectId
			// TODO: what is the appropriate action?
			return;
		}

		// remove approval process instance
		Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
		//req.setComments('Removing request.');
		req.setAction('Removed');
		req.setWorkitemId(workItemList[0].Id);
		Approval.ProcessResult result = Approval.process(req);
		if ( !result.isSuccess() ) {
			throw new ApplicationException('Failed to remove record with Id = "' + objectId + '" from approval process');
		}		

	}

	public List<Map<String, String>> getApprovalHistoryRecordList(Id recordId) {
		List<Map<String, String>> approvalHistoryRecordList = new List<Map<String, String>>();

		List<ProcessInstance> piList = [SELECT CreatedById, CreatedDate, Id, LastModifiedById, LastModifiedDate, Status, TargetObjectId, (SELECT Id, StepStatus, CreatedDate, Comments, OriginalActor.Name, Actor.Name FROM Steps order by CreatedDate desc) FROM ProcessInstance where TargetObjectId = :recordId order by LastModifiedDate desc];

		for (ProcessInstance pi : piList) {
			Map<String, String> approvalRecord = new Map<String, String>();
			
			approvalRecord.put('Status', (pi.Status == 'Started') ? 'Submitted' : pi.Status);
			approvalRecord.put('Assigned To', pi.Steps[0].OriginalActor.Name);
			approvalRecord.put('Actual Approver', pi.Steps[0].Actor.Name);
			approvalRecord.put('Comments', (pi.Steps[0].Comments == null) ? '' : pi.Steps[0].Comments);
			approvalRecord.put('Overall Status', pi.Status);

					    
	    if (pi.Steps.size() == 1) {
	    	approvalRecord.put('Date', pi.LastModifiedDate.format());
	    	approvalRecord.put('Status', 'Submitted');
	    	approvalRecord.put('Overall Status', '');

	    	ProcessInstanceWorkitem piw = [select Actor.Name, CreatedById, CreatedDate, Id, IsDeleted, OriginalActor.Name, ProcessInstanceId from ProcessInstanceWorkitem where ProcessInstanceId =: pi.Id];

				Map<String, String> approverRecord = new Map<String, String>();
				approverRecord.put('Date', piw.CreatedDate.format());
				approverRecord.put('Status', 'Pending');
				approverRecord.put('Assigned To', piw.OriginalActor.Name);
				approverRecord.put('Actual Approver', piw.Actor.Name);
				approverRecord.put('Comments', '');
				approverRecord.put('Overall Status', 'Pending');

				approvalHistoryRecordList.add(approverRecord);
	    	approvalHistoryRecordList.add(approvalRecord);				

	    } else {

	    	approvalRecord.put('Date', pi.Steps[0].CreatedDate.format());

				Map<String, String> approverRecord = new Map<String, String>();
				approverRecord.put('Date', pi.Steps[1].CreatedDate.format());
				approverRecord.put('Status', (pi.Steps[1].StepStatus == 'Started') ? 'Submitted' : pi.Steps[1].StepStatus);
				approverRecord.put('Assigned To', pi.Steps[1].OriginalActor.Name);
				approverRecord.put('Actual Approver', pi.Steps[1].Actor.Name);
				approverRecord.put('Comments', (pi.Steps[1].Comments == null) ? '' : pi.Steps[1].Comments);
				approverRecord.put('Overall Status', pi.Status);

				approvalHistoryRecordList.add(approvalRecord);
				approvalHistoryRecordList.add(approverRecord);
	    }
	  }
	  return approvalHistoryRecordList;
	}

	public void testRecallApprovalRequest() {
		Id objectId = 'a0CZ000000OOoe9';
		//Id approverUserId = [select Id from User where Username = 'brian.pfeil@merck.com.hhusd1' limit 1].Id;
		recallApprovalRequest(objectId);
	}


	public class ApplicationException extends Exception {}
}