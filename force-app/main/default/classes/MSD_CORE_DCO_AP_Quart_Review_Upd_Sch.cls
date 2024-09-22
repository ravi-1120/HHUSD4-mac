global class MSD_CORE_DCO_AP_Quart_Review_Upd_Sch implements schedulable
{
    global void execute(SchedulableContext sc)
    {
    MSD_CORE_DCO_AP_Quart_Review_Flag_Upd b = new MSD_CORE_DCO_AP_Quart_Review_Flag_Upd(); 
      database.executebatch(b);
    }
}