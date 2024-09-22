/**
 * Component Name: MSD_CORE_MHEESitePageConfiguration
 * Created By: Focal CXM
 * Description: Serverside controller for  LWC components
 * Test class : MSD_CORE_MHEESitePageConfigurationTest
 * @description MSD_CORE_MHEESitePageConfiguration
 */
public class MSD_CORE_MHEESitePageConfiguration { 
        /**
        * @description sitePageAPINames
        */
    //SitePageNames to support /s site
    Static Map<String, String> sitePageAPINames = new Map<String,String>{
        'Menu'=>'Menu__c',
        'Dashboard'=>'Home',
        'othermercksite'=>'OtherMerckSites__c',
        'Pipeline'=>'pipeline__c',
        'Schedule'=>'ScheduleAppointment__c',
        'RequestAppointment'=>'RequestAppointment__c',
        'RequestDetail'=>'RequestDetail__c',
        'StudyDetail'=>'StudyDetail__c',
        'Notification'=>'Notification__c',// For User Story :1097 by Tausif
        'Factsheet'=>'Factsheet__c', //Added for Notifications 1270 by SM
        'DiseaseInformation'=>'Disease_Information__c',
        'forgotpassword'=>'Forgot_Password'

    };
        /**
        * @description sitePageNamesWihtoutS
        */
    //SitePageNames to support site without /s
    Static Map<String, String> sitePageNamesWihtoutS = new Map<String,String>{
        'Menu'=>'Menu__c',
        'Dashboard'=>'Home',
        'othermercksite'=>'OtherMerckSites__c',
        'Pipeline'=>'pipeline__c',
        'Schedule'=>'ScheduleAppointment__c',
        'RequestAppointment'=>'RequestAppointment__c',
        'RequestDetail'=>'RequestDetail__c',
        'StudyDetail'=>'StudyDetail__c',
        'Notification'=>'Notification__c',// For User Story :1097 by Tausif
        'Factsheet'=>'Factsheet__c', //Added for Notifications 1270 by SM
        'DiseaseInformation'=>'Disease_Information__c',
        'forgotpassword'=>'Forgot_Password'

    };
        /**
        * @description sitePageNames
        */
    Static Map<String, String> sitePageNames = new Map<String,String>{
        'Menu'=>'/menu',
        'Dashboard'=>'/',
        'othermercksite'=>'/othermercksites',
        'Pipeline'=>'/pipeline',
        'Schedule'=>'/scheduleappointment',
        'RequestAppointment'=>'/requestappointment',
        'RequestDetail'=>'/requestappointment/requestdetail',
        'StudyDetail'=>'/studydetail',
        'Notification'=>'/notification',// For User Story :1097 by Tausif
        'Factsheet'=>'/factsheet', //Added for Notifications 1270 by SM
        'DiseaseInformation'=>'/disease-information', 
        'forgotpassword'=>'/ForgotPassword'

    };
    // Static Map<String, String> sitePageAPINameswithmhee = new Map<String,String>{
    //     'Menu'=>'/mhee/menu',
    //     'Dashboard'=>'/mhee',
    //     'othermercksite'=>'/mhee/othermercksites',
    //     'Pipeline'=>'/mhee/pipeline',
    //     'Schedule'=>'/mhee/scheduleappointment'
    // };
    public static Boolean appendS = Boolean.valueOf(System.label.MSD_CORE_MHEE_APPEND_S); //true; // Move this to Custom Lable  // MSD_CORE_MFR_APPEND_S   
    public static Boolean appendSiteName = Boolean.valueOf(System.label.MSD_CORE_MHEE_APPEND_SITE_NAME); // Move this to Custom Lable    // MSD_CORE_MFR_APPEND_SITE_NAME
    static String siteName = System.label.MSD_CORE_MHEE_SITE_NAME;//'/merckportal';// Move this to Custom Lable // MSD_CORE_MFR_SITE_NAME
    @AuraEnabled
        /**
        * @description getSiteName
        * @return siteName
        * @param pageName
        */
    public static String getSiteName(String pageName){
        String siteName;
        try{
            if(appendS){
                siteName = sitePageAPINames.get(pageName);
            }else{
                siteName = sitePageNamesWihtoutS.get(pageName);
            }            
        }catch(Exception ex){System.debug(LoggingLevel.WARN,ex);}
        return siteName;
    }
    @AuraEnabled
        /**
        * @description getSiteAPIName
        * @return siteAPIName
        * @param pageName
        */
    public static String getSiteAPIName(String pageName){
        String siteAPIName;
        try{
            siteAPIName = sitePageNames.get(pageName);
            if(appendS){
                siteAPIName = '/s'+siteAPIName;
            }
            
            if(appendSiteName){
                siteAPIName = siteName+sitePageNames.get(pageName);
            }
        }catch(Exception ex){System.debug(LoggingLevel.WARN,ex);}
        return siteAPIName;
    }
    //RT
    @AuraEnabled(Cacheable=true)
    /**
     * @description getSiteNameAndAPIName
     * @return results
     * @param pageName
     */
    public static Map<String,String> getSiteNameAndAPIName(String pageName){
        System.debug(LoggingLevel.WARN,'pagename'+pagename);
        Map<String,String> results = new Map<String,String>();
        results.put('siteName',MSD_CORE_MHEESitePageConfiguration.getSiteName(pageName));
        results.put('siteAPIName',MSD_CORE_MHEESitePageConfiguration.getSiteAPIName(pageName));
        return results;
    }
    @AuraEnabled(Cacheable=true)
    /**
     * @description getAllSiteNameAndAPINames
     * @return results
     */
    public static Map<String,Object> getAllSiteNameAndAPINames(){
        Map<String,Object> results = new Map<String,Object>();
        Map<String,String> siteAPINames = new Map<String,String>();
        for(String siteName : sitePageNames.keySet()){
            siteAPINames.put(siteName,MSD_CORE_MHEESitePageConfiguration.getSiteAPIName(siteName));
        }
        results.put('siteAPINames',sitePageAPINames);
        results.put('siteNames',siteAPINames);
        System.debug(LoggingLevel.WARN,'results--=>'+results);
        return results;
    }
}