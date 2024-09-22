/**
 * Component Name:      MSD_CORE_DiseaseInformationController
 * Created By:          Ravi Modi (Focal CXM)
 * Created Date:        11th Sep 2023
 * @description:        Server side controller for mSD_CORE_DiseaseInformation LWC component
 * Test Class:          
 */

public without sharing class MSD_CORE_DiseaseInformationController {
  
    
    /**
     * Method Name  :   getAllDiseaseInformation
     * @description :   Use to get All Disease Information record
     * @return      :   List<MSD_CORE_Disease_Information__c>
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   11th Sep 2023
     */
    @AuraEnabled
    public static diseaseInformation getAllDiseaseInformation(Integer pageSize, Integer offset, String searchKey){
        try {
            diseaseInformation wrap = new diseaseInformation();
            string key = '';
            String userid = UserInfo.getUserId();
            String soql = 'SELECT Id, Name, MSD_CORE_Disease_Information_Title__c, MSD_CORE_Resource_Type__c, MSD_CORE_Resource_URL__c, (SELECT Id, Name, MSD_CORE_Payor__c FROM Disease_Info_Librarys__r WHERE MSD_CORE_Payor__c = \'' +userid+ '\') FROM MSD_CORE_Disease_Information__c WHERE MSD_CORE_Disease_Information_Title__c LIKE  \''+'%' + searchKey +'%' +'\' AND MSD_CORE_Resource_URL__c != null ORDER BY MSD_CORE_Disease_Information_Title__c ASC  LIMIT ' + pageSize +' OFFSET ' + offset;
            wrap.diseaselist = Database.query(soql);
            wrap.totaldisease = [SELECT Id, Name FROM MSD_CORE_Disease_Information__c WHERE MSD_CORE_Resource_URL__c != null].size();
            return wrap;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Method Name  :   getSavedDiseaseInformation
     * @description :   Use to get Disease Information record
     * @return      :   List<MSD_CORE_Disease_Info_Library__c>
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   11th Sep 2023
     */
    @AuraEnabled
    public static diseaseSaveInformation getSavedDiseaseInformation(Integer pageSize, Integer offset, String searchKey){
        try {
            diseaseSaveInformation wrap = new diseaseSaveInformation();
            String userid = UserInfo.getUserId();
            String soql = 'SELECT Id, Name, MSD_CORE_Payor__c, MSD_CORE_Disease_Information__c, MSD_CORE_Disease_Information__r.Name, MSD_CORE_Disease_Information__r.MSD_CORE_Resource_Type__c, MSD_CORE_Disease_Information__r.MSD_CORE_Resource_URL__c, MSD_CORE_Disease_Information__r.MSD_CORE_Disease_Information_Title__c FROM MSD_CORE_Disease_Info_Library__c WHERE MSD_CORE_Payor__c =\'' +userid+ '\' AND MSD_CORE_Disease_Information__r.MSD_CORE_Disease_Information_Title__c LIKE \''+'%' + searchKey +'%' +'\' AND MSD_CORE_Disease_Information__r.MSD_CORE_Resource_URL__c != null ORDER BY MSD_CORE_Disease_Information__r.MSD_CORE_Disease_Information_Title__c ASC  LIMIT ' + pageSize +' OFFSET ' + offset;
            wrap.diseaselist = Database.query(soql);
            wrap.totaldisease =[SELECT Id, Name FROM MSD_CORE_Disease_Info_Library__c WHERE MSD_CORE_Payor__c =: userid AND MSD_CORE_Disease_Information__r.MSD_CORE_Resource_URL__c != null].size();
            return wrap;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Method Name  :   createDiseaseLibrary
     * @description :   Use to Create Disease library Record
     * @return      :   String
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   11th Sep 2023
     */
    @AuraEnabled
    public static String createDiseaseLibrary(String diseaseid){
        String returnvalue;
        try {
            MSD_CORE_Disease_Info_Library__c dislib = new MSD_CORE_Disease_Info_Library__c();
            dislib.MSD_CORE_Payor__c = UserInfo.getUserId();
            dislib.MSD_CORE_Disease_Information__c = diseaseid;
            insert dislib;
            returnvalue = 'Success';
        } catch (Exception e) {
            returnvalue = e.getMessage() +'--' +e.getLineNumber();
        }
        return returnvalue;
    }

    /**
     * Method Name  :   deleteDiseaseLibrary
     * @description :   Use to Delete Disease library Record
     * @return      :   String
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   11th Sep 2023
     */
    @AuraEnabled
    public static String deleteDiseaseLibrary(String diseaseid){
        String returnvalue;
        try {
            delete [SELECT Id, MSD_CORE_Disease_Information__c, MSD_CORE_Payor__c FROM MSD_CORE_Disease_Info_Library__c WHERE MSD_CORE_Disease_Information__c =: diseaseid AND MSD_CORE_Payor__c =: UserInfo.getUserId()];
            returnvalue = 'Success';
        } catch (Exception e) {
            returnvalue = e.getMessage() +'--' +e.getLineNumber();
        }
        return returnvalue;
    }

    public class diseaseInformation {
        @AuraEnabled
        public List<MSD_CORE_Disease_Information__c> diseaselist{get;set;}
        @AuraEnabled
        public Integer totaldisease{get;set;}
	}

    public class diseaseSaveInformation {
        @AuraEnabled
        public List<MSD_CORE_Disease_Info_Library__c> diseaselist{get;set;}
        @AuraEnabled
        public Integer totaldisease{get;set;}
	}
}