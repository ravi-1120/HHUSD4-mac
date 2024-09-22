/*
* MSD_CORE_DCRUtility
* Created By:    Samuel Rosen
* Created Date:  6/20/2015
* Description:   This utility is responsible for creating New Account and
*                new Address DCRs for HCP, HBP, and Business Accounts as well 
*                as Edit Account DCRs for HCP and HBP Accounts.
*/
public with sharing class MSD_CORE_DCRUtility {
    private static Service_Cloud_Settings_MVN__c serviceCloudSettings = Service_Cloud_Settings_MVN__c.getInstance();
    private static final String PendingStatus = serviceCloudSettings.MSD_CORE_Account_Status_Pending__c;
    private static final String NeedMoreInfoStatus = serviceCloudSettings.MSD_CORE_Account_Status_Need_More_Info__c;

    public static Map<String, String> PersonFieldsToStamp;
    public static Map<String, String> BusinessFieldsToStamp;

    static {
        initializeFieldsToStamp();
    }

    private static void initializeFieldsToStamp(){
        PersonFieldsToStamp = new Map<String, String>();
        BusinessFieldsToStamp = new Map<String, String>();

        List<MSD_CORE_Account_Fields_To_Stamp_Map__c> fieldsToStamp = 
            MSD_CORE_Account_Fields_To_Stamp_Map__c.getAll().values();

        for(MSD_CORE_Account_Fields_To_Stamp_Map__c fieldToStamp : fieldsToStamp){
            if(fieldToStamp.MSD_CORE_Is_Person__c){
                PersonFieldsToStamp.put(fieldToStamp.Name, fieldToStamp.MSD_CORE_Target_Field__c);
            } else {
                BusinessFieldsToStamp.put(fieldToStamp.Name, fieldToStamp.MSD_CORE_Target_Field__c);
            }
        }
    }
    
    //this is only for new accounts and new address
    public static void checkAndSubmitNewRecordsToDCR(Account acc, Address_vod__c address) {
        String country = [SELECT MSD_CORE_Country_Code__c FROM User WHERE Id =: userinfo.getUserId()].MSD_CORE_Country_Code__c; 
        System.debug('KRB 1');
        if (address == null) {            
            System.debug(LoggingLevel.FINE, '\n\tAddress is null for ' + acc.Id);
            updateAccountStatus(acc, NeedMoreInfoStatus);
            return; 
        }
        System.debug('KRB 2');
        updateAddressAsInactive(address);
        System.debug('KRB 3');
        if (acc.Status_MRK__c != serviceCloudSettings.MSD_CORE_Account_Status_Pending__c &&
            String.isBlank(acc.Merck_ID_MRK__c)) {  
              System.debug('KRB 4');
            if (verifyRequirements(acc, country, acc.RecordTypeId) &&
                verifyRequirements(address, country, address.RecordTypeId)) { 
                System.debug('KRB 4a');    
                updateAccountStatus(acc, PendingStatus);
                System.debug('KRB 4b');
                submitDCRRequest(acc, address); 
                    System.debug('KRB 6');
            } else {
                System.debug('KRB 7');
                updateAccountStatus(acc, NeedMoreInfoStatus); 
            }
        } else if (verifyRequirements(address, country, address.RecordTypeId)) {
            System.debug(LoggingLevel.DEBUG, '\n\tAccount (' + acc.Id + ') submitted for DCR has Status_MRK__c ' + 
                acc.Status_MRK__c + ' and Merck_ID_MRK__c of (' + acc.Merck_ID_MRK__c + ')');
           System.debug('KRB 8');
            submitDCRRequest(null, address);
        } 
    }

    public static Data_Change_Request_vod__c submitUpdatedAccount(Account beforeAccount, Map<String, String> updatedDCRFields) {
        if(beforeAccount.Id == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.MSD_CORE_Account_ID_Missing));
            return null;
        }

        Data_Change_Request_vod__c dcr = new Data_Change_Request_vod__c(); 
        dcr.RecordTypeId = [select Id from RecordType 
                            where SObjectType='Data_Change_Request_vod__c' 
                            and DeveloperName = :serviceCloudSettings.MSD_CORE_Edit_Account_DCR_Record_Type__c].Id;

        dcr.Account_vod__c = beforeAccount.Id; 
        dcr.MSD_CORE_Application_Source__c = serviceCloudSettings.MSD_CORE_DCR_Application_Source__c;
        dcr.Country_Mapping_vod__c = [SELECT MSD_CORE_Country_Code__c FROM User WHERE Id =: userinfo.getUserId()].MSD_CORE_Country_Code__c; 
        dcr.Type_vod__c = serviceCloudSettings.MSD_CORE_DCR_Edit_Type__c;
        insert dcr;

        Map<String, Schema.SObjectField> apiToLabel = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();
        List<Data_Change_Request_Line_vod__c> dcrlList = new List<Data_Change_Request_Line_vod__c>(); 
        for(String apiFieldName : updatedDCRFields.keySet()) {
            Data_Change_Request_Line_vod__c line = new Data_Change_Request_Line_vod__c(); 
            line.Data_Change_Request_vod__c = dcr.Id; 
            line.Field_API_Name_vod__c = apiFieldName;
            line.Field_Name_vod__c = apiToLabel.get(apiFieldName).getDescribe().getLabel(); 
            line.New_Value_vod__c = updatedDCRFields.get(apiFieldName);
            line.Old_Value_vod__c = (String)beforeAccount.get(apiFieldName);
            dcrlList.add(line);  
        }
        insert dcrlList; 

        return dcr;
    }

    public static List<MSD_CORE_NAW_Field_Types__c> fieldsFor(String objectAPIName, String country, Id recordTypeId){
        return fieldsFor(objectAPIName, country, recordTypeId, false);
    }

    public static List<MSD_CORE_NAW_Field_Types__c> fieldsFor(String objectAPIName, String country, Id recordTypeId, Boolean isRequiredDCR){
        String recordTypeName;
        
        String profileName = [Select Id,Name from Profile where Id = :userinfo.getProfileId()].Name;
        String contactCenterProfilePrefix = serviceCloudSettings.MSD_CORE_Contact_Center_Profile_Prefix__c;

        System.debug('KRB: '+ '\n\tRequesting '+(isRequiredDCR ? 'required ' : '')+'DCR Fields for.\n'+
                                            '\t\tRecord_Type__c = ' + recordTypeName + '\n' +
                                            '\t\tObject_API_Name__c = ' + objectAPIName + '\n' +
                                            '\t\tProfile__c = ' + profileName + '\n' +
                                            '\t\tMSD_CORE_Contact_Center_Profile_Prefix__c = ' + 
                                            serviceCloudSettings.MSD_CORE_Contact_Center_Profile_Prefix__c + '\n' +
                                            '\t\tCountry_Code__c = ' + country);
        
        System.debug(LoggingLevel.FINE, '\n\tRequesting '+(isRequiredDCR ? 'required ' : '')+'DCR Fields for.\n'+
                                            '\t\tRecord_Type__c = ' + recordTypeName + '\n' +
                                            '\t\tObject_API_Name__c = ' + objectAPIName + '\n' +
                                            '\t\tProfile__c = ' + profileName + '\n' +
                                            '\t\tMSD_CORE_Contact_Center_Profile_Prefix__c = ' + 
                                            serviceCloudSettings.MSD_CORE_Contact_Center_Profile_Prefix__c + '\n' +
                                            '\t\tCountry_Code__c = ' + country);

        String fieldQuery = 'SELECT Active__c, Country_Code__c, DCR__c, Display_Order__c, Editable__c, ' +
                                   'Field_API_Name__c, Id, Object_API_Name__c, Page_Section__c, ' +
                                   'Profile__c, Read_Only__c, Required__c, Edit_Page_Hidden__c ' +
                              'FROM MSD_CORE_NAW_Field_Types__c '+
                             'WHERE Object_API_Name__c = :objectAPIName '+
                               'AND Active__c = true ' +
                               'AND (   Country_Code__c = :country ' +
                                    'OR Country_Code__c = null) ' + 
                               'AND (   Profile__c = :profileName ' +
                                    'OR Profile__c = :contactCenterProfilePrefix) ';
        if(recordTypeId != null){
            recordTypeName = [SELECT Name FROM RecordType WHERE Id= :recordTypeId].Name;
            fieldQuery += 'AND (   Record_Type__c = :recordTypeName ' +
                                    'OR Record_Type__c = null) ';
        }
        if(isRequiredDCR){
            fieldQuery += ' ' + 'AND DCR__c = true AND Required__c = true';
        }
        
        System.debug('KRB y: ' + fieldQuery);

        List<MSD_CORE_NAW_Field_Types__c> fields = (List<MSD_CORE_NAW_Field_Types__c>)Database.query(fieldQuery);

        return fields;
    }

    public static List<MSD_CORE_NAW_Field_Types__c> requiredFieldsFor(String objectAPIName, String country, Id recordTypeId){
        return null;
    }

    private static Boolean verifyRequirements(SObject obj, String country, Id recordTypeId) {
        String objectAPIName = obj.getSObjectType().getDescribe().getName();
        System.debug('KRB a');
        List<MSD_CORE_NAW_Field_Types__c> requiredFields;

        System.debug(LoggingLevel.FINE, '\n\tVerifying Requirements for ' + obj.Id
                    +' from ' + country + ' of RecordTypeId ' + recordTypeId);

        requiredFields = fieldsFor(objectAPIName, country, recordTypeId, true);
        System.debug('KRB b');
        
        for(MSD_CORE_NAW_Field_Types__c field : requiredFields) {
            
            System.debug('KRB: Field: ' + field.Field_API_Name__c );
            if (obj.get(field.Field_API_Name__c) == null || obj.get(field.Field_API_Name__c) == '') {
                System.debug(LoggingLevel.FINE, '\n\tRequired field ' + field.Field_API_Name__c + ' is blank');
                return false; 
            }
        }
        if (requiredFields.size() > 0) {
            return true; 
        } else {
            System.debug(LoggingLevel.WARN, '\n\tThere are no required fields for this object.\n'+
                                            '\t\tRecord_Type__c = ' + recordTypeId + '\n' +
                                            '\t\tObject_API_Name__c = ' + objectAPIName + '\n' +
                                            '\t\tCountry = ' + country + '\n');
            return false; 
        }  
    }

    private static void updateAccountStatus(Account acc, String status) {
        acc.Status_MRK__c = status;        
        update acc; 
    }

    private static void updateAddressAsInactive(Address_vod__c address) {
        address.Inactive_vod__c = true;
        update address; 
    }

    private static void submitDCRRequest(Account acc, Address_vod__c address) {
        if (acc != null && address != null) {
            MSD_CORE_DCRService.createNewAccountAndAddressDCRs(acc, address, serviceCloudSettings.MSD_CORE_DCR_Application_Source__c); 
        } else if (acc == null && address != null) {
            system.debug('KRB 10');
            MSD_CORE_DCRService.createNewAddressDCR(address,  serviceCloudSettings.MSD_CORE_DCR_Application_Source__c);
            system.debug('KRB 11');
        }
    }

    public static void stampObject(SObject objectToStamp, Map<String, String> fieldsToStamp){
        for(String fieldToStamp : fieldsToStamp.keySet()){
            objectToStamp.put(fieldsToStamp.get(fieldToStamp), objectToStamp.get(fieldToStamp));
        }
    }

}