global class MSD_CORE_Speaker_Biography_Upd_Sch implements schedulable
{
    global void execute(SchedulableContext sc)
    {
    MSD_CORE_Speaker_Biography_Upd b = new MSD_CORE_Speaker_Biography_Upd (); 
      database.executebatch(b);
    }
}