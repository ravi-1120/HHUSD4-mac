/*
   KRB Release 11.0 - 1/11/2018 - Controller for the Additional AE Case Contact Search Component: MSD_CORE_Additional_Case_Contact_Search.vfp 
*/

public class MSD_CORE_AE_Case_Con_Search_Extension {

   //TODO:Get all Error Messages in as Labels
   public String obj{get;set;}
   public String firstName{get;set;}
   public String lastName{get;set;}
   public String city{get;set;}
   public String phone{get;set;}
   public String zip{get;set;}
   public Id additionalCaseContactId{get;set;}
   public List<MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper> retWrapper{get;set;}
   public Case currentCase{get;set;}
   public Map<String,String> rtMap = new Map<String,String>();
   public Boolean refreshPage {get; set;}
   public Boolean hasError { get { return ApexPages.hasMessages(); } }
   public String additionalAECaseContactRecordTypeName { get; set; }
   public String additionalAECaseContactRecordTypeId { get; set; }  
   public Service_Cloud_Settings_MVN__c settings {get;set;}
   public String accountType {get;set;}

           
   public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('All','All')); 
        options.add(new SelectOption('CONSUMER','CONSUMER')); 
        options.add(new SelectOption('EMPLOYEE','EMPLOYEE')); 
        options.add(new SelectOption('HEALTHCARE BUSINESS PROF','HEALTHCARE BUSINESS PROF'));
        options.add(new SelectOption('INDIV HEALTHCARE PROF','INDIV HEALTHCARE PROF'));
        return options; 
    }
                   
    // ---------------------
           
   public MSD_CORE_AE_Case_Con_Search_Extension (ApexPages.StandardController cont){
      settings = Service_Cloud_Settings_MVN__c.getInstance();
      currentCase = (Case)cont.getRecord();        
      refreshPage=false;
      accountType = 'All';
       
   }
    
   public MSD_CORE_AE_Case_Con_Search_Extension getCont(){
      return this;
   }
    
   public PageReference createNew(){
       
      if (String.isBlank(lastName)){  
         ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, Label.MSD_CORE_AE_Contact_Search_Required_Flds));
         return null;
      }
        
      additionalAECaseContactRecordTypeName = settings.Adverse_Event_Record_Type_MVN__c; 
      additionalAECaseContactRecordTypeId = [select Id from RecordType where SObjectType='MSD_CORE_AE_Contact__c' and DeveloperName = :additionalAECaseContactRecordTypeName].Id; 
       
      List<MSD_CORE_AE_Contact__c> ins = new List<MSD_CORE_AE_Contact__c>();
      MSD_CORE_AE_Contact__c aeContact = new MSD_CORE_AE_Contact__c();
                      
       if(!String.isBlank(firstName)){
          aeContact.MSD_CORE_First_Name__c = firstName; 
       } 
       if(!String.isBlank(lastName)){
          aeContact.MSD_CORE_Last_Name__c = lastName; 
       } 
      
	  aeContact.MSD_CORE_Adverse_Event__c = currentCase.Id;
      aecontact.RecordTypeId = additionalAECaseContactRecordTypeId;   
      
       if(!String.isBlank(phone)){
           aecontact.MSD_CORE_Phone__c = phone;
       }
       
       //KRB added 4/5/2018 
        if(!String.isBlank(city)){
           aecontact.MSD_CORE_City__c = city;
       }
      
    
       if(!String.isBlank(zip)){
           aecontact.MSD_CORE_Postal_Code__c = zip;
       }
                
      ins.add(aeContact);

      try{
         
        Database.SaveResult[] srList = Database.insert(ins);
        
        for (Database.SaveResult sr : srList) {
           if (sr.isSuccess()) {
               // Operation was successful, so get the ID of the record that was processed
               System.debug('KRB: Successfully inserted AE Case Contact.  ID: ' + sr.getId());
               additionalCaseContactId = sr.getId();
           }
           else {
               // Operation failed, so get all errors                
               for(Database.Error err : sr.getErrors()) {
               System.debug('KRB: The following error has occurred.');                    
               System.debug(err.getStatusCode() + ': ' + err.getMessage());
               System.debug('KRB: fields that affected this error: ' + err.getFields());
               }
          }
       } 
                   
      }catch(Exception e){
          //No Reason to do this below. Apex handles Throwing the Exception to the component. 
          //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
          return null;
      }
       
       refreshPage=true;
       return null;
   }
   
   public void create(){

      if (retWrapper == null){
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.MSD_CORE_AE_Contact_Search_Search_And_Select));
           return;
      }
        
      boolean recordSelected = False;
      for(MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper w : retWrapper){
         if(w.include){
            recordSelected = true;
         }
      }
        
      if(!recordSelected){
         ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, Label.MSD_CORE_AE_Contact_Search_Select_Record));
         return;
      }
       
      additionalAECaseContactRecordTypeName = settings.Adverse_Event_Record_Type_MVN__c; //'Adverse_Event_MVN'
      additionalAECaseContactRecordTypeId = [select Id from RecordType where SObjectType='MSD_CORE_AE_Contact__c' and DeveloperName = :additionalAECaseContactRecordTypeName].Id; 

      List<MSD_CORE_AE_Contact__c> ins = new List<MSD_CORE_AE_Contact__c>();
      
      for(MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper w : retWrapper){
            if(w.include){
                
                MSD_CORE_AE_Contact__c aeContact = new MSD_CORE_AE_Contact__c();
                
                aeContact.MSD_CORE_Adverse_Event__c = currentCase.Id;
                
                if(!String.isBlank(w.firstName)){
                   aeContact.MSD_CORE_First_Name__c = w.firstName;
                }
                if(!String.isBlank(w.lastName)){
                   aeContact.MSD_CORE_Last_Name__c = w.lastName;
                }                
                if(!String.isBlank(w.addressLine1)){
                   aeContact.MSD_CORE_Address_Line_1__c = w.addressLine1;
                }                
                if(!String.isBlank(w.city)){
                   aeContact.MSD_CORE_City__c = w.city;
                }                
                if(!String.isBlank(w.state)){
                   aeContact.MSD_CORE_State_Province__c = w.state;
                }                
                if(!String.isBlank(w.zip)){
                   aeContact.MSD_CORE_Postal_Code__c = w.zip;
                }                
                if(!String.isBlank(w.phone)){
                   aeContact.MSD_CORE_Phone__c = w.phone;
                }  
                
                aeContact.RecordTypeId = additionalAECaseContactRecordTypeId;
                
                ins.add(aeContact);
                
            }
        }
        
        try{
           insert ins;
        }catch(DMLException e){
           //Note: SF will handle displaying the Error on the VF Page. Just need to have the Try/Catch
           //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
           return;
        }
       
        refreshPage=true;
        return;
    }
}