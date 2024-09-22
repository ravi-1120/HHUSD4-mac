public class VeevaAOCTriggerHandler extends VeevaTriggerHandler {
    
    @TestVisible public static List<Content_Acknowledgement_vod__c> newAOCs = new List<Content_Acknowledgement_vod__c>();
    @TestVisible public static List<Content_Acknowledgement_vod__c> oldAOCs = new List<Content_Acknowledgement_vod__c>();
    @TestVisible private static Map<String, Content_Acknowledgement_vod__c> mobileIdToAOCMap = new Map<String, Content_Acknowledgement_vod__c>();

    @TestVisible protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        newAOCs = (List<Content_Acknowledgement_vod__c>) triggerNew;
        oldAOCs = (List<Content_Acknowledgement_vod__c>) triggerOld;
        for(Content_Acknowledgement_vod__c newAOC: newAOCs) {
            if(String.isNotBlank(newAOC.Mobile_Id_vod__c)) {
                mobileIdToAOCMap.put(newAOC.Mobile_Id_vod__c, newAOC);
            }
        }
    }

    protected override String sObjectType() {
        return 'Content_Acknowledgement_vod__c';
    }

    @TestVisible protected override void beforeUpdate() {
        validateAOCRecords(false, newAOCs);
    }

    @TestVisible protected override void afterInsert() {
        processSigReqsForMissingAOCID();
    }

    @TestVisible protected override void afterUpdate() {
        processSigReqsForMissingAOCID();
        processSigReqsForAcceptedAOCs();
    }

    @TestVisible protected override void beforeDelete() {
        validateAOCRecords(true, oldAOCs);
    }

    private static void validateAOCRecords(boolean isDelete, List<Content_Acknowledgement_vod__c> aocList) {
        for (Integer i = 0 ;  i < aocList.size(); i++) {
            if (aocList[i].Unlock_vod__c == true){
                aocList[i].Unlock_vod__c = false;
                continue;
            } else if (isDelete ? isAOCSignaturePending(aocList[i]) : isAOCCompletedOrSignaturePending(oldAOCs[i], aocList[i])) {
                aocList[i].Status_vod__c.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('NO_UPD_SUB','TriggerError','You may not update a submitted call or any of the supporting data.'), false);
            }
        }
    }

    private static boolean isAOCCompletedOrSignaturePending(Content_Acknowledgement_vod__c oldAOC, Content_Acknowledgement_vod__c newAOC) {
        return oldAOC.Status_vod__c == 'Completed_vod' || isAOCSignaturePending(newAOC);
    }

    private static boolean isAOCSignaturePending(Content_Acknowledgement_vod__c newAOC) {
        return (String.isNotBlank(newAOC.Signature_Request_UUID_vod__c) && newAOC.Signature_Date_vod__c == null);
    }

    private static void processSigReqsForMissingAOCID() {
        Set<String> mobileIds = mobileIdToAOCMap.keySet();
        List<Signature_Request_vod__c> sigReqsMissingAOCID = getSignatureReqsByMobileId(mobileIds);
        for (Signature_Request_vod__c sigReq : sigReqsMissingAOCID) {
            sigReq.AOC_ID_vod__c = mobileIdToAOCMap.get(sigReq.Call2_Mobile_Id_vod__c).Id;
        }
        upsert sigReqsMissingAOCID;
    }

    private static List<Signature_Request_vod__c> getSignatureReqsByMobileId(Set<String> mobileIds) {
        List<Signature_Request_vod__c> sigReqs = new List<Signature_Request_vod__c>();
        if (!mobileIds.isEmpty()){
            sigReqs = [SELECT Id, Call2_Mobile_Id_vod__c, AOC_ID_vod__c FROM Signature_Request_vod__c WHERE Call2_Mobile_Id_vod__c IN :mobileIds AND AOC_Id_vod__c = null];
        }
        return sigReqs;
    }

    private static void processSigReqsForAcceptedAOCs() {
        Map<String, Content_Acknowledgement_vod__c> completedAOCUUIDs = new Map<String, Content_Acknowledgement_vod__c>();
        for (Content_Acknowledgement_vod__c aoc : newAOCs) {
            if (aoc.Status_vod__c == 'Completed_vod' && !String.isBlank(aoc.Signature_Request_UUID_vod__c)) {
                completedAOCUUIDs.put(aoc.Signature_Request_UUID_vod__c, aoc);
            }
        }
        List<Signature_Request_vod__c> pendingSigReqs = getPendingSignatureReqsByUUID(completedAOCUUIDs.keySet());
        for (Signature_Request_vod__c sigReq : pendingSigReqs) {
            sigReq.Status_vod__c = 'Signature_Accepted_vod';
            sigReq.Signature_Accepted_Datetime_vod__c = completedAOCUUIDs.get(sigReq.Signature_Request_UUID_vod__c).Signature_Date_vod__c;
        }
        upsert pendingSigReqs;
    }

    private static List<Signature_Request_vod__c> getPendingSignatureReqsByUUID(Set<String> uuids) {
        List<Signature_Request_vod__c> sigReqs = new List<Signature_Request_vod__c>();
        if (!uuids.isEmpty()){
            sigReqs = [SELECT Id, Status_vod__c, Signature_Accepted_Datetime_vod__c, Signature_Request_UUID_vod__c FROM Signature_Request_vod__c WHERE Signature_Request_UUID_vod__c IN :uuids AND Status_vod__c != 'Signature_Accepted_vod'];
        }
        return sigReqs;
    }
}