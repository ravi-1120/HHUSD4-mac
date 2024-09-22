///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          Pw_AutoSelect_Budget_To_Event 
///   Description:    This class adds a budget to event 
///   Author:         Khushbu Khetan                  
///   Notes:          Conatins methods which will add budget to event
///   Date: 27-12-2017
///   Revision History:
///-----------------------------------------------------------------
public class Pw_AutoSelect_Budget_To_Event {

     public string errorMessage{get;set;}

     //This method auto selects budget for the event.
     public boolean AutoSelectBudgetToEvent(Id eventId){  
            boolean isBudgetAutoSelected = false;    
            errorMessage = '';  
            List<EM_Event_Budget_vod__c> eventBudgetList = new List<EM_Event_Budget_vod__c>();
            try
            {
                eventBudgetList = [select Id from EM_Event_Budget_vod__c where Event_vod__c=:eventId limit 1];
                if(eventBudgetList.size()==0)
                {
                    List<EM_Budget_vod__c> BudgetList = [select Id,Name from EM_Budget_vod__c];
                    if(BudgetList!=null && BudgetList.size()>0)
                    {
                        if(BudgetList.size()==1)
                        {
                            EM_Event_Budget_vod__c eventBudget = new EM_Event_Budget_vod__c ();
                            eventBudget.Budget_vod__c = BudgetList[0].Id;
                            eventBudget.Event_vod__c = eventId;
                            insert eventBudget;
                            isBudgetAutoSelected =true;
                        }
                        else if(BudgetList.size()>1)
                        {
                            /*PW_General_Settings__c regSettings = PW_General_Settings__c.getValues('General Settings');
                            for(EM_Budget_vod__c budget : BudgetList)
                            {
                                if(budget.Name == regSettings.PW_Budget_Name__c)
                                {
                                    EM_Event_Budget_vod__c eventBudget = new EM_Event_Budget_vod__c ();
                                    eventBudget.Budget_vod__c = budget.Id;
                                    eventBudget.Event_vod__c = eventId;
                                    insert eventBudget;
                                    isBudgetAutoSelected =true;
                                    break;
                                }
                            }
                            
                            if(!isBudgetAutoSelected)
                            {
                                system.debug('Budget with the name in custom settings is not present in org');
                                errorMessage = 'Budget with the name in custom settings is not present in org';
                            }*/
                            isBudgetAutoSelected = false;
                            errorMessage = 'Budget not selected';
                            
                        }
                    }
                    else
                    {
                        system.debug('Budget not present in org');
                        errorMessage = 'Budget not present in org';
                        isBudgetAutoSelected =false;
                    }
                }
                else
                {
                    isBudgetAutoSelected =true;
                }
            }
            catch(Exception ex)
            {
                PW_Log_Into_CustomLogger.Log(ex.getStackTraceString(),ex.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
                system.debug('Exception : '+ex.getMessage());
                errorMessage = 'Auto Budget selection error : '+ex.getMessage();
                isBudgetAutoSelected = false;
            }
            return isBudgetAutoSelected;
            
     }
     
     
      //This method validates budget for the event.
     public boolean ValidateBudgetForEvent(Id eventId){ 
         boolean validateBudget = false;
         List<EM_Event_Budget_vod__c> eventBudgetList = new List<EM_Event_Budget_vod__c>();
         try
            {
                eventBudgetList = [select Id from EM_Event_Budget_vod__c where Event_vod__c=:eventId limit 1];
                if(eventBudgetList.size()==0)
                {
                    List<EM_Budget_vod__c> BudgetList = [select Id,Name from EM_Budget_vod__c];
                    if(BudgetList!=null && BudgetList.size()>0)
                    {
                        if(BudgetList.size()==1)
                        {
                            validateBudget = true;
                        }
                        else if(BudgetList.size()>1)
                        {
                            system.debug('Please select a budget');
                            errorMessage = 'Please select a budget';
                            validateBudget = false;
                        }
                        
                    }
                    else
                    {
                        system.debug('Budget not present in org');
                        errorMessage = 'Budget not present in org';
                        validateBudget = false;
                    }
                    
                }
                else
                {
                    validateBudget = true;
                }
            }
            catch(Exception ex)
            {
                PW_Log_Into_CustomLogger.Log(ex.getStackTraceString(),ex.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
                system.debug('Exception : '+ex.getMessage());
                errorMessage = 'Auto Budget selection error : '+ex.getMessage();
                validateBudget = false;
            }
           return validateBudget;     
     }
     
     
     
}