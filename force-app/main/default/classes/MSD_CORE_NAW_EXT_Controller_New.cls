public without sharing class MSD_CORE_NAW_EXT_Controller_New{

/** Apex Class controls
*   VisualForce : MSD_Core_NAW_VF_New
*   
*/

/************** Variable Definitions *********************/

Set<String> recordTypes = new Set<String>(); //Distinct Record Types in MSD_CORE_NAW_Field_Types__c Object.
public Account Accobj {get;set;}
//public Contact Conobj {get;set;}
public Address_vod__c Addobj {get;set;}
public Id RT {get;set;}
public Id IntegrationId {get;set;}
public boolean IsPerson {get;set;}
public boolean Submit_btn {get;set;}
public List<String> accFields {get; set;}
public List<String> addFields {get; set;}
    
//Added for Lightning
public string theme{get;set;}

public String selRT {get; set;} //Account Record Type Selected by the Rep - MSD_Core_NAW_RecordType_Selection_VF 
public String sRT {get; set;} //Account Record Type Selected by the Rep - MSD_Core_NAW_VF
public List<MSD_CORE_NAW_Field_Types__c> NAW_Fields_Accounts {get;set;}
public List<MSD_CORE_NAW_Field_Types__c> NAW_Fields_Address {get;set;}

public boolean concent{get;set;}
public string consent_msg {get;set;}

public string Instructions{get;set;}

public Map<String ,String> AccMap {get;set;}
public Map<String,MSD_CORE_NAW_Field_Types__c > AccFieldsMap{get;set;}      


public Map<String,MSD_CORE_NAW_Field_Types__c> NAWAccFMap{get;set;} 
public Map<String,MSD_CORE_NAW_Field_Types__c> NAWAddFMap{get;set;} 
        

/************** Controller for MSD_Core_NAW_VF_New Page  *********************/

public MSD_CORE_NAW_EXT_Controller_New(){
sRT = ApexPages.currentPage().getParameters().get('recType');
//System.debug('Selected Record Type inside the constructor...' + sRT);

RecordType r = [SELECT Id, IsPersonType FROM RecordType WHERE Name = :sRT and SobjectType = 'Account' and IsActive = true LIMIT 1];
RT = r.Id;
IsPerson = r.IsPersonType;
//concent = false;
Submit_btn =true;


New_Account_Wizard__c Ins = [Select Description__c,Name,Instructions__c FROM New_Account_Wizard__c where Record_Type__c = :sRT ];
Instructions = Ins.Instructions__c;

User u = [Select Id FROM User WHERE Username LIKE 'integration@merck.com%' LIMIT 1];
IntegrationId = u.Id;


Accobj = new Account(RecordTypeId = RT);
//Conobj = new Contact();
Addobj = new Address_vod__c();
consent_msg  = System.Label.MSD_CORE_NAW_Consent;

system.debug('Ankur Consent Checkbox ' +Accobj.Consent_MRK__c );

accFields = new List<String>();
for(MSD_CORE_NAW_Field_Types__c n : [SELECT Field_API_Name__c,Required__c FROM MSD_CORE_NAW_Field_Types__c WHERE Active__c = true AND Object_API_Name__c = 'Account' AND Profile__c = 'All Sales User Profiles' AND Address_Wizard__c = False AND Record_Type__c = :sRT ORDER BY Display_Order__c]) {
    accFields.add(n.Field_API_Name__c);
}

for(String s : accFields)
    Accobj.put(s, '');


addFields = new List<String>();
for(MSD_CORE_NAW_Field_Types__c n : [SELECT Field_API_Name__c,Required__c FROM MSD_CORE_NAW_Field_Types__c WHERE Active__c = true AND Object_API_Name__c = 'Address' AND  Profile__c = 'All Sales User Profiles' AND Address_Wizard__c = False AND Record_Type__c = :sRT ORDER BY Display_Order__c]) {
    AddFields.add(n.Field_API_Name__c);
}

for(String s : addFields)
    Addobj.put(s, '');


NAWAccFMap = new Map<String,MSD_CORE_NAW_Field_Types__c>();
for(MSD_CORE_NAW_Field_Types__c NAWFT:[Select Field_API_Name__c,Required__c,Label__c FROM MSD_CORE_NAW_Field_Types__c WHERE Active__c = true AND Object_API_Name__c = 'Account' AND Profile__c = 'All Sales User Profiles' AND Address_Wizard__c = False AND Record_Type__c = :sRT]){
NAWAccFMap.put(NAWFT.Field_API_Name__c, NAWFT);
}


NAWAddFMap = new Map<String,MSD_CORE_NAW_Field_Types__c>();
for(MSD_CORE_NAW_Field_Types__c NAWFT:[Select Field_API_Name__c,Required__c,Label__c FROM MSD_CORE_NAW_Field_Types__c WHERE Active__c = true AND Object_API_Name__c = 'Address' AND Profile__c = 'All Sales User Profiles' AND Address_Wizard__c = False AND Record_Type__c = :sRT]){
NAWAddFMap.put(NAWFT.Field_API_Name__c, NAWFT);
}

//Added for Lightning Upgrade:
theme = UserInfo.getUiTheme();
    
//system.debug('Ankur ' + NAW_Fields_Accounts);

/**** Commented 7/11/2015
NAW_Fields_Address = [SELECT Field_API_Name__c,Required__c FROM MSD_CORE_NAW_Field_Types__c WHERE Active__c = true AND Object_API_Name__c = 'Address' AND Profile__c = 'All Sales User Profiles' AND Record_Type__c = :sRT ORDER BY Display_Order__c];

    AccMap = new Map<String,String>();
    AccFieldsMap = new Map<String,MSD_CORE_NAW_Field_Types__c >();
    
     
      for(MSD_CORE_NAW_Field_Types__c FT:[SELECT Field_API_Name__c,Required__c FROM MSD_CORE_NAW_Field_Types__c WHERE Active__c = true AND Object_API_Name__c = 'Account' AND Profile__c = 'All Sales User Profiles' AND Record_Type__c = :sRT ORDER BY Display_Order__c])
      {
            AccMap.put(FT.Field_API_Name__c,'');
            AccFieldsMap.put(FT.Field_API_Name__c,FT);
        } 
***/        
}
             
public PageReference Submit()
    {
        
         System.debug('Acc Data' + Accobj);
          System.debug('Address Data' + Addobj);
          
          Accobj.OwnerId = IntegrationId; //Assigning the Owner of the Account as Integration User.
          
          if(IsPerson){ 
          Accobj.Preferred_First_Name_MRK__c = Accobj.Preferred_First_Name_MRK__c.capitalize();
          Accobj.Preferred_Last_Name_MRK__c = Accobj.Preferred_Last_Name_MRK__c.capitalize();
          
          if(Accobj.Preferred_Middle_Name_MRK__c != null){
          Accobj.Preferred_Middle_Name_MRK__c = Accobj.Preferred_Middle_Name_MRK__c.capitalize();
          }
          }
          else
          {
          AccObj.Name = AccObj.Name.toUpperCase();
          }

                  
          Accobj.Status_MRK__c = 'Pending'; //US Specific
         // Accobj.Status_Reason_MRK__c = 'PENDING'; //Not Populating this field because PENDING is not present in CM. This field is Inactive Status Reason Field.
                 
          
          if(IsPerson){         
          Accobj.LastName =  Accobj.Preferred_Last_Name_MRK__c;
          Accobj.FirstName = Accobj.Preferred_First_Name_MRK__c;
          
                   
          AccObj.Class_of_Trade_Owner_MRK__c = Accobj.Class_of_Trade_Sub_MRK__c;
          Addobj.Business_vod__c = true;
          }
          else
          {
          Addobj.Physical_Address_MRK__c = true;
          }
         
          System.Savepoint sp = Database.setSavepoint();
          
          try{
          insert Accobj;
          
          Addobj.Account_vod__c = Accobj.Id;
          Addobj.Inactive_vod__c = true;
          
          insert Addobj;
          
          MSD_CORE_DCRService.createNewAccountAndAddressDCRs (Accobj, Addobj,'Veeva CRM'); // calling Kevin B Service

          }
          catch (Exception ex) {
          Database.rollback(sp);
          Accobj = Accobj.clone(false); // Code added to prevent caching. Error "Cannot Specify Id in an Internal Call Error". Step to replicate is i.) Fill the form with First Name as less than 2 char 2.) Submit the form with correction
          Addobj = Addobj.clone(false); // Code added to prevent caching. Error "Cannot Specify Id in an Internal Call Error". Step to replicate is i.) Fill the form with First Name as less than 2 char 2.) Submit the form with correction
          String errorMessage = ex.getMessage();
          System.debug('Ankur ' + errorMessage );
          Integer occurence;
          if (ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
          occurence = errorMessage.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 34;
          errorMessage = errorMessage.mid(occurence, errorMessage.length());
          occurence = errorMessage.lastIndexOf(':');
          errorMessage = errorMessage.mid(0, occurence);
          }
          else {
          errorMessage = ex.getMessage();
          }

          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
          return null; //line added to stay on the same page in case of a validation error.
          }

          
          system.debug('New Account ' + Accobj);
          system.debug('New Address' + Addobj);
          
          PageReference pg = new PageReference('/apex/MSD_Core_NAW_Confirmation_VF?AccId='+Accobj.Id);
          return pg;
         
    }

    public PageReference Cancel() { //Code to call the Home Page
        //Updated for Lightning Upgrade: 
        if(theme == 'Theme3'){
           PageReference HomePage = new PageReference('/home/home.jsp'); 
           HomePage.setRedirect(true);
           return HomePage;
        }else{
           PageReference HomePage = new PageReference('/lightning/page/home'); 
           HomePage.setRedirect(true);
           return HomePage;
        }
   }  
   
public void changeSubmitBtn(){
System.debug('Submit Button...' + Submit_btn);
Submit_btn = False;
System.debug('Submit Button...' + Submit_btn);
}             

}