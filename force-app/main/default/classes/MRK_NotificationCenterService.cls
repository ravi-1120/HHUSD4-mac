/*
 BMP - 8/1/13
 Notification Center Service
 	- targets end users
 	- UI is exposed as Home Page component
*/
@RestResource(urlMapping='/mrk/notification/*')
global class MRK_NotificationCenterService {
	
	public static final String SETTING_NAME = 'NOTIFICATION_CENTER';

	public MRK_NotificationCenterService() {
		
	}

	global static List<Map<String,Object>> getNotificationsByUserid(String userid) {

		List<Map<String,Object>> notificationList = new List<Map<String,Object>>();
		
		List<Object> providerClassNameList = (List<Object>)MRK_Setting.getObjectList(SETTING_NAME, 'notification source provider classes');

		for (Object providerClassName : providerClassNameList) {
			Type providerType = System.Type.forName((String)providerClassName);
			if (providerType != null) {
				try {
					MRK_AbstractNotificationSource source = (MRK_AbstractNotificationSource)providerType.newInstance();
					notificationList.addAll( source.getNotifications(userid) );
				} catch (System.TypeException e) {
					// TODO: manually create a single notification indicating that there was an error
					// if one data source fails, they all fail to make it clear to the user there's an
					// issue
				} catch (Exception e) {

				}

			}
		}

		return notificationList;
	}

	@HttpGet
	global static Map<String,String> getAllNotifications() {
		RestRequest req = RestContext.request;
    String userid = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
    Map<String, String> result = new Map<String,String>();
    String itemsAsJSON = JSON.serializePretty( getNotificationsByUserid(userid) );
    result.put('items', itemsAsJSON);
    result.put('settings', JSON.serializePretty( MRK_Setting.getValues(SETTING_NAME) ));
    result.put('timestamp', DateTime.now().format('dd/MM/yy hh:mm:ss a') );
    return result;
	}

  @HttpPut
  global static String doPut(Map<String, String> data) {
		RestRequest req = RestContext.request;
    String userid = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);  	
  	List<Object> activities = (List<Object>)JSON.deserializeUntyped( data.get('activities') );

  	List<Communication_Activity_MRK__c> caList = new List<Communication_Activity_MRK__c>();
  	for (Object obj : activities) {
  		Map<String,Object> a = (Map<String,Object>)obj;
  		Communication_Activity_MRK__c ac = new Communication_Activity_MRK__c(
  			External_ID_MRK__c = userid + ';' + (String)a.get('id'),
  			Communication_MRK__c=(String)a.get('id'),
  			Read_Status_MRK__c=(String)a.get('read'),
  			User_MRK__c=userid);

			caList.add(ac);  		
  	}

  	upsert caList External_ID_MRK__c;

    return '***' + data.get('activities') + '***';
  }

	public static /* testMethod */ void testGetNotificationsByUserid() {
		String userid = [select id from user where username like '%commuser%' limit 1].Id;
		List<Map<String,Object>> notifications = getNotificationsByUserid(userid);
		System.debug('notifications = ' + JSON.serializePretty( notifications ));
	}

}