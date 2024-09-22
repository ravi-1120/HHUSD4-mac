/** 
 * Batch Apex Name : MRK_Comm_DryRun_UTL
 * This Batch Apex Class performs the Quality Check of the records present in MRK_COMM_PROCESSING Object & mark them for ready for processing. 
 * @version        1.0
 * @author         Ankur Mehrotra 
 */
global class MRK_Comm_DryRun_UTL implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
       String query = 'SELECT Id,Name,Comm_Target_Id__c,Communication_Target_Id__c,Comm_Name__c,Communication_Calendar__c,CT_Created_by__c,CT_CreatedDate__c,CT_LastModifiedBy__c,CT_LastModifiedDate__c,Errors__c,New_Product__c,New_Profile__c,New_Team__c,New_Type__c,Product__c,Profile__c,Ready_for_Processing__c,No_Change__c,Team__c,Type__c,Communication_Event_Target_Id__c,Calendar_Event_Id__c,Communication_Id__c,Last_Retarget_Date__c,Operation__c FROM MRK_MYCOMM_PROCESSING__c'; // where Ready_for_Processing__c = true';       
        //String query = 'SELECT Id,Name FROM MRK_MYCOMM_PROCESSING__c';       
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<MRK_MYCOMM_PROCESSING__c> scope) {
    
        //Map to hold the names of all Active Detail Products by key as name. - Check with Brian if the Prod List is only Detail products?
        Map<String,Product_vod__c> ProdMap = new Map<String,Product_vod__c>();
        for(Product_vod__c Prod:[select Name, External_ID_vod__c from Product_vod__c where Active_MRK__c = true and Company_Product_vod__c = true and Product_Type_vod__c = 'Detail']){
        ProdMap.put(Prod.Name, Prod);
        }
        
        //Map to hold the Active Sales Teams.
        Map<String,Sales_Team_MRK__c> STMap = new Map<String,Sales_Team_MRK__c>();
        for(Sales_Team_MRK__c STM:[SELECT Name,Sales_Team_Code_MRK__c FROM Sales_Team_MRK__c WHERE Active_MRK__c = true]){
        STMap.put(STM.Name,STM);
        }
        
        //Map to hold the Active Custom MRK Profiles
        Map<String,Profile> ProfileMap = new Map<String,Profile>();
        for(Profile P: [SELECT Name,Id FROM Profile WHERE Name LIKE 'MRK%']){
        ProfileMap.put(P.Name,P);
        }
        
        //Custom Label which holds different MyComm types.
        String MyCommTypes = System.Label.MRK_MYCOMM_TYPES;
        
       //Iterating through all the records.
       for(MRK_MYCOMM_PROCESSING__c p: scope  ){
       
       String Ops;
       
       //Define if the operation is an Insert or Update Operation.
       //If(p.Product__c == null && p.Profile__c == null && p.Team__c == null && p.Type__c == null){
       //p.Operation__c = 'INSERT';
       //Ops = 'INS';
       //}
       //else{
       //p.Operation__c = 'UPDATE';
       //Ops = 'UPD';
       //}
       
         If(p.New_Type__c == 'Optional' || p.New_Type__c == 'Required'){
         If(p.Communication_Event_Target_Id__c == null){
         p.Operation__c = 'CET-INSERT';
         Ops = 'INS';
         } else {
         p.Operation__c = 'CET-UPDATE';
         Ops = 'UPD';
         }
         }
             
        If(p.New_Type__c == 'Action' || p.New_Type__c == 'Background'){
         If(p.Communication_Target_Id__c == null){
         p.Operation__c = 'CT-INSERT';
         Ops = 'INS';
         } else {
         p.Operation__c = 'CT-UPDATE';
         Ops = 'UPD';
         }
         }
                  
       //Populate Calendar or Communication Target Record based on Types. 
       If(Ops == 'UPD'){          
          If(p.Type__c == 'Action' || p.Type__c == 'Background')
          {
          p.Communication_Calendar__c = 'Communication';
          }
       }

       If(Ops == 'UPD'){          
           If(p.Type__c == 'Optional' || p.Type__c == 'Required')
           {
            p.Communication_Calendar__c = 'Calendar';
            }
        }   
       
       If(Ops == 'INS'){          
          If(p.New_Type__c == 'Action' || p.New_Type__c == 'Background')
          {
          p.Communication_Calendar__c = 'Communication';
          }
       }

       If(Ops == 'INS'){          
           If(p.New_Type__c == 'Optional' || p.New_Type__c == 'Required')
           {
            p.Communication_Calendar__c = 'Calendar';
            }
        }   
       
          //system.debug('Ankur' + p.Communication_Calendar__c);
          
                   
          //Check if the Update record set is ready for processing or No Change.
          If(Ops == 'UPD'){ 
             if(p.New_Product__c == p.Product__c && p.New_Profile__c == p.Profile__c && p.New_Team__c == p.Team__c && p.New_Type__c == p.Type__c){
              p.No_Change__c = true;
              } else {
              p.Ready_for_Processing__c = true;
             }
           }
           
           //Recording Observations -- Start
          If(Ops == 'UPD'){ 
           if(p.New_Product__c != p.Product__c){
           p.Observations__c = 'Change in Product List';
           }
           }
           
           If(Ops == 'UPD'){ 
           if(p.New_Profile__c != p.Profile__c ){
           if(p.Observations__c == null){
           p.Observations__c = 'Change in Profile List';
           }else{
           p.Observations__c = p.Observations__c + ';' + ' Change in Profile List';
           }
           }
           }
           
           If(Ops == 'UPD'){ 
           if(p.New_Team__c != p.Team__c){
           if(p.Observations__c == null){
           p.Observations__c = 'Change in Sales Team List';
           }else{
           p.Observations__c = p.Observations__c + ';' + ' Change in Sales Team List';
           }
           }
           }
           
           If(Ops == 'UPD'){ 
           if(p.New_Type__c != p.Type__c){
           if(p.Observations__c == null){
           p.Observations__c = 'Change in Type List';
           }else{
           p.Observations__c = p.Observations__c + ';' + ' Change in Type List';
           } 
           }
           }
           //Recording Observations -- End
               
           //Checking for any Potential Typo Errors
           Boolean result =   MyCommTypes.contains(p.New_Type__c);
           if(!result){
           p.Errors__c = p.New_Type__c + ' does not exists in My Comm. Check My Comm Object & entry in custom label MRK_MYCOMM_TYPES; ';
           p.Ready_for_Processing__c = false;
           }
           
           //Spliting Product records in an array
           String TrimmedProdList = p.New_Product__c.trim();
           String ReplacedProdList3 = TrimmedProdList.Replace(';   ',';');
           String ReplacedProdList2 = ReplacedProdList3.Replace(';  ',';');
           String ReplacedProdList1 = ReplacedProdList2.Replace('; ',';');
           String [] newProdList = ReplacedProdList1.split(';');
         
           //String [] newProdList = p.New_Product__c.split(';');
         // system.debug('Ankur String Size' + newProdList.size());
          //system.debug('Ankur using Split  ' + newProdList);
               
          for(String s:  newProdList){
          System.debug('Ankur Prod Loop' +s );
          if(ProdMap.containskey(s)){
               If(p.Prod_External_Id__c == null){
                p.Prod_External_Id__c = ProdMap.get(s).External_ID_vod__c;
                }
                else{
                p.Prod_External_Id__c = ProdMap.get(s).External_ID_vod__c + '; ' +  p.Prod_External_Id__c;
                }
          }else{
          p.Errors__c = p.Errors__c + s + ' does not exist; ';
          p.Ready_for_Processing__c = false;
          }   
          }     
         
          //Spliting Sales Team records in an array
           String TrimmedSTList = p.New_Team__c.trim();
           String ReplacedSTList3 = TrimmedSTList.Replace(';   ',';');
           String ReplacedSTList2 = ReplacedSTList3.Replace(';  ',';');
           String ReplacedSTList1 = ReplacedSTList2.Replace('; ',';');
           String [] newSTList = ReplacedSTList1.split(';');
         
               
          for(String st:  newSTList){
          if(STMap.containskey(st)){
              if(p.Sales_Team_Codes__c == null){
              p.Sales_Team_Codes__c = STMap.get(st).Sales_Team_Code_MRK__c;
              }
              else{
              p.Sales_Team_Codes__c = STMap.get(st).Sales_Team_Code_MRK__c + '; ' +  p.Sales_Team_Codes__c;
              }
          }else{
          p.Errors__c = p.Errors__c + st + ' does not exist; ';
          p.Ready_for_Processing__c = false;
          }   
          }  

          //Spliting Profile records in an array
           String TrimmedProfileList = p.New_Profile__c.trim();
           String ReplacedProfileList3 = TrimmedProfileList.Replace(';   ',';');
           String ReplacedProfileList2 = ReplacedProfileList3.Replace(';  ',';');
           String ReplacedProfileList1 = ReplacedProfileList2.Replace('; ',';');
           String [] newPFList = ReplacedProfileList1.split(';');        

          System.debug('Ankur - newPFList ' + newPFList );

          for(String PF:  newPFList){
          if(!ProfileMap.containskey(PF)){
          p.Errors__c = p.Errors__c + PF + ' Name does not exist; ';
          p.Ready_for_Processing__c = false;
          }   
          }  
          
          if(p.Operation__c == 'CET-INSERT' || p.Operation__c == 'CT-INSERT'){
            if(p.Errors__c  == null){
             p.Ready_for_Processing__c = true;
            }
          }

          if(p.Errors__c != null || p.Errors__c == '' || p.Errors__c == ' ')
          {
          p.Errors__c = p.Errors__c.Replace('null','***');
          }
        
   }
   update(scope);
   }
    
        
    global void finish(Database.BatchableContext BC) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
 
//mail.setToAddresses(new String[] {email});
String[] toAddresses = new String[] {'ankur.mehrotra2@merck.com'};
mail.setToAddresses(toAddresses);
mail.setReplyTo('ankur.mehrotra2@merck.com');
mail.setSenderDisplayName('Batch Processing');
mail.setSubject('Batch Process Completed');
mail.setPlainTextBody('Batch Process has completed');
 
Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}