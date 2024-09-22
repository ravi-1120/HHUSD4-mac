global class PW_Expense_Actuals_Rest_Api_Model {

    public id Event_Id{get;set;}
    public List<Pw_Expense_Header_Model> ListOfActuals{get;set;}
    public Integer Message_Id{get;set;}
    public List<Id> PW_Mapped_Expensetypes{get;set;}  // newly added  for Merc
}