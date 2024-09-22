global class PW_Estimates_Rest_API_Model {
    public id Event_Id{get;set;}
    public List<PW_Expense_Estimate_Model> ListOfEstimates{get;set;}
    public Integer Message_Id{get;set;}
    public List<Id> PW_Mapped_Expensetypes{get;set;}  //new added  for Merck
}