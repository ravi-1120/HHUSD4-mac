/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_DataStewardshipNotificationSource.cls
* @description - Concrete class for fetching data stewardship notifications
* @createdate - July 8th, 2013
*
*/

global class MRK_DataStewardshipNotificationSource extends MRK_AbstractNotificationSource {

	global MRK_DataStewardshipNotificationSource() {
		// no arg constructor required for dynamic instantiation via the provider pattern
		// e.g. Type.forName("MRK_DataStewardshipNotificationSource").newInstance()
	}
    
	global override void init() {
	}

	global override List<Map<String,Object>> getNotifications(String userid) {
		List<Map<String,Object>> notifications = new List<Map<String,Object>>();

		if ( MRK_Setting.getBoolean(MRK_NotificationCenterService.SETTING_NAME, 'show sample data stewardship notifications') ) {

			List<Object> sampleNotifications = MRK_Setting.getObjectList(MRK_NotificationCenterService.SETTING_NAME, 'sample data stewardship notifications');
			for (Object n : sampleNotifications) {
				notifications.add((Map<String,Object>)n);
			}

		}
		
		return notifications;
	}


}