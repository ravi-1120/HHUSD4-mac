public class MSD_CORE_HEQ_BusinessRuleHandler {
    public static List<String> getOptions(Id userId, String resourceType) {
        List<String> lstOfStringToBeReturned = new List<String>();
        List<GroupMember> lstOfPublicGroupUsers = [SELECT id, Group.DeveloperName, UserOrGroup.Name, UserOrGroupId 
                                                   FROM GroupMember
                                                   WHERE UserOrGroupId =:userId];
        System.debug('### lstOfPublicGroupUsers '+lstOfPublicGroupUsers);
        if(lstOfPublicGroupUsers.size()>0) {
            
            List<Business_Rule__mdt> lstOfBusinessRules = [SELECT Id, MSD_CORE_HEQ_Add_To_Collection__c, MSD_CORE_HEQ_Customize__c,
                                                           MSD_CORE_HEQ_Download__c, MSD_CORE_HEQ_Email_To_Customer__c, 
                                                           MSD_CORE_HEQ_Open__c, MSD_CORE_HEQ_Preview_and_Details__c, MSD_CORE_HEQ_Print_To_Customer__c,
                                                           Resource_Type__c, MSD_CORE_HEQ_Shared_Group_API_Name__c
                                                           FROM Business_Rule__mdt 
                                                           WHERE Resource_Type__c =: resourceType 
                                                           AND MSD_CORE_HEQ_Shared_Group_API_Name__c =:lstOfPublicGroupUsers[0].Group.DeveloperName];
            
            System.debug('### lstOfBusinessRules '+lstOfBusinessRules);
            
            if(lstOfBusinessRules.size()>0) {
                if(lstOfBusinessRules[0].MSD_CORE_HEQ_Add_To_Collection__c == true) {
                    lstOfStringToBeReturned.add('Add To Collection');
                }
                if(lstOfBusinessRules[0].MSD_CORE_HEQ_Customize__c == true) {
                    lstOfStringToBeReturned.add('Customize');
                }
                if(lstOfBusinessRules[0].MSD_CORE_HEQ_Download__c == true) {
                    lstOfStringToBeReturned.add('Download');
                }
                if(lstOfBusinessRules[0].MSD_CORE_HEQ_Email_To_Customer__c == true) {
                    lstOfStringToBeReturned.add('Email To Customer');
                }
                if(lstOfBusinessRules[0].MSD_CORE_HEQ_Open__c == true) {
                    lstOfStringToBeReturned.add('Open');
                }
                if(lstOfBusinessRules[0].MSD_CORE_HEQ_Preview_and_Details__c == true) {
                    lstOfStringToBeReturned.add('Preview and Details');
                }
                if(lstOfBusinessRules[0].MSD_CORE_HEQ_Print_To_Customer__c == true) {
                    lstOfStringToBeReturned.add('Print to Customer');
                }            
            }
        }        
        return lstOfStringToBeReturned;
    }
}