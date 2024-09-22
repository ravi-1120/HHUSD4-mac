public with sharing class VeevaCalendarApprovedEmailHelper {

    public static boolean remoteMeetingInviteAEEnabled() {
        // check if can send Approved email
        if (!canSendApprovedEmail()) {
            return false;
        }

         // check if remote entry point is disabled
         if (remoteMeetingApprovedEmailEndpointIsDisabled()) {
            return false;
         }
 
         // check if remote meeting an available record type
        if (!hasRemoteMeetingSentEmail()) {
            return false;
        }
 
         // check if there is a remote meeting approved document with expected status

         return hasRemoteMeetingApprovedDocument();
    }
    
    @TestVisible
    private static boolean canSendApprovedEmail() {
        Boolean hasMultiChannelConsent = Multichannel_Consent_vod__c.sObjectType.getDescribe() != null;
        Boolean hasApprovedDocument = Approved_Document_vod__c.sObjectType.getDescribe() != null;
        DescribeSobjectResult sentEmailDescObj = Sent_Email_vod__c.sObjectType.getDescribe();
        return hasMultiChannelConsent && hasApprovedDocument && sentEmailDescObj?.isCreateable() && sentEmailDescObj?.isUpdateable();
    }

    private static boolean remoteMeetingApprovedEmailEndpointIsDisabled() {
        Object disabledEntrySetting = VeevaCustomSettingsService.getCustomSettings('Approved_Email_Settings_vod__c', new List<String>{'DISABLED_APPROVED_EMAIL_ENTRYPOINTS_vod__c'})?.get('DISABLED_APPROVED_EMAIL_ENTRYPOINTS_vod__c');
        List<String> disabledEntryPoints = disabledEntrySetting != null ? disabledEntrySetting.toString().split(';;') : new List<String>();
        return disabledEntryPoints.contains('RemoteMeeting_vod');
    }

    private static boolean hasRemoteMeetingSentEmail() {
        Schema.RecordTypeInfo remoteMeetingRT = Schema.SObjectType.Sent_Email_vod__c.getRecordTypeInfosByDeveloperName().get('Remote_Meeting_vod');
        return remoteMeetingRT?.isAvailable();
    }

    private static boolean hasRemoteMeetingApprovedDocument() {
        List<SObject> approvedEmailDoc = new List<SObject>();

        // check if there is a remote meeting approved document with expected status
        Schema.RecordTypeInfo approvedDocRemoteMeetingRT = Schema.SObjectType.Approved_Document_vod__c.getRecordTypeInfosByDeveloperName().get('Remote_Meeting_vod');

        try {
            User user = [SELECT Approved_Email_Admin_vod__c FROM User WHERE Id = :UserInfo.getUserId()];
            // Admin / non-admin users have differing access to Approved Documents. Only Admins can see those with a  'Staged' status.
            List<String> scope = user?.Approved_Email_Admin_vod__c ? new List<String>{'Staged_vod', 'Approved_vod'} : new List<String>{'Approved_vod'};
            if (approvedDocRemoteMeetingRT != null) {
                approvedEmailDoc = [SELECT Id FROM Approved_Document_vod__c WHERE (RecordTypeId = :approvedDocRemoteMeetingRT.getRecordTypeId() AND Status_vod__c IN :scope) LIMIT 1];
            }
        } catch (Exception e) {
            return false;
        }
        
        return !approvedEmailDoc.isEmpty();
    }
}