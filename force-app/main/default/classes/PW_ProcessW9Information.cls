///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_ProcessW9Information
///   Description:    This class is a Utility class for for processing Speaker Profile- W9 Information received from TP
///   Author:         Anshuman Hazarika                   
///   Notes:          
///    Date: 21/05/2020
///   Revision History:
/// 1. Created 21/05/2020 New July 2020 release

global class PW_ProcessW9Information
{

    public static void DeleteAllW9ForASpeaker(Id SpeakerID)
    {
        List<PW_W9_Information__c> lstW9Information = [select Id from PW_W9_Information__c where PW_Veeva_Speaker__c =: SpeakerID ];
          if(lstW9Information==null || lstW9Information.size()==0)
          {
                return;
          }
          
          delete lstW9Information;
    }   
    public static string ReturnExpenseTypeNames(string allExpenseTypeIds_semicolseperated)
    {
            String semiColoneSepExpenseTypeNames = '';
            
            if(String.isBlank(allExpenseTypeIds_semicolseperated))
            {
                return semiColoneSepExpenseTypeNames;
            }
            
            List<Id> lstAllExpenseTypeIds = allExpenseTypeIds_semicolseperated.Split(';');
            List<String> expenseNameList = new List<String>();
            
            for(Expense_Type_vod__c expenseType :  [Select id, Name from Expense_Type_vod__c where id in : lstAllExpenseTypeIds ]){
                expenseNameList.add(expenseType.Name);              
            }

            semiColoneSepExpenseTypeNames = String.join(expenseNameList, '; ');
            
            return semiColoneSepExpenseTypeNames;
    }
    
    //Create a records for the W9 objects comming from TP and link it to the speaker
    public static void InsertW9List(List<PW_W9_Information_Model> ListOfW9Info, ID SpeakerID)
    {
        List<PW_W9_Information__c> lstW9Information = new List<PW_W9_Information__c>();
        
        for (PW_W9_Information_Model W9Info : ListOfW9Info )
        {
            PW_W9_Information__c objW9Info = new PW_W9_Information__c();
            
            objW9Info.PW_W9_Address1__c = W9Info.PW_W9_Address1;
            objW9Info.PW_W9_Address2__c = W9Info.PW_W9_Address2;
            objW9Info.PW_W9_City__c = W9Info.PW_W9_City;
            objW9Info.PW_W9_Payee_Name__c = W9Info.PW_W9_Payee_Name;
            objW9Info.PW_W9_Payment_Category__c =ReturnExpenseTypeNames(W9Info.PW_W9_Payment_Category_ID);
            objW9Info.PW_W9_Payment_Category_ID__c = W9Info.PW_W9_Payment_Category_ID;
            objW9Info.PW_Veeva_Speaker__c = SpeakerID;
            objW9Info.PW_W9_StateName__c = W9Info.PW_W9_StateName;
            objW9Info.PW_W9_TIN__c = W9Info.PW_W9_TIN;
            objW9Info.PW_W9_W9TPID__c = W9Info.PW_W9_W9TPID;
            objW9Info.PW_W9_Type__c =  W9Info.PW_W9_Type;
            objW9Info.PW_W9_ZipCode__c = W9Info.PW_W9_ZipCode;
            
            lstW9Information.add(objW9Info);
        
        }
        
        if(lstW9Information.size()!=0)
        {
            insert lstW9Information;
        }

    }
}