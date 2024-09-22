/*
 BMP - 7/31/13
 concrete class for fetching communication notifications
*/
global class MRK_CommunicationNotificationSource extends MRK_AbstractNotificationSource {

	global MRK_CommunicationNotificationSource() {
		// no arg constructor required for dynamic instantiation via the provider pattern
		// e.g. Type.forName("MRK_CommunicationNotificationSource").newInstance()
	}
    
	global override void init() {
	}

	global override List<Map<String,Object>> getNotifications(String userid) {

		List<Map<String,Object>> notifications = new List<Map<String,Object>>();

		if ( MRK_Setting.getBoolean(MRK_NotificationCenterService.SETTING_NAME, 'show sample communication notifications') ) {
			List<Object> sampleNotifications = MRK_Setting.getObjectList(MRK_NotificationCenterService.SETTING_NAME, 'sample communication notifications');
			for (Object n : sampleNotifications) {
				notifications.add((Map<String,Object>)n);
			}
		} else {
			notifications.addAll( MRK_CommunicationServices.getNotifications(userid) );
		}

		return notifications;
	}


}