public class VeevaCallTriggerHandler extends VeevaTriggerHandler {
    
    @TestVisible private List<Call2_vod__c> newCalls;
    @TestVisible private List<Call2_vod__c> oldCalls;
    @TestVisible private Map<ID, Call2_vod__c> newCallsMap;
    @TestVisible private Map<ID, Call2_vod__c> oldCallsMap;
    
    @TestVisible private static Map<String, String> errorMsgs = new Map<String, String>();
    @TestVisible private static VOD_ERROR_MSG_BUNDLE msgBundle;
    
    @TestVisible public static Set<String> sigReqUUIDToSkip = new Set<String>();
    @TestVisible private static Map<String, Call2_vod__c> sigReqUUIDToCall = new Map<String, Call2_vod__c>();
    @TestVisible private static Map<String, Signature_Request_vod__c> sigReqUUIDToSigReq = new Map<String, Signature_Request_vod__c>();
	@TestVisible private static Map<String, Id> mobileIdtoCallId = new Map<String, Id>();
    @TestVisible private static boolean updateIsFromFutureTask = false;
    
    private enum DmlOperationType { INSERT_OBJECTS, DELETE_OBJECTS }
    
    @TestVisible protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
    	newCalls = (List<Call2_vod__c>) triggerNew;
        oldCalls = (List<Call2_vod__c>) triggerOld;
        newCallsMap = (Map<ID, Call2_vod__c>) triggerNewMap;
        oldCallsMap = (Map<ID, Call2_vod__c>) triggerOldMap;

		for(Call2_vod__c newCall: newCalls) {
            String sigReqUUID = newCall.Signature_Request_UUID_vod__c;
            if(String.isNotBlank(sigReqUUID) && !sigReqUUIDToSkip.contains(sigReqUUID)) {
                sigReqUUIDToCall.put(sigReqUUID, newCall);
            }
			mobileIdtoCallId.put(newCall.Mobile_ID_vod__c, newCall.Id);
        }        
    }
    
    protected override String sObjectType() {
        return 'Call2_vod__c ';
    }
    
    protected override void beforeInsert() {
        beforeInsertUpdate();
    }

    protected override void beforeUpdate() {
        //Skip triggers if the update of call is triggered from the future task in this same trigger.
        if(!updateIsFromFutureTask) {
        	beforeInsertUpdate();
        }
    }
    
    private void beforeInsertUpdate() {
        if (VEEVA_SAMPLE_CANCEL.isSampleCancel || CallSampleManagement.inSampleManagement || VOD_CALL2_ATTACHMENT_CLASS.inCallAttachment) {
        	return;
    	}

    	// If this is a Concur Update, then skip all Call trigger logic.
    	if (Trigger.isUpdate && VEEVA_CONCUR_UTILS.isConcurUpdate(oldCalls, newCalls)) {
        	// This is a Concur update. Set the Override Lock to false
        	for(Call2_vod__c call : newCalls) {
            	if(call.Override_Lock_vod__c) {
                	call.Override_Lock_vod__c = false;
            	}
        	}
            
        	return;
    	}

    	List<String> childAccountIds = new List<String>();
		List<Expense_vod__c> emptyExpenses = [SELECT Id, Call2_vod__c FROM Expense_vod__c WHERE Call2_vod__c IN :newCallsMap.keySet() AND Amount_vod__c <= 0.0];        
        Map<Id, Boolean> callHasEmptyExpense = new Map<Id, Boolean>();
        for (Expense_vod__c expense : emptyExpenses) {
            callHasEmptyExpense.put(expense.Call2_vod__c, true);
        }
   		for (Call2_vod__c call : newCalls) {
   			// Mark off Calls as either needing a Concur Sync or not
			if(VEEVA_CONCUR_UTILS.concurSyncPending(call, !callHasEmptyExpense.containsKey(call.Id))) {
            	call.Expense_Post_Status_vod__c = 'Pending';
       		}
            
        	childAccountIds.add(call.Child_Account_Id_vod__c);
   		}

    	if (Trigger.isUpdate) {
        	for (Integer i=0; i<newCalls.size(); i++) {
                Call2_vod__c newCall = newCalls[i];
            	Call2_vod__c copyCall = new Call2_vod__c(Id = newCall.Id,
                    	Add_Key_Message_vod__c = newCall.Add_Key_Message_vod__c,
                    	Add_Detail_vod__c = newCall.Add_Detail_vod__c,
                    	Status_vod__c = newCall.Status_vod__c,
                    	No_Disbursement_vod__c = newCall.No_Disbursement_vod__c,
                    	Override_Lock_vod__c = newCall.Override_Lock_vod__c);
                            	VOD_CALL2_HEADER_CLASS.putIfAbsentToBeforeMap(newCall.Id, copyCall);
        	}
    	}
            
    	Map<Id, Call2_vod__c> calls = new Map<Id, Call2_vod__c> ([Select Id, Override_Lock_vod__c,
                                                                  (Select Name, Id from Call2_vod__r)
                                                                  From Call2_vod__c
                                                                  Where Id in :newCalls]);
        
    	List<Child_Account_vod__c> childAccounts = new List<Child_Account_vod__c>([Select Id From Child_Account_vod__c Where Id in :childAccountIds]);
    	Set<String> idSet = new Set<String>();
    	for(Child_Account_vod__c acct : childAccounts) {
        	idSet.add(acct.Id);
    	}
            
    	boolean isSaveTransaction = VeevaSettings.isEnableSamplesOnSave();
    	List<Call2_vod__c> updCallList = new List<Call2_vod__c>();
    	for (Integer i = 0 ;  i < newCalls.size(); i++) {
        	Call2_vod__c newCall = newCalls[i];
         	if (newCall.Territory_vod__c == null || newCall.Territory_vod__c == '') {
                String terr = VOD_CALL2_HEADER_CLASS.getMyFirstTerr();
                if (terr != null) {
                    newCall.Territory_vod__c = terr;
                }
            }
       
        	if (newCall.Attendee_Type_vod__c != null && newCall.Attendee_Type_vod__c.length() > 0 &&  
                	newCall.Entity_Reference_Id_vod__c != null && newCall.Entity_Reference_Id_vod__c.length() > 0) {
                if ('Person_Account_vod' == newCall.Attendee_Type_vod__c  || 'Group_Account_vod' == newCall.Attendee_Type_vod__c ) {
                    newCall.Account_vod__c = newCall.Entity_Reference_Id_vod__c;
                    newCall.Entity_Reference_Id_vod__c = null;                   
                } else if ('Contact_vod' == newCall.Attendee_Type_vod__c) {
                    newCall.Contact_vod__c = newCall.Entity_Reference_Id_vod__c;
                    newCall.Entity_Reference_Id_vod__c = null;  
                } else if ('User_vod' == newCall.Attendee_Type_vod__c) {
                    newCall.User_vod__c = newCall.Entity_Reference_Id_vod__c;
                    newCall.Entity_Reference_Id_vod__c = null;  
                } else if ('Event_vod' == newCall.Attendee_Type_vod__c) {
                    newCall.Medical_Event_vod__c = newCall.Entity_Reference_Id_vod__c;
                    newCall.Entity_Reference_Id_vod__c = null;  
                }       
            }
            
            newCall.Location_Name_vod__c = newCall.Location_Id_vod__c;
            if (Trigger.isInsert || idSet.contains(newCall.Child_Account_Id_vod__c)) {
                newCall.Child_Account_vod__c = newCall.Child_Account_Id_vod__c;
            }
            //Stamp new offline ship to location fields
            VOD_CALL2_HEADER_CLASS.stampShipToLocation(newCall);
        
        	if (newCall.Call_Datetime_vod__c != null) {
            	//We check to see if the Call_Datetime_vod__c has write FLS.
            	//We also throw error only if old date and new date are different, to avoid error when event color, etc is changed.
            	//If not we throw an error to ensure the field value is cleared before user can reschedule calls
            	if (Trigger.isUpdate && newCall.Call_Date_vod__c != oldCalls[i].Call_Date_vod__c && 
                    !Schema.sObjectType.Call2_vod__c.fields.Call_Datetime_vod__c.isUpdateable()) {
                	newCall.Call_Datetime_vod__c.addError('', false);
            	}
            	// We have the datetime so we must populate date
            	DateTime dt = newCall.Call_Datetime_vod__c;   
            	newCall.Call_Date_vod__c = Date.newInstance(dt.year(), dt.month(), dt.day());    
        	} else if (newCall.Call_Datetime_vod__c == null && newCall.Call_Date_vod__c == null) {
            	newCall.Call_Date_vod__c = System.today();
        	}
        
        	Date today = System.today();
        	if (newCall.Status_vod__c == 'Submitted_vod' && newCall.Call_Date_vod__c > today) {
            	if(newCall.Call_Datetime_vod__c == null) {
            		newCall.Call_Date_vod__c.addError(getErrorMessage('FUTURE_DATE','Tablet'), false);
            	} else {
            		newCall.Call_Datetime_vod__c.addError(getErrorMessage('FUTURE_DATE','Tablet'), false);                
            	}
        	} 
        
        	if (Trigger.isInsert) {
            	//Clean out temp fields
            	if (newCall.Add_Detail_vod__c == 'DELETE') {
                	newCall.Add_Detail_vod__c = null;
            	}
            	if (newCall.Add_Key_Message_vod__c == 'DELETE') {
                	newCall.Add_Key_Message_vod__c = null;
            	}
        	}
            
        	if (newCall.Unlock_vod__c == true) {
            	VOD_CALL2_HEADER_CLASS.setUpdateAction (true);
            	Call2_vod__c callParent = calls.get(newCall.Id);
            	newCall.Status_vod__c = 'Saved_vod';
            	newCall.Unlock_vod__c = false;
            	newCall.Submitted_By_Mobile_vod__c = false;
    
            	for (Call2_vod__c childCall : callParent.Call2_vod__r) {
                	Call2_vod__c updCall = new Call2_vod__c (Id = childCall.Id,
                                                    Submitted_By_Mobile_vod__c = false,
                                                     Unlock_vod__c = true);
                	updCallList.add(updCall);
            	}
            	continue;
        	} 
            
        	if (Trigger.isUpdate) {
         		Call2_vod__c callHead = oldCalls[i];
            
            	// If a call is Save on Sample and has a sample, dont let the OwnerId change.
            	if (isSaveTransaction == true && callHead.Status_vod__c == 'Saved_vod' && (
                    callHead.Signature_vod__c != null || 
                    callHead.Sample_Card_vod__c != null || 
                    callHead.Sample_Send_Card_vod__c != null)) {
                    	if (newCall.OwnerId != oldCalls[i].OwnerId)
                        	newCall.OwnerId = oldCalls[i].OwnerId;
            	}
                  
            	Call2_vod__c callParent = calls.get(newCall.Id);
            	if ((oldCalls[i].Status_vod__c == 'Submitted_vod')  &&
                    (newCall.Override_Lock_vod__c == false) &&
                    (callParent.Override_Lock_vod__c == false)) {
                	newCall.Status_vod__c.addError(getErrorMessage('NO_UPD_SUB','TriggerError'), false);
                	continue;
            	}
                
            	newCall.Add_Detail_vod__c = null;
            	newCall.Add_Key_Message_vod__c = null;
            	newCall.No_Disbursement_vod__c = false;
            	newCall.Override_Lock_vod__c = false;
            	if (newCall.Status_vod__c == 'Submitted_vod' && VOD_CALL2_HEADER_CLASS.getUpdateAction () == false &&
                    	VOD_CALL2_HEADER_CLASS.getInsertAction() == false) {
                	newCall.Status_vod__c = 'Saved_vod';
            	}
        	}
    	}
        
    	if (updCallList.size () > 0) {
        	System.debug ('# of headers - ' + updCallList.size ());
        	update updCallList;
    	}

    	VeevaCountryHelper.updateCountryFields(Call2_vod__c.getSObjectType(), Call2_vod__c.OwnerId, Call2_vod__c.Account_vod__c, Trigger.isUpdate, newCalls, oldCalls);
    	VeevaCallChannelHelper.setCallChannel(Trigger.isAfter, Trigger.isUpdate, newCalls);
        
        //Clear the signature request UUID on Call if signature request is invalid.
        clearSigReqUUIDOnCall(false);
    }
    
    @TestVisible protected override void beforeDelete() {
    	String ProfileId = UserInfo.getProfileId();
    	Profile pr = [Select Id, PermissionsModifyAllData From Profile where Id = :ProfileId];
        
    	boolean modAllData = false;
        if (pr != null && pr.PermissionsModifyAllData) {
        	modAllData = true;            
        }
        
        Map<Id, Call2_vod__c> callMaps = new Map<Id, Call2_vod__c> ([SELECT Id, Parent_Call_vod__c, Parent_Call_vod__r.Status_vod__c, Remote_Meeting_vod__c, MS_Teams_Remote_Meeting_vod__c,  
                                               (SELECT Id, Call2_vod__c 
                                                FROM Call_Objectives_vod__r) 
                                               from Call2_vod__c 
                                               where ID in :oldCalls]);
        
        CallSampleManagement.onDeleteCall(oldCallsMap);

    	boolean callArchiveUser = false;
    	Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getOrgDefaults();
    	if (vsc !=  null && vsc.CALL_ARCHIVE_USER_vod__c == UserInfo.getUserName()) {
        	callArchiveUser = true;
        }

    	boolean isEnableSamplesOnSave = VeevaSettings.isEnableSamplesOnSave();
    	List<String> callIds = new List<String>();
        List<ID> callIdsForUtDeletion = new List<ID>();
        List<Unavailable_Time_vod__c> utsToDelete = new List<Unavailable_Time_vod__c>();
    	for (Integer i = 0 ; i < oldCalls.size(); i++) {
        	Call2_vod__c info =  callMaps.get(oldCalls[i].Id);
            String parentStatus = '';
            
            if(info != null) {
        		parentStatus = info.Parent_Call_vod__r.Status_vod__c;

        		if (info.Call_Objectives_vod__r != null) {
            		for (Call_Objective_vod__c objective : info.Call_Objectives_vod__r) {
                		objective.Call2_vod__c = null;
                		VEEVA_CALL_OBJECTIVE_TRIG.objectives.add(objective);
            		}
        		}
            }

        	if (callArchiveUser) {
            	callIds.add(oldCalls[i].Id);
        	} else {
            	if (isEnableSamplesOnSave &&
                    oldCalls[i].Status_vod__c == 'Saved_vod' &&
                    (oldCalls[i].Sample_Send_Card_vod__c != null ||  oldCalls[i].Sample_Card_vod__c != null)) {
                    String noDelCallWithTran =  getErrorMessage('NO_DEL_CALL_W_TRAN','TriggerError');
                	oldCalls[i].Status_vod__c.addError(noDelCallWithTran, false);
            	}

            	if (oldCalls[i].Signature_Date_vod__c != null) {
                	if (modAllData == false) {
                    	oldCalls[i].Signature_Date_vod__c.addError(getErrorMessage('NO_SIGNATURE_DELETE', 'Call'), false);
                	}
            	}
                
                if(String.isNotBlank(oldCalls[i].Signature_Request_UUID_vod__c) && 
                   String.isBlank(oldCalls[i].Signature_vod__c)) {
                    String noDelActiveSigReq = getErrorMessage('NO_DEL_PENDING_SIG','TriggerError');
                    oldCalls[i].Signature_Request_UUID_vod__c.addError(noDelActiveSigReq, false);
                }

            	if (oldCalls[i].Status_vod__c == 'Submitted_vod' || parentStatus == 'Submitted_vod') {
                    String noDelSub = getErrorMessage('NO_DEL_SUB','TriggerError');
                	oldCalls[i].Id.addError(noDelSub, false);
            	} else {
                	callIds.add (oldCalls[i].Id);
            	}
        	}

			if (oldCalls[i].Is_Parent_Call_vod__c == 1 && oldCalls[i].Unavailable_for_Scheduling_vod__c) {
				callIdsForUtDeletion.add(oldCalls[i].Id);
			}
    	}

        if (!callIdsForUtDeletion.isEmpty()) {
            utsToDelete.addAll([SELECT Id FROM Unavailable_Time_vod__c WHERE Call2_vod__c IN :callIdsForUtDeletion]);
            handleUnavailableTimeDeletion(utsToDelete);
        }

        List<Call2_vod__c> delCalls = [Select Id from Call2_vod__c where Parent_Call_vod__c in :callIds AND Id NOT IN :callMaps.keySet()];
    	deleteSObjects(delCalls, oldCalls);
		deleteMIFRs();
        deleteRemoteMeetings(callMaps);
		deleteExpenses();
    }
	
    protected override void afterInsert() {
        System.debug ('Number of Insert Transactions = ' + newCalls.size());

    	VOD_CALL2_HEADER_CLASS.setInsertAction (true);
    	VOD_CALL2_ATTACHMENT_CLASS.updateReceiptAttachmentsPending(newCallsMap);
            
    	// obtain the record type ids
    	String eventRecTypeId = VOD_CALL2_HEADER_CLASS.getRecordTypeId('Event');
    	String sampleRecTypeId = VOD_CALL2_HEADER_CLASS.getRecordTypeId('Sample_Transaction_vod__c');

    	List<Call2_Detail_vod__c> detsToAdd = new List<Call2_Detail_vod__c>();
    	List<Call2_vod__c> hdrUpdList = new List <Call2_vod__c>();
    	List<Call2_Key_Message_vod__c> keysToAdd = new List <Call2_Key_Message_vod__c>();
		List<Unavailable_Time_vod__c> utsToCreate = new List<Unavailable_Time_vod__c>();
    	for (Integer k = 0; k < newCalls.size (); k++) {
        	Call2_vod__c mainCall = newCalls[k];
        	addUpdatedHdr(mainCall, hdrUpdList);
            addDetails(mainCall.Add_Detail_vod__c, mainCall, detsToAdd, null, false, null, false);
            addKeyMessages(mainCall.Add_Key_Message_vod__c, mainCall, keysToAdd, null, false);
			if (mainCall.Is_Parent_Call_vod__c == 1 && mainCall.Unavailable_for_Scheduling_vod__c) {
				Unavailable_Time_vod__c ut = new VeevaUnavailableTimeBuilder()
                    .setOwnerId(mainCall.OwnerId)
                    .setCall(mainCall.Id)
					.setStartAndEndDates(mainCall.Call_Datetime_vod__c, mainCall.Duration_vod__c?.intValue())
                    .build();
				utsToCreate.add(ut);
			}
    	}

		handleUnavailableTimeUpsert(utsToCreate);
        
     	VOD_CHILD_SUBMIT.setSubmitCheck(false);

        insertSObjects(detsToAdd);
        insertSObjects(keysToAdd);
        
    	VOD_CHILD_SUBMIT.setSubmitCheck(true);
    
        if (hdrUpdList.size () > 0) {
        	update hdrUpdList;
        }     
        
    	// release memory
    	detsToAdd.clear();
    	keysToAdd.clear();
    	hdrUpdList.clear(); 
        
    	List<Id> accountsList = new List<Id>();  
    	buildAccountParentCallNamesLists(accountsList, null, null);
        
        Map<Id, Account> accounts = new Map<Id,Account>([Select Id,Name,Credentials_vod__c,Salutation,
                                        (Select License_vod__c,State_vod__c 
                                         From Address_vod__r order by Primary_vod__c) 
                                        From Account 
                                        Where Id in :accountsList]);
    	// Now handle events
    	VOD_CALL2_HEADER_CLASS.insertEvent(newCalls, accounts, eventRecTypeId);
        
        processTSF(newCalls, false);
        processCyclePlanRealtimeCalC(newCalls);
        
    	VeevaCallChannelHelper.setCallChannel(Trigger.isAfter, Trigger.isUpdate, newCalls);
		
		if (!System.isFuture() && !System.isBatch()) {
			stampSignatureRequestWithCallIdByMobileId(mobileIdtoCallId);
		}
        processSignatureRequests();

        if(!System.isFuture() && !System.isBatch()) {
            Map<String, Id> callMobileIds = new Map<String, Id>();
            for(Call2_vod__c call : newCalls) {
                if(call.Mobile_ID_vod__c != null) {
                    callMobileIds.put(call.Mobile_ID_vod__c, call.Id);
                }
            }
            VeevaUpdateDocumentedInterestFuture.updateDocumentedInterest(callMobileIds);
        }
    }
    
    protected override void afterUpdate() {
        if (VEEVA_SAMPLE_CANCEL.isSampleCancel || CallSampleManagement.inSampleManagement ||  VOD_CALL2_ATTACHMENT_CLASS.inCallAttachment) {
            return;
    	}
        
        //Skip triggers if the update of call is triggered from the future task in this same trigger.
        if(updateIsFromFutureTask) {
            return;
        }
        
    	//System.debug ('Number of Transactions = ' + newCalls.size());
        if (VOD_CALL2_HEADER_CLASS.getInsertAction() == true) {
        	return;
        }

    	// If this is a Concur Update, then skip all Call trigger logic.
    	if (VEEVA_CONCUR_UTILS.isConcurUpdate(oldCalls, newCalls)) {
        	return;
    	}

    	VOD_CALL2_ATTACHMENT_CLASS.updateReceiptAttachmentsPending(newCallsMap);

        if (VOD_CALL2_HEADER_CLASS.getUpdateAction() == true) {
        	return;
        }

    	VOD_CALL2_HEADER_CLASS.setUpdateAction(true);

    	String eventRecTypeId = VOD_CALL2_HEADER_CLASS.getRecordTypeId('Event');
    	String sampleRecTypeId = VOD_CALL2_HEADER_CLASS.getRecordTypeId('Sample_Transaction_vod__c');
    	String sampleOrderRectypeId = VOD_CALL2_HEADER_CLASS.getRecordTypeId('Sample_Order_Transaction_vod__c');

    	// fetch the product types which  has no lot vod and needs creation of No_Lot_vod
    	Set<String> noLotproductTypes = getNoLotProductTypes();

    	Map <Id, Call2_vod__c> callMap =
            	new Map <Id, Call2_vod__c>(
                    	[Select Id,
                            	License_vod__c,
                            	Parent_Address_vod__c,
                            	Address_vod__c,
                            	OwnerId,
                            	(Select Id,
                                    	User_vod__c,
                                    	Account_vod__c,
                                    	Contact_vod__c,
                                    	Call_Date_vod__c
                                    	from Call2_vod__r),
                            	(Select Id
                                    	from Events
                                    	where RecordTypeId=:eventRecTypeId),

                            	(Select Id,
                                    	Name,
                                    	Lot_vod__c,
                                    	Product_vod__c,
                                    	Quantity_vod__c,
                                    	Distributor_vod__c,
                                    	Delivery_Status_vod__c,
                                    	Manufacturer_vod__c, Tag_Alert_Number_vod__c, Cold_Chain_Status_vod__c,Custom_Text_vod__c
                                    	From Call2_Sample_vod__r )
                            	from Call2_vod__c
                            	Where Id in :newCalls]);

    	Set<String> productIds = new Set<String>();
    	Set<String> lotNums = new Set<String>();
    	Set<String> ownerIDs = new Set<String>();
    	for (Call2_vod__c call : callMap.values()) {
        	// store away call names for later use by sample transaction
        	ownerIDs.add (call.OwnerId);
        	for (Call2_Sample_vod__c sample : call.Call2_Sample_vod__r) {
            	if (sample.Lot_vod__c != '') {
                	lotNums.add(sample.Lot_vod__c);
                	productIds.add(sample.Product_vod__c);
            	}
        	}
    	}

    	// now add the name No_Lot_vod which will not be there in call sample
    	lotNums.add('No_Lot_vod');
    	// debug for lot names
    	system.debug('the sample lot names ' +  lotNums);

    	List<Id> accountsList = new List<Id>();
    	List<String> parentIds = new List<String>();
    	List<String> callNames = new List<String>();
		buildAccountParentCallNamesLists(accountsList, parentIds, callNames);

    	Set<String> callsWithTrans = new Set<String>();
    	Set<Sample_Transaction_vod__c> callSampleTrans = new Set<Sample_Transaction_vod__c>();
    	for (Sample_Transaction_vod__c samptrans : [Select Id, Call_Name_vod__c, Sample_vod__c, Lot_vod__c, Tag_Alert_Number_vod__c, Cold_Chain_Status_vod__c,Custom_Text_vod__c
            	From Sample_Transaction_vod__c
            	where Call_Name_vod__c in :callNames
    				and RecordTypeId = :sampleRecTypeId
    				and Lot_vod__r.OwnerId in :ownerIDs]) {
        	callsWithTrans.add(samptrans.Call_Name_vod__c);
        	callSampleTrans.add(samptrans);
    	}

    	Set<String> callsWithOrders = new Set<String>();
        // use direct Sample_Order_Transaction_vod__c -> Call2_Sample_vod__c relation to prevent duplicates
    	for (Sample_Order_Transaction_vod__c sampords
            	: [Select Id,Call_Sample_Id_vod__c
            	From Sample_Order_Transaction_vod__c
            	where Call_Name_vod__c in :callNames
    				and OwnerId in :ownerIDs]) {
        	callsWithOrders.add(sampords.Call_Sample_Id_vod__c);
    	}

    	Map <Id, Call2_vod__c> parents = new Map <Id, Call2_vod__c>([Select Id, Address_vod__c, License_vod__c, Parent_Address_vod__c,
                                                                     (Select Detail_Priority_vod__c, Product_vod__c
                                                                      From Call2_Detail_vod__r),
                                                                     (Select Product_vod__c, Key_Message_vod__c, Reaction_vod__c, Category_vod__c, Vehicle_vod__c
                                                                      From Call2_Key_Message_vod__r)
                                                                     From Call2_vod__c 
                                                                     where Id in :parentIds]);
        
    	Map<Id, Account> accounts = new Map<Id,Account>([Select Id, Name, Credentials_vod__c, Salutation,
                                                         (Select License_vod__c,State_vod__c 
                                                          From Address_vod__r order by Primary_vod__c) 
                                                         From Account 
                                                         Where Id in :accountsList]);
      
        Map<Id, Product_vod__c> products = new Map<Id,Product_vod__c>([Select Id, Name, Product_Type_vod__c, Sample_U_M_vod__c, Manufacturer_vod__c 
                                                                       From Product_vod__c 
                                                                       Where Id In :productIds]);

    	List<Sample_Lot_vod__c> sampleLots = [Select Id, Name, Sample_vod__c, Product_vod__c, Product_vod__r.Product_Type_vod__c, OwnerId 
                                              From Sample_Lot_vod__c 
                                              Where Name In :lotNums And OwnerId IN :ownerIDs];

    	// debugging reasons
    	system.debug(' from trigger the sample lots fetched are ' + sampleLots);
        
    	Map<Id, set<String>> oldDetailProds = new Map<Id, set<String>>();
    	Map<Id, set<String>> newDetailProds = new Map<Id, set<String>>();
    	Map<Id, Call2_vod__c> beforeMap = VOD_CALL2_HEADER_CLASS.getMap();
        
    	List<String> callIds = new List<String>();
    	Set<String> callIdsForDets = new Set<String>();
    	Set<String> callIdsForKeys = new Set<String>();
        
    	List<Call2_Key_Message_vod__c> keysToAdd = new List <Call2_Key_Message_vod__c>();
    	List<Call2_Detail_vod__c> detsToAdd = new List<Call2_Detail_vod__c>();
    	List<Call2_Key_Message_vod__c> delKeyMsg = new List <Call2_Key_Message_vod__c>();
    	List<Call2_Detail_vod__c> delDetails = new List <Call2_Detail_vod__c>();
    	List<Sample_Transaction_vod__c> newTrans = new List<Sample_Transaction_vod__c>();
    	List<Sample_Order_Transaction_vod__c> newOrders = new List<Sample_Order_Transaction_vod__c>();
		List<Unavailable_Time_vod__c> utsToUpsert = new List<Unavailable_Time_vod__c>();
		List<Unavailable_Time_vod__c> utsToDelete = new List<Unavailable_Time_vod__c>();
		List<ID> callIdsForUtDeletion = new List<ID>();
		List<ID> callIdsForUtUpdate = new List<ID>();
        boolean isEnableRealTimeCC = VEEVA_CYCLE_PLAN_REALTIME_CALC.isEnableRealTimeCC();
            
    	for (Integer i = 0; i < newCalls.size(); i++ ) {
        	Call2_vod__c call2 = newCalls[i];
        	Call2_vod__c call2old = oldCalls[i];
        	Call2_vod__c beforeCall2 = beforeMap.get(call2.Id);
        	boolean bPushToChild = false;
            
        	oldDetailProds.put(call2.Id, new set<String>());
        	newDetailProds.put(call2.Id, new set<String>());

        	// handle sample trans
        	if (call2.Account_vod__c != null) {
            	newTrans.addAll(VOD_CALL2_HEADER_CLASS.handleDisbursement(call2,
                    	callMap,
                    	accounts,
                    	parents,
                    	products,
                    	sampleLots,
                    	callsWithTrans,
                    	sampleRecTypeId,
                    	noLotproductTypes,
                    	callSampleTrans,
                    	beforeCall2));

            	newOrders.addAll(VOD_CALL2_HEADER_CLASS.handleOrders(call2,
                    	callMap,
                    	accounts,
                    	parents,
                    	products,
                    	sampleLots,
                    	callsWithOrders,
                    	sampleOrderRectypeId,
                    	noLotproductTypes,
                    	beforeCall2));
        	}


        	// If this a a parent call
        	if (call2.Account_vod__c != call2old.Account_vod__c ||
                        	call2.User_vod__c != call2old.User_vod__c ||
                        	call2.Contact_vod__c != call2old.Contact_vod__c||
                        	call2.Call_Date_vod__c != call2old.Call_Date_vod__c ||
                	(beforeCall2!= null && beforeCall2.Add_Key_Message_vod__c != null &&
                                	'DELETE'.equals (beforeCall2.Add_Key_Message_vod__c) == false)) {
            	bPushToChild = true;
            	if ('DELETE'.equals (beforeCall2.Add_Key_Message_vod__c)) {
                	beforeCall2.Add_Key_Message_vod__c = null;
                	callIdsForKeys.add(call2.Id);
            	}
        	}

			if (call2.Is_Parent_Call_vod__c == 1 && call2old.Unavailable_for_Scheduling_vod__c != call2.Unavailable_for_Scheduling_vod__c) {
				if (call2.Unavailable_for_Scheduling_vod__c) {
					Unavailable_Time_vod__c ut = new VeevaUnavailableTimeBuilder()
						.setOwnerId(call2.OwnerId)
                        .setCall(call2.Id)
                        .setStartAndEndDates(call2.Call_Datetime_vod__c, call2.Duration_vod__c?.intValue())
                        .build();
					utsToUpsert.add(ut);
				} else {
					callIdsForUtDeletion.add(call2.Id);
				}
			} else if (call2.Is_Parent_Call_vod__c == 1 && call2.Unavailable_for_Scheduling_vod__c &&
						(call2old.OwnerId != call2.OwnerId ||
						call2old.Call_Datetime_vod__c != call2.Call_Datetime_vod__c ||
						call2old.Duration_vod__c != call2.Duration_vod__c)) {
				callIdsForUtUpdate.add(call2.Id);
            }
            
            if(beforeCall2 != null) {
            	addDetails(beforeCall2.Add_Detail_vod__c, call2, detsToAdd, callIdsForDets, true, newDetailProds, isEnableRealTimeCC);
            	addKeyMessages(beforeCall2.Add_Key_Message_vod__c, call2, keysToAdd, callIdsForKeys, true);
            }
    	}

		if (!callIdsForUtDeletion.isEmpty()) {
            utsToDelete.addAll([SELECT Id FROM Unavailable_Time_vod__c WHERE Call2_vod__c IN :callIdsForUtDeletion]);
            handleUnavailableTimeDeletion(utsToDelete);
        }

		if (!callIdsForUtUpdate.isEmpty()) {
			List<Unavailable_Time_vod__c> filteredUtsToUpdate = [SELECT Id, Call2_vod__c FROM Unavailable_Time_vod__c WHERE Call2_vod__c IN :callIdsForUtUpdate];
            for (Unavailable_Time_vod__c ut : filteredUtsToUpdate) {
                Id callId = ut.Call2_vod__c;
                Call2_vod__c currentCall2 = this.newCallsMap.get(callId);

				Unavailable_Time_vod__c utToUpsert = new VeevaUnavailableTimeBuilder()
					.setId(ut.Id)
					.setOwnerId(currentCall2.OwnerId)
                    .setCall(currentCall2.Id)
                    .setStartAndEndDates(currentCall2.Call_Datetime_vod__c, currentCall2.Duration_vod__c?.intValue())
                    .build();

				utsToUpsert.add(utToUpsert);
            }
		}

		handleUnavailableTimeUpsert(utsToUpsert);

    	// release memory
    	parents.clear();
    	accounts.clear();
    	products.clear();

        List<Call2_Detail_vod__c> call2Det = new List<Call2_Detail_vod__c>();
    	List<Call2_Key_Message_vod__c> call2Key = new List<Call2_Key_Message_vod__c>();
  		fetchCallDetailAndKeyMessages(callIdsForDets, callIdsForKeys, call2Det, call2Key, oldDetailProds, isEnableRealTimeCC);
        
    	VOD_CHILD_SUBMIT.setSubmitCheck(false);
        
        deleteSObjects(call2Det);
        deleteSObjects(call2Key);
        insertSObjects(keysToAdd);
        insertSObjects(detsToAdd);
        insertSObjects(newOrders);
        insertSObjects(newTrans);

    	VOD_CHILD_SUBMIT.setSubmitCheck(true);
    	VOD_CALL2_HEADER_CLASS.updateEvent(newCalls, callMap, eventRecTypeId);
    	callMap.clear();

    	VeevaCallChannelHelper.setCallChannel(Trigger.isAfter, Trigger.isUpdate, newCalls);

    	processSubmittedCalls(beforeMap);

    	// find out call updates that affect TSF 
    	List<Call2_vod__c> calls = new List<Call2_vod__c>();
    	for (Integer i = 0; i < newCalls.size(); i++) {
        	Call2_vod__c call = newCalls[i];
            if (call.Account_vod__c == null || call.Territory_vod__c == null) {
            	continue;
            }
        	Call2_vod__c oldCall = oldCalls[i];

        	if ((call.Call_Date_vod__c <= System.today()  && call.Status_vod__c != 'Planned_vod'
                && VOD_ProcessTSF.tsfProcessed.contains(call.Id) == false) ||
                (oldCall.Status_vod__c != 'Planned_vod' && call.Status_vod__c == 'Planned_vod')) {
            	calls.add(call);
            	VOD_ProcessTSF.tsfProcessed.contains(call.Id);
        	}
    	}

        processTSF(calls, true);

    	//realtime calculation of cycle plan
    	processCyclePlanRealtimeCalCAfterInsert(beforeMap, oldDetailProds, newDetailProds, isEnableRealTimeCC);
        
        processSignatureRequests();
    }
    
    protected override void afterDelete() {
        processTSF(oldCalls, false);
        processCyclePlanRealtimeCalC(oldCalls);

    	if (!VEEVA_CALL_OBJECTIVE_TRIG.objectives.isEmpty()) {
        	update VEEVA_CALL_OBJECTIVE_TRIG.objectives;
			// CRM-306618
			// If a record fails to be updated or deleted the before/after delete trigger will run again.
			// Because the call objectives are stored in a static list, the list will hold the values on 
			// the rerun and then add those records again. This throws a duplicate Id error when a DML statement
			// is attempted on the list. To prevent this, clear the call objectives list after the update.
			VEEVA_CALL_OBJECTIVE_TRIG.objectives = new List<Call_Objective_vod__c>();
    	}
    }
    
    @TestVisible private Set<String> getNoLotProductTypes() {
        Veeva_Settings_vod__c vsc = VeevaSettings.getVeevaSettings();
    	Set<String> noLotproductTypes = new Set<String> ();
    	if (vsc != null && vsc.Sample_Management_Product_Types_vod__c != null) {
        	List<String> productTypesTemp = vsc.Sample_Management_Product_Types_vod__c.Split(';;');
        	noLotproductTypes.addAll(productTypesTemp);
    	}
        
        return noLotproductTypes;
    }
    
    @TestVisible private void deleteMIFRs() {
    	List<Medical_Inquiry_Fulfillment_Response_vod__c> mifrToDelete = [SELECT Id, Status_vod__c, Interaction_vod__c 
                                                                          FROM Medical_Inquiry_Fulfillment_Response_vod__c
                                                                          WHERE Interaction_vod__c IN :oldCallsMap.keySet() 
                                                                          	AND Status_vod__c != 'Completed_vod'];
    	if (!mifrToDelete.isEmpty()) {
        	delete mifrToDelete;
    	}
    }

	@TestVisible private void deleteExpenses() {
    	List<Expense_vod__c> expensesToDelete = [SELECT Id, Call2_vod__c FROM Expense_vod__c WHERE Call2_vod__c IN :oldCallsMap.keySet()];
    	if (!expensesToDelete.isEmpty()) {
        	delete expensesToDelete;
    	}
    }
    
    @TestVisible private void deleteRemoteMeetings(Map<Id, Call2_vod__c> callMaps) {
    	Set<Id> meetingIdsToDelete = new Set<Id>();
    	for (Call2_vod__c call : callMaps.values()) {
        	if (!String.isEmpty(call.Remote_Meeting_vod__c) && String.isEmpty(call.Parent_Call_vod__c)) {
            	meetingIdsToDelete.add(call.Remote_Meeting_vod__c);
    		}
    		if (!String.isEmpty(call.MS_Teams_Remote_Meeting_vod__c) && String.isEmpty(call.Parent_Call_vod__c)) {
    			meetingIdsToDelete.add(call.MS_Teams_Remote_Meeting_vod__c);
    		}
    	}

        if(!meetingIdsToDelete.isEmpty()) {
    		List<Call2_vod__c> otherCalls = [Select Id, Remote_Meeting_vod__c, MS_Teams_Remote_Meeting_vod__c 
                                             From Call2_vod__c 
                                             where (Remote_Meeting_vod__c IN :meetingIdsToDelete or MS_Teams_Remote_Meeting_vod__c in :meetingIdsToDelete) AND ID NOT IN :callMaps.keySet()];
    		for (Call2_vod__c call : otherCalls) {
        		meetingIdsToDelete.remove(call.Remote_Meeting_vod__c);
        		meetingIdsToDelete.remove(call.MS_Teams_Remote_Meeting_vod__c);
    		}
        }
        
        if(!meetingIdsToDelete.isEmpty()) {
    		Database.delete(new List<Id>(meetingIdsToDelete), false);
        }
    }
    
    @TestVisible private void deleteSObjects(List<SObject> sobjects) {
        deleteSObjects(sobjects, newCalls);
    }
    
    @TestVisible private void deleteSObjects(List<SObject> sobjects, List<Call2_vod__c> calls) {
        doDmlOperation(DmlOperationType.DELETE_OBJECTS, sobjects, calls);
    }
    
    @TestVisible private void insertSObjects(List<SObject> sobjects) {
        doDmlOperation(DmlOperationType.INSERT_OBJECTS, sobjects, newCalls);
    }
    
    @TestVisible private void doDmlOperation(DmlOperationType operationType, List<SObject> sobjects, List<Call2_vod__c> calls) {
        if (sobjects.size () > 0) {
        	try {
                
                switch on operationType {
                    when INSERT_OBJECTS {
                        insert sobjects;
                    }
                    when DELETE_OBJECTS {
                        delete sobjects;
                    }
                }
                
        	} catch (System.DmlException e) {
            	processDMLException(e, calls);
            	return;
        	}
            
        	sobjects.clear();
    	}
    }
    
    @TestVisible private void processDMLException(System.DmlException e, List<Call2_vod__c> calls) {
        Integer numErrors = e.getNumDml();
        String error = '';
        
        System.debug('Error has occured: ' + numErrors);
        System.debug('Error has occured: ' + e);
        
        for (Integer i = 0; i < numErrors; i++) {
            Id thisId = e.getDmlId(i);
            System.debug ('Error info : ' + e.getDmlMessage(i));
            if (thisId != null) {
                error += thisId + ' - ';
            }
            error += e.getDmlMessage(i) + '\n';
        }
        
        for (Call2_vod__c errorRec : calls) {
            errorRec.Id.addError(error, false);
        }
    }
    
    @TestVisible private void processSubmittedCalls(Map<Id, Call2_vod__c> beforeMap) {
        List<Call2_vod__c> submitList = new List<Call2_vod__c>();
        for (integer l = 0; l < newCalls.size(); l++) {
        	Call2_vod__c bfCall= beforeMap.get(newCalls[l].Id);
        	if (bfCall != null && bfCall.Status_vod__c  == 'Submitted_vod') {
            	Call2_vod__c nCall = new Call2_vod__c(Id = newCalls[l].Id, Status_vod__c = 'Submitted_vod');
            	submitList.add(nCall);
        	}
    	}

    	if (submitList.size() > 0) {
        	try {
            	update submitList;
        	} catch (System.DmlException e) {
            	for (Integer m = 0; m < submitList.size(); m++) {
                	String ID = submitList[m].Id;
                	if (ID != null) {
                    	Call2_vod__c call = newCallsMap.get(ID);
                    	if (call != null) {
                        	if (e.getNumDml() > 0) {
                           		System.Debug('Pulling Message from Exception');
                            	call.addError(e.getDmlMessage(0), false);
                        	} else {
                            	System.Debug('Defaulting Message ');
                            	call.addError(getErrorMessage(System.Label.CANNOT_SUBMIT_CALL), false);
                        	}
                    	}
                	}
            	}
       		}
    	}
        
    	submitList.clear();
    }
    
    @TestVisible private void fetchCallDetailAndKeyMessages(Set<String> callIdsForDets, Set<String> callIdsForKeys, 
                                               List<Call2_Detail_vod__c> call2Det, 
                                               List<Call2_Key_Message_vod__c> call2Key, 
                                               Map<Id, set<String>> oldDetailProds,
                                               boolean isEnableRealTimeCC) {
        if (callIdsForDets.size() > 0 || callIdsForKeys.size() > 0) {

        	for (Call2_vod__c call2sForDelete :
        	[Select Id, 
             (Select Id,Call2_vod__c,Product_vod__c, Detail_Group_vod__c  
              From Call2_Detail_vod__r), 
             (Select Id,Call2_vod__c 
              From Call2_Key_Message_vod__r) 
             from  Call2_vod__c 
             where Id in :callIdsForDets or Id in :callIdsForKeys] ) {

            	for (Call2_Detail_vod__c detToCheck : call2sForDelete.Call2_Detail_vod__r) {
                	if (callIdsForDets.contains(detToCheck.Call2_vod__c)) {
                    	call2Det.add(detToCheck);
                    	if(isEnableRealTimeCC && detToCheck.Product_vod__c != null) {
                        	String prodKey = '';
                            if(detToCheck.Detail_Group_vod__c != null) {
                            	prodKey = detToCheck.Detail_Group_vod__c + '_' + detToCheck.Product_vod__c;
                            } else {
                            	prodKey = detToCheck.Product_vod__c;
                            }

                        	oldDetailProds.get(detToCheck.Call2_vod__c).add(prodKey);
                    	}
                	}
            	}
                 
            	for (Call2_Key_Message_vod__c keyTotCheck : call2sForDelete.Call2_Key_Message_vod__r) {
                    if (callIdsForKeys.contains(keyTotCheck.Call2_vod__c)) {
                    	call2Key.add(keyTotCheck);
                    }
            	}

        	}
    	}
    }
    
    @TestVisible private void addUpdatedHdr(Call2_vod__c mainCall, List<Call2_vod__c> hdrUpdList) {
        String addDetails = mainCall.Add_Detail_vod__c;
        String addKeyMsg =  mainCall.Add_Key_Message_vod__c;
        
        if (addDetails != null || addKeyMsg != null || mainCall.Override_Lock_vod__c == true) {
            // Reset helper fields back to initial state
            Call2_vod__c updCallHdr = new Call2_vod__c (Id = mainCall.Id, 
                                                        Add_Detail_vod__c = null, 
                                                        Add_Key_Message_vod__c = null,
                                                        Override_Lock_vod__c = false);
            hdrUpdList.add(updCallHdr);
        }
    }
    
    @TestVisible private void addDetails(String addDetails, Call2_vod__c mainCall, List<Call2_Detail_vod__c> detsToAdd,
                            Set<String> callIdsForDets, boolean doDeleteCheck, Map<Id, set<String>> newDetailProds, boolean isEnableRealTimeCC) {
        // Parent Call just takes the values in the Add_Detail_vod__c field and populates the details.
        // We have details to insert
       	System.debug(addDetails);
        
        if (addDetails != null) {
            
            if(callIdsForDets != null) {
            	callIdsForDets.add(mainCall.Id);
            }
            
            if(doDeleteCheck && 'DELETE'.equals(addDetails) == true) {
                return;
            }
            
            String [] dets = addDetails.split(',');
            
            for (Integer it = 0; it < dets.size(); it++) {
                Double priority  = it + 1;
               	String [] detParts = dets[it].Split(';;');
               	String[] prodKey = detParts[0].Split('_');               
               	String productId = null;
               	String prodGroupId = null;
                    
               	if(prodKey.size() > 1) {
                   	productId = prodKey[1];
                   	prodGroupId = prodKey[0];
               	} else {                                  
                   	productId = prodKey[0];
               	}
                
                System.Debug(productId);
                System.Debug(prodGroupId);
                
                String detType = null;
                if(detParts.size()>1) {
                    detType = detParts[1];
                } else {
                    detType = 'Paper_Detail_vod';
                }
                
                Call2_Detail_vod__c call_det = new Call2_Detail_vod__c (Detail_Priority_vod__c = priority,
                                                                        Product_vod__c = productId ,
                                                                        Detail_Group_vod__c = prodGroupId,
                                                                        Type_vod__c = detType,
                                                                        Call2_vod__c = mainCall.Id,
                                                                        Override_Lock_vod__c = mainCall.Override_Lock_vod__c);
                detsToAdd.add(call_det);
                
                if(newDetailProds != null && isEnableRealTimeCC && detParts[0] != null) {
                    newDetailProds.get(mainCall.Id).add(detParts[0]);
                }
            }  
        }
    }
    
    @TestVisible private void addKeyMessages(String addKeyMsg, Call2_vod__c mainCall, 
                                List<Call2_Key_Message_vod__c> keysToAdd, Set<String> callIdsForKeys, boolean doDeleteCheck) {
        // We have key messages to insert
       	System.debug('Key Message = ' + addKeyMsg);
        
        if(addKeyMsg != null) {
            if(callIdsForKeys != null) {
            	callIdsForKeys.add(mainCall.Id);
            }
            
            if(doDeleteCheck && 'DELETE'.equals(addKeyMsg) == true) {
                return;
            }
            
        	String [] lines = addKeyMsg.split(';;;');
        	System.debug ('# of lines = ' + lines.size());
        
        	if(lines != null) {
            	for (Integer l = 0; l < lines.size(); l++ ) {
                	System.debug ('Line # = ' + l + ' = ' + lines[l]);
                	Call2_Key_Message_vod__c newKeyMsg = 
                            	new Call2_Key_Message_vod__c (Call2_vod__c  = mainCall.Id,
                                                              Account_vod__c = mainCall.Account_vod__c,
                                                              Contact_vod__c = mainCall.Contact_vod__c,
                                                              Call_Date_vod__c = mainCall.Call_Date_vod__c,
                                                              User_vod__c = mainCall.User_vod__c,
                                                              Override_Lock_vod__c = mainCall.Override_Lock_vod__c);
                
                	String [] fields = lines[l].split('@@');
                	if(fields[0] != null  && fields[0] != '') {
                    	newKeyMsg.Key_Message_vod__c = fields[0];
                	}
                
                	if (fields.size() > 1) {
                    	if (fields[1] != null && fields[1] != '') {
                        	String[] prodKey = fields[1].Split('_');
                        	String productId = '';
                        	String prodGroupId = null;
                        
                        	if(prodKey.size() > 1) {
                            	productId = prodKey[1];
                            	prodGroupId = prodKey[0];
                        	} else {
                            	productId = prodKey[0];
                        	}
                        
                        	System.Debug(productId);
                        	System.Debug(prodGroupId);
                        
                        	newKeyMsg.Product_vod__c = productId;
                        	newKeyMsg.Detail_Group_vod__c = prodGroupId;
                    	}
                	}
                
                	if (fields.size() > 2)
                    	newKeyMsg.Reaction_vod__c = fields[2];
                	if (fields.size() > 3)
                    	newKeyMsg.Category_vod__c = fields[3];
                	if (fields.size() > 4)
                    	newKeyMsg.Vehicle_vod__c = fields[4];
                	if (fields.size() > 5 && fields[5]!='')
                    	newKeyMsg.Start_Time_vod__c = DateTime.valueOfGmt(fields[5]);
                	if (fields.size() > 6 && fields[6]!='')
                    	newKeyMsg.Duration_vod__c = Double.valueOf(fields[6]);
                	if (fields.size() > 7)
                    	newKeyMsg.CLM_ID_vod__c = fields[7];
                	if (fields.size() > 8)
                    	newKeyMsg.Presentation_ID_vod__c = fields[8];
                	if (fields.size() > 9)
                    	newKeyMsg.Slide_Version_vod__c = fields[9]; 
                	if (fields.size() > 10)
                    	newKeyMsg.Segment_vod__c = fields[10];
                	if (fields.size() > 11 && fields[11]!='')
                    	newKeyMsg.Display_Order_vod__c = Double.valueOf(fields[11]);
                	if (fields.size() > 12 && fields[12]!='')
                    	newKeyMsg.Clm_Presentation_vod__c = fields[12];
                	if (fields.size() > 13)
                    	newKeyMsg.Clm_Presentation_Name_vod__c = fields[13];
                	if (fields.size() > 14)
                    	newKeyMsg.Clm_Presentation_Version_vod__c = fields[14];
                	if (fields.size() > 15)
                    	newKeyMsg.Key_Message_Name_vod__c = fields[15];
                	if (fields.size() > 16)
                    	newKeyMsg.Share_Channel_vod__c = fields[16];
					if (fields.size() > 17){
                    	newKeyMsg.Detail_Removed_vod__c = Boolean.valueOf(fields[17]);
					}
                
                	keysToAdd.add(newKeyMsg);
            	}
        	}
        }
    }
    
    @TestVisible private void buildAccountParentCallNamesLists(List<Id> accountsList, List<String> parentIds, List<String> callNames) {
        for (Integer i = 0; i < newCalls.size(); i++) {
        	Call2_vod__c thisCall = newCalls[i];
            
        	if (parentIds != null && thisCall.Parent_Call_vod__c != null) {
            	parentIds.add(thisCall.Parent_Call_vod__c);
        	}
        
        	if (accountsList != null && thisCall.Account_vod__c != null) {
            	accountsList.add(thisCall.Account_vod__c); 
        	}
            
            if(callNames != null) {
        		callNames.add(thisCall.Name); 
            }
    	}
    }
    
    private void processTSF(List<Call2_vod__c> calls, boolean isUpdate) {
        String str = VOD_ProcessTSF.writeCalls(calls, isUpdate);
        if (str.indexOf('call2_vod') != -1) {
        	VOD_ProcessTSF.processTSF(str);  
        }
    }
    
    private void processCyclePlanRealtimeCalCAfterInsert(Map<Id, Call2_vod__c> beforeMap, 
                                                         Map<Id, set<String>> oldDetailProds, 
                                                         Map<Id, set<String>> newDetailProds,
                                                         boolean isEnableRealTimeCC) {
    	List<Call2_vod__c> callsRC = new List<Call2_vod__c>();
    	if(isEnableRealTimeCC) {
        	for (Integer i = 0; i < newCalls.size(); i++) {
            	Call2_vod__c call = newCalls[i];
            	Call2_vod__c bfCall= beforeMap.get(newCalls[i].Id);
            	Call2_vod__c oldCall = oldCalls[i];

            	set<String> oldProducts = oldDetailProds.get(oldCall.Id);
            	set<String> newProducts = newDetailProds.get(call.Id);
                if(oldCall.Account_vod__c == null || oldCall.Territory_vod__c == null || call.Account_vod__c == null || call.Territory_vod__c == null) {
                	continue;
                }

            	set<String> missingProducts = new set<String>();
            	set<String> addedProducts = new set<String>();

            	for(String oldproduct : oldProducts) {
                	if(!newProducts.contains(oldproduct)){
                    	missingProducts.add(oldproduct);
                	}
            	}

            	for(String newProduct : newProducts){
                	if(!oldProducts.contains(newProduct)){
                    	addedProducts.add(newProduct);
                	}
            	}
            	System.debug('missing products: ' + missingProducts.size());
            	System.debug('added products: ' +  addedProducts.size());

            	System.debug ('VEEVADEBUG: Processing : "' + call.Account_vod__c + '" for territrory = "'
                    	+ call.Territory_vod__c +'" Date ="'+ call.Call_Date_vod__c  + '" Status="' + bfCall.Status_vod__c + '"');

            	System.debug ('VEEVADEBUG: Processing : "' +oldCall.Account_vod__c + '" for territrory = "'
                    	+ oldCall.Territory_vod__c +'" Date ="'+ oldCall.Call_Date_vod__c  + '" Status="' + oldCall.Status_vod__c + '"');

            	//if no call detail change and no call account, date, territory and status change
            	if((addedProducts.size() == 0) && (missingProducts.size() == 0) && (oldCall.Account_vod__c == call.Account_vod__c) && (oldCall.Territory_vod__c == call.Territory_vod__c) &&
                    	(oldCall.Status_vod__c == bfCall.Status_vod__c) && (oldCall.Call_date_vod__c == call.Call_date_vod__c)) {
                	if (!(oldCall.createddate == oldCall.lastmodifieddate && oldCall.last_device_vod__c == 'Online_vod')){
                    	continue;
                	}
            	}

            	// realtime cycle plan calculation

            	//VEEVA_CYCLE_PLAN_REALTIME_CALC.calculateUpdate(oldCall.Account_vod__c,oldCall.Call_Date_vod__c,oldCall.territory_vod__c,call.Account_vod__c, call.Call_Date_vod__c, call.territory_vod__c);
            	callsRC.add(oldCall);
            	callsRC.add(call);
        	}
            
        	VEEVA_CYCLE_PLAN_REALTIME_CALC.invokeCalculation(callsRC);
    	}
    }
    
    private void processCyclePlanRealtimeCalC(List<Call2_vod__c> callsToProcess) {
    	if(VEEVA_CYCLE_PLAN_REALTIME_CALC.isEnableRealTimeCC()){ 
    		List<Call2_vod__c> calls = new List<Call2_vod__c>();  
	    	for (Integer i = 0; i < callsToProcess.size(); i++) {
	    		Call2_vod__c call = callsToProcess[i];
	        	if(call.Account_vod__c == null || call.Call_Date_vod__c == null || call.Territory_vod__c == null)
		        	continue;
		        calls.add(call);
	    	}
	    	VEEVA_CYCLE_PLAN_REALTIME_CALC.invokeCalculation(calls);
    	}
    }
    
    @TestVisible private static void clearSigReqUUIDOnCall(boolean isFutureTask) {
        Set<String> sigReqUUIDs = sigReqUUIDToCall.keySet(); 
        if(sigReqUUIDs.size() > 0) {
            
        	List<Signature_Request_vod__c> sigReqs = [select Id, Call2_vod__c, Account_vod__c, Signature_Request_UUID_vod__c, Status_vod__c 
                                                      from Signature_Request_vod__c 
                                                      where Signature_Request_UUID_vod__c in :sigReqUUIDs];
			List<Call2_vod__c> callsToBeUpserted = new List<Call2_vod__c>();
        	for(Signature_Request_vod__c sigReq: sigReqs) {
            	sigReqUUIDToSigReq.put(sigReq.Signature_Request_UUID_vod__c, sigReq);
                
            	Call2_vod__c call = sigReqUUIDToCall.get(sigReq.Signature_Request_UUID_vod__c);
            	if(call != null && 
                   !VeevaSignatureRequestTriggerHandler.isValidSignatureRequest(sigReq) && 
                   String.isNotBlank(call.Signature_Request_UUID_vod__c)) {
                	call.Signature_Request_UUID_vod__c = null;
                    callsToBeUpserted.add(call);
            	}
        	}
            
            //Upsert calls if the processing is from future task.
            if(isFutureTask && !callsToBeUpserted.isEmpty()) {
                updateIsFromFutureTask = true;
                upsert callsToBeUpserted;
                updateIsFromFutureTask = false;
            }
            
        }
    }

	@Future
	public static void stampSignatureRequestWithCallIdByMobileId(Map<String, Id> mobileIdToCallIdMap) {
		if (mobileIdToCallIdMap.isEmpty()) {
			return;
		}

		Map<String, Schema.RecordTypeInfo> recordTypeInfos = Schema.SObjectType.Signature_Request_vod__c.getRecordTypeInfosByDeveloperName();
		Id contentAckRecordTypeId = recordTypeInfos.get('Content_Acknowledgement_vod').getRecordTypeId();

		// Query signature requests by mobile IDs that have an empty Call2_vod__c field and are of the "Content_Acknowledgement_vod" Record Type
		List<Signature_Request_vod__c> signatureRequests = [
			SELECT Id, Call2_vod__c, Call2_Mobile_Id_vod__c
			FROM Signature_Request_vod__c
			WHERE Call2_Mobile_Id_vod__c IN :mobileIdToCallIdMap.keySet() AND Call2_vod__c = null AND RecordTypeId = :contentAckRecordTypeId
		];

		if (!signatureRequests.isEmpty()) {
			// Stamp all signature requests of "Content Acknowledgment" type with the corresponding Call Id
			for (Signature_Request_vod__c sigReq : signatureRequests) {
				if (mobileIdToCallIdMap.containsKey(sigReq.Call2_Mobile_Id_vod__c)) {
					sigReq.Call2_vod__c = mobileIdToCallIdMap.get(sigReq.Call2_Mobile_Id_vod__c);
				}
			}
			// Update the signature requests with new call IDs
			update signatureRequests;
		}
	}

    @TestVisible private static void processSignatureRequests() {
        //Map to collect the calls for which the sig req records are not found so that a future task can be 
        //launched for second try in case if sig req record is also being created at the same time.
        Map<String, Call2_vod__c> sigReqUUIDToCallForFuture = new Map<String, Call2_vod__c>(sigReqUUIDToCall);
        List<Signature_Request_vod__c> sigReqsToBeUpserted = new List<Signature_Request_vod__c>();
        Set<String> sigReqUUIDs = sigReqUUIDToSigReq.keySet();
        boolean sigReqNeedsUpdate;
        
        for(String sigReqUUID: sigReqUUIDs) {
            Signature_Request_vod__c sigReq = sigReqUUIDToSigReq.get(sigReqUUID);
            Call2_vod__c call = sigReqUUIDToCall.get(sigReqUUID);
            sigReqUUIDToCallForFuture.remove(sigReqUUID);
            
            if(call != null) {
            	sigReqNeedsUpdate = false;
                
               	//Stamp Call if it doesn't exist.
               	if(String.isBlank(sigReq.Call2_vod__c)) {
                   	sigReq.Call2_vod__c = call.Id;
                   	sigReqNeedsUpdate = true;
               	}
                    
               	//Stamp Account if it doesn't exist.
               	if(String.isBlank(sigReq.Account_vod__c)) {
                   	sigReq.Account_vod__c = call.Account_vod__c;
                   	sigReqNeedsUpdate = true;
               	}
                
                if(sigReqNeedsUpdate) {
               		sigReqsToBeUpserted.add(sigReq);
                    VeevaSignatureRequestTriggerHandler.sigReqUUIDToSkip.add(sigReq.Signature_Request_UUID_vod__c);
                }
            }
        }
        
        if(sigReqsToBeUpserted.size()>0) {
            upsert sigReqsToBeUpserted;
        }
        
        if(!sigReqUUIDToCallForFuture.isEmpty() && !System.isFuture()) {
            processCallAndSignatureRequestsFuture(JSON.serialize(sigReqUUIDToCallForFuture));
        }
    }
    
    @future
    @TestVisible private static void processCallAndSignatureRequestsFuture(String sigReqUUIDToCallForFutureString) {
        Map<String, Call2_vod__c> sigReqUUIDToCallForFuture = (Map<String, Call2_vod__c>) 
            JSON.deserialize(sigReqUUIDToCallForFutureString, Map<String, Call2_vod__c>.class);
        sigReqUUIDToCall = new Map<String, Call2_vod__c>(sigReqUUIDToCallForFuture);
        
        clearSigReqUUIDOnCall(true);
        processSignatureRequests();
    }
    
    @TestVisible private String getErrorMessage(String msgKey) {
        return getErrorMessage(msgKey, null, true);
    }
    
    @TestVisible private String getErrorMessage(String msgKey, String category) {
        return getErrorMessage(msgKey, category, false);
    }
    
    @TestVisible private String getErrorMessage(String msgKey, String category, boolean fromBundle) {
        String errorMsg = errorMsgs.get(msgKey);
        if(errorMsg == null) {
            if(fromBundle) {
                if(msgBundle == null) {
            		msgBundle = new VOD_ERROR_MSG_BUNDLE();
        		}
                
                errorMsg = msgBundle.getErrorMsg(msgKey);
            } else {
            	errorMsg = VOD_GET_ERROR_MSG.getErrorMsg(msgKey, category);
            }
            
            errorMsgs.put(msgKey, errorMsg);
        }
        
        return errorMsg;
    }

	private void handleUnavailableTimeUpsert(List<Unavailable_Time_vod__c> toUpsert) {
		if (!toUpsert.isEmpty()) {
            Database.UpsertResult[] upsertResults = Database.upsert(toUpsert, false);
            for (Integer i = 0; i < upsertResults.size(); i++) {
                Database.UpsertResult result = upsertResults.get(i);
                if (!result.isSuccess()){
                    Id targetCallRecord = toUpsert.get(i).Call2_vod__c;
                    Database.Error[] errors = result.getErrors();
                    
                    String msg = '';
                    for (Database.Error e : errors) {
                        msg += e.getStatusCode() + ': ' + e.getMessage() + ' ';                 
                    }
                    this.newCallsMap.get(targetCallRecord).addError(msg);
                }
            }
        }
	}

	private void handleUnavailableTimeDeletion(List<Unavailable_Time_vod__c> toDelete) {
        if (!toDelete.isEmpty()) {
            Database.DeleteResult[] deletionResults = Database.delete(toDelete, false);
            for (Integer i = 0; i < deletionResults.size(); i++) {
                Database.DeleteResult result = deletionResults.get(i);
                if (!result.isSuccess()){
                    Id targetCallRecord = toDelete.get(i).Call2_vod__c;
                    Database.Error[] errors = result.getErrors();
                    
                    String msg = '';
                    for (Database.Error e : errors) {
                        msg += e.getStatusCode() + ': ' + e.getMessage() + ' ';                 
                    }
                    this.oldCallsMap.get(targetCallRecord).addError(msg);
                }
            }
        }
    }
}