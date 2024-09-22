public class VeevaUpdateDocumentedInterestFuture {
    @future
    @TestVisible public static void updateDocumentedInterest(Map<String, Id> callMobileIds) {
        List<Documented_Interest_vod__c> documentedInterests = [SELECT ID, Interaction_Reference_Id_vod__c FROM Documented_Interest_vod__c WHERE Interaction_Reference_Id_vod__c IN :callMobileIds.keySet()];

        for(Documented_Interest_vod__c di : documentedInterests) {
            Id callId = callMobileIds.get(di.Interaction_Reference_Id_vod__c);
            if(callId != null) {
                di.Interaction_Reference_Id_vod__c = callId;
            }
        }

        upsert documentedInterests;
    }
}