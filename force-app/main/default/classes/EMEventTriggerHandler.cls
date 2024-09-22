/*
 * This class is meant to hold the call to the AdHocSyncProcess for QR Sign-In and Event Registration. Current implementation has syncEvents()
 * called from triggers/VOD_EM_EVENT_AFTER_INS_UPD.trigger for events with name change only and in classes/VOD_EVENT_UTILS.cls
 * for roll-up called by changes to event attendees and event speakers. Be careful to move calls to this method,
 * VeevaQRSignInSync.callAdHocSyncProcess() has a callout with a future annotation that can cause errors if already in a
 * future context from a previous class.
 * See https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_future.htm
 */

public class EMEventTriggerHandler{

    public static void syncEvents(List<EM_Event_vod__c> events){
        Set<String> objectFields = Schema.SObjectType.EM_Event_vod__c.fields.getMap().keySet();
        boolean isQrEnabled = objectFields.contains('qr_sign_in_enabled_vod__c');
        boolean isRegistrationEnabled = objectFields.contains('registration_form_vod__c');
        if (isQrEnabled || isRegistrationEnabled) {
            String query = constructQuery(isQrEnabled, isRegistrationEnabled);
            if (String.isNotBlank(query)) {
                List<EM_Event_vod__c> eventsToSync = Database.query(query);
                Set<Id> eventIds = new Set<Id>();
                for(EM_Event_vod__c event: eventsToSync){
                    eventIds.add(event.Id);
                }
                
                if (eventIds.size() > 0 && !(System.isBatch() || System.isFuture() || System.isQueueable() || System.isScheduled())) {
                    VeevaQRSignInSync adHocJob = new VeevaQRSignInSync(eventIds);
                    System.enqueueJob(adHocJob);
                }
            }
        }
    }
    
    @TestVisible
    private static String constructQuery(boolean isQrEnabled, boolean isRegistrationEnabled) {
        String eventQuery = null;
        List<String> conditions = new List<String>();
        if (isQrEnabled) {
            conditions.add('QR_Sign_In_Enabled_vod__c = \'Yes_vod\'');
        }
        if (isRegistrationEnabled) {
            conditions.add('Registration_Form_vod__c != null');
        }
        if (!conditions.isEmpty()) {
            String conditionsClause = String.join(conditions, ' OR ');
            eventQuery = 'SELECT Id FROM EM_Event_vod__c WHERE Id IN :events AND ('+conditionsClause+')';
        }
        return eventQuery;
    }
}