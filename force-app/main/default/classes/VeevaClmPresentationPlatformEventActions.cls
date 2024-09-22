public without sharing class VeevaClmPresentationPlatformEventActions {

 
    public static boolean canPublishPlatformEvent(List<Clm_Presentation_vod__c> newList) {
        for(Clm_Presentation_vod__c presentation : newList) {
            if(presentation.Type_vod__c != 'Custom') {
                return true;
            }
        }

        return false;
    }

    public static boolean canPublishPlatformEvent(List<Clm_Presentation_vod__c> newList, Map<Id, Clm_Presentation_vod__c> oldMap) {
        for(Clm_Presentation_vod__c presentation : newList) {

            boolean hasChange = compareFields(presentation, oldMap.get(presentation.Id));

            if(hasChange && presentation.Type_vod__c != 'Custom') {
                return true;
            }
        }

        return false;
    }

    private static boolean compareFields(Clm_Presentation_vod__c presentation, Clm_Presentation_vod__c oldPresentation) {
           if(presentation.Name != oldPresentation.Name ||
           presentation.Product_vod__c != oldPresentation.Product_vod__c ||
           presentation.Hidden_vod__c != oldPresentation.Hidden_vod__c ||
           presentation.Training_vod__c != oldPresentation.Training_vod__c ||
           presentation.Directory_vod__c != oldPresentation.Directory_vod__c ||
           presentation.Version_vod__c != oldPresentation.Version_vod__c ||
           presentation.Vault_External_Id_vod__c != oldPresentation.Vault_External_Id_vod__c ||
           presentation.Presentation_Id_vod__c != oldPresentation.Presentation_Id_vod__c ||
           presentation.Status_vod__c != oldPresentation.Status_vod__c ||
           presentation.Description_vod__c != oldPresentation.Description_vod__c ||
           presentation.Keywords_vod__c != oldPresentation.Keywords_vod__c ||
           presentation.End_Date_vod__c != oldPresentation.End_Date_vod__c ||
           presentation.Start_Date_vod__c != oldPresentation.Start_Date_vod__c ||
           presentation.Detail_Group_vod__c != oldPresentation.Detail_Group_vod__c ||
           presentation.Total_slides_vod__c != oldPresentation.Total_slides_vod__c) {
                return true;
            }

            return false;
    }
}