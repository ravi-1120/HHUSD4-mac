/**
 * Component Name:      MSD_CORE_MFRSitePageConfiguration
 * Created By:          Focal CXM
 * Description:         Server side controller for MFR Portal Site page configurations
 * Test Class:          MSD_CORE_MFRSitePageConfigurationTest
 * @description MSD_CORE_MFRSitePageConfiguration
 */
public without sharing class MSD_CORE_MFRSitePageConfiguration {
    /**
        * @description sitePageNames to support /s site
    */
    static Map<String, String> sitePageNames = new Map<String,String>{
        'ProductList'=>'Productlistpage__c',
        'Library'=>'library__c',
        'Dashboard'=>'Dashboard__c',
        'MyContacts'=>'mycontacts__c',
        'Learnmore'=>'Learnmore__c',
        'Signup'=>'Signup__c',
        'Attestation'=>'Attestation__c',
        'Librarydetail'=>'detail__c',
        'Appointment'=>'detail__c',
        'Request'=>'detail__c',
        'Schedule'=>'schedule_1__c',
        'viewschedule'=>'schedule__c',
        'login'=>'Login',
        'Welcomepage'=> 'Welcomepage__c',
        'LoginNew'=> 'LoginNew__c',
        'menu'=>'menu__c',
        'notification'=>'notification__c',
        'productdetail'=> 'productdetail__c',
        'othermercksites'=>'otherMerckSites__c',
        'logoutcconfirmationpage'=>'Logoutconfirmationpage__c',
        'contactmanager'=>'mfr_contactYourAccountManager__c',
        'setting'=>'settings__c',
        'ForgotpasswordNew'=> 'ForgotpasswordNew__c',
        'forgotpassword'=>'Forgot_Password'
    };

    /**
        * @description sitePageNames to support without /s
    */
    static Map<String, String> sitePageNamesWihtoutS = new Map<String,String>{
        'ProductList'=>'Productlistpage__c',
        'Library'=>'library__c',
        'Dashboard'=>'Dashboard__c',
        'MyContacts'=>'mycontacts__c',
        'Attestation'=>'Attestation__c',
        'Librarydetail'=>'detail__c',
        'Learnmore'=>'Learnmore__c',
        'Appointment'=>'detail__c',
        'Request'=>'detail__c',
        'Schedule'=>'schedule_1__c',
        'viewschedule'=>'viewschedule__c',
        // 'viewschedule'=>'schedule__c',
        'login'=>'Login',
        'Welcomepage'=> 'Welcomepage__c',
        'LoginNew'=> 'LoginNew__c',
        'menu'=>'menu__c',
        'notification'=>'notification__c',
        'productdetail'=> 'productdetail__c',
        'othermercksites'=>'otherMerckSites__c',
        'logoutcconfirmationpage'=>'Logoutconfirmationpage__c',
        'contactmanager'=>'mfr_contactYourAccountManager__c',
        'setting'=>'settings__c',
        'forgotpassword'=>'Forgot_Password',
        'ForgotpasswordNew'=> 'ForgotpasswordNew__c',
        'Signup'=>'Signup__c'
    };                

    /**
        * @description sitePageAPINames
    */
    static Map<String, String> sitePageAPINames = new Map<String,String>{
        'ProductList'=>'/product-list-page',
        'Library'=>'/library',
        'Dashboard'=>'/dashboard',
        'MyContacts'=>'/my-contacts',
        'Librarydetail'=>'/library/detail',
        'Attestation'=>'/attestation',
        'Appointment'=>'/library/detail',
        'Request'=>'/library/detail',
        'Schedule' =>'/schedule',
        'viewschedule'=>'/library/viewschedule',
        'login'=>'/login',
        'Welcomepage'=> '/welcomepage',
        'LoginNew'=> '/loginnew',
        'Learnmore'=>'/learnmore',
        'menu'=>'/menu',
        'notification'=>'/menu/notification',
        'productdetail'=>'/product/productdetail',
        'othermercksites'=>'/othermercksites',
        'logoutcconfirmationpage'=>'/logout-confirmation-page',
        'contactmanager'=> '/logout-confirmation-page/mfr-contactyouraccountmanager',
        'setting'=> '/settings',
        'forgotpassword'=>'/ForgotPassword',
        'ForgotpasswordNew'=> '/forgotpasswordnew',
        'Signup'=>'/signup'
    };

    /**
        * @description sitePageAPINames to support /s site
    */
    static Map<String, String> sitePageAPINameswiths = new Map<String,String>{
        'ProductList'=>'/s/product-list-page',
        'Library'=>'/s/library',
        'Dashboard'=>'/s/dashboard',
        'MyContacts'=>'/s/my-contacts',
        'Librarydetail'=>'/s/library/detail',
        'Appointment'=>'/s/library/detail',
        'Request'=>'/s/library/detail'
    };
            
    public static Boolean appendS = Boolean.valueOf(System.label.MSD_CORE_MFR_APPEND_S); //true; // Move this to Custom Lable  // MSD_CORE_MFR_APPEND_S   
    public static Boolean appendSiteName = Boolean.valueOf(System.label.MSD_CORE_MFR_APPEND_SITE_NAME); // Move this to Custom Lable    // MSD_CORE_MFR_APPEND_SITE_NAME
    static String siteName = System.label.MSD_CORE_MFR_SITE_NAME;//'/merckportal';// Move this to Custom Lable // MSD_CORE_MFR_SITE_NAME
    
    /**
        * @description getSiteName
        * @return siteName
        * @param pageName
    */
    @AuraEnabled
    public static String getSiteName(String pageName){
        String siteName;
        try{
            if(appendS){
                siteName = sitePageNames.get(pageName);
            }else{
                siteName = sitePageNamesWihtoutS.get(pageName);
            }   
            System.debug(LoggingLevel.WARN,'debuglogsiteName' +siteName);
            
        }catch(Exception ex){System.debug(LoggingLevel.WARN,ex);}
        return siteName;
    }

    /**
        * @description getSiteAPIName
        * @return siteAPIName
        * @param pageName
    */
    @AuraEnabled
    public static String getSiteAPIName(String pageName){
        String siteAPIName;
        try{
            siteAPIName = sitePageAPINames.get(pageName);
            if(appendS){
                siteAPIName = '/s'+siteAPIName;
            }
            
            if(appendSiteName){
                siteAPIName = siteName+sitePageAPINames.get(pageName);
            }
            System.debug(LoggingLevel.WARN,'debuglogsiteAPIName' +siteAPIName);
        }catch(Exception ex){System.debug(LoggingLevel.WARN,ex);}
        return siteAPIName;
    }

    /**
     * @description getSiteNameAndAPIName
     * @return results
     * @param pageName
     */
    @AuraEnabled(Cacheable=true)
    public static Map<String,String> getSiteNameAndAPIName(String pageName){
        System.debug(LoggingLevel.WARN,'pagename'+pagename);
        Map<String,String> results = new Map<String,String>();
        results.put('siteName',MSD_CORE_MFRSitePageConfiguration.getSiteName(pageName));
        results.put('siteAPIName',MSD_CORE_MFRSitePageConfiguration.getSiteAPIName(pageName));
        System.debug(LoggingLevel.WARN,'pagenamedebuglog'+results);
        return results;
        
    }

    /**
     * @description getAllSiteNameAndAPINames
     * @return results
     */
    @AuraEnabled(Cacheable=true)
    public static Map<String,Object> getAllSiteNameAndAPINames(){
        Map<String,Object> results = new Map<String,Object>();
        results.put('siteNames',sitePageNames);
        Map<String,String> siteAPINames = new Map<String,String>();
        for(String siteName : sitePageAPINames.keySet()){
            siteAPINames.put(siteName,MSD_CORE_MFRSitePageConfiguration.getSiteAPIName(siteName));
            System.debug(LoggingLevel.WARN,'siteAPINamesdebuglog' +siteAPINames);
        }
        
        results.put('siteAPINamesdebuglog',siteAPINames);
        return results;
    }

    /**
     * @description getOrgDomain
     * @return results
     */
    @AuraEnabled(Cacheable=true)
    public static Map<String,String> getOrgDomain(){
        Map<String,String> results = new Map<String,String>();
		String baseURL = String.valueof(System.URL.getSalesforceBaseURL().gethost());
        results.put('baseURL',baseURL);
		System.debug(LoggingLevel.WARN,'baseURldebuglof' +baseURL);
        System.debug(LoggingLevel.WARN,'resultsdebuglog' +results);
        return results;
    }
    
    /**
     * @description getMHEEURL
     * @return results
     */
    @AuraEnabled(Cacheable=true)
    public static String getMHEEURL(){
        String url;
        MFR_Site__mdt [] apiNames = [SELECT domainURL__c FROM MFR_Site__mdt WHERE DeveloperName = 'MHEE']; // Modified the SOQL to add the developerName - Sabari
		url = apiNames[0].domainURL__c;
        return url;
    }
}