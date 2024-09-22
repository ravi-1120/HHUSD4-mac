///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_Update_Expense_Estimates_from_Tp
///   Description:    This class is used to add, update and delete estimates in veeva
///   Author:         Snehal Asare                   
///   Notes:          Conatins methods create and get the json
///   Date: 25-12-2016
///   Revision History:
///-----------------------------------------------------------------
public class PW_Update_Expense_Estimates_from_Tp {
    
    public static void Update_Expense_Estimates_Of_Veeva(PW_Estimates_Rest_API_Model estimatesFromTp){

       List<id>  PW_Mapped_Expensetypes= estimatesFromTp.PW_Mapped_Expensetypes;   
        // Query Change to Filterout Budget Cost Category Belonging to Merck.
       list<EM_Expense_Estimate_vod__c> eventEstimatesListOfVeeva=[select id ,Expense_Type_vod__c from EM_Expense_Estimate_vod__c where Expense_Type_vod__c in :PW_Mapped_Expensetypes and Event_vod__c=: estimatesFromTp.Event_Id];
       list<EM_Event_Budget_vod__c> eventBudgetList=[select id from EM_Event_Budget_vod__c where Event_vod__c=: estimatesFromTp.Event_Id];
      
       if(eventBudgetList.size()==0){
               Throw new Pw_ApplicationException('Budget is not added to the event');     
          }
       // Create a savepoint while     
       Savepoint sp = Database.setSavepoint();
       
       if(eventEstimatesListOfVeeva.size()>0){
         Database.DeleteResult[] drList=database.delete(eventEstimatesListOfVeeva,true);
       }
       
       eventEstimatesListOfVeeva.clear();
      PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
        boolean isCommitted =regSettings.PW_IsCommittedForExpenseEstimate__c;
       for(PW_Expense_Estimate_Model estimate : estimatesFromTp.ListOfEstimates){   
        
           EM_Expense_Estimate_vod__c estimateLocal = new EM_Expense_Estimate_vod__c();
           if(isCommitted)
           {
				estimateLocal.Committed_vod__c=estimate.Estimate;      // For Merck         
           }
           else
           {
                  estimateLocal.Estimate_vod__c=estimate.Estimate; 
           }
       
           estimateLocal.Expense_Type_vod__c=estimate.Expense_Type;
           estimateLocal.Expense_Type_Name_vod__c=estimate.Expense_Type_Name;
           estimateLocal.Event_vod__c=estimatesFromTp.Event_Id;
           estimateLocal.Event_Budget_vod__c = eventBudgetList[0].id;
           eventEstimatesListOfVeeva.add(estimateLocal);           
       }       
        Database.SaveResult[] srList=database.insert(eventEstimatesListOfVeeva,false);                
       
       for(Database.SaveResult sr : srList) {

            if (!sr.isSuccess()) {
               Database.rollback(sp);                
               Throw new Pw_ApplicationException(sr.getErrors()[0].getMessage());               
            }
        }
                     
    }
}