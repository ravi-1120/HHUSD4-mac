/*
KRB Release 11.0 - 1/11/2018 
Controller for the Additional AE Case Contact Results Component: MSD_CORE_Record_Selector 
/**********************************************************************************************
Modified By  :  Haritha
Usage   :  Added few @AuraEnabled methods to use in MSD_CORE_CC_AddlCaseContactssSearch Aura Cmp.
*********************************************************************************************/


public class MSD_CORE_AE_Contact_Record_Selector_Cont {

    public MSD_CORE_AE_Case_Con_Search_Extension cont{get;set;}
    public String contfirstName{get;set;}
    public String contlastName{get;set;}
    public String contPhone{get;set;}
    public String contZip{get;set;}
    public String contCity{get;set;}
    public String contType{get;set;}
    public String sObjName{get;set;}
    public String search{get;set;}
    public Service_Cloud_Settings_MVN__c settings {get;set;}
    
        
    //following the same design as the Customer Search - can never be greater than 200.
    public String soqlLimitStmt = ' LIMIT 201';
    
    //private static Integer SEARCHLIMIT = (Integer) Service_Cloud_Settings_MVN__c.getInstance().MSD_CORE_AE_Case_Contact_SearchMaxResult__c; // can never be greater than 200 due to sosl limits
    private static Integer SEARCHLIMIT = 100;
    static {
        if(SEARCHLIMIT == null || SEARCHLIMIT < 1) {
            SEARCHLIMIT = 100;
        }
        SEARCHLIMIT=Math.min(SEARCHLIMIT, 200);
    } 
    
    public MSD_CORE_AE_Contact_Record_Selector_Cont(){  
        System.debug('in constructor');
    }
    
    public List<Wrapper> getObjList(){
       return cont.retWrapper;
    }
    
    public void runQuery(){
         
       //Make sure we have at least one condition for the WHERE cause. 
       if (String.isBlank(contfirstName) && String.isBlank(contlastName) && String.isBlank(contZip) && String.isBlank(contPhone)&& String.isBlank(contCity)){
          //Clear out the List populating the Grid
          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.MSD_CORE_AE_Contact_Search_Enter_Search_Criteria));
          cont.retWrapper = new List<Wrapper>();
          return;
       }

       if(!String.isBlank(contZip) || !String.isBlank(contCity)){
          runQueryOnAddress(); 
       }else{
          runQueryOnAccount(); 
       }
    }   
    
    private void runQueryOnAccount(){

       cont.retWrapper = new List<Wrapper>();
        
       String q;
       String addressSubQuery = ' SELECT Name, City_vod__c, State_vod__c, Zip_vod__c FROM Address_vod__r WHERE Inactive_vod__c = false ';
       String selectStmt = 'SELECT firstName, lastName, Preferred_First_Name_MRK__c, Preferred_Last_Name_MRK__c,  phone, (' + addressSubQuery + ') FROM Account ';
       String whereClause = ' ';
       List<SObject> objList = new List<SObject>();
        
       if (!String.isBlank(contfirstName)){
          //whereClause = 'WHERE firstName = \'' + String.escapeSingleQuotes(contfirstName) + '\'  ';  
          whereClause = 'WHERE ((firstName = \'' + String.escapeSingleQuotes(contfirstName) + '\') or (Preferred_First_Name_MRK__c = \'' + 
                String.escapeSingleQuotes(contfirstName) + '\'))  ';  
       }       
        
       if (!String.isBlank(contlastName)){
          if(String.isBlank(whereClause)){
             whereClause = 'WHERE ((lastName = \'' + String.escapeSingleQuotes(contlastName) + '\') or (Preferred_Last_Name_MRK__c = \'' 
                    + String.escapeSingleQuotes(contlastName) + '\'))';
          }else{
             whereClause = whereClause + 'AND ((lastName = \'' + String.escapeSingleQuotes(contlastName) + '\') or (Preferred_Last_Name_MRK__c = \'' 
                    + String.escapeSingleQuotes(contlastName) + '\'))';
          }
       }       
        
       if (!String.isBlank(contPhone)){
          if(String.isBlank(whereClause)){
                whereClause = 'WHERE phone = \'' + String.escapeSingleQuotes(contPhone) + '\'  ';
          }else{
                whereClause = whereClause + 'AND phone = \'' + String.escapeSingleQuotes(contPhone) + '\'  ';
          }
       }   
       
       if (!String.isBlank(contType)){
       
           if(contType != 'All'){ //if All, no need for the Filter.
               if(contType == 'CONSUMER'){
                  if(String.isBlank(whereClause)){
                     whereClause = 'WHERE Class_of_Trade_MRK__c = \'CONSUMER\'  ';
                  }else{
                     whereClause = whereClause + 'AND Class_of_Trade_MRK__c = \'CONSUMER\'  ';
                  }
               }
               if(contType == 'EMPLOYEE'){
                  if(String.isBlank(whereClause)){
                     whereClause = 'WHERE Class_of_Trade_MRK__c = \'EMPLOYEE\'  ';
                  }else{
                     whereClause = whereClause + 'AND Class_of_Trade_MRK__c = \'EMPLOYEE\'  ';
                  }
               }
               if(contType == 'HEALTHCARE BUSINESS PROF'){
                  if(String.isBlank(whereClause)){
                     whereClause = 'WHERE Class_of_Trade_MRK__c = \'HEALTHCARE BUSINESS PROF\'  ';
                  }else{
                     whereClause = whereClause + 'AND Class_of_Trade_MRK__c = \'HEALTHCARE BUSINESS PROF\'  ';
                  }
               }
               if(contType == 'INDIV HEALTHCARE PROF'){
                  if(String.isBlank(whereClause)){
                     whereClause = 'WHERE Class_of_Trade_MRK__c = \'INDIV HEALTHCARE PROF\'  ';
                  }else{
                     whereClause = whereClause + 'AND Class_of_Trade_MRK__c = \'INDIV HEALTHCARE PROF\'  ';
                  }
               }
           } 
       }   

       q = selectStmt + whereClause + soqlLimitStmt; 
        
       System.debug('KRB: DEBUG: Select Statement: ' + q);

       try{
          objList = Database.query(q);
       }catch(Exception e){
          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
          return;
       }
        
       System.debug('KRB: DEBUG: Count in objList: ' + objList.size());
        
       if(objList.isEmpty()){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.MSD_CORE_AE_Contact_Search_No_Records_Found));
            cont.retWrapper = new List<Wrapper>();
            return;
       }
        
       if(objList.size() > SEARCHLIMIT){
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.Too_Many_Results));
           cont.retWrapper = new List<Wrapper>();
           return;
       }
 
       try{
           for(SObject obj : objList){
               Account acct = (Account)obj;
               
               List<Address_vod__c> addressList = new List<Address_vod__c>();
               addressList = acct.Address_vod__r;
               
               if(addressList.isEmpty()){
                    Wrapper wrapObj = new Wrapper();
                    wrapObj.firstName = acct.Preferred_First_Name_MRK__c;
                    wrapObj.lastName = acct.Preferred_Last_Name_MRK__c;
                    wrapObj.phone = acct.phone;
                    cont.retWrapper.add(wrapObj);
               }else{
                  for(Address_vod__c addr: acct.Address_vod__r){
                     cont.retWrapper.add(fillAddress(addr, acct));
                  }
               }
           }
            
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Issue returning results: '  + e.getMessage()));
            cont.retWrapper = new List<Wrapper>();
            return;
        }
        
    }
    
    private void runQueryOnAddress(){
                
        cont.retWrapper = new List<Wrapper>();
        
        String q;
        //String addressSubQuery = ' SELECT Name, City_vod__c, State_vod__c, Zip_vod__c from Address_vod__r ';
        String selectStmt = 'SELECT Name, City_vod__c, State_vod__c, Zip_vod__c, Account_vod__r.Preferred_First_Name_MRK__c, Account_vod__r.Preferred_Last_Name_MRK__c, Account_vod__r.id, Account_vod__r.lastName, Account_vod__r.firstName, Account_vod__r.phone FROM Address_vod__c ';
        String whereClause = ' ';
        List<SObject> objList = new List<SObject>();

        if (!String.isBlank(contfirstName)){
            //whereClause = 'WHERE Account_vod__r.firstName = \'' + String.escapeSingleQuotes(contfirstName) + '\'  ';  
            whereClause = 'WHERE ((Account_vod__r.firstName = \'' + String.escapeSingleQuotes(contfirstName) + '\') or (Account_vod__r.Preferred_First_Name_MRK__c = \'' + 
                String.escapeSingleQuotes(contfirstName) + '\'))  ';  

        }       
        
        if (!String.isBlank(contlastName)){
            if(String.isBlank(whereClause)){
                //whereClause = 'WHERE Account_vod__r.lastName = \'' + String.escapeSingleQuotes(contlastName) + '\'  ';
                whereClause = 'WHERE ((Account_vod__r.lastName = \'' + String.escapeSingleQuotes(contlastName) + '\') or (Account_vod__r.Preferred_Last_Name_MRK__c = \'' 
                    + String.escapeSingleQuotes(contlastName) + '\'))';

            }else{
               // whereClause = whereClause + 'AND Account_vod__r.lastName = \'' + String.escapeSingleQuotes(contlastName) + '\'  ';
               whereClause = whereClause + 'AND ((Account_vod__r.lastName = \'' + String.escapeSingleQuotes(contlastName) + '\') or (Account_vod__r.Preferred_Last_Name_MRK__c = \'' 
                    + String.escapeSingleQuotes(contlastName) + '\'))';
            }
        }       
        
        if (!String.isBlank(contPhone)){
            if(String.isBlank(whereClause)){
                whereClause = 'WHERE Account_vod__r.phone = \'' + String.escapeSingleQuotes(contPhone) + '\'  ';
            }else{
                whereClause = whereClause + 'AND Account_vod__r.phone = \'' + String.escapeSingleQuotes(contPhone) + '\'  ';
            }
        }       

        if (!String.isBlank(contZip)){
            if(String.isBlank(whereClause)){
                whereClause = 'WHERE Zip_vod__c = \'' + String.escapeSingleQuotes(contZip) + '\'  ';
            }else{
                whereClause = whereClause + 'AND Zip_vod__c = \'' + String.escapeSingleQuotes(contZip) + '\'  ';
            }
        }
        
        if (!String.isBlank(contCity)){
            if(String.isBlank(whereClause)){
                whereClause = 'WHERE City_vod__c = \'' + String.escapeSingleQuotes(contCity) + '\'  ';
            }else{
                whereClause = whereClause + 'AND City_vod__c = \'' + String.escapeSingleQuotes(contCity) + '\'  ';
            }
        } 
        
        
        //Account Type Filter
        if (!String.isBlank(contType)){
       
           if(contType != 'All'){ //if All, no need for the Filter.
               if(contType == 'CONSUMER'){
                  if(String.isBlank(whereClause)){
                     whereClause = 'WHERE Account_vod__r.Class_of_Trade_MRK__c = \'CONSUMER\'  ';
                  }else{
                     whereClause = whereClause + 'AND Account_vod__r.Class_of_Trade_MRK__c = \'CONSUMER\'  ';
                  }
               }
               if(contType == 'EMPLOYEE'){
                  if(String.isBlank(whereClause)){
                     whereClause = 'WHERE Account_vod__r.Class_of_Trade_MRK__c = \'EMPLOYEE\'  ';
                  }else{
                     whereClause = whereClause + 'AND Account_vod__r.Class_of_Trade_MRK__c = \'EMPLOYEE\'  ';
                  }
               }
               if(contType == 'HEALTHCARE BUSINESS PROF'){
                  if(String.isBlank(whereClause)){
                     whereClause = 'WHERE Account_vod__r.Class_of_Trade_MRK__c = \'HEALTHCARE BUSINESS PROF\'  ';
                  }else{
                     whereClause = whereClause + 'AND Account_vod__r.Class_of_Trade_MRK__c = \'HEALTHCARE BUSINESS PROF\'  ';
                  }
               }
               if(contType == 'INDIV HEALTHCARE PROF'){
                  if(String.isBlank(whereClause)){
                     whereClause = 'WHERE Account_vod__r.Class_of_Trade_MRK__c = \'INDIV HEALTHCARE PROF\'  ';
                  }else{
                     whereClause = whereClause + 'AND Account_vod__r.Class_of_Trade_MRK__c = \'INDIV HEALTHCARE PROF\'  ';
                  }
               }
           } 
       }   

        
        //add the last Filter 
        if(String.isBlank(whereClause)){
           whereClause = 'WHERE Inactive_vod__c = false';
        }else{
           whereClause = whereClause + 'AND Inactive_vod__c = false';
        }
       
        q = selectStmt + whereClause + soqlLimitStmt; 
        
        System.debug('KRB: DEBUG: Select Statement: ' + q);

        try{
           objList = Database.query(q);
        }catch(Exception e){
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
           return;
        }
        
        System.debug('KRB: DEBUG: Count in objList: ' + objList.size());
        
        if(objList.isEmpty()){
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.MSD_CORE_AE_Contact_Search_No_Records_Found));
           cont.retWrapper = new List<Wrapper>();
           return;
        }
        
        if(objList.size() > SEARCHLIMIT){
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.Too_Many_Results));
           cont.retWrapper = new List<Wrapper>();
           return;
        }
        
        
        try{
           for(SObject obj : objList){
               Address_vod__c addr = (Address_vod__c)obj;
              
                    cont.retWrapper.add(fillAddress(addr));
               
           }
            
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Issue returning results: '  + e.getMessage()));
            cont.retWrapper = new List<Wrapper>();
            return;
        }   
    }
        
    public class Wrapper{
        @AuraEnabled
        public SObject obj{get;set;}
         @AuraEnabled
        public boolean include{get;set;}
         @AuraEnabled
        public String accessLevel{get;set;}
         @AuraEnabled
        public String addressLine1{get;set;}
         @AuraEnabled
        public String city{get;set;}
         @AuraEnabled
        public String state{get;set;}
         @AuraEnabled
        public String zip{get;set;}
         @AuraEnabled
        public String firstName{get;set;}
         @AuraEnabled
        public String lastName{get;set;}
         @AuraEnabled
        public String phone{get;set;}
        
       
        public Wrapper(SObject objIn){
            obj = objIn;
        }
        public Wrapper(){
            
        }    
        
    }
    
    @AuraEnabled    
    public static List<Wrapper> runQueryOnAddressLtg(String JSONFields, String contType){
        //Map<String, String> mapSearchFields = JSON.deserializeUntyped(JSONFields);
        Map<String, Object> mapSearchFields = (Map<String, Object>)JSON.deserializeUntyped(JSONFields);

        String contfirstName = String.ValueOf(mapSearchFields.get('First Name'));
        String contlastName = String.ValueOf(mapSearchFields.get('Last Name'));
        String contPhone = String.ValueOf(mapSearchFields.get('Phone'));
        String contCity = String.ValueOf(mapSearchFields.get('City'));
        String contZip = String.ValueOf(mapSearchFields.get('Zip'));
        String soqlLimitStmt = ' LIMIT 201';
             
        List<Wrapper> retWrapper = new List<Wrapper>();
        
        String q;
        //String addressSubQuery = ' SELECT Name, City_vod__c, State_vod__c, Zip_vod__c from Address_vod__r ';
        String selectStmt = 'SELECT Name, City_vod__c, State_vod__c, Zip_vod__c, Account_vod__r.Preferred_First_Name_MRK__c, Account_vod__r.Preferred_Last_Name_MRK__c, Account_vod__r.id, Account_vod__r.lastName, Account_vod__r.firstName, Account_vod__r.phone FROM Address_vod__c ';
        String whereClause = ' ';
        List<SObject> objList = new List<SObject>();

        if (!String.isBlank(contfirstName)){
            //whereClause = 'WHERE Account_vod__r.firstName = \'' + String.escapeSingleQuotes(contfirstName) + '\'  ';  
            whereClause = 'WHERE ((Account_vod__r.firstName = \'' + String.escapeSingleQuotes(contfirstName) + '\') or (Account_vod__r.Preferred_First_Name_MRK__c = \'' + 
                String.escapeSingleQuotes(contfirstName) + '\'))  ';  

        }       
        
        if (!String.isBlank(contlastName)){
            if(String.isBlank(whereClause)){
                //whereClause = 'WHERE Account_vod__r.lastName = \'' + String.escapeSingleQuotes(contlastName) + '\'  ';
                whereClause = 'WHERE ((Account_vod__r.lastName = \'' + String.escapeSingleQuotes(contlastName) + '\') or (Account_vod__r.Preferred_Last_Name_MRK__c = \'' 
                    + String.escapeSingleQuotes(contlastName) + '\'))';

            }else{
               // whereClause = whereClause + 'AND Account_vod__r.lastName = \'' + String.escapeSingleQuotes(contlastName) + '\'  ';
               whereClause = whereClause + 'AND ((Account_vod__r.lastName = \'' + String.escapeSingleQuotes(contlastName) + '\') or (Account_vod__r.Preferred_Last_Name_MRK__c = \'' 
                    + String.escapeSingleQuotes(contlastName) + '\'))';
            }
        }       
        
        if (!String.isBlank(contPhone)){
            if(String.isBlank(whereClause)){
                whereClause = 'WHERE Account_vod__r.phone = \'' + String.escapeSingleQuotes(contPhone) + '\'  ';
            }else{
                whereClause = whereClause + 'AND Account_vod__r.phone = \'' + String.escapeSingleQuotes(contPhone) + '\'  ';
            }
        }       

        if (!String.isBlank(contZip)){
            if(String.isBlank(whereClause)){
                whereClause = 'WHERE Zip_vod__c = \'' + String.escapeSingleQuotes(contZip) + '\'  ';
            }else{
                whereClause = whereClause + 'AND Zip_vod__c = \'' + String.escapeSingleQuotes(contZip) + '\'  ';
            }
        }
        
        if (!String.isBlank(contCity)){
            if(String.isBlank(whereClause)){
                whereClause = 'WHERE City_vod__c = \'' + String.escapeSingleQuotes(contCity) + '\'  ';
            }else{
                whereClause = whereClause + 'AND City_vod__c = \'' + String.escapeSingleQuotes(contCity) + '\'  ';
            }
        } 
        
        
        //Account Type Filter
        if (!String.isBlank(contType)){
       
           if(contType != 'All'){ //if All, no need for the Filter.
               if(contType == 'CONSUMER'){
                  if(String.isBlank(whereClause)){
                     whereClause = 'WHERE Account_vod__r.Class_of_Trade_MRK__c = \'CONSUMER\'  ';
                  }else{
                     whereClause = whereClause + 'AND Account_vod__r.Class_of_Trade_MRK__c = \'CONSUMER\'  ';
                  }
               }
               if(contType == 'EMPLOYEE'){
                  if(String.isBlank(whereClause)){
                     whereClause = 'WHERE Account_vod__r.Class_of_Trade_MRK__c = \'EMPLOYEE\'  ';
                  }else{
                     whereClause = whereClause + 'AND Account_vod__r.Class_of_Trade_MRK__c = \'EMPLOYEE\'  ';
                  }
               }
               if(contType == 'HEALTHCARE BUSINESS PROF'){
                  if(String.isBlank(whereClause)){
                     whereClause = 'WHERE Account_vod__r.Class_of_Trade_MRK__c = \'HEALTHCARE BUSINESS PROF\'  ';
                  }else{
                     whereClause = whereClause + 'AND Account_vod__r.Class_of_Trade_MRK__c = \'HEALTHCARE BUSINESS PROF\'  ';
                  }
               }
               if(contType == 'INDIV HEALTHCARE PROF'){
                  if(String.isBlank(whereClause)){
                     whereClause = 'WHERE Account_vod__r.Class_of_Trade_MRK__c = \'INDIV HEALTHCARE PROF\'  ';
                  }else{
                     whereClause = whereClause + 'AND Account_vod__r.Class_of_Trade_MRK__c = \'INDIV HEALTHCARE PROF\'  ';
                  }
               }
           } 
       }   

        
        //add the last Filter 
        if(String.isBlank(whereClause)){
           whereClause = 'WHERE Inactive_vod__c = false';
        }else{
           whereClause = whereClause + 'AND Inactive_vod__c = false';
        }
       
        q = selectStmt + whereClause + soqlLimitStmt; 
        
        System.debug('KRB: DEBUG: Select Statement: ' + q);

        try{
           objList = Database.query(q);
        }catch(Exception e){
           System.debug('An exception has occured -->'+e.getMessage() + 'at '+e.getLineNumber());
        }
        
        System.debug('KRB: DEBUG: Count in objList: ' + objList.size());
         /*
        if(objList.isEmpty()){
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.MSD_CORE_AE_Contact_Search_No_Records_Found));
           cont.retWrapper = new List<Wrapper>();
           return;
        }
       
        if(objList.size() > SEARCHLIMIT){
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.Too_Many_Results));
           cont.retWrapper = new List<Wrapper>();
           return;
        }*/
        
        
        try{
           for(SObject obj : objList){
               Address_vod__c addr = (Address_vod__c)obj;
              
                    retWrapper.add(fillAddress(addr));
               
           }
            
        }catch(Exception e){
             System.debug('An exception has occured -->'+e.getMessage() + 'at '+e.getLineNumber());
        }  
        System.debug('retWrapper --->' +retWrapper);
     return retWrapper;
    }
    
    @AuraEnabled
    public static List<Wrapper> runQueryOnAccountLtg(String JSONFields, String contType){
        
        Map<String, Object> mapSearchFields = (Map<String, Object>)JSON.deserializeUntyped(JSONFields);
        
        String contfirstName = escapeSingleQuotesIfNotEmpty(String.ValueOf(mapSearchFields.get('First Name')));
        String contlastName = escapeSingleQuotesIfNotEmpty(String.ValueOf(mapSearchFields.get('Last Name')));
        String contPhone = escapeSingleQuotesIfNotEmpty(String.ValueOf(mapSearchFields.get('Phone')));
        String contCity = escapeSingleQuotesIfNotEmpty(String.ValueOf(mapSearchFields.get('City')));
        String contZip = escapeSingleQuotesIfNotEmpty(String.ValueOf(mapSearchFields.get('Zip')));
        String soqlLimitStmt = ' LIMIT 201';
       List<Wrapper> retWrapper = new List<Wrapper>();
       
       String q;
       String addressSubQuery = ' SELECT Name, City_vod__c, State_vod__c, Zip_vod__c FROM Address_vod__r WHERE Inactive_vod__c = false ';
       String selectStmt = 'SELECT firstName, lastName, Preferred_First_Name_MRK__c, Preferred_Last_Name_MRK__c,  phone, (' + addressSubQuery + ') FROM Account ';
       String whereClause = ' ';
       List<SObject> objList = new List<SObject>();
        
       if (!String.isBlank(contfirstName)){
          //whereClause = 'WHERE firstName = \'' + String.escapeSingleQuotes(contfirstName) + '\'  ';  
          whereClause = 'WHERE ((firstName = \'' + String.escapeSingleQuotes(contfirstName) + '\') or (Preferred_First_Name_MRK__c = \'' + 
                String.escapeSingleQuotes(contfirstName) + '\'))  ';  
       }       
        
       if (!String.isBlank(contlastName)){
          if(String.isBlank(whereClause)){
             whereClause = 'WHERE ((lastName = \'' + String.escapeSingleQuotes(contlastName) + '\') or (Preferred_Last_Name_MRK__c = \'' 
                    + String.escapeSingleQuotes(contlastName) + '\'))';
          }else{
             whereClause = whereClause + 'AND ((lastName = \'' + String.escapeSingleQuotes(contlastName) + '\') or (Preferred_Last_Name_MRK__c = \'' 
                    + String.escapeSingleQuotes(contlastName) + '\'))';
          }
       }       
        
       if (!String.isBlank(contPhone)){
          if(String.isBlank(whereClause)){
                whereClause = 'WHERE phone = \'' + String.escapeSingleQuotes(contPhone) + '\'  ';
          }else{
                whereClause = whereClause + 'AND phone = \'' + String.escapeSingleQuotes(contPhone) + '\'  ';
          }
       }   
       
       if (!String.isBlank(contType)){
       
           if(contType != 'All'){ //if All, no need for the Filter.
               if(contType == 'CONSUMER'){
                  if(String.isBlank(whereClause)){
                     whereClause = 'WHERE Class_of_Trade_MRK__c = \'CONSUMER\'  ';
                  }else{
                     whereClause = whereClause + 'AND Class_of_Trade_MRK__c = \'CONSUMER\'  ';
                  }
               }
               if(contType == 'EMPLOYEE'){
                  if(String.isBlank(whereClause)){
                     whereClause = 'WHERE Class_of_Trade_MRK__c = \'EMPLOYEE\'  ';
                  }else{
                     whereClause = whereClause + 'AND Class_of_Trade_MRK__c = \'EMPLOYEE\'  ';
                  }
               }
               if(contType == 'HEALTHCARE BUSINESS PROF'){
                  if(String.isBlank(whereClause)){
                     whereClause = 'WHERE Class_of_Trade_MRK__c = \'HEALTHCARE BUSINESS PROF\'  ';
                  }else{
                     whereClause = whereClause + 'AND Class_of_Trade_MRK__c = \'HEALTHCARE BUSINESS PROF\'  ';
                  }
               }
               if(contType == 'INDIV HEALTHCARE PROF'){
                  if(String.isBlank(whereClause)){
                     whereClause = 'WHERE Class_of_Trade_MRK__c = \'INDIV HEALTHCARE PROF\'  ';
                  }else{
                     whereClause = whereClause + 'AND Class_of_Trade_MRK__c = \'INDIV HEALTHCARE PROF\'  ';
                  }
               }
           } 
       }   

       q = selectStmt + whereClause + soqlLimitStmt; 
        
       System.debug('KRB: DEBUG: Select Statement: ' + q);

       try{
          objList = Database.query(q);
       }catch(Exception e){
         
       }
        
       System.debug('KRB 1: DEBUG: Count in objList: ' + objList.size());
        
       if(objList.isEmpty()){
           
       }
        
        
       if(objList.size() > SEARCHLIMIT){
           
       }

 
       try{
           for(SObject obj : objList){
               Account acct = (Account)obj;
               
               List<Address_vod__c> addressList = new List<Address_vod__c>();
               addressList = acct.Address_vod__r;
               
               if(addressList.isEmpty()){
                    Wrapper wrapObj = new Wrapper();
                    wrapObj.firstName = acct.Preferred_First_Name_MRK__c;
                    wrapObj.lastName = acct.Preferred_Last_Name_MRK__c;
                    wrapObj.phone = acct.phone;
                   wrapObj.include = false;
                    retWrapper.add(wrapObj);
               }else{
                  for(Address_vod__c addr: acct.Address_vod__r){
                     retWrapper.add(fillAddress(addr, acct));
                  }
               }
           }
            
        }catch(Exception e){
            
        }
        
        
        return retWrapper;
    }
    
    @AuraEnabled
    public static String createCaseContacts(String selectedConsJSON, String caseId){
        System.debug(selectedConsJSON);
        System.debug(caseId);
        List<Wrapper> retWrapper = (List<Wrapper>)System.JSON.deserialize(selectedConsJSON,List<Wrapper>.class);
       
      String additionalAECaseContactRecordTypeName = Service_Cloud_Settings_MVN__c.getInstance().Adverse_Event_Record_Type_MVN__c; //'Adverse_Event_MVN'
      String additionalAECaseContactRecordTypeId = [select Id from RecordType where SObjectType='MSD_CORE_AE_Contact__c' and DeveloperName = :additionalAECaseContactRecordTypeName].Id; 

      List<MSD_CORE_AE_Contact__c> ins = new List<MSD_CORE_AE_Contact__c>();
      
      for(MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper w : retWrapper){
            if(w.include){
                
                MSD_CORE_AE_Contact__c aeContact = new MSD_CORE_AE_Contact__c();
                
                aeContact.MSD_CORE_Adverse_Event__c = caseId;
                
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
        System.debug('ins -->'+ins);
        try{
           insert ins;
            System.debug('return');
           return 'SUCCESS';
        }catch(DMLException e){
            System.debug(e.getMessage());
           //Note: SF will handle displaying the Error on the VF Page. Just need to have the Try/Catch
           //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
           return 'EXCEPTION_'+e.getdmlMessage(0);
        }
    }
    
    @AuraEnabled
    public static string createNewLtg(String JSONFields, String caseId){
        Map<String, Object> mapSearchFields = (Map<String, Object>)JSON.deserializeUntyped(JSONFields);
        String firstName = String.ValueOf(mapSearchFields.get('First Name'));
        String lastName = String.ValueOf(mapSearchFields.get('Last Name'));
        String phone = String.ValueOf(mapSearchFields.get('Phone'));
        String city = String.ValueOf(mapSearchFields.get('City'));
        String zip = String.ValueOf(mapSearchFields.get('Zip'));
        
        String additionalAECaseContactRecordTypeName = Service_Cloud_Settings_MVN__c.getInstance().Adverse_Event_Record_Type_MVN__c; //'Adverse_Event_MVN'
        String additionalAECaseContactRecordTypeId = Schema.SObjectType.MSD_CORE_AE_Contact__c.getRecordTypeInfosByDeveloperName().get(additionalAECaseContactRecordTypeName).getRecordTypeId();
         
        List<MSD_CORE_AE_Contact__c> ins = new List<MSD_CORE_AE_Contact__c>();
        MSD_CORE_AE_Contact__c aeContact = new MSD_CORE_AE_Contact__c();
                      
        if(!String.isBlank(firstName)){
            aeContact.MSD_CORE_First_Name__c = firstName; 
        } 
        if(!String.isBlank(lastName)){
            aeContact.MSD_CORE_Last_Name__c = lastName; 
        } 
      
        aeContact.MSD_CORE_Adverse_Event__c = caseId;
        aecontact.RecordTypeId = additionalAECaseContactRecordTypeId;   
      
        if(!String.isBlank(phone)){
            aecontact.MSD_CORE_Phone__c = phone;
        }
        
        if(!String.isBlank(city)){
            aecontact.MSD_CORE_City__c = city;
        }
    
        if(!String.isBlank(zip)){
            aecontact.MSD_CORE_Postal_Code__c = zip;
        }
        
        try{
            insert aecontact;
            return aecontact.Id;
        }        
        catch(Exception e){
            System.debug('An exception has occurred -->'+e.getMessage()+'at '+e.getLineNumber());
            return 'EXCEPTION_'+e.getdmlMessage(0);
      }
   }
    
    private static String escapeSingleQuotesIfNotEmpty(String inputString){
        if(inputString != null && inputString.length() > 0){
            return String.escapeSingleQuotes(inputString.trim());
        } else {
            return '';
        }
    }
    
    public static Wrapper fillAddress(Address_vod__c addr, Account acct)
    {
        Wrapper wrapObj = new Wrapper(); 
        wrapObj.addressLine1 = addr.Name;
        wrapObj.city = addr.City_vod__c;
        wrapObj.state = addr.State_vod__c;
        wrapObj.zip = addr.Zip_vod__c;
        wrapObj.firstName = acct.Preferred_First_Name_MRK__c;
        wrapObj.lastName = acct.Preferred_Last_Name_MRK__c;
        wrapObj.phone = acct.phone;
        return wrapObj;
    }
    
    public static Wrapper fillAddress(Address_vod__c addr)
    {
        Wrapper wrapObj = new Wrapper(); 
        wrapObj.addressLine1 = addr.Name;
        wrapObj.city = addr.City_vod__c;
        wrapObj.state = addr.State_vod__c;
        wrapObj.zip = addr.Zip_vod__c;
        wrapObj.firstName = addr.Account_vod__r.Preferred_First_Name_MRK__c;
        wrapObj.lastName = addr.Account_vod__r.Preferred_Last_Name_MRK__c;
        wrapObj.phone = addr.Account_vod__r.phone;
        wrapObj.include = false;
        return wrapObj;
    }
}