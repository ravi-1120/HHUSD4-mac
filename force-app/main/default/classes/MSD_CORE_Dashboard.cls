/**
 * Component Name:      MSD_CORE_Dashboard
 * Created By:          Focal CXM
 * Created Date:        21st October 2022
 * Description:         Server side controller for mSD_CORE_Dashboard LWC component
 * Test Class:          MSD_CORE_DashboardTest
 */

public without sharing class MSD_CORE_Dashboard {
    public static string className = 'MSD_CORE_Dashboard';
    
    /**
     * @description Method used to get the list  of Primary Executives
     * @return User
    */
    @AuraEnabled(cacheable=true)
    public static List<User> getPrimaryExecutive(String userId){
        //Mukesh
        try {
            User usr = [SELECT Id, ContactId from User WHERE  Id=: userId LIMIT 1];
            Contact con = [SELECT Id, Name, MSD_CORE_Medical_AE__c, MSD_CORE_Oncology_AE__c FROM Contact WHERE Id =: usr.ContactId LIMIT 1];
            if (con != null) {
                return [SELECT Id, Name, FirstName, LastName, Phone, CommunityNickname, FullPhotoUrl,MediumPhotoUrl, Email, Title FROM User where Id=:con.MSD_CORE_Medical_AE__c OR Id=: con.MSD_CORE_Oncology_AE__c];
            }
            return null;
        } catch (Exception e) {
            MHEEExceptionHandler.logException(e, className, 'getPrimaryExecutive', 'Get Primary Executive');return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<MSD_Core_MHEE_Configurations__mdt> getAllConfigurations() {
        return [
            
            SELECT Id, DeveloperName, MasterLabel, MSD_Core_MHEE_Description__c, MSD_Core_MHEE_Detailed_Description__c, MSD_Core_MHEE_Explore_header__c, MSD_Core_MHEE_View_Resource_link__c, Sequence__c, Image_link__c  FROM MSD_Core_MHEE_Configurations__mdt ORDER BY Sequence__c ASC
            
        ];
    }

    /**
     * @description Method used to get the list of Other Merck Sites
     * @return MSD_CORE_OtherMerck__mdt
    */
    @AuraEnabled(cacheable=true)
    public static List<MSD_CORE_OtherMerck__mdt> getMerckSites(){

        try {
            List<MSD_CORE_OtherMerck__mdt> merckSites =[SELECT Id, MSD_CORE_Description__c, MSD_CORE_Header1__c, MSD_CORE_Header2__c,MSD_CORE_Header1_Index1__c,MSD_CORE_Header1_Index2__c,MSD_CORE_Site__c, MSD_CORE_Index__C FROM  MSD_CORE_OtherMerck__mdt ORDER By MSD_CORE_Index__C ASC];
            return merckSites;
        } catch (Exception e) {
            MHEEExceptionHandler.logException(e, className, 'getMerckSites', 'Get Merck Sites');return null;
        }
    }
    /**
     * @description getEnableDisease
     * @return Boolean
    */
   @AuraEnabled(cacheable=true)
    public static Boolean getEnableDisease(){
       List<MHEE_site__mdt> siteSetting = [Select Id,Enable_Disease_Info_Menu__c From MHEE_site__mdt];
        //return siteSetting;
        if(siteSetting.size()>0){
            return siteSetting[0].Enable_Disease_Info_Menu__c;
        }
        else{
            return false;
        }
    }
}