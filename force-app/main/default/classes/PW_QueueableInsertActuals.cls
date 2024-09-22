public class PW_QueueableInsertActuals implements Queueable {
    public PW_Expense_Actuals_Rest_Api_Model ActualsFromTp{get;set;}
    public void execute(QueueableContext context){

          // Step 1: Load data
         Savepoint sp = Database.setSavepoint();
        try
        {
         id EventId=ActualsFromTp.Event_Id;
         Map<string,EM_Event_Speaker_vod__c> mapOfEventSpeaker = new Map<string,EM_Event_Speaker_vod__c>();
         list<Expense_Header_vod__c> eventHeadersListOfVeeva= new List<Expense_Header_vod__c> ();      // Changed for  Merc[select id from Expense_Header_vod__c where Event_vod__c=: EventId];
         list<EM_Event_Budget_vod__c> eventBudgetList=[select id from EM_Event_Budget_vod__c where Event_vod__c=: EventId];
         
          if(eventBudgetList.size()==0){
               Throw new Pw_ApplicationException('Budget is not added to the event');     
          }
          
         //Queries                      
         List<EM_Event_Speaker_vod__c> eventSpeakerList = [SELECT id,Speaker_vod__r.PW_Speaker_ID__c FROM EM_Event_Speaker_vod__c where Event_vod__c=: EventId and Speaker_vod__r.PW_Speaker_ID__c!=null limit: Limits.getLimitQueryRows() - Limits.getQueryRows()];
        
         System.debug('Actuals Data in veevaP ' +eventHeadersListOfVeeva); 
         for(EM_Event_Speaker_vod__c eventSpeakertLocal :eventSpeakerList){
              mapOfEventSpeaker.put(eventSpeakertLocal.Speaker_vod__r.PW_Speaker_ID__c, eventSpeakertLocal);
            }
         
         if( Insert_Expense_Actuals(ActualsFromTp.ListOfActuals,eventBudgetList,eventHeadersListOfVeeva,mapOfEventSpeaker, EventId))
         {  // added if for Merck to resolve existing Prod Issue.
          PW_QueueableActualCallout actualsCallOut = new PW_QueueableActualCallout();
            actualsCallOut.Message = 'Successfully updated Actuals.';
            actualsCallOut.Status='Success';
            actualsCallOut.MessageId=ActualsFromTp.Message_Id;
            actualsCallOut.EventId = ActualsFromTp.Event_Id;
            System.enqueueJob(actualsCallOut);
            }
        }
        catch(exception ex){
              Database.rollback(sp); 
            PW_QueueableActualCallout actualsCallOut = new PW_QueueableActualCallout();
            actualsCallOut.Message = ex.getMessage();
            actualsCallOut.Status='Fail';
            actualsCallOut.MessageId=ActualsFromTp.Message_Id;
            actualsCallOut.EventId = ActualsFromTp.Event_Id;
            PW_Log_Into_CustomLogger.Log(ex.getStackTraceString(),ex.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
            System.enqueueJob(actualsCallOut);
        }
    }
    
      public Boolean  Insert_Expense_Actuals(list<Pw_Expense_Header_Model> HeaderListFromTp,list<EM_Event_Budget_vod__c> eventBudgetList,list<Expense_Header_vod__c> eventHeadersListOfVeeva,Map<string,EM_Event_Speaker_vod__c> mapOfEventSpeaker, id EventId){
         
          //Step 2: Insert Headers and Lines
          list<Expense_Line_vod__c> eventLinesListOfVeeva=new  list<Expense_Line_vod__c>();
          
          // Create a savepoint while     
         Savepoint sp = Database.setSavepoint();
          
         try{
             
                 if(eventHeadersListOfVeeva.size()>0){
                   // Remove  for  Merck // Database.DeleteResult[] drList=database.delete(eventHeadersListOfVeeva,true);
                 }
               
                 eventHeadersListOfVeeva.clear();
                filterExpenseHeaderList(HeaderListFromTp);   // Remove  any header  which has no Expense Line.
                 for(Pw_Expense_Header_Model actualHeaderFromTp : HeaderListFromTp){                      
                     fill_Expense_Headers_List(actualHeaderFromTp,mapOfEventSpeaker,eventHeadersListOfVeeva,EventId);                                                                                              
                  } 
                 System.debug('Actuals Data in veevaP ' +eventHeadersListOfVeeva); 
                 
                 //step 3: Insert Headers in Veeva  
                 Database.SaveResult[] srHeaderList=database.insert(eventHeadersListOfVeeva,true);
                
                 System.debug('Actuals header is inserted'+srHeaderList);  
                              
                 for(Integer i=0;i<srHeaderList.size();i++){         
                    if (srHeaderList[i].isSuccess()) {                        
                        for(Pw_Expense_Line_Model actualLinesFromTp : HeaderListFromTp[i].ListOfExpenseLines){                          
                            fill_Expense_Lines_List(actualLinesFromTp,eventLinesListOfVeeva,eventBudgetList[0].id,srHeaderList[i].getId(),EventId);                                               
                        }                        
                    }
                 }
                 
                 System.debug('Actuals lines'+eventLinesListOfVeeva); 
             
                 //Step 4: Insert Expense Lines in Veeva
                 if(eventLinesListOfVeeva.size()>0){
                    
                     Database.SaveResult[] srLinesList=database.insert(eventLinesListOfVeeva,true);
                     System.debug('Actuals lines is inserted'+srLinesList);               
                  }
      
          }catch(exception ex){
              Database.rollback(sp); 
              PW_QueueableActualCallout actualsCallOut = new PW_QueueableActualCallout();
            actualsCallOut.Message = ex.getMessage();
            actualsCallOut.Status='Fail';
            actualsCallOut.MessageId=ActualsFromTp.Message_Id;
            actualsCallOut.EventId = EventId;
           PW_Log_Into_CustomLogger.Log(ex.getStackTraceString(),ex.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
              
            System.enqueueJob(actualsCallOut);
            return false;
          }
        return true;
    }
      
      public static void fill_Expense_Headers_List(Pw_Expense_Header_Model actualHeaderFromTp,Map<string,EM_Event_Speaker_vod__c> mapOfEventSpeaker,list<Expense_Header_vod__c> eventHeadersListOfVeeva,id EventId){
             
          Expense_Header_vod__c headerLocal = new Expense_Header_vod__c();                    
                 
               if(string.isNotBlank(actualHeaderFromTp.Payee_Tp_Speaker_Id)&& mapOfEventSpeaker.keyset().contains(actualHeaderFromTp.Payee_Tp_Speaker_Id)){
                   System.debug('Actuals Data  ' + actualHeaderFromTp.Payee_Tp_Speaker_Id); 
                   headerLocal.Payee_Speaker_vod__c=mapOfEventSpeaker.get(actualHeaderFromTp.Payee_Tp_Speaker_Id).id;
                  // headerLocal.Incurred_Expense_Speaker_vod__c=mapOfEventSpeaker.get(actualHeaderFromTp.Payee_Tp_Speaker_Id).id;
                            if( !String.isEmpty(actualHeaderFromTp.Incurred_Expense_Tp_Speaker_Id))
                            {
                                   if(mapOfEventSpeaker.get(actualHeaderFromTp.Incurred_Expense_Tp_Speaker_Id) != null)
                                   {
                                     headerLocal.Incurred_Expense_Speaker_vod__c=mapOfEventSpeaker.get(actualHeaderFromTp.Incurred_Expense_Tp_Speaker_Id).id;
                                    }else
                                    {
                                     Throw new Pw_ApplicationException('Tp speaker Id is not present in Veeva for Incurred_Expense_Tp_Speaker_Id::'+actualHeaderFromTp.Incurred_Expense_Tp_Speaker_Id);  
                                    }
                            }
                            else if(actualHeaderFromTp.Incurred_Expense_Vendor !=null)
                            {
                            headerLocal.Incurred_Expense_Vendor_vod__c=actualHeaderFromTp.Incurred_Expense_Vendor;
                            }
                            else if(actualHeaderFromTp.Incurred_Expense_Venue !=null)
                            {
                            headerLocal.Incurred_Expense_Venue_vod__c=actualHeaderFromTp.Incurred_Expense_Venue;
                            }
                        
                  }else if(actualHeaderFromTp.Payee_Venue!=null){
                     headerLocal.Payee_Venue_vod__c =actualHeaderFromTp.Payee_Venue;
                     if(!String.isEmpty(actualHeaderFromTp.Incurred_Expense_Tp_Speaker_Id))
                            {
                                if(mapOfEventSpeaker.get(actualHeaderFromTp.Incurred_Expense_Tp_Speaker_Id) != null)
                                   {
                                     headerLocal.Incurred_Expense_Speaker_vod__c=mapOfEventSpeaker.get(actualHeaderFromTp.Incurred_Expense_Tp_Speaker_Id).id;
                                    }else
                                    {
                                     Throw new Pw_ApplicationException('Tp speaker Id is not present in Veeva for Incurred_Expense_Tp_Speaker_Id::'+actualHeaderFromTp.Incurred_Expense_Tp_Speaker_Id);  
                                    }
                            }
                            else if(actualHeaderFromTp.Incurred_Expense_Vendor !=null)
                            {
                            headerLocal.Incurred_Expense_Vendor_vod__c=actualHeaderFromTp.Incurred_Expense_Vendor;
                            }
                            else if(actualHeaderFromTp.Incurred_Expense_Venue !=null)
                            {
                            headerLocal.Incurred_Expense_Venue_vod__c=actualHeaderFromTp.Incurred_Expense_Venue;
                            }
                  }else if(actualHeaderFromTp.Payee_Vendor!=null){
                     headerLocal.Payee_Vendor_vod__c =actualHeaderFromTp.Payee_Vendor;
                          if(!String.isEmpty(actualHeaderFromTp.Incurred_Expense_Tp_Speaker_Id))
                            {
                                   if(mapOfEventSpeaker.get(actualHeaderFromTp.Incurred_Expense_Tp_Speaker_Id) != null)
                                    {
                                     headerLocal.Incurred_Expense_Speaker_vod__c=mapOfEventSpeaker.get(actualHeaderFromTp.Incurred_Expense_Tp_Speaker_Id).id;
                                    }else
                                    {
                                      Throw new Pw_ApplicationException('Tp speaker Id is not present in Veeva for Incurred_Expense_Tp_Speaker_Id::'+actualHeaderFromTp.Incurred_Expense_Tp_Speaker_Id);  
                                    }
                            }
                            else if(actualHeaderFromTp.Incurred_Expense_Vendor !=null)
                            {
                            headerLocal.Incurred_Expense_Vendor_vod__c=actualHeaderFromTp.Incurred_Expense_Vendor;
                            }
                            else if(actualHeaderFromTp.Incurred_Expense_Venue !=null)
                            {
                            headerLocal.Incurred_Expense_Venue_vod__c=actualHeaderFromTp.Incurred_Expense_Venue;
                            }
                  }else{
                               
                     Throw new Pw_ApplicationException('Payee Not Present in Actual Header from TP/MW or TP Speaker Id in the Payee not present in Veeva. ');  
                  }
                  headerLocal.Event_vod__c=EventId;
                  headerLocal.Payment_Date_vod__c=actualHeaderFromTp.Payment_Date;
                  headerLocal.Status_vod__c=actualHeaderFromTp.Status;
               
                 
                  System.debug('Actuals Data  ' +headerLocal); 
                  eventHeadersListOfVeeva.add(headerLocal);                        
      }
    
      public static void fill_Expense_Lines_List(Pw_Expense_Line_Model actualLinesFromTp,list<Expense_Line_vod__c> eventLinesListOfVeeva,id BudgetId,id HeaderId,id EventId){
         
                Expense_Line_vod__c linesLocal = new Expense_Line_vod__c();
                     
                  linesLocal.Actual_vod__c= actualLinesFromTp.Actual;
                  linesLocal.Committed_vod__c = actualLinesFromTp.Committed; //IN:29287
                  linesLocal.Event_Budget_vod__c= BudgetId;
                  linesLocal.Expense_Type_vod__c= actualLinesFromTp.Expense_Type;
                  linesLocal.Expense_Type_Name_vod__c= actualLinesFromTp.Expense_Type_Name;
                  linesLocal.Expense_Header_vod__c= HeaderId; 
                  linesLocal.Event_vod__c=EventId;
                        
                eventLinesListOfVeeva.add(linesLocal); 
    }

  //------------New Function
    public void filterExpenseHeaderList(List<Pw_Expense_Header_Model> HeaderListFromTp)   
    {           
       // This function remove headers which has no line 
                Integer j = 0;
                while (j < HeaderListFromTp.size())
                {
                            if(HeaderListFromTp.get(j).ListOfExpenseLines == null ||  HeaderListFromTp.get(j).ListOfExpenseLines.size() == 0)
                            {
                                 HeaderListFromTp.remove(j);
                            }else
                             {
                                j++;
                             }
                 }
    }
}