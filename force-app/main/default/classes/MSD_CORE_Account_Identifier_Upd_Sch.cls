global class MSD_CORE_Account_Identifier_Upd_Sch implements schedulable
{
    global void execute(SchedulableContext sc)
    {
    MSD_CORE_Account_Identifier_Upd b = new MSD_CORE_Account_Identifier_Upd(); 
      database.executebatch(b);
    }
}