global class MSD_CORE_Delete_DCO_Monitored_Text_Sch implements schedulable
{
    global void execute(SchedulableContext sc)
    {
    MSD_CORE_Delete_DCO_Monitored_Text b = new MSD_CORE_Delete_DCO_Monitored_Text(); //ur batch class
      database.executebatch(b);
    }
}