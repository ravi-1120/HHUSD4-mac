public class MRK_Setting {

	static Map<String,Map<String, Object>> settingsCacheMap = new Map<String,Map<String, Object>>();


	public static Map<String, Object> getValues(String name) {

		Map<String, Object> settingsMap = settingsCacheMap.get(name);
		if (settingsMap == null) {
			Setting_MRK__c settings = [select Id, OwnerId, IsDeleted, Name, Description_MRK__c, Text_MRK__c from Setting_MRK__c where Name = :name and Active_MRK__c = true limit 1];
			settingsMap = (Map<String, Object>)JSON.deserializeUntyped(settings.Text_MRK__c);			
			settingsCacheMap.put(name, settingsMap);
		}

		return settingsMap;
	}

	public static String getString(String settingName, String keyPath) {
		return (String)getObject(settingName, keyPath);
		//return (String)getValues(settingName).get(key);
	}

	public static Boolean getBoolean(String settingName, String keyPath) {
		return (Boolean)getObject(settingName, keyPath);
	}

	public static Integer getInteger(String settingName, String keyPath) {
		return (Integer)getObject(settingName, keyPath);
	}


	public static List<Object> getObjectList(String settingName, String keyPath) {
		return (List<Object>)getObject(settingName, keyPath);
	}

	public static List<Map<String, Object>> getMapList(String settingName, String keyPath) {
		return (List<Map<String, Object>>)getObject(settingName, keyPath);
	}

	public static Object getObject(String settingName, String keyPath) {
		return getObjectAtPath( getValues(settingName), keyPath );
	}

	private static Object getObjectAtPath(Object obj, String keyPath) {
		List<String> propertyPathComponents = keyPath.split('\\.');
		Integer pathComponentsLength = propertyPathComponents.size();
		for (Integer i = 0; i < pathComponentsLength; i++) {
			String propertyComponentName = propertyPathComponents[i];
			obj = ((Map<String,Object>)obj).get(propertyComponentName);
		}
		return obj;
	}

	public static void scratchpad() {
		List<Object> sections = getObjectList('COACHING_AND_FEEDBACK', 'usco.sections');
		for (Object section : sections) {
			List<Object> fields = (List<Object>)((Map<String, Object>)section).get('skill fields');
			System.debug( JSON.serializePretty(fields) );	
		}
		
		
		/*
		Object obj = getObject('TEST', 'section.fields');
		for (Object f : (List<Object>)obj) {
			Map<String,Object> m = (Map<String,Object>)f;
			String name = (String)m.get('name');
			System.debug( 'name = ' + name );
		}

		String jsonString = '{"section": {"text fields": [{"name": "CI_Knowledge_MRK__c", "type": "text"}, {"name": "CI_Summary_MRK__c", "type": "summary"} ], "summary field": "CI_Summary_MRK__c"} }';
		*/
		//System.debug( JSON.serializePretty(obj) );
		/*
		
		Map<String, Object> settingsMap = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
		
		//String properyPath = 'section.text fields';
		String key = 'section';
		
		List<String> propertyPathComponents = key.split('\\.');
		Integer pathComponentsLength = propertyPathComponents.size();
		Object obj = settingsMap;
		for (Integer i = 0; i < pathComponentsLength; i++) {
			String propertyComponentName = propertyPathComponents[i];
			if (i != (pathComponentsLength - 1)) {
				obj = ((Map<String,Object>)obj).get(propertyComponentName);
			} else {
				obj = ((Map<String,Object>)obj).get(propertyComponentName);
			}	
		}

		System.debug( 'settingsMap =\n' + JSON.serializePretty(obj) );

		//System.debug( 'split =\n' + JSON.serializePretty('a.b.c'.split('\\.')) );
		*/
	}

}