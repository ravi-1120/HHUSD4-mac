@isTest
public class MSD_CORE_DiseaseControllerTest {
    @isTest
    static void testGetAllDiseaseInformation() {
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 10;    
        insert vsc;
        
        User usr;
		System.runAs(new User(Id = UserInfo.getUserId())){ 
             usr = createUser();
        }
        Test.startTest();
        MSD_CORE_DiseaseInformationController.getAllDiseaseInformation(5, 0, 'Disease');
        Test.stopTest();
    }
    @isTest
    static void testgetSavedDiseaseInformation() {
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 10;    
        insert vsc;
        
        User usr;
		System.runAs(new User(Id = UserInfo.getUserId())){ 
             usr = createUser();
        }
        Test.startTest();
        MSD_CORE_DiseaseInformationController.getSavedDiseaseInformation(5, 0, 'Disease');
        Test.stopTest();
    }
    @isTest
    static void testgetcreateDiseaseLibrary() {
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 10;    
        insert vsc;
        
        User usr;
		System.runAs(new User(Id = UserInfo.getUserId())){ 
             usr = createUser();
        }
        MSD_CORE_Disease_Info_Library__c disLib = createDiseaseInfoLib();
        Test.startTest();
        MSD_CORE_DiseaseInformationController.createDiseaseLibrary(disLib.Id);
        Test.stopTest();
    }
    @isTest
    static void testdeleteDiseaseLibrary() {
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 10;    
        insert vsc;
        
        User usr;
		System.runAs(new User(Id = UserInfo.getUserId())){ 
             usr = createUser();
        }
        MSD_CORE_Disease_Info_Library__c disLib = createDiseaseInfoLib();
        Test.startTest();
        MSD_CORE_DiseaseInformationController.deleteDiseaseLibrary(disLib.Id);
        Test.stopTest();
    }

    private static User createUser() {
        Profile firstProfile = [SELECT Id FROM Profile Limit 1];
        User user1 = new User(LastName = 'Userton',
                           FirstName='User',
                           Alias = 'usus',
                           Email = 'user.user@merck.com',
                           Username = Math.random() + '@' + Math.random(),
                           ProfileId = firstProfile.Id,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                    
        );
        insert user1;
        return user1;
    }
   /**
   * @description createDiseaseInfo
   * @return disinfo
   */
    public static MSD_CORE_Disease_Information__c createDiseaseInfo(){
        MSD_CORE_Disease_Information__c disinfo = new MSD_CORE_Disease_Information__c();
        disinfo.MSD_CORE_Disease_Information_Title__c = 'Disease';
        disinfo.MSD_CORE_Resource_Type__c = 'PDF';
        disinfo.MSD_CORE_Resource_URL__c = 'test.merckformularyresources.com';
        insert disinfo;
        return disinfo;
    }
   /**
   * @description createDiseaseInfoLib
   * @return disinfolib
   */ 
    public static MSD_CORE_Disease_Info_Library__c createDiseaseInfoLib(){
        User usr = createUser();
        MSD_CORE_Disease_Information__c disinfo = createDiseaseInfo();
        MSD_CORE_Disease_Info_Library__c disinfolib = new MSD_CORE_Disease_Info_Library__c();
        disinfolib.MSD_CORE_Disease_Information__c = disinfo.Id;
        disinfolib.MSD_CORE_Payor__c = usr.Id;
        insert disinfolib;
        return disinfolib;
    }
}