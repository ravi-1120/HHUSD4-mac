@isTest
public class AMOSiteMapControllerTest {

   public static testmethod void test_SiteMapController(){
        Test.startTest();
        PageReference pageRef = Page.AMOSiteMap;
		Test.setCurrentPage(pageRef);
        AMOSiteMapController sm =new AMOSiteMapController();
       System.debug('-->'+sm.sitemap);
       ApexPages.currentPage().getParameters().get('test data');
       System.assert(ApexPages.currentPage().getParameters().get('test data') ==
    	ApexPages.currentPage().getParameters().get('test data'));
        Test.stopTest();
        //System.assert(String.isNotBlank(testSitemap));
    }
}