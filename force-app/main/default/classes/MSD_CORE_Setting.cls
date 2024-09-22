/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MSD_CORE_Setting.cls
* @description - MSD Setting
* @createdate - Apr 9th, 2015
*
*/
public class MSD_CORE_Setting {

	static Map<String,Map<String, Object>> settingsCacheMap = new Map<String,Map<String, Object>>();

    /**
     * Method Name  :   getValues
     * @param       :   name
     * @description :   Use to get the values
     * @return      :   settingsMap
     */

	public static Map<String, Object> getValues(String name) {

		Map<String, Object> settingsMap = settingsCacheMap.get(name);
		if (settingsMap == null) {
			MSD_CORE_Setting__c settings = [select Id, OwnerId, IsDeleted, Name, MSD_CORE_Description__c, MSD_CORE_Value__c from MSD_CORE_Setting__c where Name = :name and MSD_CORE_Active__c = true limit 1];
			settingsMap = (Map<String, Object>)JSON.deserializeUntyped(settings.MSD_CORE_Value__c);
			settingsCacheMap.put(name, settingsMap);
		}

		return settingsMap;
	}
    
      /**
     * Method Name  :   getString
     * @param       :   settingName
     * @param       :   keyPath
     * @description :   Use to get the strings
     * @return      :   settingsMap
     */

	public static String getString(String settingName, String keyPath) {
		return (String)getObject(settingName, keyPath);
	}

      /**
     * Method Name  :   getBoolean
     * @param       :   settingName
     * @param       :   keyPath
     * @description :   Use to get the strings
     * @return      :   settingsMap
     */
	public static Boolean getBoolean(String settingName, String keyPath) {
		return (Boolean)getObject(settingName, keyPath);
	}

      /**
     * Method Name  :   getInteger
     * @param       :   settingName
     * @param       :   keyPath
     * @description :   Use to get the integer
     * @return      :   settingsMap
     */
	public static Integer getInteger(String settingName, String keyPath) {
		return (Integer)getObject(settingName, keyPath);
	}

  /**
     * Method Name  :   getObjectList
     * @param       :   settingName
     * @param       :   keyPath
     * @description :   Use to get the objectList
     * @return      :   settingsMap
     */
	public static List<Object> getObjectList(String settingName, String keyPath) {
		return (List<Object>)getObject(settingName, keyPath);
	}

      /**
     * Method Name  :   getMapList
     * @param       :   settingName
     * @param       :   keyPath
     * @description :   Use to get the MapList
     * @return      :   settingsMap
     */
	public static List<Map<String, Object>> getMapList(String settingName, String keyPath) {
		return (List<Map<String, Object>>)getObject(settingName, keyPath);
	}

      /**
     * Method Name  :   getStringToStringMap
     * @param       :   settingName
     * @param       :   keyPath
     * @description :   Use to get the StringToStringMap
     * @return      :   m
     */
	public static Map<String,String> getStringToStringMap(String settingName, String keyPath) {
	    Map<String,String> m = new Map<String,String>();
	    Map<String,Object> objMap = (Map<String,Object>)getObject(settingName, keyPath);
	    for (String key : objMap.keySet()) {
	        m.put(key, (String)objMap.get(key));
	    }
	    return m;
	}

     /**
     * Method Name  :   getObject
     * @param       :   settingName
     * @param       :   keyPath
     * @description :   Use to get the Object
     * @return      :   settingsMap
     */
	public static Object getObject(String settingName, String keyPath) {
		return getObjectAtPath( getValues(settingName), keyPath );
	}

     /**
     * Method Name  :   getObjectAtPath
     * @param       :   obj
     * @param       :   keyPath
     * @description :   Use to get the ObjectAtPath
     * @return      :   obj
     */
	private static Object getObjectAtPath(Object obj, String keyPath) {
		List<String> propertyPathComponents = keyPath.split('\\.');
		Integer pathComponentsLength = propertyPathComponents.size();
		for (Integer i = 0; i < pathComponentsLength; i++) {
			String propertyComponentName = propertyPathComponents[i];
			obj = ((Map<String,Object>)obj).get(propertyComponentName);
		}
		return obj;
	}

    /*
	public static void scratchpad() {
		List<Object> sections = getObjectList('LIST_MANAGEMENT', 'usco.sections');
		for (Object section : sections) {
			List<Object> fields = (List<Object>)((Map<String, Object>)section).get('skill fields');
			System.debug( JSON.serializePretty(fields) );
		}

    }
    */

}