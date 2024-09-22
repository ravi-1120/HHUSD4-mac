public class Pw_Expense_Header_Model {
    
    public decimal Actual{set;get;}   
    public string Payee_Tp_Speaker_Id{set;get;}  
    public id Payee_Vendor{set;get;}
    public id Payee_Venue{set;get;}
    public date Payment_Date{set;get;}
    public string Status{set;get;}
    
    public string Incurred_Expense_Tp_Speaker_Id{set;get;}  
    public id Incurred_Expense_Vendor{set;get;}
    public id Incurred_Expense_Venue{set;get;}
    
    public List<Pw_Expense_Line_Model> ListOfExpenseLines{get;set;}
}