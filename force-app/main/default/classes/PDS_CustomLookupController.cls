/**
* @description       : PDS_CustomLookupController
* @author            : Rusheel
* @group             : 
* @last modified on  : 04-17-2024
* @last modified by  : Rusheel
**/
public without sharing class PDS_CustomLookupController {
    
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(String objectName, String searchKey) {
        String key1 = searchKey + '%';
        String key2 = '%' + searchKey;
        String key3 = '%' + searchKey + '%';
        String query;
        try {
            if (String.isNotBlank(objectName) && String.isNotBlank(searchKey)) {
                if(objectName == 'PDS_Contact__c'){
                    //query = 'SELECT Id, Name,PDS_Fax_Number__c,PDS_Unit__c,PDS_Organization__c,PDS_Address_2__c,PDS_Address_3__c, PDS_Phone_2__c,PDS_Shipping_Country__c,PDS_Shipping_Postal_Code__c,PDS_Shipping_Street__c,PDS_Shipping_State__c, PDS_Email__c, PDS_Email_Address_2__c, PDS_Email_Address_3__c,PDS_Phone__c  FROM ' + objectName + ' WHERE Name LIKE :key1 OR Name LIKE :key2 OR Name LIKE :key3 LIMIT 5';  
                    query = 'SELECT Id, Name, PDS_Fax_Number__c, PDS_Unit__c, PDS_Organization__c, PDS_Address_2__c, PDS_Address_3__c, PDS_Phone_2__c, PDS_Shipping_Country__c, PDS_Shipping_Postal_Code__c, PDS_Shipping_Street__c, PDS_Shipping_State__c, PDS_Email__c, PDS_Email_Address_2__c, PDS_Email_Address_3__c, PDS_Phone__c FROM ' + objectName + ' WHERE (Name LIKE :key1 OR Name LIKE :key2 OR Name LIKE :key3) AND PDS_Address_Type__c = \'Contact\' AND PDS_IsActive__c = true LIMIT 5';  
                    System.debug('entered contacts');
                }else{
                    query = 'SELECT Id, Name FROM ' + objectName + ' WHERE Name LIKE :key1 OR Name LIKE :key2 OR Name LIKE :key3 LIMIT 5';
                    System.debug('entered other');
                }   
                return Database.query(query);
            } else if (String.isNotBlank(objectName)) {
               // query = 'SELECT Id, Name FROM ' + objectName + ' ORDER BY Name ASC LIMIT 5';
                if(objectName == 'PDS_Contact__c'){
                  //  query = 'SELECT Id, Name,PDS_Fax_Number__c,PDS_Address_2__c,PDS_Unit__c,PDS_Organization__c,PDS_Address_3__c,PDS_Shipping_Street__c,PDS_Shipping_Postal_Code__c,PDS_Shipping_Country__c,PDS_Shipping_State__c, PDS_Phone_2__c, PDS_Email__c, PDS_Email_Address_2__c, PDS_Email_Address_3__c,PDS_Phone__c FROM ' + objectName + ' ORDER BY Name ASC LIMIT 5';  
                    query = 'SELECT Id, Name, PDS_Fax_Number__c, PDS_Unit__c, PDS_Organization__c, PDS_Address_2__c, PDS_Address_3__c, PDS_Phone_2__c, PDS_Shipping_Country__c, PDS_Shipping_Postal_Code__c, PDS_Shipping_Street__c, PDS_Shipping_State__c, PDS_Email__c, PDS_Email_Address_2__c, PDS_Email_Address_3__c, PDS_Phone__c FROM ' + objectName + ' WHERE (Name LIKE :key1 OR Name LIKE :key2 OR Name LIKE :key3) AND PDS_Address_Type__c = \'Contact\' AND PDS_IsActive__c = true LIMIT 5';  
                    System.debug('entered contacts');
                }else{
                    query = 'SELECT Id, Name FROM ' + objectName + ' ORDER BY Name ASC LIMIT 5';
                    System.debug('entered other');
                } 
                return Database.query(query);
            } else {
                return new List<SObject>();
            }
        } catch (Exception e) {
            return null;
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValue(String objectType, String selectedField){    
        try {
            List<String> pickListValuesList = new List<String>();
            Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectType);
            Schema.DescribeSObjectResult res = convertToObj.getDescribe();
            Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(selectedField).getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                pickListValuesList.add(pickListVal.getLabel());
            }     
            return pickListValuesList;
        } catch (Exception e) {
            return null;
        }
    }
    
    @AuraEnabled
    public static List<PDS_Contact__c> saveContacts(String recordData) {
        List<PDS_Contact__c> returnName;
        try {
            Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(recordData);

            PDS_Contact__c obj = new PDS_Contact__c();
            obj.Name = (String) dataMap.get('name');
            obj.PDS_Shipping_Street__c = (String) dataMap.get('street');
            obj.PDS_Address_2__c = (String) dataMap.get('addone');
            obj.PDS_Address_3__c = (String) dataMap.get('addtwo');
            obj.PDS_Shipping_Country__c = (String) dataMap.get('country');
            obj.PDS_Shipping_State__c = (String) dataMap.get('state');
            obj.PDS_Shipping_Postal_Code__c = (String) dataMap.get('zipcode');
            obj.PDS_Phone__c = (String) dataMap.get('phone');
            obj.PDS_Fax_Number__c = (String) dataMap.get('fax');
            obj.PDS_Phone_2__c = (String) dataMap.get('mobile');
            obj.PDS_Email__c = (String) dataMap.get('email');
            obj.PDS_Email_Address_2__c = (String) dataMap.get('emailtwo');
            obj.PDS_Email_Address_3__c = (String) dataMap.get('emailthree');
            obj.PDS_Unit__c = (String) dataMap.get('unit');
            obj.PDS_Organization__c = (String) dataMap.get('organization');
            obj.PDS_Address_Type__c = 'Contact';
            obj.PDS_IsActive__c = true;

            if(dataMap.containsKey('id')) {
                obj.Id = (String) dataMap.get('id');
                upsert obj;
            } else {
                insert obj;
            }
            returnName = [SELECT Id,Name,PDS_Shipping_Street__c,PDS_Unit__c,PDS_Organization__c,PDS_Address_2__c,PDS_Address_3__c,PDS_Shipping_Country__c,PDS_Shipping_State__c,PDS_Shipping_Postal_Code__c,PDS_Phone__c,PDS_Fax_Number__c,PDS_Phone_2__c,PDS_Email__c,PDS_Email_Address_2__c,PDS_Email_Address_3__c FROM PDS_Contact__c WHERE Id = :obj.Id LIMIT 1];
            return returnName;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating request: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<SObject> getRecordById(String pdsContactId) {
        try{
            return [SELECT Id, Name,PDS_Fax_Number__c,PDS_Unit__c,PDS_Organization__c,PDS_Address_2__c,PDS_Address_3__c, PDS_Phone_2__c,PDS_Shipping_Country__c,PDS_Shipping_Postal_Code__c,PDS_Shipping_Street__c,PDS_Shipping_State__c, PDS_Email__c, PDS_Email_Address_2__c, PDS_Email_Address_3__c,PDS_Phone__c  FROM PDS_Contact__c WHERE Id = :pdsContactId];
        } catch (Exception e) {
            throw new AuraHandledException('getRecordById: ' + e.getMessage());
        }
    }
}