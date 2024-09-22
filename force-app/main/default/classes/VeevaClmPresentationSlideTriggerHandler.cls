public without sharing class VeevaClmPresentationSlideTriggerHandler {

    private static final String OBJECT_NAME = 'Clm_Presentation_Slide_vod__c';

    public void onAfterInsert(List<Clm_Presentation_Slide_vod__c> newPresentationSlides)
    {
        if(VeevaClmPresentationSlidePEActions.canPublishPlatformEvent(newPresentationSlides)) {
            VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.INSERT_EVENT_TYPE, newPresentationSlides.size());
        }
    }

    public void onAfterUpdate(List<Clm_Presentation_Slide_vod__c> updatedPresentationSlides, Map<Id, Clm_Presentation_Slide_vod__c> oldPresentationSlideMap)
    {
        if(VeevaClmPresentationSlidePEActions.canPublishPlatformEvent(updatedPresentationSlides, oldPresentationSlideMap)) {
             VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.UPDATE_EVENT_TYPE, updatedPresentationSlides.size());
        }
    }

    public void onAfterDelete(List<Clm_Presentation_Slide_vod__c> deletedPresentationSlides)
    {
        if(VeevaClmPresentationSlidePEActions.canPublishPlatformEvent(deletedPresentationSlides)) {
            VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.DELETE_EVENT_TYPE, deletedPresentationSlides.size());
        }
    }
}