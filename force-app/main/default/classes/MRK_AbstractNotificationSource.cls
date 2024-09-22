/*
 BMP - 7/31/13
 abstract class for notification source providers.  defines requires methods for
 provided subclasses to implement
*/
global abstract class MRK_AbstractNotificationSource {
	global abstract void init();
	//global abstract List<Map<String,String>> getNotifications();
	global abstract List<Map<String,Object>> getNotifications(String userid);
}