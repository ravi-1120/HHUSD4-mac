public without sharing class VeevaClmPresentationTriggerHandler {

    private static final String OBJECT_NAME = 'Clm_Presentation_vod__c';

    public void onBeforeInsert(List<Clm_Presentation_vod__c> newPresentations)
    {
        stampPublishMethod(newPresentations);
    }

    public void onAfterInsert(List<Clm_Presentation_vod__c> newPresentations)
    {
        if(VeevaClmPresentationPlatformEventActions.canPublishPlatformEvent(newPresentations)) {
            VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.INSERT_EVENT_TYPE, newPresentations.size());
        }
    }

    public void onBeforeUpdate(Map<Id, Clm_Presentation_vod__c> updatedPresentationMap)
    {
        List<Clm_Presentation_vod__c> presentationsToStamp = new List<Clm_Presentation_vod__c>();
        for (String presId : updatedPresentationMap.keySet()) {
            Clm_Presentation_vod__c presentation = updatedPresentationMap.get(presId);
            if (String.isBlank(presentation.Publish_Method_vod__c)) {
                presentationsToStamp.add(presentation);
            }
        }
        stampPublishMethod(presentationsToStamp);
    }

    public void onAfterUpdate(List<Clm_Presentation_vod__c> updatedPresentations, Map<Id, Clm_Presentation_vod__c> oldPresentationMap)
    {
        if(VeevaClmPresentationPlatformEventActions.canPublishPlatformEvent(updatedPresentations, oldPresentationMap)) {
             VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.UPDATE_EVENT_TYPE, updatedPresentations.size());
        }
    }

    public void onBeforeDelete(Map<Id, Clm_Presentation_vod__c> oldPresentationMap){
        deleteContentPrefsForPresentations(oldPresentationMap.keySet());
    }

    public void onAfterDelete(List<Clm_Presentation_vod__c> deletedPresentations)
    {
        if(VeevaClmPresentationPlatformEventActions.canPublishPlatformEvent(deletedPresentations)) {
            VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.DELETE_EVENT_TYPE, deletedPresentations.size());
        }
    }

    private void deleteContentPrefsForPresentations(Set<Id> deletedPresentationIds) {
        if(deletedPresentationIds != null && deletedPresentationIds.size() > 0){
            delete [select Id from Content_Preference_vod__c where CLM_Presentation_vod__c in :deletedPresentationIds];
        }
    }

    private void stampPublishMethod(List<Clm_Presentation_vod__c> presentations) {

        for (Clm_Presentation_vod__c presentation : presentations) {
            String presentationType = presentation.Type_vod__c;
            String vaultDocId = presentation.Vault_Doc_Id_vod__c;
            String vaultExternalId = presentation.Vault_External_Id_vod__c;

        	if (String.isNotBlank(vaultDocId) && String.isNotBlank(vaultExternalId) && 'HQ'.equals(presentationType)) {
                Integer vaultExternalIdDocNumberIndex = vaultExternalId.indexOf('::');
                if (vaultExternalIdDocNumberIndex != -1) {
                    String vaultExternalDocNumber = vaultExternalId.substring(vaultExternalIdDocNumberIndex + 2, vaultExternalId.length());
                    if(vaultDocId.equals(vaultExternalDocNumber)) {
                        presentation.Publish_Method_vod__c = 'Vault_Published_vod';
                    } else {
                        presentation.Publish_Method_vod__c = 'Vault_Auto_Published_vod';
                    }
                }

            } else if (('HQ'.equals(presentationType) || String.isBlank(presentationType)) && String.isBlank(vaultExternalId)) {
                presentation.Publish_Method_vod__c = 'CRM_Published_vod';
            }
        }
    }
}