/*
* Class: PDS_CustomMetadataHandler
* Test Class: PDS_CustomMetadataHandlerTest
* Description: Fetches Custom Metadata for PDS Application
* Author: Gopi Chintamaneni
* Created On: 04/18/2024
* Last Modified: 04/18/2024
*/
public without sharing class PDS_CustomMetadataHandler {
    public static map<string, object> cachedAppSettings;

    @AuraEnabled
    public static map<string, object> getApplicationSettings(string flowDeveloperName){   
        try{
            if(cachedAppSettings == Null){
                cachedAppSettings = new  map<string, object>();
                Map<String, Schema.SObjectField> schemaFieldMap = Schema.SObjectType.PDS_Application_Setting__mdt.fields.getMap();
                string query = 'SELECT ' + getCSVFields(schemaFieldMap.keySet()) + ' FROM PDS_Application_Setting__mdt WHERE developername = ' +  '\'' + String.escapeSingleQuotes(flowDeveloperName) + '\'';
                PDS_Application_Setting__mdt applicationSettings = Database.query(query);

                for (String fieldName: schemaFieldMap.keySet()) {
                    cachedAppSettings.put(fieldName, applicationSettings.get(fieldName));
                } 
            }
        } catch(Exception e){
            System.debug('getApplicationSettings' + e.getMessage());
        }
        return cachedAppSettings;
    }

    private static string getCSVFields(set<string> fieldsList){
        string strFields = '';
        if(fieldsList != null && fieldsList.size() >0){
            for(string strField : fieldsList){
                strFields += strField + ',';
            }
            strFields = strFields.substringBeforeLast(',');
        }
        return strFields;
    }
}