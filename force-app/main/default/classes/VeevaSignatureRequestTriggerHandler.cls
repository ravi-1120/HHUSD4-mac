public class VeevaSignatureRequestTriggerHandler extends VeevaTriggerHandler {
    
    @TestVisible public static Set<String> sigReqUUIDToSkip = new Set<String>();
    @TestVisible private static Map<String, Signature_Request_vod__c> sigReqUUIDToSigReq = new Map<String, Signature_Request_vod__c>();
    @TestVisible private static Map<String, Signature_Request_vod__c> sigReqCallMobileIdToSigReq = new Map<String, Signature_Request_vod__c>();    
    @TestVisible private static Map<String, Call2_vod__c> sigReqUUIDToCall = new Map<String, Call2_vod__c>();
    @TestVisible private static Map<ID, Signature_Request_vod__c> callWithoutSigReqUUIDToSigReq = new Map<ID, Signature_Request_vod__c>();
    @TestVisible private static boolean updateIsFromFutureTask = false;
    @TestVisible private static List<Signature_Request_vod__c> newSignatureRequests = new List<Signature_Request_vod__c>();
    
    @TestVisible protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        newSignatureRequests = (List<Signature_Request_vod__c>) triggerNew;
    
        // Fetching record type information
        Map<String, RecordTypeInfo> recordTypeInfos = Signature_Request_vod__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        RecordTypeInfo contentAcknowledgementRtInfo = recordTypeInfos.get('Content_Acknowledgement_vod');
    
        for (Signature_Request_vod__c newSigReq : newSignatureRequests) {
            String sigReqUUID = newSigReq.Signature_Request_UUID_vod__c;
            String sigReqCallMobileId = newSigReq.Call2_Mobile_id_vod__c;
            if (contentAcknowledgementRtInfo != null && newSigReq.RecordTypeId == contentAcknowledgementRtInfo.getRecordTypeId() && String.isNotBlank(sigReqCallMobileId)) {
                sigReqCallMobileIdToSigReq.put(sigReqCallMobileId, newSigReq);
            } else if (String.isNotBlank(sigReqUUID) && !sigReqUUIDToSkip.contains(sigReqUUID)) {
                sigReqUUIDToSigReq.put(sigReqUUID, newSigReq);
            }
        }
    }

    @TestVisible protected override boolean doRecursionCheck() {
        return true;
    }
    
    protected override String sObjectType() {
        return 'Signature_Request_vod__c ';
    }
    
    @TestVisible protected override void filterRecordsToProcess(System.TriggerOperation context, List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        super.filterRecordsToProcess(context, triggerNew, triggerOld, triggerNewMap, triggerOldMap);
        
        if(triggerOld != null) {
            for(SObject record: triggerOld) {
            	Signature_Request_vod__c existingSigReq = (Signature_Request_vod__c)record;
                
                if(triggerNewMap != null) {
            		Signature_Request_vod__c newSigReq = (Signature_Request_vod__c)triggerNewMap.get(existingSigReq.Id);
                
            		if(newSigReq != null && existingSigReq.Engage_Last_Modified_Datetime_vod__c > newSigReq.Engage_Last_Modified_Datetime_vod__c) {
            			newSigReq.Engage_Last_Modified_Datetime_vod__c.addError('Rejecting as the current version of record in database is the latest', false);
                
                    	Id sigReqId = newSigReq.Id;
                		filterRecord(sigReqId, oldRecordsMapToProcess, triggerOldMap, oldRecordsToProcess);
                		filterRecord(sigReqId, newRecordsMapToProcess, triggerNewMap, newRecordsToProcess);
            		}
                }
        	}
        }
    }
    
    private void filterRecord(Id recIdTobeRemoved, Map<ID, SObject> recordsMapToProcess, Map<ID, SObject> triggerMap, List<SObject> recordsToProcess) {
        recordsMapToProcess.remove(recIdTobeRemoved);
        SObject recToBeRemoved = triggerMap!=null?triggerMap.get(recIdTobeRemoved):null;
        if(recToBeRemoved != null) {
            Integer recIndex = recordsToProcess.indexOf(recToBeRemoved);
            if(recIndex != -1) {
                recordsToProcess.remove(recIndex);
            }
        }
    }
    
    @TestVisible protected override void beforeInsert() {
        stampAOCIDOnSignatureRequest();

        // Stamp Call for Signature Requests Associated to Call via Call Mobile ID
        stampCallOnSigReqViaMobileId();
        // Stamp Call And Account for Signature Requests Associated to Call via UUID
        stampCallAndAccountOnSigReq(false);
    }

    @TestVisible protected override void beforeUpdate() {
        //Skip triggers if the update of Sig Req is triggered from the future task in this same trigger.
        if(!updateIsFromFutureTask) {
            stampAOCIDOnSignatureRequest();
            // Stamp Call for Signature Requests Associated to Call via Call Mobile ID
            stampCallOnSigReqViaMobileId();

            // Stamp Call And Account for Signature Requests Associated to Call via UUID
        	stampCallAndAccountOnSigReq(false);
        }
    }

    private void stampCallOnSigReqViaMobileId() {
        if (sigReqCallMobileIdToSigReq.size() == 0) {
            return;
        }

        Set<String> callMobileIds = new Set<String>();

        // Process each signature request to establish  mobile-id-based connections to calls
        for (Signature_Request_vod__c signatureRequest : sigReqCallMobileIdToSigReq.values()) {
            if (String.isBlank(signatureRequest.Call2_vod__c) && !String.isBlank(signatureRequest.Call2_Mobile_id_vod__c)) {
                // Prepare to fetch Call ID using mobile ID if direct Call ID is missing
                callMobileIds.add(signatureRequest.Call2_Mobile_id_vod__c);
            }
        }

        // If mobile IDs are involved, fetch corresponding Call IDs
        if (!callMobileIds.isEmpty()) {
            for (Call2_vod__c call : [SELECT Id, Mobile_Id_vod__c FROM Call2_vod__c WHERE Mobile_Id_vod__c IN :callMobileIds]) {
                // Stamp Signature Request Call Id
                if (sigReqCallMobileIdToSigReq.containsKey(call.Mobile_Id_vod__c)) {
                    Signature_Request_vod__c signatureRequest = sigReqCallMobileIdToSigReq.get(call.Mobile_Id_vod__c);
                    signatureRequest.Call2_vod__c = call.Id;
                }
            }
        }
    }
    
    @TestVisible private static void stampCallAndAccountOnSigReq(boolean isFutureTask) {
        Set<String> sigReqUUIDs = sigReqUUIDToSigReq.keySet(); 
        if(sigReqUUIDs.size() > 0) {
            //Map to collect the sig reqs for which the call records are not found so that a future task can be 
        	//launched for second try in case if call record is also being created at the same time.
        	Map<String, Signature_Request_vod__c> sigReqUUIDToSigReqForFuture = new Map<String, Signature_Request_vod__c>();
        	List<Signature_Request_vod__c> sigReqsToBeUpserted = new List<Signature_Request_vod__c>();
            
            buildSigReqUUIDToCallMap(sigReqUUIDs);
            
            for(String sigReqUUID: sigReqUUIDs) {
                Signature_Request_vod__c sigReq = sigReqUUIDToSigReq.get(sigReqUUID);
                Call2_vod__c call = sigReqUUIDToCall.get(sigReqUUID);
                String callId = sigReq.Call2_vod__c;
                
                if(call != null) {
                    boolean sigReqNeedsUpdate = false;
                    
                    //Stamp Call if it doesn't exist.
                    if(String.isBlank(callId)) {
                        sigReq.Call2_vod__c = call.Id;
                        sigReqNeedsUpdate = true;
                    }
                    
                    //Stamp Account if it doesn't exist.
                    if(String.isBlank(sigReq.Account_vod__c) && String.isNotBlank(call.Account_vod__c)) {
                        sigReq.Account_vod__c = call.Account_vod__c;
                        sigReqNeedsUpdate = true;
                    }
                    
                    if(sigReqNeedsUpdate) {
                        sigReqsToBeUpserted.add(sigReq);
                    }
                    
                } else if(String.isNotBlank(callId)) {
                    callWithoutSigReqUUIDToSigReq.put(callId, sigReq);
                } else {
                    sigReqUUIDToSigReqForFuture.put(sigReqUUID, sigReq);
                }
            }
            
            if(!sigReqUUIDToSigReqForFuture.isEmpty() && !System.isFuture()) {
            	processSigReqsAndCallFuture(JSON.serialize(sigReqUUIDToSigReqForFuture));
        	}
            
            if(isFutureTask && !sigReqsToBeUpserted.isEmpty()) {
                updateIsFromFutureTask = true;
                upsert sigReqsToBeUpserted;
                updateIsFromFutureTask = false;
        	}
        }
    }
    
    @future
    @TestVisible private static void processSigReqsAndCallFuture(String sigReqUUIDToSigReqForFutureString) {
        Map<String, Signature_Request_vod__c> sigReqUUIDToSigReqForFuture = (Map<String, Signature_Request_vod__c>) 
            JSON.deserialize(sigReqUUIDToSigReqForFutureString, Map<String, Signature_Request_vod__c>.class);
        sigReqUUIDToSigReq = new Map<String, Signature_Request_vod__c>(sigReqUUIDToSigReqForFuture);
        
        stampCallAndAccountOnSigReq(true);
        processCalls();
    }
    
    @TestVisible private static void buildSigReqUUIDToCallMap(Set<String> sigReqUUIDs) {
        List<Call2_vod__c> calls = [select Id, Account_vod__c, Signature_Request_UUID_vod__c from Call2_vod__c where Signature_Request_UUID_vod__c in :sigReqUUIDs];

        for(Call2_vod__c call: calls) {
            sigReqUUIDToCall.put(call.Signature_Request_UUID_vod__c, call);
        }
    }

    @TestVisible protected override void afterInsert() {
        processCalls();
        processRequestedRecsWithUUID();
    }
    
    @TestVisible protected override void afterUpdate() {
        //Skip triggers if the update of Sig Req is triggered from the future task in this same trigger.
        if(!updateIsFromFutureTask) {
        	processCalls();
            processInvalidSignatureRequests();
        }
    }
    
    private static void processCalls() {
        List<Call2_vod__c> callsToBeUpserted = new List<Call2_vod__c>();
        //Clear signature request UUID on Call if the Signature Request is invalid.
        fillCallsForSigClearing(callsToBeUpserted);
        //Stamp signature request UUID on call if it is valid and missing.
        fillCallsForSigStamping(callsToBeUpserted);
        
        if(callsToBeUpserted.size() > 0) {
            upsert callsToBeUpserted;
        }
    }
    
    @TestVisible private static void fillCallsForSigClearing(List<Call2_vod__c> callsToBeUpserted) {
        
        Set<String> sigReqUUIDs = sigReqUUIDToCall.keySet(); 
        for(String sigReqUUID: sigReqUUIDs) {
            Signature_Request_vod__c sigReq = sigReqUUIDToSigReq.get(sigReqUUID);
            Call2_vod__c call = sigReqUUIDToCall.get(sigReqUUID);
            
            //Clear signature request uuid on Call if signature request is invalid.
            if(!isValidSignatureRequest(sigReq) && String.isNotBlank(call.Signature_Request_UUID_vod__c)) {
                call.Signature_Request_UUID_vod__c = null;
                call.Override_Lock_vod__c = true;
                callsToBeUpserted.add(call);
            }
        }
        
    }

    @TestVisible private static void fillCallsForSigStamping(List<Call2_vod__c> callsToBeUpserted) {
        
        Set<ID> callIds = callWithoutSigReqUUIDToSigReq.keySet();
        for(ID callId: callIds) {
            Signature_Request_vod__c sigReq = callWithoutSigReqUUIDToSigReq.get(callId);
            
            //Stamp the signature request uuid on Call if  signature request is valid.
            if(isValidSignatureRequest(sigReq)) {
                Call2_vod__c call = new Call2_vod__c(Id = callId, Signature_Request_UUID_vod__c = sigReq.Signature_Request_UUID_vod__c);
                callsToBeUpserted.add(call);
                VeevaCallTriggerHandler.sigReqUUIDToSkip.add(sigReq.Signature_Request_UUID_vod__c);
            }
        }
        
    }
    
    @TestVisible public static boolean isValidSignatureRequest(Signature_Request_vod__c sigReq) {
        switch on sigReq.Status_vod__c {
            when 'Requested_vod', 'Signature_Accepted_vod', 'Signature_Captured_vod' {
                return true;
            }
            when 'Request_Canceled_vod', 'Signature_Declined_vod', 'Request_Expired_vod' {
                return false;
            }
        }
        
        return false;
    }

    @TestVisible private static void stampAOCIDOnSignatureRequest(){
        List<Signature_Request_vod__c> sigReqsToUpdate = new List<Signature_Request_vod__c>();
        List<String> mobileIds = new List<String>();
        Map<String, Integer> sigReqIdxByMobileId = new Map<String, Integer>();
        for (Integer i = 0; i < newSignatureRequests.size(); i++) {
            Signature_Request_vod__c sigReq = newSignatureRequests[i];
            if (!String.isEmpty(sigReq.Call2_Mobile_id_vod__c) && String.isEmpty(sigReq.AOC_ID_vod__c)){
                mobileIds.add(sigReq.Call2_Mobile_id_vod__c);
                sigReqIdxByMobileId.put(sigReq.Call2_Mobile_id_vod__c, i);
            }
        }
        List<Content_Acknowledgement_vod__c> contentAcknowledgementRecs = getContentAcknowledgementRecs(mobileIds);
        for (Content_Acknowledgement_vod__c contentAckRec : contentAcknowledgementRecs) {
            Integer sigReqIdx = sigReqIdxByMobileId.get(contentAckRec.Mobile_ID_vod__c);
            newSignatureRequests[sigReqIdx].AOC_ID_vod__c = contentAckRec.Id;
        }
    }

    @TestVisible private static List<Content_Acknowledgement_vod__c> getContentAcknowledgementRecs(List<String> mobileIds){
        List<Content_Acknowledgement_vod__c> contentAcknowledgements = new List<Content_Acknowledgement_vod__c>();
        if (mobileIds != null && !mobileIds.isEmpty()){
            contentAcknowledgements = [select Id, Mobile_ID_vod__c FROM Content_Acknowledgement_vod__c WHERE Mobile_ID_vod__c in :mobileIds];
        }
        return contentAcknowledgements;
    }

    @TestVisible private static void processRequestedRecsWithUUID(){
        Map<Id, String> aocIdToSigReqUUID = new Map<Id, String>();
        for (Signature_Request_vod__c signReq : newSignatureRequests) {
            if (!String.isBlank(signReq.AOC_ID_vod__c) && !String.isBlank(signReq.Signature_Request_UUID_vod__c) && signReq.Status_vod__c == 'Requested_vod') {
                aocIdToSigReqUUID.put((Id) signReq.AOC_ID_vod__c, signReq.Signature_Request_UUID_vod__c);
            }
        }
        stampUUIDOnAOCRecords(aocIdToSigReqUUID);
    }

    @TestVisible private static void stampUUIDOnAOCRecords(Map<Id, String> aocIdToSigReqUUIDMap) {
        Set<Id> aocIds = aocIdToSigReqUUIDMap.keySet();
        List<Content_Acknowledgement_vod__c> contentAcknowledgementsToUpdate = new List<Content_Acknowledgement_vod__c>();
        if (aocIds.isEmpty()){
            return;
        }
        List<Content_Acknowledgement_vod__c> contentAcknowledgements = [SELECT Id, Signature_Request_UUID_vod__c FROM Content_Acknowledgement_vod__c WHERE Id IN :aocIds];
        for (Content_Acknowledgement_vod__c aocRec : contentAcknowledgements) {
            aocRec.Signature_Request_UUID_vod__c = aocIdToSigReqUUIDMap.get(aocRec.Id);
            aocRec.Unlock_vod__c = true;
            contentAcknowledgementsToUpdate.add(aocRec);
        }
        if (!contentAcknowledgementsToUpdate.isEmpty()) {
            upsert contentAcknowledgementsToUpdate;
        }
    }

    @TestVisible private static void processInvalidSignatureRequests() {
        List<String> sigReqUUIDs = new List<String>();
        for (Signature_Request_vod__c signReq : newSignatureRequests) {
            if (!String.isBlank(signReq.Status_vod__c) && !String.isBlank(signReq.Signature_Request_UUID_vod__c)
                && (!isValidSignatureRequest(signReq))) {
                sigReqUUIDs.add(signReq.Signature_Request_UUID_vod__c);
            }
        }
        clearUUIDOnAOCRecs(sigReqUUIDs);
    }

    @TestVisible private static void clearUUIDOnAOCRecs(List<String> sigReqUUIDs) {
        if (sigReqUUIDs.isEmpty()){
            return ;
        }
        List<Content_Acknowledgement_vod__c> aocRecs = [SELECT Id, Signature_Request_UUID_vod__c FROM Content_Acknowledgement_vod__c WHERE Signature_Request_UUID_vod__c IN :sigReqUUIDs];
        for (Content_Acknowledgement_vod__c aoc : aocRecs) {
            aoc.Unlock_vod__c = true;
            aoc.Signature_Request_UUID_vod__c = null;
        }
        upsert aocRecs;
    }
}