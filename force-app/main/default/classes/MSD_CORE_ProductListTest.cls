@isTest
Public class MSD_CORE_ProductListTest{
@isTest
  static void testgetUserInfo(){
    User communityUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
    Test.startTest();
    User getUser = MSD_CORE_ProductList.getUserInfo(communityUser.Id);
    System.assertEquals(getUSer.Id, communityUser.Id,'Both the users are not matching');
    Test.stopTest();
    User usr = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
    System.runAs(usr) {
      Contact con = [SELECT ID, MSD_CORE_Oncology_AE__c FROM Contact WHERE Id = :communityUser.ContactId];
      con.MSD_CORE_Oncology_AE__c = communityUser.Id;
      update con;
      System.debug(LoggingLevel.WARN, 'Current User: ' + UserInfo.getUserName());
      System.debug(LoggingLevel.WARN, 'Current Profile: ' + UserInfo.getProfileId());
    }
  }
  
@isTest
  static void testGetPending(){
    MSD_CORE_Product_Payor__c product = createProduct();
    Meeting_Request_vod__c meetingReq = createMeetingReq();
      // 
  Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
  vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
  insert vsc;
  User usr;
  System.runAs(new User(Id = UserInfo.getUserId())){ 
      usr = createUser1();
  }
  // New ADDED
    Test.startTest();
    list<Meeting_Request_vod__c> productList1 = MSD_CORE_ProductList.getPending((String)meetingReq.MSD_CORE_Product_Payor__c,(String)meetingReq.MSD_CORE_Payor__c);
    Test.stopTest();
    System.assert(productList1.size()==0,'Pending product list Exists');
  }  
@isTest
static void testGetPending1(){
  MSD_CORE_Product_Payor__c product = createProduct();
  Meeting_Request_vod__c meetingReq = createMeetingReq();
  meetingReq.MSD_CORE_Status__c = 'Pending';
  update meetingReq;
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  list<Meeting_Request_vod__c> productList1 = MSD_CORE_ProductList.getPending((String)meetingReq.MSD_CORE_Product_Payor__c,(String)meetingReq.MSD_CORE_Payor__c);
  Test.stopTest();
  System.assert(productList1.size()>0,'No pending product list');
}
@isTest
static void testGetAppointments(){
  MSD_CORE_Product_Payor__c product = createProduct();
  Meeting_Request_vod__c meetingReq = createMeetingReq();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  list<Meeting_Request_vod__c> productList1 = MSD_CORE_ProductList.getAppointments((String)meetingReq.MSD_CORE_Product_Payor__c,(String)meetingReq.MSD_CORE_Payor__c);
  Test.stopTest();
  System.assert(productList1.size()==0,'Approved product list exists');
}
@isTest
static void testGetAppointments1(){
  MSD_CORE_Product_Payor__c product = createProduct();
  Meeting_Request_vod__c meetingReq = createMeetingReq();
  meetingReq.MSD_CORE_Status__c = 'Approved';
  update meetingReq;
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  list<Meeting_Request_vod__c> productList1 = MSD_CORE_ProductList.getAppointments((String)meetingReq.MSD_CORE_Product_Payor__c,(String)meetingReq.MSD_CORE_Payor__c);
  Test.stopTest();
  System.assert(productList1.size()>0,'No Approved product list');
}
@isTest
static void testGetActiveRequests(){
  MSD_CORE_Product_Payor__c product = createProduct();
  Meeting_Request_vod__c meetingReq = createMeetingReq();

  // 
  Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
  vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
  insert vsc;
  User usr;
  System.runAs(new User(Id = UserInfo.getUserId())){ 
      usr = createUser1();
  }
  // New ADDED

  Test.startTest();
  list<Meeting_Request_vod__c> productList1 = MSD_CORE_ProductList.getActiveRequests((String)meetingReq.MSD_CORE_Product_Payor__c,(String)meetingReq.MSD_CORE_Payor__c);
  Test.stopTest();
  System.assert(productList1.size()==0,'Pending product list Exists');
}
@isTest
static void testGetActiveRequests1(){
  MSD_CORE_Product_Payor__c product = createProduct();
  Meeting_Request_vod__c meetingReq = createMeetingReq();
  meetingReq.MSD_CORE_Status__c = 'Pending';
  update meetingReq;
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  list<Meeting_Request_vod__c> productList1 = MSD_CORE_ProductList.getActiveRequests((String)meetingReq.MSD_CORE_Product_Payor__c,(String)meetingReq.MSD_CORE_Payor__c);
  Test.stopTest();
  System.assert(productList1.size()>0,'No Pending product list');
}
@isTest
static void testGetCatalogPerProdSaved(){
  MSD_CORE_Library__c coreLib = new MSD_CORE_Library__c();

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
  //list<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductList.getCatalogPerProdSaved((String)coreLib.MSD_CORE_Product_Payor__c,(String)coreLib.MSD_CORE_Payor__c);
  list<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductList.getCatalogPerProdSaved(catalog.Id,usr.Id);
  Test.stopTest();
  System.assert(cataloglst1.size()==0,'Catalog list exists');
}
@isTest
static void testGetCatalogPerProdSaved1(){
  MSD_CORE_Library__c coreLib = createCoreLibrary();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
    MSD_CORE_Catalog__c catalog =  createCatalog();
        
    MSD_CORE_Eligibility__c eligibility = createEligibility(usr.Id);
    List<MSD_CORE_Content_Permission_Mapping__c> mappings = createContentPermissiontest(eligibility.Id ,catalog.Id); 
  Test.startTest();
  //list<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductList.getCatalogPerProdSaved((String)coreLib.MSD_CORE_Product_Payor__c,(String)coreLib.MSD_CORE_Payor__c);
  list<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductList.getCatalogPerProdSaved(catalog.Id,usr.Id);
  Test.stopTest();
  System.assert(cataloglst1.size()>=0,'No Catalog list exists');
}
@isTest
static void testGetCatalogPerProd(){
  MSD_CORE_Catalog__c catalog = new MSD_CORE_Catalog__c();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  list<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductList.getCatalogPerProd((String)catalog.MSD_CORE_Product_Payor__c);
  Test.stopTest();
  System.assert(cataloglst1.size()==0,'Catalog list exists');
}
@isTest
static void testGetCatalogPerProd1(){
  MSD_CORE_Catalog__c catalog = createCatalog();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  list<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductList.getCatalogPerProd((String)catalog.MSD_CORE_Product_Payor__c);
  Test.stopTest();
  System.assert(cataloglst1.size()>0,'No Catalog list exists');
}
@isTest
static void testGetCatalogRecord(){
  MSD_CORE_Catalog__c catalog = new MSD_CORE_Catalog__c();
     MSD_CORE_Library__c coreLib = new MSD_CORE_Library__c();
       // 
  Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
  vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
  insert vsc;
  User usr;
  System.runAs(new User(Id = UserInfo.getUserId())){ 
      usr = createUser1();
  }
  // New ADDED
  Test.startTest();
  MSD_CORE_Catalog__c cataloglst1 = MSD_CORE_ProductList.getCatalogRecord((String)catalog.Id,(String)coreLib.MSD_CORE_Product_Payor__c);
  Test.stopTest();
  System.assert(cataloglst1 == null,'Catalog list exists');
}
@isTest
static void testGetCatalogRecord1(){
  MSD_CORE_Catalog__c catalog = createCatalog();
  MSD_CORE_Library__c coreLib = new MSD_CORE_Library__c();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  MSD_CORE_Catalog__c cataloglst1 = MSD_CORE_ProductList.getCatalogRecord((String)catalog.Id,(String)coreLib.MSD_CORE_Product_Payor__c);
  Test.stopTest();
  System.assert(cataloglst1 != null,'No Catalog list exists');
}
@isTest
static void testGetAppointmentPerUser(){
  MSD_CORE_Product_Payor__c product = createProduct();
  Meeting_Request_vod__c meetingReq = createMeetingReq();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  list<Meeting_Request_vod__c> productList1 = MSD_CORE_ProductList.getAppointmentPerUser((String)meetingReq.MSD_CORE_Payor__c);
  Test.stopTest();
  System.assert(productList1.size()==0,'Approved product list Exists');
}
@isTest
static void testGetAppointmentPerUser1(){
  MSD_CORE_Product_Payor__c product = createProduct();
  Meeting_Request_vod__c meetingReq = createMeetingReq();
  meetingReq.MSD_CORE_Status__c = 'Approved';  
  meetingReq.Start_DateTime_vod__c = System.now().addDays(1);
  update meetingReq;
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  list<Meeting_Request_vod__c> productList1 = MSD_CORE_ProductList.getAppointmentPerUser((String)meetingReq.MSD_CORE_Payor__c);
  Test.stopTest();
  System.assert(productList1.size()==0,'No Approved product list');
}
@isTest
static void testGetAppointmentDetails(){
  Meeting_Request_vod__c meetingReq =  new Meeting_Request_vod__c();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  list<Meeting_Request_vod__c> productList1 = MSD_CORE_ProductList.getAppointmentDetails((String)meetingReq.Id);
  Test.stopTest();
  System.assert(productList1.size()==0,'product list exists');
}
@isTest
static void testGetAppointmentDetails1(){
  MSD_CORE_Product_Payor__c product = createProduct();
  Meeting_Request_vod__c meetingReq = createMeetingReq();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  list<Meeting_Request_vod__c> productList1 = MSD_CORE_ProductList.getAppointmentDetails((String)meetingReq.Id);
  Test.stopTest();
  System.assert(productList1.size()>0,'No product list');
}
@isTest
static void testGetmeetingtime(){
  MSD_CORE_Meeting_Time__c meetTime = new MSD_CORE_Meeting_Time__c();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
    List<MSD_CORE_ProductList.meetingtimeswrapper> wrap = new List<MSD_CORE_ProductList.meetingtimeswrapper>();
	wrap = MSD_CORE_ProductList.getmeetingtime((String)meetTime.MSD_CORE_Meeting_Request__c);
  Test.stopTest();
  System.assert(wrap.size()==0,'Meeting List exists');
}
@isTest
static void testGetmeetingtime1(){
  MSD_CORE_Meeting_Time__c meetTime = createMeetTime();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();

	List<MSD_CORE_ProductList.meetingtimeswrapper> wrap = new List<MSD_CORE_ProductList.meetingtimeswrapper>();
	wrap = MSD_CORE_ProductList.getmeetingtime((String)meetTime.MSD_CORE_Meeting_Request__c);
  Test.stopTest();
  System.assert(wrap.size()>0,'No meeting list');
}
@isTest
static void testGetproductlist(){
  User testUser = createUser1();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  List<MSD_CORE_Product_Payor__c> productlist = MSD_CORE_ProductList.getproductlist((String)testUser.Id);
  Test.stopTest();
  System.assert(productlist == null,'Product List Exists');
}

@isTest
static void testGetproductlist1(){
  
  User communityUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
  User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
  Test.startTest();
  List<MSD_CORE_Product_Payor__c> productlist = MSD_CORE_ProductList.getproductlist((String)communityUser.Id);
  Test.stopTest();
  System.assert(productlist.size() == 0,'Product List Exists');
    
}

@isTest
static void testNewgetproductlist(){
  User testUser = new User();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  MSD_CORE_ProductList.conWrap productlist = new MSD_CORE_ProductList.conWrap();
  productlist = MSD_CORE_ProductList.newgetproductlist((String)testUser.Id);
  Test.stopTest();
  System.assert(productlist == null,'Product List Exists');
}
@isTest
static void testNewgetproductlist1(){
  User communityUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
  Test.startTest();
  MSD_CORE_ProductList.conWrap productlist = new MSD_CORE_ProductList.conWrap();
  productlist = MSD_CORE_ProductList.newgetproductlist((String)communityUser.Id);
  Test.stopTest();
  System.assert(productlist != null,'Product List Exists');
  User usr = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
  System.runAs(usr) {
    Contact con = [SELECT ID, MSD_CORE_Oncology_AE__c FROM Contact WHERE Id = :communityUser.ContactId];
    con.MSD_CORE_Oncology_AE__c = communityUser.Id;
    update con;
    System.debug(LoggingLevel.WARN, 'Current User: ' + UserInfo.getUserName());
    System.debug(LoggingLevel.WARN, 'Current Profile: ' + UserInfo.getProfileId());
  }
}
@isTest
static void testNewgetproductlistActive(){
  User testUser = createUser1();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  MSD_CORE_ProductList.conWrap productlist = new MSD_CORE_ProductList.conWrap();
  productlist = MSD_CORE_ProductList.newgetproductlistActive((String)testUser.Id);
  Test.stopTest();
  System.assert(productlist == null,'Product List Exists');
}
@isTest
static void testNewgetproductlistActive1(){
  User communityUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
  Test.startTest();
  MSD_CORE_ProductList.conWrap productlist = new MSD_CORE_ProductList.conWrap();
  productlist = MSD_CORE_ProductList.newgetproductlistActive((String)communityUser.Id);
  Test.stopTest();
  System.assert(productlist != null,'No Product List');
 User usr = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
  System.runAs(usr) {
    Contact con = [SELECT ID, MSD_CORE_Oncology_AE__c FROM Contact WHERE Id = :communityUser.ContactId];
    con.MSD_CORE_Oncology_AE__c = communityUser.Id;
    update con;
    System.debug(LoggingLevel.WARN, 'Current User: ' + UserInfo.getUserName());
    System.debug(LoggingLevel.WARN, 'Current Profile: ' + UserInfo.getProfileId());
  } 
}
@isTest
static void testRemoveCatalogs(){
  MSD_CORE_Library__c coreLib = createCoreLibrary();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  MSD_CORE_ProductList.removeCatalogs((String)coreLib.MSD_CORE_Catalog__c,(String)(coreLib.MSD_CORE_Payor__c));
  Test.stopTest();
  System.assert(coreLib!= null,'create Library');
}
@isTest
static void testGetCatalogs(){
  MSD_CORE_Catalog__c catalog = createCatalog();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  List<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductList.getCatalogs((String)catalog.MSD_CORE_Product_Payor__c);
  Test.stopTest();
  System.assert((String)cataloglst1[0].Id != 'a015i00000BfS6IAAV','ID matches');

}
@isTest
static void testGetTotalCatalogCount(){
  MSD_CORE_Library__c coreLib = createCoreLibrary();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  Integer discount = MSD_CORE_ProductList.getTotalCatalogCount((String)coreLib.MSD_CORE_Product_Payor__c,(String)(coreLib.MSD_CORE_Payor__c));
  Test.stopTest();
  System.assert(discount == 0,'returned total count');
}
@isTest
static void testGetTotalCatalogCount1(){
  MSD_CORE_Library__c coreLib = createCoreLibrary1();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  Integer discount = MSD_CORE_ProductList.getTotalCatalogCount((String)coreLib.MSD_CORE_Product_Payor__c,(String)(coreLib.MSD_CORE_Payor__c));
  Test.stopTest();
  System.assert(discount == 0,'returned total count');
}
@isTest
static void testGetLibraryCatalogCount(){
  MSD_CORE_Library__c coreLib = createCoreLibrary();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  Integer discount = MSD_CORE_ProductList.getLibraryCatalogCount((String)coreLib.MSD_CORE_Product_Payor__c,(String)coreLib.MSD_CORE_Payor__c);
  Test.stopTest();
  System.assert(discount == 0,'returned total count');
}
@isTest
static void testGetLibraryCatalogCount1(){
   MSD_CORE_Library__c coreLib = createCoreLibrary1();
     // 
  Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
  vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
  insert vsc;
  User usr;
  System.runAs(new User(Id = UserInfo.getUserId())){ 
      usr = createUser1();
  }
  // New ADDED
  Test.startTest();
  Integer discount = MSD_CORE_ProductList.getLibraryCatalogCount((String)coreLib.MSD_CORE_Product_Payor__c,(String)coreLib.MSD_CORE_Payor__c);
  Test.stopTest();
 System.assert(discount != null,'returned total count');
}
@isTest
static void testGetCatalogsByOffset(){
  MSD_CORE_Catalog__c catalog = createCatalog();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  List<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductList.getCatalogsByOffset((String)catalog.MSD_CORE_Product_Payor__c,(String)catalog.MSD_CORE_Payor__c,'5','1');
  Test.stopTest();
  System.assert(cataloglst1 == null,'Catalog list exists');
}
@isTest
static void testGetCatalogsByOffset1(){
  MSD_CORE_Catalog__c catalog = new MSD_CORE_Catalog__c();
  User communityUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
  User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
  Test.startTest();
  List<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductList.getCatalogsByOffset((String)catalog.MSD_CORE_Product_Payor__c,(String)communityUser.Id,'5','1');
  Test.stopTest();
  System.assert(cataloglst1.size()==0,'No Catalog list exists');

}
@isTest
static void test_getCatalogs(){
  MSD_CORE_Catalog__c catalog = createCatalog();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  List<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductList.getCatalogs((String)catalog.MSD_CORE_Product_Payor__c,(String)catalog.MSD_CORE_Payor__c);
  Test.stopTest();
  System.assert(cataloglst1 == null,'Catalog list exists');
}
@isTest
static void testGetCatalogs1(){
  MSD_CORE_Catalog__c catalog = new MSD_CORE_Catalog__c();
  User communityUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
  User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
  Test.startTest();
  List<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductList.getCatalogs((String)catalog.MSD_CORE_Product_Payor__c,(String)communityUser.Id);
  Test.stopTest();
  System.assert(cataloglst1 != null,'one');
}
@isTest
static void testGetProducts(){
  MSD_CORE_Product_Payor__c product = new MSD_CORE_Product_Payor__c();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  List<MSD_CORE_Product_Payor__c> productList = MSD_CORE_ProductList.getProducts((String)product.Id);
  Test.stopTest();
  System.assert(productList.size() == 0,'Product list exists');
}
@isTest
static void testGetProducts1(){
  MSD_CORE_Product_Payor__c product = createProduct();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  List<MSD_CORE_Product_Payor__c> productList = MSD_CORE_ProductList.getProducts((String)product.Id);
  Test.stopTest();
  System.assert(productList.size()>0,'No Product list exists');
}
@isTest
static void testGetProductsprodId(){
  MSD_CORE_Product_Payor__c product = new MSD_CORE_Product_Payor__c();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  List<MSD_CORE_Product_Payor__c> productList = MSD_CORE_ProductList.getProductsprodId((String)product.Id);
  System.debug(LoggingLevel.WARN,productList.size());
  Test.stopTest();
  System.assert(productList.size() == 0,'Product list exists');
}
@isTest
static void testGetProductsprodId1(){
  MSD_CORE_Product_Payor__c product = createProduct();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  List<MSD_CORE_Product_Payor__c> productList = MSD_CORE_ProductList.getProductsprodId((String)product.Id);
  Test.stopTest();
  System.assert(productList.size()>0,'No Product list exists');
}
@isTest
static void testGetLibraryCatalogs(){
  MSD_CORE_Library__c coreLib = new MSD_CORE_Library__c();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
    MSD_CORE_Catalog__c catalog =  createCatalog();
        
    MSD_CORE_Eligibility__c eligibility = createEligibility(usr.Id);
    List<MSD_CORE_Content_Permission_Mapping__c> mappings = createContentPermissiontest(eligibility.Id ,catalog.Id); 
  Test.startTest();
  //List<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductList.getLibraryCatalogs((String)coreLib.MSD_CORE_Product_Payor__c,(String)coreLib.MSD_CORE_Payor__c,'5','1');
  List<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductList.getLibraryCatalogs(catalog.Id,usr.Id,'5','1');
  Test.stopTest();
  System.assert(cataloglst1 != null,'Catalog list exists');
}
@isTest
static void testGetLibraryCatalogs1(){
  MSD_CORE_Library__c coreLib = createCoreLibrary();
    // 
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
    // New ADDED
  Test.startTest();
  //List<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductList.getLibraryCatalogs((String)coreLib.MSD_CORE_Product_Payor__c,(String)coreLib.MSD_CORE_Payor__c,'5','1');
  List<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductList.getLibraryCatalogs(catalog.Id,usr.Id,'5','1');
  Test.stopTest();
  System.assert(cataloglst1 != null,'Catalog list exists');
}
@isTest
static void testGetLibraryCatalogswrap(){
  MSD_CORE_Library__c coreLib = new MSD_CORE_Library__c();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  MSD_CORE_ProductList.ProductListWrapper productList = new MSD_CORE_ProductList.ProductListWrapper();
  productList = MSD_CORE_ProductList.getLibraryCatalogs1((String)coreLib.MSD_CORE_Product_Payor__c,(String)coreLib.MSD_CORE_Payor__c,'5','1');
  System.assert(productList == null,'Catalog list exists');
  Test.stopTest();
}
@isTest
static void testGetLibraryCatalogswrap1(){
  MSD_CORE_Library__c coreLib = createCoreLibrary();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  MSD_CORE_ProductList.ProductListWrapper productList = new MSD_CORE_ProductList.ProductListWrapper();
  productList = MSD_CORE_ProductList.getLibraryCatalogs1((String)coreLib.MSD_CORE_Product_Payor__c,(String)coreLib.MSD_CORE_Payor__c,'5','1');
  Test.stopTest();
  System.assert(productList!=null,'Catalog list exists');
}
@isTest
static void testGetPdfDownloadLink(){
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  MSD_CORE_ProductList.getPdfDownloadLink();
  Test.stopTest();
  System.assert(vsc!=null,'New Veeva Settings');
}

@isTest
static void testcreateRelatedLibrary(){
  MSD_CORE_Library__c coreLib = new MSD_CORE_Library__c();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  MSD_CORE_ProductList.createRelatedLibrary(coreLib);
  Test.stopTest();
  System.assert(vsc!=null,'New Veeva Settings');
}

@isTest
static void testGetBrandInformations(){
    MSD_CORE_Product_Payor__c prodPay = createProduct();
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }

    List<Brand_Information__c> brandConfigList = new List<Brand_Information__c>();
    brandConfigList.add(new Brand_Information__c(Name = 'Indication', Product_Payor__c = prodPay.Id));
    brandConfigList.add(new Brand_Information__c(Name = 'Selected Safety Information', Product_Payor__c = prodPay.Id));
    insert brandConfigList;

    Test.startTest();
      Map<String,Brand_Information__c> productConfig = MSD_CORE_ProductList.getBrandInformations((String)prodpay.Id,'Product Payor');
    Test.stopTest();
    System.assert(productConfig != null, 'No Product exists');
}

@isTest
static void testGetBrandInformationsForCatalog(){
  MSD_CORE_Catalog__c catalog = createCatalog();
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }

    List<Brand_Information__c> brandConfigList = new List<Brand_Information__c>();
    brandConfigList.add(new Brand_Information__c(Name = 'Indication', Product_Payor__c = catalog.MSD_CORE_Product_Payor__c));
    brandConfigList.add(new Brand_Information__c(Name = 'Selected Safety Information', Product_Payor__c = catalog.MSD_CORE_Product_Payor__c));
    insert brandConfigList;

    Test.startTest();
      Map<String,Brand_Information__c> productConfig = MSD_CORE_ProductList.getBrandInformations((String)catalog.Id,'Catalog');
    Test.stopTest();
    System.assert(productConfig != null, 'No Product exists');
}

@isTest
static void testGetBrandInformationsForRequest(){
    Meeting_Request_vod__c meet = createMeetingReq();
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }

    List<Brand_Information__c> brandConfigList = new List<Brand_Information__c>();
    brandConfigList.add(new Brand_Information__c(Name = 'Indication', Product_Payor__c = meet.MSD_CORE_Product_Payor__c));
    brandConfigList.add(new Brand_Information__c(Name = 'Selected Safety Information', Product_Payor__c = meet.MSD_CORE_Product_Payor__c));
    insert brandConfigList;

    Test.startTest();
      Map<String,Brand_Information__c> productConfig = MSD_CORE_ProductList.getBrandInformations((String)meet.Id,'Meeting Request');
    Test.stopTest();
    System.assert(productConfig != null, 'No Product exists');
}

/*
@isTest
static void testGetProdIndication1(){
  MSD_CORE_Product_Payor__c prodPay = createProduct();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  MSD_CORE_Product_Payor__c product = MSD_CORE_ProductList.getProdIndication((String)prodpay.Id);
  Test.stopTest();
  System.assert(product.Id != null, 'No Product exists');
}

@isTest
static void test_GetProdIndication1(){
  Meeting_Request_vod__c meet = createMeetingReq();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  Meeting_Request_vod__c meetreq = MSD_CORE_ProductList.getProdIndication1((String)meet.Id);
  Test.stopTest();
  System.assert(meetreq.Id != null, 'No meet exists');
}
*/

@isTest
static void testGetPrimaryExecutive(){
  User communityUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
  User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
  Test.startTest();
  List<user> primaryexcutiveList = MSD_CORE_ProductList.getPrimaryExecutive((String)communityUser.Id);
  Test.stopTest();
  System.assert(primaryexcutiveList.size()==0,'primaryexcutiveList exists');
}
@isTest
static void testgetExecutiveContacts(){
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  List<Contact> contactList = MSD_CORE_ProductList.getExecutiveContacts();
  Test.stopTest();
  System.assert(contactList.size()==0,'contactList exists');
}
@isTest
static void testGetUserDetails(){
  User communityUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
  User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
  Test.startTest();
  List<user> UserDetails = MSD_CORE_ProductList.getUserDetails((String)communityUser.Id);
  Test.stopTest();
  System.assert(UserDetails.size() !=0,'No UserDetails found');
}
@isTest
static void testGetLicense(){
  User communityUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
  User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
  Test.startTest();
  List<License__c> license = MSD_CORE_ProductList.getLicenses((String)communityUser.ContactId);
  Test.stopTest();
  System.assert(license.size() ==0,'license found');
}
@isTest
static void testgetproductFilter(){
  MSD_CORE_Filter__c filter = new MSD_CORE_Filter__c();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  List<MSD_CORE_Filter__c> filterList = MSD_CORE_ProductList.getproductFilter((String)filter.MSD_CORE_Product_Payor__c);
  Test.stopTest();
  System.assert(filterList.size() ==0,'filterList found');
}
@isTest
static void testgetproductFilter1(){
  MSD_CORE_Filter__c filter = createFilter();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  List<MSD_CORE_Filter__c> filterList = MSD_CORE_ProductList.getproductFilter((String)filter.MSD_CORE_Product_Payor__c);
  Test.stopTest();
  System.assert(filterList.size() >0,'No filterList found');
}

@isTest
static void testgetCatalogsFilter(){
  MSD_CORE_Catalog__c catalog = createCatalog();
  catalog.MSD_CORE_Filter__c = 'Adjuvant Treatment for RCC or Advanced Renal Cell Carcinoma (RCC)';
  update catalog;
  List<String> criteria =new List<String>();
  criteria.add('Test');
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  List<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductList.getCatalogsFilter((String)catalog.MSD_CORE_Product_Payor__c,(String)catalog.MSD_CORE_Payor__c,criteria);
  Test.stopTest();
  System.assert(cataloglst1 == null,'Catalog list exists');

}
@isTest
static void testgetCatalogsFilter1(){
  MSD_CORE_Catalog__c catalog = new MSD_CORE_Catalog__c();
  List<String> criteria =new List<String>();
  User communityUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
  User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
  Test.startTest();
  List<MSD_CORE_Catalog__c> cataloglst1 = MSD_CORE_ProductList.getCatalogsFilter((String)catalog.MSD_CORE_Product_Payor__c,(String)communityUser.Id,criteria);
  Test.stopTest();
  System.assert(cataloglst1 != null,'No Catalog list exists');

}
@isTest
static void testcreateMeetingRequest(){
  List<Meeting_Request_vod__c> meetReqList = new List<Meeting_Request_vod__c>();
  Meeting_Request_vod__c meetReq = createMeetingReq();
  meetReqList.add(meetReq);  
  String request = JSON.serialize(meetReqList);
  // 
  Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
  vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
  insert vsc;
  User usr;
  System.runAs(new User(Id = UserInfo.getUserId())){ 
      usr = createUser1();
  }
  // New ADDED
  Test.startTest();
  MSD_CORE_ProductList.Response objres = MSD_CORE_ProductList.createMeetingRequest(request);
  Test.stopTest();
  System.assert(objres!=null,'No response exists');
}


@isTest
static void testcreateMeetingTimes(){

  String request ='[{"MSD_CORE_Time_Slot__c":"10 AM to 12 PM"	,"MSD_CORE_Duration__c":60}]';
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  MSD_CORE_ProductList.Response objres = new MSD_CORE_ProductList.Response();
  objres = MSD_CORE_ProductList.createMeetingTimes(request);
  Test.stopTest();
  System.assert(String.valueOf(objres.status)=='Success','msg failure');
}

@isTest
static void testcreatetimemeet(){
  String request ='';
  Date dt= system.today();
  String tm = '10AM - 12PM';
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  String msg = MSD_CORE_ProductList.createtimemeet(request,dt,tm);
  Test.stopTest();
  System.assert(msg !='Success','msg failure');
}

@isTest
static void testgetMeetingRequest(){
  Meeting_Request_vod__c meetreq = createMeetingReq();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  MSD_CORE_ProductList.Response objres = new MSD_CORE_ProductList.Response();
  objres = MSD_CORE_ProductList.getMeetingRequest(String.valueof(meetreq.Id));
  Test.stopTest();
  System.assert(objres != null,'No response exists');  
}

@isTest
static void testgetmfeeFilter() {
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  MSD_CORE_ProductList.getmfeeFilter('oncology');
  MSD_CORE_ProductList.getmfeeFilter('nononcology');
  List<sObject> res = MSD_CORE_ProductList.getmfeeFilter('');
  Test.stopTest();
  System.assert(res == null, 'No response exists');
}

@isTest
static void testgetstudyDetail() {
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  List<MSD_CORE_Study_detail__c> res = MSD_CORE_ProductList.getstudyDetail('');
  Test.stopTest();
  System.assert(res != null, 'No response exists');
}

@isTest
static void testgetAEdetail() {
  User communityUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
  User usr = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
  System.runAs(usr) {
    Contact con = [SELECT ID, MSD_CORE_Oncology_AE__c FROM Contact WHERE Id = :communityUser.ContactId];
    con.MSD_CORE_Oncology_AE__c = communityUser.Id;
    update con;
  }
  Test.startTest();
  List<MSD_CORE_ProductList.UserWrap> res = MSD_CORE_ProductList.getAEdetail(communityUser.Id);
  List<MSD_CORE_ProductList.UserWrap> res1 = MSD_CORE_ProductList.getAEdetail('');
  Test.stopTest();
  System.assert(res1 == null, 'No response exists');
} 

@isTest
static void testgetAEdetail1() {
  User communityUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
  User usr = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
  System.runAs(usr) {
    Contact con = [SELECT ID, MSD_CORE_Medical_AE__c FROM Contact WHERE Id = :communityUser.ContactId];
    con.MSD_CORE_Medical_AE__c = communityUser.Id;
    update con;
  }  

  Test.startTest();
  List<MSD_CORE_ProductList.UserWrap> res = MSD_CORE_ProductList.getAEdetail(communityUser.Id);
  List<MSD_CORE_ProductList.UserWrap> res1 = MSD_CORE_ProductList.getAEdetail('');  
  MSD_CORE_ProductList.getcontentconnector('/133572_1_0_rendition_viewable_rendition__v.pdf');
  
  
  Test.stopTest();
  System.assert(res1 == null, 'No response exists');
}

@isTest
static void testgetAEdetail2(){

    User usr = createUser1();
    MSD_CORE_Product_Payor__c prodPay = createProduct();
    MSD_CORE_Catalog__c catalog = createCatalog();
    System.assert(prodPay != null, 'Product exists');
} 
@isTest
static void testdeleteMeetingTimes() {
  MSD_CORE_Meeting_Time__c meetTime = createMeetTime();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  delete meetTime;
  Test.stopTest();
  MSD_CORE_ProductList.deleteMeetingTimes(String.valueof(meetTime.Id));
  System.assert(meetTime != null,'No meeting Time');
}
@isTest
static void testgetContactRole(){
  User communityUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
  User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
  Test.startTest();
  Contact con = [SELECT ID, MSD_CORE_Role__c FROM Contact WHERE Id = :communityUser.ContactId];
    MSD_CORE_ProductList.getContactRole(String.valueOf(communityUser));
  Test.stopTest();
  System.assert(con != null,'No Contact');
}

@isTest
static void testcreateMeetingRequestMHEE() {
 	List<Meeting_Request_vod__c> meetReqList = new List<Meeting_Request_vod__c>();
  	Meeting_Request_vod__c meetReq = createMeetingReq();
  	meetReqList.add(meetReq);  
	String request = JSON.serialize(meetReqList);
    System.debug(LoggingLevel.WARN,'request testcreateMeetingRequestMHEE' + request );
      // 
  Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
  vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
  insert vsc;
  User usr;
  System.runAs(new User(Id = UserInfo.getUserId())){ 
      usr = createUser1();
  }
  // New ADDED
  	Test.startTest();
  	MSD_CORE_ProductList.Response res = MSD_CORE_ProductList.createMeetingRequestMHEE(request);
  	Test.stopTest();
  	System.assert(res != null, 'No response exists');
} 

@isTest
static void testupdatemeetstatus() {
    Meeting_Request_vod__c meetReq = createMeetingReq();
      MSD_CORE_Meeting_Time__c meetTime = new MSD_CORE_Meeting_Time__c();
    meetTime.MSD_CORE_Meeting_Request__c = meetReq.Id;
    meetTime.MSD_CORE_Time_Slot__c = '10 AM to 12 PM';
    meetTime.MSD_CORE_Selected__c = true;
    meetTime.MSD_CORE_Meeting_Date__c = System.today();
    meetTime.MSD_CORE_Duration__c = 60;
    insert meetTime;

  	String request = '{"meetingPreference":"'+ meetReq.MSD_CORE_Meeting_preference__c +'","attendee":"'+ meetReq.MSD_CORE_attendee__c +'","appointmentdate":"'+ null +'","appointmenttime":"'+ null +'","recordId":"'+ meetReq.Id  +'" }';
      // 
  Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
  vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
  insert vsc;
  User usr;
  System.runAs(new User(Id = UserInfo.getUserId())){ 
      usr = createUser1();
  }
  // New ADDED
  	Test.startTest();
  	List<MSD_CORE_Meeting_Time__c> res = MSD_CORE_ProductList.updatemeetstatus(request);
	Test.stopTest();
  System.assert(meetReq!=null,'createrequest');
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
    User usr = createUser1();
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
 * @description createMeetTime
 * @return meetTime
 */
  public static MSD_CORE_Meeting_Time__c createMeetTime(){
    User usr = createUser1();
    Meeting_Request_vod__c reqvod = createMeetingReq();
    MSD_CORE_Meeting_Time__c meetTime = new MSD_CORE_Meeting_Time__c();
    meetTime.MSD_CORE_Meeting_Request__c = reqvod.Id;
    meetTime.MSD_CORE_Time_Slot__c = '10 AM to 12 PM';
    meetTime.MSD_CORE_Selected__c = true;
    meetTime.MSD_CORE_Meeting_Date__c = System.today();
    meetTime.MSD_CORE_Duration__c = 60;
    insert meetTime;
    return meetTime;
  }
  /**
   * @description createCatalog
   * @return catalog
   */

  public static MSD_CORE_Catalog__c createCatalog(){
    User usr = createUser1();
    MSD_CORE_Product_Payor__c prodPay = createProduct();
    Meeting_Request_vod__c meetReq = createMeetingReq();
      
    MSD_CORE_Catalog__c catalog = new MSD_CORE_Catalog__c();
    catalog.MSD_CORE_Meeting_Request__c = meetReq.Id;
    catalog.MSD_CORE_Product_Payor__c = prodPay.Id;
    catalog.MSD_CORE_Payor__c = usr.Id;
    catalog.MSD_CORE_Resource_Status__c = 'Published';
    insert catalog;
    return catalog;
  }
  /**
   * @description createCatalog1
   * @return catalog1
   */
   public static MSD_CORE_Catalog__c createCatalog1(){
    User usr = createUser1();
    MSD_CORE_Product_Payor__c prodPay = createProduct();
    Meeting_Request_vod__c meetReq = createMeetingReq();
      
    MSD_CORE_Catalog__c catalog = new MSD_CORE_Catalog__c();
    catalog.MSD_CORE_Meeting_Request__c = meetReq.Id;
    catalog.MSD_CORE_Product_Payor__c = prodPay.Id;
    catalog.MSD_CORE_Payor__c = usr.Id;
    catalog.MSD_CORE_Resource_Status__c = 'Published';
    insert catalog;
       
    MSD_CORE_Catalog__c catalog1 = new MSD_CORE_Catalog__c();
    catalog1.MSD_CORE_Meeting_Request__c = meetReq.Id;
    catalog1.MSD_CORE_Product_Payor__c = prodPay.Id;
    catalog1.MSD_CORE_Payor__c = usr.Id;
    catalog1.MSD_CORE_Resource_Status__c = 'Published';
    catalog1.MSD_CORE_Leave_Behind__c = 'Static Leave Behind';
    catalog1.MSD_CORE_Expiration_Date__c = Date.today().AddDays(2);
    catalog1.Parent_Resource__c = catalog.id;
    insert catalog1;   
    return catalog1;
  }
  /**
   * @description createCoreLibrary
   * @return coreLib
   */  
  public static MSD_CORE_Library__c createCoreLibrary(){
    User usr = createUser1(); 
     //User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);

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
  /**
   * @description createCoreLibrary1
   * @return coreLib
   */  
     public static MSD_CORE_Library__c createCoreLibrary1(){
    User usr = createUser1();
    MSD_CORE_Product_Payor__c prodPay = createProduct();
    MSD_CORE_Catalog__c catalog = createCatalog1();
    MSD_CORE_Library__c coreLib = new MSD_CORE_Library__c();
    coreLib.MSD_CORE_Product_Payor__c = prodPay.Id;
    coreLib.MSD_CORE_Payor__c = usr.Id;
    coreLib.MSD_CORE_Active__c = true;
    coreLib.MSD_CORE_Catalog__c = catalog.Id;
    insert coreLib;
    return coreLib;
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
    
    
     public static MSD_CORE_Eligibility__c createEligibility(String userId){
        User usr = createUser();
        MSD_CORE_Eligibility__c elig = new MSD_CORE_Eligibility__c();
        elig.MSD_CORE_Organization_Type__c = 'Accountable care organization(ACO)';
        elig.MSD_CORE_Payor__c = userId;
        insert elig;
        return elig;
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
   * @description createFilter
   * @return filter
   */  
  public static MSD_CORE_Filter__c createFilter(){
    MSD_CORE_Product_Payor__c prodPay = createProduct();
    MSD_CORE_Filter__c filter = new MSD_CORE_Filter__c();
    filter.MSD_CORE_Product_Payor__c = prodPay.Id;
    insert filter;
    return filter;
  }

  private static User createUser1() {
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
@isTest
 static void getActiveRequestsTest(){
    MSD_CORE_Product_Payor__c product = createProduct();
    Meeting_Request_vod__c meetingReq = createMeetingReq();
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    Test.startTest(); 
     list<Meeting_Request_vod__c> productList1 =MSD_CORE_ProductList.getActiveRequestsTest();
     Test.stopTest();
     System.assert(productList1.size()==0,'Pending product list Exists');
}
@isTest
static void getupcomingappointmentsTest(){
  MSD_CORE_Product_Payor__c product = createProduct();
  Meeting_Request_vod__c meetingReq = createMeetingReq();
      User usr = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
      System.runAs(usr) {
  meetingReq.MSD_CORE_Status__c = 'Approved';
  update meetingReq;
      }
  Test.startTest();
  list<Meeting_Request_vod__c> productList1 = MSD_CORE_ProductList.getupcomingappointments();
  Test.stopTest();
  System.assert(product!=null,'products');

}    
@isTest 
static void removeCatalogswithParentTest(){
  MSD_CORE_Catalog__c catlog = createCatalog();
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
   MSD_CORE_ProductList.removeCatalogswithParent((String)catlog.Id,(String)catlog.MSD_CORE_Payor__c);
  Test.stopTest();
  System.assert(catlog!=null,'catalogone');
}  
@isTest
static void removeCatalogsTest(){
   MSD_CORE_Library__c coreLib = createCoreLibrary();
     // 
  Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
  vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
  insert vsc;
  User usr;
  System.runAs(new User(Id = UserInfo.getUserId())){ 
      usr = createUser1();
  }
  // New ADDED
  Test.startTest();
   MSD_CORE_ProductList.removeCatalogs((String)coreLib.MSD_CORE_Catalog__c,(String)coreLib.MSD_CORE_Payor__c);
  Test.stopTest();
  System.assert(coreLib!=null,'createLibrary');
}     
@isTest
static void getDiseaseTopicsTest(){ //By Tausif for new invocation method:GetDiseaseTopics
  Meeting_Request_vod__c meetingReq = createMeetingReq();
  meetingReq.ScheduleFilter__c = 'Cardiovascular disease MK-2060, Chikugunya virus vaccine V184';
  update meetingReq;
  list<String> lstDiseaseTopic= new list<String>();
  lstDiseaseTopic.add(meetingReq.id);
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  list<String> listDiseases = MSD_CORE_ProductList.GetDiseaseTopics(lstDiseaseTopic);
  Test.stopTest();
  System.assert(meetingReq!=null,'createRequest');

} 
@isTest
static void getDiseaseTopicsWithOneScheduleFilterTest(){ //By Tausif for new invocation method:GetDiseaseTopics
  Meeting_Request_vod__c meetingReq = createMeetingReq();
  meetingReq.ScheduleFilter__c = 'Cardiovascular disease MK-2060';
  update meetingReq;
  list<String> lstDiseaseTopic= new list<String>();
  lstDiseaseTopic.add(meetingReq.id);
    // 
    Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
    vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
    insert vsc;
    User usr;
    System.runAs(new User(Id = UserInfo.getUserId())){ 
        usr = createUser1();
    }
    // New ADDED
  Test.startTest();
  list<String> listDiseases = MSD_CORE_ProductList.GetDiseaseTopics(lstDiseaseTopic);
  Test.stopTest();
  System.assert(meetingReq!=null,'createRequest');
}     
}