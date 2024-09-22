public without sharing class VeevaDataChangeRequestTriggerHandler extends VeevaTriggerHandler {
    private static final Id REMOVE_FROM_TERRITORY_RECORD_TYPE_ID = Schema.SObjectType.Data_Change_Request_vod__c
        .getRecordTypeInfosByDeveloperName().get('Remove_From_Territory_vod')?.getRecordTypeId();
    private static final Id ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Data_Change_Request_vod__c
        .getRecordTypeInfosByDeveloperName().get('Account_vod')?.getRecordTypeId();

    private static final String PENDING_VERIFICATION_STATUS = 'Pending_Verification_vod';
    private static final String RECONCILIATION_REJECTED_STATUS = 'Reconciliation_Rejected_vod';
    private static final String RECONCILED_TO_NEW_ACCOUNT_STATUS = 'Reconciled_To_New_Account_vod';

    private static final String PROCESSED_STATUS = 'Processed_vod';
    private static final String CANCELLED_STATUS = 'Cancelled_vod';
    private static final Set<String> RECONCILED_STATUSES = new Set<String>{
        'Reconciled_To_Existing_Account_vod',
        'Reconciled_To_Existing_User_vod',
        'Reconciled_To_New_Account_vod',
        'Reconciled_To_Customer_Master_vod'
    };

    private static final String REJECTED_RESULT = 'CHANGE_REJECTED';

    private List<Data_Change_Request_vod__c> newDataChangeRequests;
    private List<Data_Change_Request_vod__c> oldDataChangeRequests;
    private Map<ID, Data_Change_Request_vod__c> newDataChangeRequestsMap;
    private Map<ID, Data_Change_Request_vod__c> oldDataChangeRequestsMap;

    protected override String sObjectType() {
        return 'Data_Change_Request_vod__c';
    }

    protected override void preTrigger(
        List<SObject> triggerNew,
        List<SObject> triggerOld,
        Map<ID, SObject> triggerNewMap,
        Map<ID, SObject> triggerOldMap
    ) {
        newDataChangeRequests = (List<Data_Change_Request_vod__c>) triggerNew;
        oldDataChangeRequests = (List<Data_Change_Request_vod__c>) triggerOld;
        newDataChangeRequestsMap = (Map<ID, Data_Change_Request_vod__c>) triggerNewMap;
        oldDataChangeRequestsMap = (Map<ID, Data_Change_Request_vod__c>) triggerOldMap;
    }

    protected override void afterInsert() {
        stampPendingAttendees(getAttendeeIds(getReconciliationDCRs(newDataChangeRequests)));
    }

    protected override void afterUpdate() {
        processDCRs();
    }

    private List<Data_Change_Request_vod__c> getReconciliationDCRs(List<Data_Change_Request_vod__c> dcrs) {
        List<Data_Change_Request_vod__c> reconciliationDCRs = new List<Data_Change_Request_vod__c>();
        for (Data_Change_Request_vod__c dcr : dcrs) {
            if (isAttendeeReconciliationDCR(dcr)) {
                reconciliationDCRs.add(dcr);
            }
        }

        return reconciliationDCRs;
    }

    private List<Id> getAttendeeIds(List<Data_Change_Request_vod__c> reconciliationDCRs) {
        List<Id> attendeeIds = new List<Id>();
        for (Data_Change_Request_vod__c reconciliationDCR : reconciliationDCRs) {
            attendeeIds.add(reconciliationDCR.EM_Attendee_vod__c);
        }

        return attendeeIds;
    }

    private void stampPendingAttendees(List<Id> attendeesToStamp) {
        if (attendeesToStamp.isEmpty()) {
            return;
        }

        // Do not overwrite statuses for attendees that have already been reconciled
        List<EM_Attendee_vod__c> stampedAttendees = [
            SELECT Id, Walk_In_Status_vod__c
            FROM EM_Attendee_vod__c
            WHERE Id IN :attendeesToStamp AND Walk_In_Status_vod__c NOT IN :RECONCILED_STATUSES
        ];
        for (EM_Attendee_vod__c attendee : stampedAttendees) {
            attendee.Walk_In_Status_vod__c = PENDING_VERIFICATION_STATUS;
        }

        Database.update(stampedAttendees, false);
    }

    /**
     * - Used to keep the Status_vod__c of the child DCRs in sync with the parent.
     * - Used to process territory dealignment requests represented by Remove_From_Territory_vod DCR records.
     */
    private void processDCRs() {
        List<Data_Change_Request_vod__c> statusChangedParents = new List<Data_Change_Request_vod__c>();
        Map<Id, String> dcrStatusesByParentId = new Map<Id, String>();
        Map<Id, Data_Change_Request_vod__c> finalizedParentDCRs = new Map<Id, Data_Change_Request_vod__c>();
    
        List<Data_Change_Request_vod__c> removeFromTerritoryRequests = new List<Data_Change_Request_vod__c>();
        
        // Find parent DCRs with changed status
        for (Data_Change_Request_vod__c dcr : newDataChangeRequests) {
            Data_Change_Request_vod__c oldDcr = oldDataChangeRequestsMap.get(dcr.Id);

            if (isRemoveFromTerritoryRequestReady(dcr, oldDcr)) {
                removeFromTerritoryRequests.add(dcr);
            } else if (isUpdatedParentDCR(dcr, oldDcr)) {
                // Only update children of a parent DCR whose status changed
                statusChangedParents.add(dcr);
                dcrStatusesByParentId.put(dcr.Id, dcr.Status_vod__c);

                if (isProcessed(dcr) || isCancelled(dcr)) {
                    finalizedParentDCRs.put(dcr.Id, dcr);
                }
            }
        }
    
        if (statusChangedParents.size() > 0) {
            updateChildDCRs(statusChangedParents, dcrStatusesByParentId);
        }
        
        if (finalizedParentDCRs.size() > 0) {
            VeevaWeChatDataChangeRequestHandler weChatDcrHandler = new VeevaWeChatDataChangeRequestHandler();
            weChatDcrHandler.handleWeChatRelatedWork(new List<Id>(finalizedParentDCRs.keySet()));

            List<Data_Change_Request_vod__c> finalizedReconciliationDCRs = getReconciliationDCRs(finalizedParentDCRs.values());
            stampFinalizedAttendees(getAttendeeIds(finalizedReconciliationDCRs), finalizedReconciliationDCRs);
        }
    
        if (removeFromTerritoryRequests.size() > 0) {
            VeevaRemoveFromTerritoryHandler removeFromTerritoryHandler = new VeevaRemoveFromTerritoryHandler();
            removeFromTerritoryHandler.processTerritoryDealignmentRequests(removeFromTerritoryRequests);
        }
    }

    private void stampFinalizedAttendees(List<Id> attendeesToStamp, List<Data_Change_Request_vod__c> finalizedReconciliationDCRs) {
        if (attendeesToStamp.isEmpty()) {
            return;
        }

        Map<Id, EM_Attendee_vod__c> attendees = new Map<Id, EM_Attendee_vod__c>([
            SELECT Id, Walk_In_Status_vod__c, Account_vod__c
            FROM EM_Attendee_vod__c
            WHERE Id IN :attendeesToStamp AND Walk_In_Status_vod__c = :PENDING_VERIFICATION_STATUS
        ]);

        if (attendees.isEmpty()) {
            return;
        }

        for (Data_Change_Request_vod__c dcr : finalizedReconciliationDCRs) {
            EM_Attendee_vod__c attendee = attendees.get(dcr.EM_Attendee_vod__c);
            // Attendee may be null if its status is not pending verification. In this case we will ignore the attendee.
            if (attendee == null) {
                continue;
            }

            if (isCancelled(dcr) || isRejected(dcr)) {
                attendee.Walk_In_Status_vod__c = RECONCILIATION_REJECTED_STATUS;
            } else  {
                attendee.Walk_In_Status_vod__c = RECONCILED_TO_NEW_ACCOUNT_STATUS;
                attendee.Account_vod__c = dcr.Account_vod__c;
            }
        }

        Database.update(attendees.values(), false);
    }

    private static Boolean isRemoveFromTerritoryRequestReady(Data_Change_Request_vod__c dcr, Data_Change_Request_vod__c oldDcr) {
        Boolean isRemoveFromTerritoryRequest = (dcr.RecordTypeId == REMOVE_FROM_TERRITORY_RECORD_TYPE_ID);
        if (!isRemoveFromTerritoryRequest) {
            return false;
        }

        String currentStatus = dcr.Status_vod__c;
        String currentExternalStatus = dcr.External_Status_vod__c;
        String currentResult = dcr.Result_vod__c;
        String currentResolutionNote = dcr.Resolution_Note_vod__c;
        String currentTerritory = dcr.Territory_vod__c;
        Id currentAccount = dcr.Account_vod__c;
        Id ownerId = dcr.OwnerId; 
        Decimal currentNetworkCustomerMode = dcr.Network_Customer_Master_Mode_vod__c;

        Boolean isReadyForProcessing =
            String.isBlank(currentResolutionNote) 
            && String.isNotBlank(currentTerritory)
            && currentAccount != null
            && ownerId != null
            && currentStatus == 'Submitted_vod'
            && currentExternalStatus == 'CHANGE_PENDINGREVIEW'
            && currentNetworkCustomerMode == 0
            && oldDcr.Result_vod__c != currentResult 
            && (currentResult == 'CHANGE_ACCEPTED' || currentResult == REJECTED_RESULT);

        return isReadyForProcessing;
    }

    private static Boolean isUpdatedParentDCR(Data_Change_Request_vod__c newDcr, Data_Change_Request_vod__c oldDcr) {
        return newDcr.Parent_Data_Change_Request_vod__c == null && oldDcr.Status_vod__c != newDcr.Status_vod__c;
    }

    private static void updateChildDCRs(List<Data_Change_Request_vod__c> updatedParentDCRs, Map<Id, String> dcrStatusesByParentId) {
        // Find child DCRs to get status updated
        List<Data_Change_Request_vod__c> updatedList = new List<Data_Change_Request_vod__c>();
        List<Data_Change_Request_vod__c> subDcrs = 
            [select Id, Status_vod__c, Parent_Data_Change_Request_vod__c from Data_Change_Request_vod__c 
                where Parent_Data_Change_Request_vod__c IN :updatedParentDCRs];
        for (Data_Change_Request_vod__c subDcr : subDcrs) {
            // Only update if status does not already match - should be all, but maybe not
            String parentStatus = dcrStatusesByParentId.get(subDcr.Parent_Data_Change_Request_vod__c);
            if (subDcr.Status_vod__c != parentStatus) {
                    subDcr.Status_vod__c = parentStatus;
                    updatedList.add(subDcr);
            }
        }

        if (updatedList.size() > 0) {
            update updatedList;
        }
    }

    private static Boolean isAttendeeReconciliationDCR(Data_Change_Request_vod__c dcr) {
        return dcr.EM_Attendee_vod__c != null && dcr.RecordTypeId == ACCOUNT_RECORD_TYPE_ID;
    }

    private static Boolean isProcessed(Data_Change_Request_vod__c dcr) {
        return dcr.Status_vod__c == PROCESSED_STATUS;
    }

    private static Boolean isCancelled(Data_Change_Request_vod__c dcr) {
        return dcr.Status_vod__c == CANCELLED_STATUS;
    }

    private static Boolean isRejected(Data_Change_Request_vod__c dcr) {
        return dcr.Result_vod__c == REJECTED_RESULT;
    }
}