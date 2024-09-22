/** 
 * Batch Apex Name : MRK_Comm_Processing_Update
 * This Batch Apex Class update the My Comm targeting & My Comm Event Targeting Objects.  
 * @version        1.0
 * @author         Ankur Mehrotra 
 */
 
global class MRK_Comm_Processing_Update implements Database.Batchable<sObject> {
global Date myDate = date.today();

    global Database.QueryLocator start(Database.BatchableContext BC) {
       String query = 'SELECT Id,Name,Communication_Target_Id__c,Comm_Name__c,Communication_Calendar__c,CT_Created_by__c,CT_CreatedDate__c,CT_LastModifiedBy__c,CT_LastModifiedDate__c,Errors__c,New_Product__c,New_Profile__c,New_Team__c,New_Type__c,Product__c,Profile__c,Ready_for_Processing__c,No_Change__c,Team__c,Type__c,Communication_Event_Target_Id__c,Calendar_Event_Id__c,Communication_Id__c,Last_Retarget_Date__c,Operation__c FROM MRK_MYCOMM_PROCESSING__c where Ready_for_Processing__c = true';       
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<MRK_MYCOMM_PROCESSING__c> scope) {
   
     Set<Id> CommTgtIds = new Set<Id>();
      Set<Id> CalTgtIds = new Set<Id>();
   
          //Add Comm Target Ids to the set
         for(MRK_MYCOMM_PROCESSING__c Comm : Scope){
         if(Comm.Communication_Target_Id__c != null) {
            CommTgtIds.add(Comm.Communication_Target_Id__c);
           }
         }
   
    //Add Cal Target Ids to the set
        for(MRK_MYCOMM_PROCESSING__c Cal : Scope){
        if(Cal.Communication_Event_Target_Id__c != null) {
          CalTgtIds.add(Cal.Communication_Event_Target_Id__c);
        }
        }
      
    Map<String,MRK_MYCOMM_PROCESSING__c> CommProc = new Map<String,MRK_MYCOMM_PROCESSING__c>();
    for(MRK_MYCOMM_PROCESSING__c M:[select Communication_Target_Id__c,Prod_External_Id__c,New_Profile__c,Sales_Team_Codes__c,New_Type__c from MRK_MYCOMM_PROCESSING__c where Ready_for_Processing__c = true and Communication_Calendar__c = 'Communication' and Operation__c = 'CT-UPDATE']){
    CommProc.put(M.Communication_Target_Id__c, M);
    }

    Map<String,MRK_MYCOMM_PROCESSING__c> CalProc = new Map<String,MRK_MYCOMM_PROCESSING__c>();
    for(MRK_MYCOMM_PROCESSING__c M:[select Communication_Event_Target_Id__c,Prod_External_Id__c,New_Profile__c,Sales_Team_Codes__c,New_Type__c from MRK_MYCOMM_PROCESSING__c where Ready_for_Processing__c = true and Communication_Calendar__c = 'Calendar' and Operation__c = 'CET-UPDATE']){
    CommProc.put(M.Communication_Event_Target_Id__c, M);
    }


//List to update the Comm Target records.
List <Communication_Target_MRK__c> CommTgttoupdate = new List <Communication_Target_MRK__c>();
for(Communication_Target_MRK__c CTU : [Select Id,Product_MRK__c,Product_IDs_MRK__c,Profile_MRK__c,Team_MRK__c,Team_IDs_MRK__c,Type_MRK__c from Communication_Target_MRK__c Where Id in :CommTgtIds])
{
   //CTU.Product_MRK__c = CommProc.get(CTU.Id).Prod_External_Id__c;
   CTU.Product_IDs_MRK__c = CommProc.get(CTU.Id).Prod_External_Id__c;
   CTU.Profile_MRK__c = CommProc.get(CTU.Id).New_Profile__c;
  // CTU.Team_MRK__c = CommProc.get(CTU.Id).Sales_Team_Codes__c;
   CTU.Team_IDs_MRK__c = CommProc.get(CTU.Id).Sales_Team_Codes__c;
   CTU.Type_MRK__c = CommProc.get(CTU.Id).New_Type__c;
   CTU.Last_Retarget_Date_MRK__c = myDate;
    
   CommTgttoupdate.add(CTU);
}
Update(CommTgttoupdate);     



//Code added to update the Last Retarget Date in Communication_MRK__c Object.
Set <Id> CommIds = new Set <Id>();
for(Communication_Target_MRK__c C : [Select Communication_MRK__c from Communication_Target_MRK__c where Id in :CommTgtIds])
{
    CommIds.add(C.Communication_MRK__c);
}

//New Code added to populate the CommIds set to Include INSERT Scenario's
for(MRK_MYCOMM_PROCESSING__c CI : [Select Communication_Id__c from MRK_MYCOMM_PROCESSING__c where Operation__c = 'CT-INSERT' and Ready_for_Processing__c = true])
{
    CommIds.add(CI.Communication_Id__c);
}


List <Communication_MRK__c> Commtoupdate = new List <Communication_MRK__c>();
for(Communication_MRK__c CU : [Select Id,Last_Retarget_Date_MRK__c from Communication_MRK__c Where Id in :CommIds])
{
      CU.Last_Retarget_Date_MRK__c = myDate;
      Commtoupdate.add(CU);
}
Update(Commtoupdate); 


//List to update the Cal Target records.
List <Communication_Event_Target_MRK__c> CalTgttoupdate = new List <Communication_Event_Target_MRK__c>();
for(Communication_Event_Target_MRK__c CETU : [Select Id,Product_MRK__c,Product_IDs_MRK__c,Profile_MRK__c,Team_MRK__c,Team_IDs_MRK__c,Type_MRK__c from Communication_Event_Target_MRK__c Where Id in :CalTgtIds])
{
   //CETU.Product_MRK__c = CommProc.get(CETU.Id).Prod_External_Id__c;
   CETU.Product_IDs_MRK__c = CommProc.get(CETU.Id).Prod_External_Id__c;
   CETU.Profile_MRK__c = CommProc.get(CETU.Id).New_Profile__c;
   //CETU.Team_MRK__c = CommProc.get(CETU.Id).Sales_Team_Codes__c;
   CETU.Team_IDs_MRK__c = CommProc.get(CETU.Id).Sales_Team_Codes__c;
   CETU.Type_MRK__c = CommProc.get(CETU.Id).New_Type__c;
   CETU.Last_Retarget_Date_MRK__c = myDate;
    
   CalTgttoupdate.add(CETU);
}
Update(CalTgttoupdate);   

//Code added to update the Last Retarget Date in Communication_Event_MRK__c Object.
Set <Id> CommEventIds = new Set <Id>();
for(Communication_Event_Target_MRK__c CET : [Select Communication_Event_MRK__c from Communication_Event_Target_MRK__c where Id in :CalTgtIds])
{
    CommEventIds.add(CET.Communication_Event_MRK__c);
}

//New Code added to populate the CommEventIds set to Include INSERT Scenario's
for(MRK_MYCOMM_PROCESSING__c CEI : [Select Calendar_Event_Id__c from MRK_MYCOMM_PROCESSING__c where Operation__c = 'CET-INSERT' and Ready_for_Processing__c = true])
{
    CommEventIds.add(CEI.Calendar_Event_Id__c);
}

List <Communication_Event_MRK__c> CommEventtoupdate = new List <Communication_Event_MRK__c>();
for(Communication_Event_MRK__c CEU : [Select Id,Last_Retarget_Date_MRK__c from Communication_Event_MRK__c Where Id in :CommEventIds])
{
      CEU.Last_Retarget_Date_MRK__c = myDate;
      CommEventtoupdate.add(CEU);
}
Update(CommEventtoupdate); 
   
  // System.debug('Ankur CommTgttoupdate '  + CommTgttoupdate);
  // System.debug('Ankur CalTgttoupdate'  + CalTgttoupdate); 
  
  
  //Insert records in Communication Target Object
  Communication_Target_MRK__c[] CommTgttoInsert = new List <Communication_Target_MRK__c>();
  for(MRK_MYCOMM_PROCESSING__c CommINS : [select Communication_Id__c,New_Type__c,Sales_Team_Codes__c,New_Profile__c,Prod_External_Id__c from MRK_MYCOMM_PROCESSING__c where Operation__c = 'CT-INSERT'])
  {
         //Communication_Target_MRK__c CTINS = new Communication_Target_MRK__c(Product_MRK__c = CommINS.Prod_External_Id__c, Profile_MRK__c = CommINS.New_Profile__c, Team_MRK__c = CommINS.Sales_Team_Codes__c, Type_MRK__c = CommINS.New_Type__c, Last_Retarget_Date_MRK__c = myDate, Communication_MRK__c = CommINS.Communication_Id__c);
         Communication_Target_MRK__c CTINS = new Communication_Target_MRK__c(Product_IDs_MRK__c = CommINS.Prod_External_Id__c, Profile_MRK__c = CommINS.New_Profile__c, Team_IDs_MRK__c = CommINS.Sales_Team_Codes__c, Type_MRK__c = CommINS.New_Type__c, Last_Retarget_Date_MRK__c = myDate, Communication_MRK__c = CommINS.Communication_Id__c);
         CommTgttoInsert.add(CTINS);
  }  
  Insert CommTgttoinsert;
  
  //system.debug('Ankur CommTgttoinsert ' + CommTgttoinsert);
  
   //Insert records in Communication Event Target Object
  Communication_Event_Target_MRK__c[] CommETTgttoInsert = new List <Communication_Event_Target_MRK__c>();
  for(MRK_MYCOMM_PROCESSING__c CommETINS : [select Calendar_Event_Id__c,New_Type__c,Sales_Team_Codes__c,New_Profile__c,Prod_External_Id__c from MRK_MYCOMM_PROCESSING__c where Operation__c = 'CET-INSERT'])
  {
         //Communication_Event_Target_MRK__c CETINS = new Communication_Event_Target_MRK__c (Product_MRK__c = CommETINS.Prod_External_Id__c, Profile_MRK__c = CommETINS.New_Profile__c, Team_MRK__c = CommETINS.Sales_Team_Codes__c, Type_MRK__c = CommETINS.New_Type__c, Last_Retarget_Date_MRK__c = myDate, Communication_Event_MRK__c = CommETINS.Calendar_Event_Id__c);
         Communication_Event_Target_MRK__c CETINS = new Communication_Event_Target_MRK__c (Product_IDs_MRK__c = CommETINS.Prod_External_Id__c, Profile_MRK__c = CommETINS.New_Profile__c, Team_IDs_MRK__c = CommETINS.Sales_Team_Codes__c, Type_MRK__c = CommETINS.New_Type__c, Last_Retarget_Date_MRK__c = myDate, Communication_Event_MRK__c = CommETINS.Calendar_Event_Id__c);
         CommETTgttoInsert.add(CETINS);
  }  
  Insert CommETTgttoInsert;
  
  
 // system.debug('Ankur CommETTgttoInsert' + CommETTgttoInsert);
    
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