public without sharing class VeevaClmPresentationSlidePEActions {

    public static boolean canPublishPlatformEvent(List<Clm_Presentation_Slide_vod__c> newList) {
        List<String> ids = new List<String>();
        for(Clm_Presentation_Slide_vod__c presentationSlide : newList) {
            ids.add(presentationSlide.Clm_Presentation_vod__c);

        }
        for (Clm_Presentation_vod__c presentation : getPresentations(ids)) {
            if(presentation.Type_vod__c != 'Custom') {
                return true;
            }
        }
    
        return false;
    }

    public static boolean canPublishPlatformEvent(List<Clm_Presentation_Slide_vod__c> newList, Map<Id, Clm_Presentation_Slide_vod__c> oldMap) {
        List<String> ids = new List<String>();
        for(Clm_Presentation_Slide_vod__c presentationSlide : newList) {
            boolean hasChange = compareFields(presentationSlide, oldMap.get(presentationSlide.Id));

            if(hasChange) {
                ids.add(presentationSlide.Clm_Presentation_vod__c);
            }
        }
        for (Clm_Presentation_vod__c presentation : getPresentations(ids)) {
            if(presentation.Type_vod__c != 'Custom') {
                return true;
            }
        }

        return false;

    }

    private static boolean compareFields(Clm_Presentation_Slide_vod__c presentationSlide, Clm_Presentation_Slide_vod__c oldPresentationSlide) {
           if(presentationSlide.Key_Message_vod__c != oldPresentationSlide.Key_Message_vod__c ||
           presentationSlide.Display_Order_vod__c != oldPresentationSlide.Display_Order_vod__c ||
           presentationSlide.Sub_Presentation_vod__c != oldPresentationSlide.Sub_Presentation_vod__c) {
                return true;
            }

            return false;
    }

    private static List<Clm_Presentation_vod__c> getPresentations(List<String> presentationIds) {
        return [SELECT Type_vod__c FROM Clm_Presentation_vod__c WHERE Id IN :presentationIds];
    }
}