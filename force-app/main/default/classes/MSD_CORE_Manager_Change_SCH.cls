global class MSD_CORE_Manager_Change_SCH implements schedulable
{
    global void execute(SchedulableContext sc)
    {
    MSD_CORE_Manager_Change b = new MSD_CORE_Manager_Change(); 
      database.executebatch(b);
    }
}