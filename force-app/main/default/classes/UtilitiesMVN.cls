/*
* UtilitiesMVN
* Created By:    Roman Lerman
* Created Date:  3/4/2013
* Description:   A set of generic utility methods used in Service Cloud
*/
public with sharing class UtilitiesMVN {
    public static Map<Id,RecordType> typeMap = new Map<Id,RecordType>([select Id,Name,DeveloperName from RecordType where SObjectType = 'Case']);
    public static Boolean isAnonymizing = false;
    public static Boolean knowledgeInstalled;
    public static Boolean isReadOnlyUser;
    public static Boolean hasModifyAllData;
    private static Set<String> accountSelectFieldList = new Set<String>{
        'Id', 'External_ID_vod__c', 'Middle_vod__c',
        'Preferred_First_Name_MRK__c', 'Preferred_Last_Name_MRK__c',
        'Preferred_Full_Name_MRK__c', 'Preferred_Middle_Name_MRK__c',
        'Preferred_Salutation_MRK__c', 'Preferred_Suffix_MRK__c', 'MSD_CORE_Country_Code__c',
        'RecordTypeId', 'PersonEmail', 'Phone', 'Fax', 'Class_of_Trade_MRK__c',
        'Class_of_Trade_Sub_MRK__c', 'IMS_Specialty_MRK__c', 'IMS_Sub_Specialty_MRK__c',
        'Class_of_Trade_Owner_MRK__c', 'Alternate_Email_MRK__c',
        'PersonHomePhone', 'PersonMobilePhone', 'PersonOtherPhone', 'Salutation',
        'MSD_CORE_Contact_Center_Email__c', 'RecordType.DeveloperName',
        'Status_MRK__c', 'Status_Reason_MRK__c', 'Merck_ID_MRK__c', 'Credentials_vod__c'
    };
    private static List<String> personAccountSelectFieldList = new List<String>{
        'FirstName', 'LastName'
    };
    private static List<String> businessAccountSelectFieldList = new List<String>{
        'Name'
    };
    private static List<String> allAccountSelectFieldList = new List<String>();

    static {
        allAccountSelectFieldList.addAll(accountSelectFieldList);
        allAccountSelectFieldList.addAll(personAccountSelectFieldList);
        allAccountSelectFieldList.addAll(businessAccountSelectFieldList);
        personAccountSelectFieldList.addAll(accountSelectFieldList);
        businessAccountSelectFieldList.addAll(accountSelectFieldList);

        knowledgeInstalled = isKnowledgeInstalled();
        isReadOnlyUser = !Schema.sObjectType.Case.isUpdateable();

        hasModifyAllData = false;
        
        if (UserInfo.getName() == 'Automated Process'){
          hasModifyAllData = true;
          system.debug('krb b');
        }else{

           try{
               User thisUser = [select Profile.PermissionsModifyAllData from User where Id = :UserInfo.getUserId()];
               hasModifyAllData = thisUser.Profile.PermissionsModifyAllData;
               system.debug('krb c');
           } catch (Exception e) {
              system.debug('Exception: lastName: ' + UserInfo.getLastName());
              system.debug('Exception: full Name: ' + UserInfo.getName()); 
           }
        }
    }

    public static Boolean matchCaseRecordTypeIdToName(Id recordTypeId, String recordTypeName){
        System.debug('RecordTypeId: '+recordTypeId);
        System.debug('RecordTypeName: '+recordTypeName);
        for(String recTypeName : splitCommaSeparatedString(recordTypeName)) {
            if(recTypeName != null && recTypeName != ''){
                recTypeName = recTypeName.trim();
                if(typeMap.containsKey(recordTypeId) && typeMap.get(recordTypeId).DeveloperName == recordTypeName){
                    return true;
                }
            }
        }
        return false;
    }

    public static Boolean isKnowledgeInstalled() {
        Boolean isInstalled = true;

        try {
            SObject cs = Schema.getGlobalDescribe().get('CaseArticle').newSObject();
        } catch (Exception e) {
            isInstalled = false;
        }

        return isInstalled;
    }

    public static List<String> splitCommaSeparatedString(String stringToSplit){
        if(String.isBlank(stringToSplit)){
            return new List<String>();
        } else{
            List<String> splitStrings = stringToSplit.split(',');
            List<String> stringsToReturn = new List<String>();
            for(String splitString : splitStrings){
                stringsToReturn.add(splitString.trim());
            }
            return stringsToReturn;
        }
    }

    public static List<String> accountSelectFields(){
        return allAccountSelectFieldList;
    }

    public static List<String> personAccountSelectFields(){
        return personAccountSelectFieldList;
    }
}