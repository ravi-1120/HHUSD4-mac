public class MSD_CORE_DCRService {
    
/* Kevin Brace Release 6.0 5/13/2015
 * 
 * DCR Service is a Service Class that can be called to load DCRs and 
 * their associated DCR Line Item Records. The Class currently supports 
 * Affiliation, Account and Address DCR Types. The Class supports the Parenting
 * of the Address DCR to the Account DCR. 
 * 
 * The Class makes use of the "Unit of Work" Service Layer Pattern 
 * as document on DeveloperForce.com. 
 * Enterprise Application Architecture Patter: "Unit Of Work", 
 * as defined by Martin Fowler
 * http://martinfowler.com/eaaCatalog/unitOfWork.html
 */
 
      
   //Required for the 'Unit Of Work' SObjects Processing (in order of dependency)
   private static List<Schema.SObjectType> DCR_SOBJECTS =
       new Schema.SObjectType[] {
        Data_Change_Request_vod__c.SObjectType,
        Data_Change_Request_Line_vod__c.SObjectType };
    
   private static String countryCode = 'US';        

   /*
   Method for Creating New Address DCR
   Kevin Brace Release 6.0 5/13/2015
   */
   public static void createNewAddressDCR (Address_vod__c addr, String appSource){
      
      //Get the Account's Record Type Name:
      String objectType = MSD_CORE_DCRServiceGateway.retrieveAccountRecordTypeNamebyAccountId(addr.Account_vod__c);

      //retrieve the Address DCR Service Layer DCR and DCR Line Item Metadata 
      Map<Id, MSD_CORE_DCRService_DCR__c> newAddressDCRServiceSettingsMap 
          = new Map<Id, MSD_CORE_DCRService_DCR__c>();
      //newAddressDCRServiceSettingsMap = MSD_CORE_DCRServiceGateway.retrieveNewAddressDCRServiceSettingsMap(countryCode, objectType);       
      newAddressDCRServiceSettingsMap = MSD_CORE_DCRServiceGateway.retrieveNewStandaloneAddressDCRServiceSettingsMap(countryCode, objectType);       

     if(newAddressDCRServiceSettingsMap.isEmpty()){
          throw new DCRServiceException('There are no Active DCR/DCRL Mappings for the Record\'s Record Type. Address Record Type = ' + addr.Account_Record_Type_MRK__c + ' :DCR/DCRL cannot be processed.');
      } 
       
      Set <Id> newAddressDCRServiceSettingIdSet = new Set<Id>();
      
      newAddressDCRServiceSettingIdSet = newAddressDCRServiceSettingsMap.keySet(); 
     
      MSD_CORE_DCRService_DCR__c newAddressDCRServiceSetting = new MSD_CORE_DCRService_DCR__c();
      List<MSD_CORE_DCRService_DCR_Controlled_Field__c> addressControlledFieldsList = new List<MSD_CORE_DCRService_DCR_Controlled_Field__c>();

       
      //Should only be one... 
      for (Id settingId: newAddressDCRServiceSettingIdSet) {
           newAddressDCRServiceSetting = newAddressDCRServiceSettingsMap.get(settingId);
      }
       
      addressControlledFieldsList= 
           newAddressDCRServiceSettingsMap.get(newAddressDCRServiceSetting.Id).DCRService_DCR_Controlled_Fields__r;
   
      //Process Address Data: 
      String addressType='Address_vod__c';
      Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
      Schema.SObjectType leadSchema = schemaMap.get(addressType);
      Map<String, Schema.SObjectField> addressObjfieldMap = leadSchema.getDescribe().fields.getMap();
   
      SObjectUnitOfWork uow = new SObjectUnitOfWork(DCR_SOBJECTS);       
           
      //Process Address DCR and DCR Line Items 
      String newType = 'New_vod';
      
      Data_Change_Request_vod__c addressDCR = new Data_Change_Request_vod__c();
      addressDCR.RecordTypeId = RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Address_vod);
      addressDCR.Status_vod__c = newAddressDCRServiceSetting.MSD_CORE_DCR_Status__c;
      addressDCR.Result_vod__c = newAddressDCRServiceSetting.MSD_CORE_Result__c;
      addressDCR.Type_vod__c = newType;
      addressDCR.Network_Customer_Master_Mode_vod__c = 0;
      addressDCR.Address_vod__c = addr.Id;
      addressDCR.Account_vod__c = addr.Account_vod__c;
      addressDCR.MSD_CORE_Application_Source__c = appSource;
      addressDCR.MSD_CORE_DCR_Status__c = newAddressDCRServiceSetting.MSD_CORE_DCR_User_Status__c;
      addressDCR.Notes_vod__c = addr.MSD_CORE_Rep_Notes__c;
      uow.registerNew(addressDCR) ;
       
      for(MSD_CORE_DCRService_DCR_Controlled_Field__c controlledField : addressControlledFieldsList){
        Data_Change_Request_Line_vod__c addressDCRL = new Data_Change_Request_Line_vod__c();
       
        addressDCRL.Field_API_Name_vod__c = controlledField.MSD_CORE_Field_API_Name__c;
        addressDCRL.Field_Name_vod__c = addressObjfieldMap.get(controlledField.MSD_CORE_Field_API_Name__c).getDescribe().getLabel(); 
        
        Object val = addr.get(controlledField.MSD_CORE_Field_API_Name__c) ; 
        if ((val == null) || (val == '') ){
           addressDCRL.New_Value_vod__c = '';
        }else{
           Schema.DescribeFieldResult f = addressObjfieldMap.get(controlledField.MSD_CORE_Field_API_Name__c).getDescribe();
           addressDCRL.New_Value_vod__c = getStringValueOf(f,val ); 
        }
          
        addressDCRL.Result_vod__c = controlledField.MSD_CORE_Result__c;
        addressDCRL.Display_Order__c = controlledField.MSD_CORE_Sort_Order__c;
        uow.registerNew(addressDCRL, Data_Change_Request_Line_vod__c.Data_Change_Request_vod__c, addressDCR);
      
      } 
    
      uow.commitWork();



   }

   /*
   Method for Creating DCR Account with Address
   Kevin Brace Release 6.0 5/13/2015
   */

   public static void createNewAccountAndAddressDCRs (Account acct, Address_vod__c addr, String appSource){  
 
      //Get the Account's Record Type Name:
      String objectType = '';
      String x = acct.RecordTypeId;
      String accountRT = 'Account';
      List <RecordType> rts = new List <RecordType>();
      rts = RT.retrieveRecordTypeListforObjectType(accountRT);
       
       for (RecordType rt: rts){
           if (rt.id == acct.RecordTypeId){
               objectType = rt.DeveloperName;
           }
       }
              
      //retrieve the Account DCR Service Layer DCR and DCR Line Item Metadata 
      Map<Id, MSD_CORE_DCRService_DCR__c> newAccountDCRServiceSettingsMap 
          = new Map<Id, MSD_CORE_DCRService_DCR__c>();
      newAccountDCRServiceSettingsMap = MSD_CORE_DCRServiceGateway.retrieveNewAccountDCRServiceSettingsMap(countryCode, objectType );       

      if(newAccountDCRServiceSettingsMap.isEmpty()){
          throw new DCRServiceException('There are no Active DCR/DCRL Mappings for the Record\'s Record Type. Account Record Type = ' + addr.Account_Record_Type_MRK__c + ' :DCR/DCRL cannot be processed.');
      }  
       
      Set <Id> newAccountDCRServiceSettingIdSet 
          = new Set<Id>();
      
      newAccountDCRServiceSettingIdSet = newAccountDCRServiceSettingsMap.keySet(); 
      
      MSD_CORE_DCRService_DCR__c newAccountDCRServiceSetting = new MSD_CORE_DCRService_DCR__c();
      List<MSD_CORE_DCRService_DCR_Controlled_Field__c> accountControlledFieldsList = new List<MSD_CORE_DCRService_DCR_Controlled_Field__c>();
      //Should only be one... 
      for (Id settingId: newAccountDCRServiceSettingIdSet) {
           newAccountDCRServiceSetting = newAccountDCRServiceSettingsMap.get(settingId);
       }
       
       accountControlledFieldsList= 
           newAccountDCRServiceSettingsMap.get(newAccountDCRServiceSetting.Id).DCRService_DCR_Controlled_Fields__r;
 
      //retrieve the Address DCR Service Layer DCR and DCR Line Item Metadata 
      Map<Id, MSD_CORE_DCRService_DCR__c> newAddressDCRServiceSettingsMap 
          = new Map<Id, MSD_CORE_DCRService_DCR__c>();
      newAddressDCRServiceSettingsMap = MSD_CORE_DCRServiceGateway.retrieveNewAddressDCRServiceSettingsMap(countryCode, objectType);       
      
      if(newAddressDCRServiceSettingsMap.isEmpty()){
          throw new DCRServiceException('There are no Active DCR/DCRL Mappings for the Record\'s Record Type. Addreww Record Type = ' + addr.Account_Record_Type_MRK__c + ' :DCR/DCRL cannot be processed.');
      }  

      Set <Id> newAddressDCRServiceSettingIdSet 
          = new Set<Id>();
      
      newAddressDCRServiceSettingIdSet = newAddressDCRServiceSettingsMap.keySet(); 
      
      MSD_CORE_DCRService_DCR__c newAddressDCRServiceSetting = new MSD_CORE_DCRService_DCR__c();
      List<MSD_CORE_DCRService_DCR_Controlled_Field__c> addressControlledFieldsList = new List<MSD_CORE_DCRService_DCR_Controlled_Field__c>();
      //Should only be one... 
      for (Id settingId: newAddressDCRServiceSettingIdSet) {
           newAddressDCRServiceSetting = newAddressDCRServiceSettingsMap.get(settingId);
      }
       
      addressControlledFieldsList= 
           newAddressDCRServiceSettingsMap.get(newAddressDCRServiceSetting.Id).DCRService_DCR_Controlled_Fields__r;
       
      //Process Account Data: 
      String accountType='Account';
      Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
      Schema.SObjectType leadSchema = schemaMap.get(accountType);
      Map<String, Schema.SObjectField> accountObjfieldMap = leadSchema.getDescribe().fields.getMap();

      //Process Address Data: 
      String addressType='Address_vod__c';
      schemaMap = Schema.getGlobalDescribe();
      leadSchema = schemaMap.get(addressType);
      Map<String, Schema.SObjectField> addressObjfieldMap = leadSchema.getDescribe().fields.getMap();
             
      Savepoint sp = Database.setSavepoint();

      try{

         //Account DCR 
         Data_Change_Request_vod__c accountDCR = new Data_Change_Request_vod__c();
         accountDCR.RecordTypeId = RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Account_vod);
         accountDCR.Status_vod__c = newAccountDCRServiceSetting.MSD_CORE_DCR_Status__c;
         accountDCR.Result_vod__c = newAccountDCRServiceSetting.MSD_CORE_Result__c;
         accountDCR.Type_vod__c = newAccountDCRServiceSetting.MSD_CORE_Type__c;
         accountDCR.MSD_CORE_DCR_Status__c = newAccountDCRServiceSetting.MSD_CORE_DCR_User_Status__c;
         accountDCR.Network_Customer_Master_Mode_vod__c = 0;
         accountDCR.Account_vod__c = acct.Id;
         accountDCR.MSD_CORE_Application_Source__c = appSource;
         accountDCR.Notes_vod__c = acct.MSD_Core_Rep_Notes__c;

         insert accountDCR;
          
         //DCR Line Items
         List <Data_Change_Request_Line_vod__c> dcrlList = new List <Data_Change_Request_Line_vod__c>();
         
         for(MSD_CORE_DCRService_DCR_Controlled_Field__c controlledField : accountControlledFieldsList){
            
            Data_Change_Request_Line_vod__c dcrl = new Data_Change_Request_Line_vod__c();
            dcrl.Field_API_Name_vod__c = controlledField.MSD_CORE_Field_API_Name__c;
            dcrl.Field_Name_vod__c = accountObjfieldMap.get(controlledField.MSD_CORE_Field_API_Name__c).getDescribe().getLabel(); 
            Object val = acct.get(controlledField.MSD_CORE_Field_API_Name__c) ; 


            if ((val == null) || (val == '') ){
               dcrl.New_Value_vod__c = '';
            }else{
               Schema.DescribeFieldResult f = accountObjfieldMap.get(controlledField.MSD_CORE_Field_API_Name__c).getDescribe();
               dcrl.New_Value_vod__c = getStringValueOf(f,val ); 
             }
              
            dcrl.Result_vod__c = controlledField.MSD_CORE_Result__c;
            dcrl.Data_Change_Request_vod__c = accountDCR.Id;
            dcrl.Display_Order__c = controlledField.MSD_CORE_Sort_Order__c; 
             
            dcrlList.add(dcrl);
         } 
          
         insert dcrlList;
 
         //Process Address DCR and DCR Line Items 
         Data_Change_Request_vod__c addressDCR = new Data_Change_Request_vod__c();
         addressDCR.RecordTypeId = RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Address_vod);
         addressDCR.Status_vod__c = newAddressDCRServiceSetting.MSD_CORE_DCR_Status__c;
         addressDCR.Result_vod__c = newAddressDCRServiceSetting.MSD_CORE_Result__c;
         addressDCR.Type_vod__c = newAddressDCRServiceSetting.MSD_CORE_Type__c;
         addressDCR.MSD_CORE_DCR_Status__c = newAddressDCRServiceSetting.MSD_CORE_DCR_User_Status__c;
         addressDCR.Parent_Data_Change_Request_vod__c = accountDCR.Id;
         addressDCR.Network_Customer_Master_Mode_vod__c = 0;
         addressDCR.Address_vod__c = addr.Id;
         //addressDCR.Account_vod__c = acct.Id;
         addressDCR.MSD_CORE_Application_Source__c = appSource;
          
         insert addressDCR;
          
         List <Data_Change_Request_Line_vod__c> addressDCRLList = new List <Data_Change_Request_Line_vod__c>();
         
         for(MSD_CORE_DCRService_DCR_Controlled_Field__c controlledField : addressControlledFieldsList){
            
            Data_Change_Request_Line_vod__c addressDCRL = new Data_Change_Request_Line_vod__c();
            addressDCRL.Field_API_Name_vod__c = controlledField.MSD_CORE_Field_API_Name__c;
            addressDCRL.Field_Name_vod__c = addressObjfieldMap.get(controlledField.MSD_CORE_Field_API_Name__c).getDescribe().getLabel(); 
            Object val = addr.get(controlledField.MSD_CORE_Field_API_Name__c) ; 

            if ((val == null) || (val == '') ){
               addressDCRL.New_Value_vod__c = '';
            }else{
               Schema.DescribeFieldResult f = addressObjfieldMap.get(controlledField.MSD_CORE_Field_API_Name__c).getDescribe();
               addressDCRL.New_Value_vod__c = getStringValueOf(f,val ); 
             }
              
            addressDCRL.Result_vod__c = controlledField.MSD_CORE_Result__c;
            addressDCRL.Data_Change_Request_vod__c = addressDCR.id;
            addressDCRL.Display_Order__c = controlledField.MSD_CORE_Sort_Order__c;
             
            addressDCRLList.add(addressDCRL);
         } 

         insert addressDCRLList;
          
      }catch(exception ex){
         Database.rollback(sp);
         System.debug('Kevin: Error Occurred! ');
         throw new DCRServiceException('Insert Failed for the following Reason: ' + ex.getMessage() );
      } 
   }
          
            
   //Methods for Creating Affiliations         
            
   /* 
   Methods for Creating Affiliations
   KRB Release 6.0 5/15/2015
   */         
            
   public static void createNewAccountAffiliationDCRs (List<Child_Account_vod__c> newAffiliationList, String applicationName){  
 
      Map<Id, MSD_CORE_DCRService_DCR__c> newAccountAffiliationsDCRServiceSettingsMap 
          = new Map<Id, MSD_CORE_DCRService_DCR__c>();
      newAccountAffiliationsDCRServiceSettingsMap = MSD_CORE_DCRServiceGateway.retrieveNewAccountAffiliationsDCRServiceSettingsMap(countryCode);       
 
      Set <Id> newAccountAffiliationDCRServiceSettingIdSet = new Set<Id>();
      
      newAccountAffiliationDCRServiceSettingIdSet = newAccountAffiliationsDCRServiceSettingsMap.keySet(); 
      
      MSD_CORE_DCRService_DCR__c newAccountAffiliationDCRServiceSetting = new MSD_CORE_DCRService_DCR__c();
      List<MSD_CORE_DCRService_DCR_Controlled_Field__c> controlledFieldsList = new List<MSD_CORE_DCRService_DCR_Controlled_Field__c>();
      //Should only be one... 
      for (Id settingId: newAccountAffiliationDCRServiceSettingIdSet) {
           newAccountAffiliationDCRServiceSetting = newAccountAffiliationsDCRServiceSettingsMap.get(settingId);
       }
       
       controlledFieldsList= 
           newAccountAffiliationsDCRServiceSettingsMap.get(newAccountAffiliationDCRServiceSetting.Id).DCRService_DCR_Controlled_Fields__r;
       
      String type='Child_Account_vod__c';
      Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
      Schema.SObjectType leadSchema = schemaMap.get(type);
      Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
                                                                  
      SObjectUnitOfWork uow = new SObjectUnitOfWork(DCR_SOBJECTS);       
           
      for (Child_Account_vod__c affiliation: newAffiliationList){

         Data_Change_Request_vod__c dcr = new Data_Change_Request_vod__c();
         dcr.RecordTypeId = RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Child_Account_vod);
         dcr.Status_vod__c = newAccountAffiliationDCRServiceSetting.MSD_CORE_DCR_Status__c;
         dcr.Result_vod__c = newAccountAffiliationDCRServiceSetting.MSD_CORE_Result__c;
         dcr.Type_vod__c = newAccountAffiliationDCRServiceSetting.MSD_CORE_Type__c;
         dcr.MSD_CORE_DCR_Status__c = newAccountAffiliationDCRServiceSetting.MSD_CORE_DCR_User_Status__c;
         dcr.Network_Customer_Master_Mode_vod__c = 0;
         dcr.Account_vod__c = affiliation.Child_Account_vod__c;
         dcr.MSD_CORE_Application_Source__c = applicationName;
         uow.registerNew(dcr) ;
             
         for(MSD_CORE_DCRService_DCR_Controlled_Field__c controlledField : controlledFieldsList){
            Data_Change_Request_Line_vod__c dcrl = new Data_Change_Request_Line_vod__c();
            dcrl.Field_API_Name_vod__c = controlledField.MSD_CORE_Field_API_Name__c;
            dcrl.Field_Name_vod__c = fieldMap.get(controlledField.MSD_CORE_Field_API_Name__c).getDescribe().getLabel(); 
            Object val = affiliation.get(controlledField.MSD_CORE_Field_API_Name__c) ; 

            if ((val == null) || (val == '') ){
               dcrl.New_Value_vod__c = '';
            }else{
               Schema.DescribeFieldResult f = fieldMap.get(controlledField.MSD_CORE_Field_API_Name__c).getDescribe();
               dcrl.New_Value_vod__c = getStringValueOf(f,val );              
             }
             
            dcrl.Result_vod__c = controlledField.MSD_CORE_Result__c;
            uow.registerNew(dcrl, Data_Change_Request_Line_vod__c.Data_Change_Request_vod__c, dcr);
         } 
      }        

      uow.commitWork();
    }

            
       
    //Test Methods
    //New Account with Address:
    public Static void testCreateNewAddressDCR(){
       String prefix = 'New_Address_DRC';

       Address_vod__c addr1 = new Address_vod__c();
       addr1.Account_vod__c = '001K0000018Qku0IAC'; //TODO: make this work for all environments....
       addr1.Name = prefix + '-118 Matthew Drive';
       addr1.City_vod__c = prefix + '-Doylestown';
       addr1.State_vod__c = prefix + '-PA';
       addr1.DEA_vod__c = prefix + '-#12345';
       addr1.id = 'a01K000000G31RO'; //TODO: make this work for all environments....
       String appSource= 'Veeva CRM';
       createNewAddressDCR(addr1,appSource );
    }
        
   //New Hospital Account with Address:
    public Static void testCreateNewHospitalAccountAndAddressDCRs(){
       String prefix = '6_18_No1_New_Hospital_Account_and_Address_DRC_';
       
       Account acct1 = new Account();
       acct1.name = prefix + 'SomeHospital';
       
       acct1.Class_of_Trade_Owner_MRK__c = prefix + 'COT';
       acct1.Class_of_Trade_Sub_MRK__c = prefix + 'COTS';
       acct1.NPI_vod__c =prefix + '1234';
        acct1.id = '001K0000018QjnwIAC'; //TODO: make this work for all environments....
       
       acct1.RecordTypeId = RT.getId(Account.SObjectType, RT.Name.Hospital_vod);
       Address_vod__c addr1 = new Address_vod__c();
       addr1.Name = prefix + '118 Matthew Drive';
       addr1.City_vod__c = prefix + 'Doylestown';
       addr1.State_vod__c = prefix + 'PA';
       addr1.Physical_Address_MRK__c = true;
       addr1.id = 'a01K000000G31da'; //TODO: make this work for all environments....
       addr1.Phone_vod__c = '215-3611079' ;   
       String appSource = 'Veeva CRM';
        
       createNewAccountAndAddressDCRs(acct1,addr1,appSource );
   }    
    //New HCP Account with Address:
    public Static void testCreateNewAccountAndAddressDCRs(){
       String prefix = '6_25_1bb_New_AccandAddr_DRC_';
       //HBP
       Account acct1 = new Account();
       acct1.Preferred_First_Name_MRK__c = prefix + 'Kevin';
       acct1.Preferred_Last_Name_MRK__c = prefix + 'Ban1 chi';
       acct1.Class_of_Trade_Owner_MRK__c = prefix + 'COT';
       acct1.Class_of_Trade_Sub_MRK__c = prefix + 'COTS';
       acct1.id = '001K0000018Qku0IAC'; //TODO: make this work for all environments....
       
       acct1.RecordTypeId = RT.getId(Account.SObjectType, RT.Name.HCP);
       Address_vod__c addr1 = new Address_vod__c();
       addr1.Name = prefix + '118 Matthew Drive';
       addr1.City_vod__c = prefix + 'Doylestown';
       addr1.State_vod__c = prefix + 'PA';
       addr1.DEA_vod__c = prefix + '#12345';
       addr1.id = 'a01K000000G31RO'; //TODO: make this work for all environments....
           
       String appSource = 'Veeva CRM';
        
       createNewAccountAndAddressDCRs(acct1,addr1,appSource );
   }        
    
   public static String getStringValueOf(Schema.DescribeFieldResult f,Object val){
             
            if (f.getType() == Schema.DisplayType.String){
               return (String)val;
            }else if (f.getType() == Schema.DisplayType.BOOLEAN){
               return MSD_CORE_Convert.ToString((BOOLEAN)val);      
            }else if (f.getType() == Schema.DisplayType.INTEGER){
               return MSD_CORE_Convert.ToString((INTEGER)val);      
            }else if (f.getType() == Schema.DisplayType.DATE){
               return MSD_CORE_Convert.ToString((DATE)val);      
           }else if (f.getType() == Schema.DisplayType.DATETIME){
               return MSD_CORE_Convert.ToString((DATETIME)val);      
           }else if (f.getType() == Schema.DisplayType.DOUBLE){
               return MSD_CORE_Convert.ToString((DOUBLE)val);       
           }else{
               return (String)val; 
            }
   }
    

    public class DCRServiceException extends Exception{
    }

}