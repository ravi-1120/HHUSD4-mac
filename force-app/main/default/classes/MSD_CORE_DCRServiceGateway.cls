public class MSD_CORE_DCRServiceGateway {
 
   public static Map<Id, Address_vod__c> retrieveValidDEAAddressesByAddressIdList(List<Id> addressIds){
               
        Map<Id, Address_vod__c> AddressMap = new Map<Id, Address_vod__c>( 
          [SELECT Id,
                  DEA_Status_vod__c
           FROM   Address_vod__c
           WHERE  DEA_Status_vod__c = 'Valid_vod'
           AND    id in : addressIds ]);
       
        return AddressMap;
    }
  
   
   public static Map<Id, Data_Change_Request_vod__c> retrieveAddressEditTypeDCRMapByDCRIdList(List<Id> dcrIds){
        
        ID addressDCRRecordType = RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Address_vod);
       
        Map<Id, Data_Change_Request_vod__c> DCRMap = new Map<Id, Data_Change_Request_vod__c>( 
          [SELECT Id,
                  RecordTypeId,
                  MSD_CORE_DCR_Status__c,
                  Status_vod__c,
                  Address_vod__c,
                  Type_vod__c
           FROM   Data_Change_Request_vod__c
           WHERE  Type_vod__c = 'Edit_vod'
           AND    RecordTypeId =: addressDCRRecordType
           AND    Address_vod__c != null
           AND    id in : dcrIds ]);
       
        return DCRMap;
    }
     
    
   public static Map<Id, Account> retrieveAccountStatusbyAccountIdMap(List<Id> acctIds){
        
       Map<Id, Account> accountIdToAccountMap = new Map<Id, Account>();
        
       accountIdToAccountMap = new Map<Id, Account>(
        [
            SELECT id,Status_MRK__c  
            FROM   Account 
            Where  id in : acctIds
        ]);

       return  accountIdToAccountMap;
    }
    
    public static Map<Id, Address_vod__c> retrieveAddressActiveStatusbyAddressIdMap(List<Id> addrIds){
        
       Map<Id, Address_vod__c> addressIdToAddressMap = new  Map<Id, Address_vod__c> ();
        
       addressIdToAddressMap = new  Map<Id, Address_vod__c>(
        [
            SELECT id,Inactive_vod__c 
            FROM   Address_vod__c 
            Where  id in : addrIds
        ]);

       return  addressIdToAddressMap;
    }

    
    
    public static String retrieveAccountRecordTypeNamebyAccountId(Id acctId){
        
       String objectType = '';
       String accountRT = 'Account';
        
       List<Account> acct = new List<Account>(
        [
            SELECT id,RecordTypeId 
            FROM   Account 
            Where  id =: acctId
        ]);
        
       List <RecordType> rts = new List <RecordType>();
       rts = RT.retrieveRecordTypeListforObjectType(accountRT);
       
       for (RecordType rt: rts){
          if (rt.id == acct[0].RecordTypeId){
               objectType = rt.DeveloperName;
          }
       }

       return  objectType;
    }
    
    
    
    public static Map<Id, String> retrieveAccountRecordTypeNamesbyAccountIdMap(List<Id> acctIds){
        
       String objectType = '';
       String accountRT = 'Account';
       Map<Id, String> accountIdToRecordTypeNameMap = new  Map<Id, String> ();
        
       List<Account> acctList = new List<Account>(
        [
            SELECT id,RecordTypeId 
            FROM   Account 
            Where  id in : acctIds
        ]);
        
       List <RecordType> rts = new List <RecordType>();
       rts = RT.retrieveRecordTypeListforObjectType(accountRT);
       
        for (Account acct : acctList){
            
           for (RecordType rt: rts){
              if (rt.id == acct.RecordTypeId){
                 objectType = rt.DeveloperName;
              }
            }
           
            //accountIdToRecordTypeNameMap
           accountIdToRecordTypeNameMap.put(acct.id, objectType); 
        } 
 
       return  accountIdToRecordTypeNameMap;
    }

    
    
    public static Map<Id, Data_Change_Request_vod__c> retrieveDCRandDCRLineItemsByDCRIdMap(List<Id> dcrIds){
        
        Map<Id, Data_Change_Request_vod__c> DCRandDCRLineItemsMap = new Map<Id, Data_Change_Request_vod__c>( 
          [SELECT Id,
                 (SELECT  Field_API_Name_vod__c,
                          Field_Name_vod__c,
                          Final_Value_vod__c
                  FROM Data_Change_Request_Lines_vod__r
                  ) 
           FROM Data_Change_Request_vod__c
           WHERE id in : dcrIds ]);
       
        return DCRandDCRLineItemsMap;
    }
    
    
    public static Map<Id, Data_Change_Request_vod__c> retrieveEditTypeDCRMapByDCRIdList(List<Id> dcrIds){
        
        Map<Id, Data_Change_Request_vod__c> DCRMap = new Map<Id, Data_Change_Request_vod__c>( 
          [SELECT Id,
                  RecordTypeId,
                  MSD_CORE_DCR_Status__c,
                  Status_vod__c,
                  Account_vod__c,
                  Address_vod__c,
                  Type_vod__c
           FROM  Data_Change_Request_vod__c
           WHERE Type_vod__c = 'Edit_vod'
           AND   id in : dcrIds ]);
       
        return DCRMap;
    }

    public static Map<Id, MSD_CORE_DCRService_DCR__c> retrieveNewAccountAffiliationsDCRServiceSettingsMap(String countryCode){
        
        Map<Id, MSD_CORE_DCRService_DCR__c> newAccountAffiliationDCRSettingsMap = new Map<Id, MSD_CORE_DCRService_DCR__c>( 
          [SELECT MSD_CORE_DCR_Status__c,
                  MSD_CORE_DCR_User_Status__c,
                  MSD_CORE_Object__c,
                  MSD_CORE_Result__c,
                  MSD_CORE_Type__c,
                 (SELECT  MSD_CORE_DCRService_DCR__c,
                          MSD_CORE_Field_API_Name__c,
                          MSD_CORE_Result__c,
                          MSD_CORE_Sort_Order__c
                  FROM DCRService_DCR_Controlled_Fields__r
                  WHERE MSD_CORE_Active__c = true
                  AND MSD_CORE_Country_Code__c =: countryCode) 
           FROM MSD_CORE_DCRService_DCR__c
           WHERE MSD_CORE_Object__c = 'Child_Account_vod__c'
           AND MSD_CORE_Type__c = 'New_vod'
           AND MSD_CORE_Country_Code__c =: countryCode
           AND MSD_CORE_Active__c = true
           LIMIT 1]);
       
        return newAccountAffiliationDCRSettingsMap;
    }
    
    
  
    public static Map<Id, MSD_CORE_DCRService_DCR__c> retrieveNewAccountDCRServiceSettingsMap(String countryCode, String objectType){
              
        Map<Id, MSD_CORE_DCRService_DCR__c> newAccountDCRSettingsMap = new Map<Id, MSD_CORE_DCRService_DCR__c>( 
          [SELECT MSD_CORE_DCR_Status__c,
                  MSD_CORE_DCR_User_Status__c,
                  MSD_CORE_Object__c,
                  MSD_CORE_Result__c,
                  MSD_CORE_Type__c,
                 (SELECT  MSD_CORE_DCRService_DCR__c,
                          MSD_CORE_Field_API_Name__c,
                          MSD_CORE_Result__c,
                          MSD_CORE_Sort_Order__c
                  FROM DCRService_DCR_Controlled_Fields__r
                  WHERE MSD_CORE_Active__c = true
                  AND MSD_CORE_Country_Code__c =: countryCode) 
           FROM MSD_CORE_DCRService_DCR__c
           WHERE MSD_CORE_Object__c = 'Account'
           AND MSD_CORE_Type__c = 'New_vod'
           AND MSD_CORE_Object_Record_Type_Name__c includes (:objectType)
           AND MSD_CORE_Country_Code__c =: countryCode
           AND MSD_CORE_Active__c = true
           LIMIT 1]);
       
        return newAccountDCRSettingsMap;
    }
    
    public static Map<Id, MSD_CORE_DCRService_DCR__c> retrieveNewAddressDCRServiceSettingsMap(String countryCode, String objectType){
              
        Map<Id, MSD_CORE_DCRService_DCR__c> newAddressDCRSettingsMap = new Map<Id, MSD_CORE_DCRService_DCR__c>( 
          [SELECT MSD_CORE_DCR_Status__c,
                  MSD_CORE_DCR_User_Status__c,
                  MSD_CORE_Object__c,
                  MSD_CORE_Result__c,
                  MSD_CORE_Type__c,
                 (SELECT  MSD_CORE_DCRService_DCR__c,
                          MSD_CORE_Field_API_Name__c,
                          MSD_CORE_Result__c,
                          MSD_CORE_Sort_Order__c
                  FROM DCRService_DCR_Controlled_Fields__r
                  WHERE MSD_CORE_Active__c = true
                  AND MSD_CORE_Country_Code__c =: countryCode) 
           FROM MSD_CORE_DCRService_DCR__c
           WHERE MSD_CORE_Object__c = 'Address_vod__c'
           AND MSD_CORE_Type__c = 'New_vod'
           AND MSD_CORE_Object_Record_Type_Name__c includes (:objectType)
           AND MSD_CORE_Country_Code__c =: countryCode
           AND MSD_CORE_Active__c = true
           LIMIT 1]);
       
        return newAddressDCRSettingsMap;
    }

    
    
    //For Standalone Address Creation
    public static Map<Id, MSD_CORE_DCRService_DCR__c> retrieveNewStandaloneAddressDCRServiceSettingsMap(String countryCode, String objectType){
              
        Map<Id, MSD_CORE_DCRService_DCR__c> newAddressDCRSettingsMap = new Map<Id, MSD_CORE_DCRService_DCR__c>( 
          [SELECT MSD_CORE_DCR_Status__c,
                  MSD_CORE_DCR_User_Status__c,
                  MSD_CORE_Object__c,
                  MSD_CORE_Result__c,
                  MSD_CORE_Type__c,
                 (SELECT  MSD_CORE_DCRService_DCR__c,
                          MSD_CORE_Field_API_Name__c,
                          MSD_CORE_Result__c,
                          MSD_CORE_Sort_Order__c
                  FROM DCRService_DCR_Controlled_Fields__r
                  WHERE MSD_CORE_Active__c = true
                  AND MSD_CORE_Country_Code__c =: countryCode) 
           FROM MSD_CORE_DCRService_DCR__c
           WHERE MSD_CORE_Object__c = 'Address_vod__c'
           AND MSD_CORE_Type__c = 'New_Standalone'
           AND MSD_CORE_Object_Record_Type_Name__c includes (:objectType)
           AND MSD_CORE_Country_Code__c =: countryCode
           AND MSD_CORE_Active__c = true
           LIMIT 1]);
       
        return newAddressDCRSettingsMap;
    }

 }