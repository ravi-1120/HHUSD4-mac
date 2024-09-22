public class Pw_Expense_Line_Model {
    
      public decimal Actual{set;get;}    
      public decimal Committed{set;get;}    
      public id Event_Budget{set;get;}  
      public id Expense_Header{set;get;}    
      public string Expense_Type{set;get;}  
      public string Expense_Type_Name{set;get;}  
      public string Payment_Status{set;get;}
      public boolean Is_Payment_Through_Cheque{set;get;}    
}