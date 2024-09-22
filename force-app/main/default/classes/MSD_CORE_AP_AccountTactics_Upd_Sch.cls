global class MSD_CORE_AP_AccountTactics_Upd_Sch implements schedulable
{
    global void execute(SchedulableContext sc)
    {
    MSD_CORE_AP_AccountTactics_Upd b = new MSD_CORE_AP_AccountTactics_Upd(); 
      database.executebatch(b);
    }
}