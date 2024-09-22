public without sharing class VeevaKeyMessagePlatformEventActions {

    public static boolean canPublishPlatformEvent(List<Key_Message_vod__c> newList, Map<Id, Key_Message_vod__c> oldMap) {
        for(Key_Message_vod__c keyMessage : newList) {
            boolean hasChange = compareFields(keyMessage, oldMap.get(keyMessage.Id));

            if(hasChange) {
                return true;
            }
        }

        return false;

    }

    private static boolean compareFields(Key_Message_vod__c keyMessage, Key_Message_vod__c oldKeyMessage) {
           if(keyMessage.Media_File_Name_vod__c != oldKeyMessage.Media_File_Name_vod__c ||
           keyMessage.Media_File_CRC_vod__c != oldKeyMessage.Media_File_CRC_vod__c ||
           keyMessage.Is_Shared_Resource_vod__c != oldKeyMessage.Is_Shared_Resource_vod__c ||
           keyMessage.Shared_Resource_vod__c != oldKeyMessage.Shared_Resource_vod__c ||
           keyMessage.Description_vod__c != oldKeyMessage.Description_vod__c ||
           keyMessage.CDN_Path_vod__c != oldKeyMessage.CDN_Path_vod__c ||
           keyMessage.Vault_GUID_vod__c != oldKeyMessage.Vault_GUID_vod__c ||
           keyMessage.Detail_Group_vod__c != oldKeyMessage.Detail_Group_vod__c ||
           keyMessage.Product_vod__c != oldKeyMessage.Product_vod__c ||
           keyMessage.Slide_Version_vod__c != oldKeyMessage.Slide_Version_vod__c ||
           keyMessage.Vault_External_Id_vod__c != oldKeyMessage.Vault_External_Id_vod__c ||
           keyMessage.Segment_vod__c != oldKeyMessage.Segment_vod__c ||
           keyMessage.CLM_ID_vod__c != oldKeyMessage.CLM_ID_vod__c ||
           keyMessage.Keywords_vod__c != oldKeyMessage.Keywords_vod__c) {
                return true;
           }

            return false;
        }
    }