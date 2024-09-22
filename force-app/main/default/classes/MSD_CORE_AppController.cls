public class MSD_CORE_AppController {

    private Map<string,String> pageParams = ApexPages.currentPage().getParameters();

    static List<StaticResource> staticResourceCache = null;

    public MSD_CORE_AppController() {

    }

    public Map<String,String> getCfg() {
        Map<string,String> defaults = new Map<String,String>{
            'standardStylesheets' => 'true',
            'showHeader' => 'true',
            'sidebar' => 'true',

            'src' => getIframeSrc(),
            'height' => '6500',
            'scrolling' => 'true'
        };

        defaults.putAll(pageParams);

        return defaults;
    }

    public String getDebugOutput() {
        return JSON.serializePretty(getIframeSrc());
    }

    public String getIframeSrc() {
        System.PageReference pageReference;

        Map<String,String> extraParams = new Map<String,String>();

        if (pageParams.get('__sessionId__') == null) {
            extraParams.put('__sessionId__', UserInfo.getSessionId());
        }

        if (pageParams.get('__hostname__') == null) {
            extraParams.put('__hostname__', ApexPages.currentPage().getHeaders().get('Host'));
        }

        extraParams.put('__frameproxyjs__', getResourceURL('frameproxy') + 'frameproxy.js');
        extraParams.put('__frameproxyhtml__', getResourceURL('frameproxy') + 'frameproxy.htm');

        String iframeSrc = pageParams.get('_iframesrc');
        if ( (iframeSrc != null) && iframeSrc.contains('staticresource:')) {
            iframeSrc = iframeSrc.replace('staticresource:', '');
            String resourceName = iframeSrc.substring(0, iframeSrc.indexOf('/'));
            String path = iframeSrc.substring(iframeSrc.indexOf('/'));
            iframeSrc = getResourceURL(resourceName) + path;
        }
        //String staticIndex = getResourceURL('angularjsbasetemplate') + '/index.html';
        //pageReference = new System.PageReference((iframeSrc != null) ? iframeSrc : '/apex/MRK_AppLoader');
        pageReference = new System.PageReference((iframeSrc != null) ? iframeSrc : '/apex/MRK_AppLoader');
        pageReference.getParameters().putAll(pageParams);
        pageReference.getParameters().putAll(extraParams);

        String hash = pageParams.get('hash');
        if (hash != null) {
            pageReference.setAnchor(hash);
        }

        return pageReference.getUrl();

    }

  //Pass the resource name
  public String getResourceURL(String resourceName)
  {
    staticResourceCache = [SELECT Name, NamespacePrefix, SystemModStamp FROM StaticResource WHERE Name = :resourceName];

    if ( (staticResourceCache == null) || (staticResourceCache.size() == 0) ) {
        return null;
    }

    StaticResource resource = staticResourceCache[0];
       //Getting namespace
       String namespace = resource.NamespacePrefix;
       //Resource URL
       return '/resource/' + resource.SystemModStamp.getTime() + '/' + (namespace != null && namespace != '' ? namespace + '__' : '') + resourceName;

    /*
    if (staticResourceCache == null) {
            staticResourceCache = [SELECT Name, NamespacePrefix, SystemModStamp FROM StaticResource WHERE Name = :resourceName];
    }

    StaticResource resource = null;
        for (StaticResource sr : staticResourceCache) {
            if (sr.Name == resourceName) {
                resource = sr;
            }
        }

    //Checking if the result is returned or not
    if(resource != null)
    {
       //Getting namespace
       String namespace = resource.NamespacePrefix;
       //Resource URL
       return '/resource/' + resource.SystemModStamp.getTime() + '/' + (namespace != null && namespace != '' ? namespace + '__' : '') + resourceName;
    } else {
        return 'fail';
    }
    */
  }


}