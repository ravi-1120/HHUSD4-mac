global class MRK_User_Emp_AccountId_Upd_Sch implements schedulable
{
    global void execute(SchedulableContext sc)
    {
    MRK_User_Emp_AccountId_Upd b = new MRK_User_Emp_AccountId_Upd(); 
      database.executebatch(b);
    }
}