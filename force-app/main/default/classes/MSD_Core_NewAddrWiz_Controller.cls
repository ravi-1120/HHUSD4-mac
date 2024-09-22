public class MSD_Core_NewAddrWiz_Controller{

public String RT {get; set;}
public String RTName {get; set;}
public String AccountId{get; set;}
public List<String> addFields {get; set;}
public Address_vod__c Addobj {get;set;}
public Map<String,MSD_CORE_NAW_Field_Types__c> NAWAddFMap{get;set;} 
public Account Acc {get;set;}
public Object Add {get;set;}
public Boolean isActive {get; set;}
public Boolean showError {get; set;}

//Added for Lightning Switch
public string theme = UserInfo.getUiTheme();

    public MSD_Core_NewAddrWiz_Controller(ApexPages.StandardController controller) {
    
    RT = ApexPages.currentPage().getParameters().get('accRecTypeId');
    AccountId = ApexPages.currentPage().getParameters().get('accId');
    
    Acc = [Select Id,Name,Class_of_Trade_MRK__c,Merck_ID_MRK__c,Status_MRK__c from Account where Id =:AccountId]; 
    system.debug('Ankur Acc' + Acc);
    
    if(Acc.Status_MRK__c == 'ACTIVE'){
      isActive = true; 
      showError = false;
    }else{
      isActive = false; 
      showError = true;
    }
    
    RecordType r = [SELECT Name,IsPersonType FROM RecordType WHERE Id =:RT AND SobjectType = 'Account' AND IsActive = true];
    RTName = r.Name;

    addFields = new List<String>();
    for(MSD_CORE_NAW_Field_Types__c n : [SELECT Field_API_Name__c,Required__c FROM MSD_CORE_NAW_Field_Types__c WHERE Active__c = true AND Object_API_Name__c = 'Address' AND Profile__c = 'All Sales User Profiles' AND Address_Wizard__c = True AND Record_Type__c = :RTName ORDER BY Display_Order__c]) {
    addFields.add(n.Field_API_Name__c);
    }

    Addobj = new Address_vod__c();
   // for(String s : addFields)
   // Addobj.put(s, '');

    NAWAddFMap = new Map<String,MSD_CORE_NAW_Field_Types__c>();
    for(MSD_CORE_NAW_Field_Types__c NAWFT:[Select Field_API_Name__c,Required__c,Label__c FROM MSD_CORE_NAW_Field_Types__c WHERE Active__c = true AND Object_API_Name__c = 'Address' AND Profile__c = 'All Sales User Profiles' AND Address_Wizard__c = True AND Record_Type__c = :RTName ]){
    NAWAddFMap.put(NAWFT.Field_API_Name__c, NAWFT);
    }

    }
    
    public PageReference Cancel() { //Code to call the Home Page
    
       //Added for Lightning Update
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
    
    public PageReference Submit()
    {
        
         Addobj.Account_vod__c = AccountId;
         Addobj.Inactive_vod__c = true;
         
         //KRB 21R1.0 - added to address the noncompiant JavaScript List Button:
         //Validation use to fire in the JavaScript. Because this is not supported, adding it here now
         
        if(Acc.Status_MRK__c != 'ACTIVE'){
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Addresses can only be added to Active Accounts.'));
           return null;
        }
         
        
        
          //Person Accounts Validation Rule      
         If(RTName == 'HCP' || RTName == 'HBP'){
         if(Addobj.Mailing_vod__c == false || Addobj.Mailing_vod__c == null ) {
              if(Addobj.Business_vod__c == false || Addobj.Business_vod__c == null ){
                   if(Addobj.Home_and_Office_MRK__c == false  || Addobj.Home_and_Office_MRK__c == null){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select atleast 1 Address Type'));
                        return null;
                }
             }
           }
         }
         
         
          //Business Accounts Validation Rule 
         If(RTName == 'Organization_vod' || RTName == 'Pharmacy_vod' || RTName == 'Hospital_vod'){
         if(Addobj.Mailing_vod__c == false || Addobj.Mailing_vod__c == null ) {
              if(Addobj.Physical_Address_MRK__c == false || Addobj.Physical_Address_MRK__c == null ){
                       ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select atleast 1 Address Type'));
                        return null;
             }
           }
         }
         
         
         
         
         
         system.debug('New Address' + Addobj);
         
         System.Savepoint sp = Database.setSavepoint();
          
      try {    
          insert Addobj;
          MSD_CORE_DCRService.createNewAddressDCR (Addobj, 'Veeva CRM');  // calling Kevin B Service
          
          } catch (Exception ex) {
          Database.rollback(sp);
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
   
          PageReference pg = new PageReference('/apex/MSD_CORE_Addr_Confirmation_VF?AddId='+Addobj.Id);
          return pg;
       
         
    }
    @AuraEnabled
    public static List<String> addFields(String RTName)
    {
        List<String> addFields = new List<String>();
    for(MSD_CORE_NAW_Field_Types__c n : [SELECT Field_API_Name__c,Required__c FROM MSD_CORE_NAW_Field_Types__c WHERE Active__c = true AND Object_API_Name__c = 'Address' AND Profile__c = 'All Sales User Profiles' AND Address_Wizard__c = True AND Record_Type__c = :RTName ORDER BY Display_Order__c]) {
    addFields.add(n.Field_API_Name__c);
    }
        System.debug(addFields);
        return addFields;
        
    }
    
    @AuraEnabled
    public static Map<String,MSD_CORE_NAW_Field_Types__c> NAWAddFMap(String RTName)
    {
        Map<String,MSD_CORE_NAW_Field_Types__c> NAWAddFMap = new Map<String,MSD_CORE_NAW_Field_Types__c>();
    for(MSD_CORE_NAW_Field_Types__c NAWFT:[Select Field_API_Name__c,Required__c,Label__c FROM MSD_CORE_NAW_Field_Types__c WHERE Active__c = true AND Object_API_Name__c = 'Address' AND Profile__c = 'All Sales User Profiles' AND Address_Wizard__c = True AND Record_Type__c = :RTName ]){
    NAWAddFMap.put(NAWFT.Field_API_Name__c, NAWFT);
    }
     return NAWAddFMap; 
    }
    
    @AuraEnabled
    public static Account Accdetails(String AccId)
    {
       Account Acc =  new Account();
        Acc = [Select Id,Name,Class_of_Trade_MRK__c,Merck_ID_MRK__c,Status_MRK__c from Account where Id =:AccId]; 
   
     return Acc; 
    }
    
     @AuraEnabled
    public static void CreateDCR(Address_vod__c Addob)
    {
        MSD_CORE_DCRService.createNewAddressDCR (Addob, 'Veeva CRM');  
    }


}