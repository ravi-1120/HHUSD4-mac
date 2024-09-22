public class MSD_CORE_DCR_Service_Layer_Test_Class {

//Test Class to test all the combinations possible in the 
//MSD_CORE_UpdateDCRStatus Trigger
     private static List<Schema.SObjectType> DCR_SOBJECTS =
       new Schema.SObjectType[] {
        Data_Change_Request_vod__c.SObjectType,
        Data_Change_Request_Line_vod__c.SObjectType };

    
    public static void createEditAccount(){

        
        
    }

    public static void createEditAddressResultsinSubmittedPreApprovedStatus(){
      
      //Org, Edit Address, NON GDGS Only Field       
      SObjectUnitOfWork uow = new SObjectUnitOfWork(DCR_SOBJECTS);       
      
      Data_Change_Request_vod__c addressDCR = new Data_Change_Request_vod__c();
      addressDCR.RecordTypeId = RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Address_vod);
      addressDCR.Type_vod__c = 'Edit_vod';
      addressDCR.Network_Customer_Master_Mode_vod__c = 0;
      addressDCR.Address_vod__c = 'a01K000000G31da'; //8712 Holde
      addressDCR.Account_vod__c = '001K0000018QjnwIAC'; //ABOUT WOMEN OBGYN -
      uow.registerNew(addressDCR) ;
        
        Data_Change_Request_Line_vod__c addressDCRL = new Data_Change_Request_Line_vod__c();
        addressDCRL.Field_API_Name_vod__c = 'State_vod__c';
        addressDCRL.Field_Name_vod__c = 'State'; 
        addressDCRL.New_Value_vod__c = 'XX';
        uow.registerNew(addressDCRL, Data_Change_Request_Line_vod__c.Data_Change_Request_vod__c, addressDCR);
        
      uow.commitWork();
    }

    
    
    public static void createEditAddressResultsinSubmittedSubmittedStatus(){
      
      //Org, Edit Address, 2 GDGS Only Fields       
      SObjectUnitOfWork uow = new SObjectUnitOfWork(DCR_SOBJECTS);       
      
      Data_Change_Request_vod__c addressDCR = new Data_Change_Request_vod__c();
      addressDCR.RecordTypeId = RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Address_vod);
      addressDCR.Type_vod__c = 'Edit_vod';
      addressDCR.Network_Customer_Master_Mode_vod__c = 0;
      addressDCR.Address_vod__c = 'a01K000000G31da'; //8712 Holde
      addressDCR.Account_vod__c = '001K0000018QjnwIAC'; //ABOUT WOMEN OBGYN -
      uow.registerNew(addressDCR) ;
        
        Data_Change_Request_Line_vod__c addressDCRL = new Data_Change_Request_Line_vod__c();
        addressDCRL.Field_API_Name_vod__c = 'Name';
        addressDCRL.Field_Name_vod__c = 'Address line 1'; 
        addressDCRL.New_Value_vod__c = '1538 Windmill Rd';
        uow.registerNew(addressDCRL, Data_Change_Request_Line_vod__c.Data_Change_Request_vod__c, addressDCR);
       

        addressDCRL = new Data_Change_Request_Line_vod__c();
        addressDCRL.Field_API_Name_vod__c = 'State_vod__c';
        addressDCRL.Field_Name_vod__c = 'State'; 
        addressDCRL.New_Value_vod__c = 'AB';
        uow.registerNew(addressDCRL, Data_Change_Request_Line_vod__c.Data_Change_Request_vod__c, addressDCR);
        
        
      uow.commitWork();
        
    }

    
    public static void createEditAddressResultsinSubmittedSubmittedMixTypeFieldsStatus(){
      
      //Org, Edit Address, 2 GDGS Only Fields       
      SObjectUnitOfWork uow = new SObjectUnitOfWork(DCR_SOBJECTS);       
      
      Data_Change_Request_vod__c addressDCR = new Data_Change_Request_vod__c();
      addressDCR.RecordTypeId = RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Address_vod);
      addressDCR.Type_vod__c = 'Edit_vod';
      addressDCR.Network_Customer_Master_Mode_vod__c = 0;
      addressDCR.Address_vod__c = 'a01K000000G31da'; //8712 Holde
      addressDCR.Account_vod__c = '001K0000018QjnwIAC'; //ABOUT WOMEN OBGYN -
      uow.registerNew(addressDCR) ;
        
        Data_Change_Request_Line_vod__c addressDCRL = new Data_Change_Request_Line_vod__c();
        addressDCRL.Field_API_Name_vod__c = 'Name';
        addressDCRL.Field_Name_vod__c = 'Address line 1'; 
        addressDCRL.New_Value_vod__c = '1538 Windmill Rd';
        uow.registerNew(addressDCRL, Data_Change_Request_Line_vod__c.Data_Change_Request_vod__c, addressDCR);
       

        addressDCRL = new Data_Change_Request_Line_vod__c();
        addressDCRL.Field_API_Name_vod__c = 'Zip_vod__c';
        addressDCRL.Field_Name_vod__c = 'Zip'; 
        addressDCRL.New_Value_vod__c = '19454';
        uow.registerNew(addressDCRL, Data_Change_Request_Line_vod__c.Data_Change_Request_vod__c, addressDCR);
        
        
      uow.commitWork();
   }


    
    
    
    public static void createEditAffilitation(){
        
    }

}