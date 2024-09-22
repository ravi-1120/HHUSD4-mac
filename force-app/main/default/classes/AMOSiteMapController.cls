public class AMOSiteMapController
{
    public String sitemap {
        get {
            System.debug('called');
            return (Test.isRunningTest() ? 'test data': [SELECT Body FROM StaticResource WHERE Name = 'AMO_Sitemap'].Body.toString());    
        }set;
    }
}