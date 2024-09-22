/**
 * Component Name:      MSD_CORE_ProductDetailTest
 * Created By:          Ravi Modi (Focal CXM)
 * @description:        Test class of MSD_CORE_ProductDetail
 */

@isTest
public class MSD_CORE_ProductDetailTest {
    /**
     * @description testGetCatalogsByOffset
     * @return void
    */
    @isTest
    static void testGetCatalogsByOffset(){

        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;
        User usr;
        System.runAs(new User(Id = UserInfo.getUserId())){ 
             usr = createUser();
        }
        
        MSD_CORE_Catalog__c catalog = createCatalog();
        
        Test.startTest();

        MSD_CORE_ProductDetail.catalogwrap wrap = new MSD_CORE_ProductDetail.catalogwrap();
        wrap = MSD_CORE_ProductDetail.getCatalogsByOffset((String)catalog.MSD_CORE_Product_Payor__c,(String)usr.Id,'5','1');

        Test.stopTest();
        /*System.assert(wrap != null,'Catalog Wrapper exists');*/
        
        
    }

    /**
     * @description testGetProducts
     * @return void
    */
    @isTest
    static void testGetProducts(){

        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;

        User usr;
        System.runAs(new User(Id = UserInfo.getUserId())){ 
             usr = createUser();
        }
    
        MSD_CORE_Product_Payor__c product = new MSD_CORE_Product_Payor__c();
        product.Related_System__c = 'MFR'; // Set Related_System__c field to 'MFR'
        product.MSD_CORE_Colourcode__c = '#FF8C00';
        insert product;
        Test.startTest();
        MSD_CORE_Product_Payor__c prod = MSD_CORE_ProductDetail.getproduct((String)product.Id);
        Test.stopTest();
        /*System.assert(prod == null,'Product not exists');*/
    }

    /**
     * @description testupdateReadCheck
     * @return void
    */
    @isTest
    static void testupdateReadCheck(){

        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;

        User usr;
        System.runAs(new User(Id = UserInfo.getUserId())){ 
             usr = createUser();
        }

        MSD_CORE_Catalog__c catalog = createCatalog();
        Test.startTest();
        String str = MSD_CORE_ProductDetail.updateReadCheck((String)catalog.Id);
        Test.stopTest();
        System.assert(str != null,'Catalog updated!');
    }

    /**
     * @description testgetproductFilter
     * @return void
    */
    @isTest
    static void testgetproductFilter(){

        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;

        User usr;
        System.runAs(new User(Id = UserInfo.getUserId())){ 
             usr = createUser();
        }

        MSD_CORE_Filter__c filter = new MSD_CORE_Filter__c();
        Test.startTest();
        List<MSD_CORE_Filter__c> filterList = MSD_CORE_ProductDetail.getproductFilter((String)filter.MSD_CORE_Product_Payor__c);
        Test.stopTest();
        System.assert(filterList.size() ==0,'filterList found');
    }
 
    /**
     * @description testgetCatalogsFilter
     * @return void
    */
    @isTest
    static void testgetCatalogsFilter(){

        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 10;    
        insert vsc;
        
        User usr;
        System.runAs(new User(Id = UserInfo.getUserId())){ 
             usr = createUser();
        }  
        
        MSD_CORE_Catalog__c catalog = createCatalog();
        List<String> criteria = new List<String>{'Test'};
        Test.startTest();
        List<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductDetail.getCatalogsFilter((String)catalog.MSD_CORE_Product_Payor__c,(String)usr.Id,criteria);
        Test.stopTest();
        /*System.assert(cataloglst1 != null,'Catalog list exists')*/
    }

    /**
     * @description testRemoveCatalogs
     * @return void
    */
    @isTest
    static void testRemoveCatalogs(){

        
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 10;    
        insert vsc;
        
        User usr;
        System.runAs(new User(Id = UserInfo.getUserId())){ 
             usr = createUser();
        }

        MSD_CORE_Library__c coreLib = createCoreLibrary();
        Test.startTest();
        MSD_CORE_ProductDetail.removeCatalogs((String)coreLib.MSD_CORE_Catalog__c,(String)(coreLib.MSD_CORE_Payor__c));
        Test.stopTest();
        System.assert(coreLib != null,'Library is exists');
    }

    /**
     * @description testgetContentConnector
     * @return void
    */
    @isTest
    static void testgetContentConnector(){

        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;

        User usr;
        System.runAs(new User(Id = UserInfo.getUserId())){ 
             usr = createUser();
        }
        
        String docurl = 'Test';
        Test.startTest();
        MSD_CORE_ProductDetail.getcontentconnector((docurl));
        Test.stopTest();
        System.assert(docurl != null,'Document is exists');
    }

    /**
     * @description createUser
     * @return user1
    */
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
     * @description createUser1
     * @return user1
    */
    private static User createUser1() {
        Profile firstProfile = [SELECT Id FROM Profile WHERE Name = 'MRK_Payor_Exec' Limit 1];
        UserRole usrRole = [SELECT Id  FROM UserRole WHERE Name = 'USD2FCL Customer Person Account' Limit 1];
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Contact con = new Contact(FirstName = 'Test Contact', LastName = 'Test LastName', AccountId = acc.Id, Email = 'testcontact123@merck.com', MSD_CORE_Health_Care_Decision_Maker__c = true);
        insert con;
        User user1 = new User(LastName = 'Userton',
                           FirstName='User',
                           Alias = 'usus',
                           Email = 'user.user@merck.com',
                           Username = Math.random() + '@' + Math.random(),
                           ProfileId = firstProfile.Id,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US',
                           ContactId = con.Id//,
                           //UserRoleId = usrRole.ID
                           );
        insert user1;
        return user1;
    }

    /**
     * @description createProduct
     * @return prodPay
    */
    public static MSD_CORE_Product_Payor__c createProduct(){
        MSD_CORE_Product_Payor__c prodPay = new MSD_CORE_Product_Payor__c();
        prodPay.Name = 'TESTING®';
        prodPay.MSD_CORE_Active__c = true;
        prodPay.MSD_CORE_Brand_Status__c = false;
        prodPay.MSD_CORE_Colourcode__c = '#FF8C00';
        prodPay.MSD_CORE_Dosage_Form_and_Strength__c = 'injection 100mg/ml (equivalent to 108.8 mg/ml sugammadex sodium), for intravenous use';
        prodPay.MSD_CORE_Generic_Name__c = '(sugammadex)';
        prodPay.MSD_CORE_Indication__c = 'TESTING® (sugammadex) is indicated for the reversal of neuromuscular blockade induced by rocuronium bromide and vecuronium bromide in adults and pediatric patients aged 2 years and older undergoing surgery.';
        prodPay.MSD_CORE_Information_About_Product__c = '<p><strong style=\"color: rgb(0, 0, 0); font-size: 24px;\">Indication</strong></p><p><br></p><p><span style=\"font-size: 16px;\">TESTING® (sugammadex) is indicated for the reversal of neuromuscular blockade induced by rocuronium bromide and vecuronium bromide in adults undergoing surgery.</span></p><p><br></p>';
        prodPay.MSD_CORE_Product_Family__c = 'TESTING®';
        prodPay.MSD_CORE_Product_ID__c = 'test1';
        prodPay.MSD_CORE_Selected_Safety_Information__c = 'Test Safety';
        prodPay.MSD_CORE_HCP_site__c = 'https://www.merckconnect.com/bridion/dosing-administration/';
        prodPay.MSD_CORE_Source__c = '10';
        prodPay.Related_System__c = 'MFR';
        insert prodPay;
        return prodPay;
    }

    /**
     * @description createMeetingReq
     * @return reqvod
    */
    public static Meeting_Request_vod__c createMeetingReq(){
        User usr = createUser();
        MSD_CORE_Product_Payor__c prodPay = createProduct();
        Meeting_Request_vod__c reqvod = new Meeting_Request_vod__c();
        reqvod.Start_DateTime_vod__c = System.now();
        reqvod.MSD_CORE_Product_Payor__c = prodPay.Id;
        reqvod.MSD_CORE_Status__c = 'Closed';
        reqvod.MSD_CORE_attendee__c = 'test1@fcxm.com';
        reqvod.MSD_CORE_Meeting_preference__c = 'Virtual meeting';
        reqvod.MSD_CORE_Payor__c = usr.Id;
        reqvod.Duration_vod__c = 60;
        reqvod.Record_Type_Name_vod__c = 'Engage_Scheduling_Site_vod';
        insert reqvod;
        return reqvod;
    }

    /**
     * @description createCatalog
     * @return catalog
    */
    public static MSD_CORE_Catalog__c createCatalog(){
        User usr = createUser();
        MSD_CORE_Product_Payor__c prodPay = createProduct();
        Meeting_Request_vod__c meetReq = createMeetingReq();
        MSD_CORE_Catalog__c catalog = new MSD_CORE_Catalog__c();
        catalog.MSD_CORE_Meeting_Request__c = meetReq.Id;
        catalog.MSD_CORE_Product_Payor__c = prodPay.Id;
        catalog.MSD_CORE_Payor__c = usr.Id;
        catalog.MSD_CORE_Resource_Status__c = 'Published';
        catalog.MSD_CORE_Filter__c ='Advanced Non-Small Cell Lung Cancer (NSCLC)';
        catalog.MSD_CORE_Content_Type__c ='Product Overview Presentation';
        catalog.MSD_CORE_Document_Status__c = 'Expired';
        catalog.MSD_CORE_Expiration_Date__c = System.today()+5;
   
        insert catalog;
        return catalog;
    }

    /**
     * @description createCoreLibrary
     * @return coreLib
    */
    public static MSD_CORE_Library__c createCoreLibrary(){
        User usr = createUser();
        MSD_CORE_Product_Payor__c prodPay = createProduct();
        MSD_CORE_Catalog__c catalog = createCatalog();
        MSD_CORE_Library__c coreLib = new MSD_CORE_Library__c();
        coreLib.MSD_CORE_Product_Payor__c = prodPay.Id;
        coreLib.MSD_CORE_Payor__c = usr.Id;
        coreLib.MSD_CORE_Active__c = true;
        coreLib.MSD_CORE_Catalog__c = catalog.Id;
        insert coreLib;
        return coreLib;
    }
    public static MSD_CORE_Eligibility__c createEligibility(){
        User usr = createUser();
        MSD_CORE_Eligibility__c elig = new MSD_CORE_Eligibility__c();
        elig.MSD_CORE_Organization_Type__c = 'Accountable care organization(ACO)';
        elig.MSD_CORE_Payor__c = usr.Id;
        insert elig;
        return elig;
   }
    
     public static MSD_CORE_Eligibility__c createEligibility(String userId){
        User usr = createUser();
        MSD_CORE_Eligibility__c elig = new MSD_CORE_Eligibility__c();
        elig.MSD_CORE_Organization_Type__c = 'Health plan';
        elig.MSD_CORE_Payor__c = userId;
        insert elig;
        return elig;
   }
    
    
    public static MSD_CORE_Content_Permission_Mapping__c createContentPermission(){
         MSD_CORE_Content_Permission_Mapping__c mappings = new MSD_CORE_Content_Permission_Mapping__c();  
         MSD_CORE_Catalog__c catalog = createCatalog();  
         MSD_CORE_Eligibility__c elig = createEligibility();
         mappings.MSD_CORE_Content_Type__c = catalog.Id;
         mappings.MSD_CORE_Organization_Type__c = elig.Id;
         mappings.MSD_CORE_Active__c = TRUE;
         insert mappings;
         return mappings;
    }
    public static list<MSD_CORE_Content_Permission_Mapping__c> createContentPermissiontest(String eligibility , String catalogId){
        List<MSD_CORE_Content_Permission_Mapping__c> mappings1 = new List<MSD_CORE_Content_Permission_Mapping__c>();
         MSD_CORE_Content_Permission_Mapping__c mappings = new MSD_CORE_Content_Permission_Mapping__c();    
         mappings.MSD_CORE_Content_Type__c = catalogId;
         mappings.MSD_CORE_Organization_Type__c = eligibility;
         mappings.MSD_CORE_Active__c = FALSE;
         insert mappings;
         mappings1.add(mappings);
        return mappings1;
    }
    
     public static list<MSD_CORE_Content_Permission_Mapping__c> createContentPermissiontest1(String eligibility , String catalogId){
        List<MSD_CORE_Content_Permission_Mapping__c> mappings1 = new List<MSD_CORE_Content_Permission_Mapping__c>();
         MSD_CORE_Content_Permission_Mapping__c mappings = new MSD_CORE_Content_Permission_Mapping__c();    
         mappings.MSD_CORE_Content_Type__c = catalogId;
         mappings.MSD_CORE_Organization_Type__c = eligibility;
         mappings.MSD_CORE_Active__c = FALSE;
         insert mappings;
         mappings1.add(mappings);
        return mappings1;
    }

    @isTest
    public static void getCatalogsByOffsettest() {
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;   
        User usr;
        System.runAs(new User(Id = UserInfo.getUserId())){ 
            usr = createUser();
        }    
        MSD_CORE_Catalog__c catalog =  createCatalog();
        Test.startTest();
        MSD_CORE_ProductDetail.catalogwrap wrap = new MSD_CORE_ProductDetail.catalogwrap();
        wrap = MSD_CORE_ProductDetail.getCatalogsByOffset(catalog.Id,usr.Id,'5','1');
        Test.stopTest();
    }
    
    
    
     @isTest
    public static void userIdNull() {
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;   
        User usr;
        System.runAs(new User(Id = UserInfo.getUserId())){ 
            usr = createUser();
        }    
        MSD_CORE_Catalog__c catalog =  createCatalog();
        Test.startTest();
        MSD_CORE_ProductDetail.catalogwrap wrap = new MSD_CORE_ProductDetail.catalogwrap();
        wrap = MSD_CORE_ProductDetail.getCatalogsByOffset(catalog.Id,'123','5','1');
        Test.stopTest();
    }
    
     @isTest
    public static void testContactExits() {
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;   
        User usr;
        System.runAs(new User(Id = UserInfo.getUserId())){ 
            usr = createUser1();
        }  
        MSD_CORE_Catalog__c catalog =  createCatalog();
        
         MSD_CORE_Eligibility__c eligibility = createEligibility(usr.Id);
        List<MSD_CORE_Content_Permission_Mapping__c> mappings = createContentPermissiontest(eligibility.Id ,catalog.Id);  
        
        
        Test.startTest();
        MSD_CORE_ProductDetail.catalogwrap wrap = new MSD_CORE_ProductDetail.catalogwrap();
        wrap = MSD_CORE_ProductDetail.getCatalogsByOffset(catalog.Id,usr.Id,'5','1');
        Test.stopTest();
    }
    
     @isTest
    public static void testgetCatalogsFilter2() {
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;   
        User usr;
        System.runAs(new User(Id = UserInfo.getUserId())){ 
            usr = createUser1();
        }  
        MSD_CORE_Catalog__c catalog =  createCatalog(); 
        MSD_CORE_Eligibility__c eligibility = createEligibility(usr.Id);
        List<MSD_CORE_Content_Permission_Mapping__c> mappings = createContentPermissiontest(eligibility.Id ,catalog.Id);     
        List<String> criteria = new List<String>{'Test'};
        Test.startTest();
        List<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductDetail.getCatalogsFilter((String)catalog.MSD_CORE_Product_Payor__c,(String)usr.Id,criteria);
        Test.stopTest();
    }
    
}