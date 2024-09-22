/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_StaticResourceUtil.cls
* @description - Static Resource Utility class
* @createdate - Oct 14th, 2013
*
*/

global class MRK_StaticResourceUtil {

	static List<StaticResource> staticResourceCache = null;

  //Pass the resource name
  public static String getResourceURL(String resourceName)
  {
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
    	return '';
    }
  }
}