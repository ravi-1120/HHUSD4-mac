global class MSD_CORE_Identify_MT_Violations_Sch implements schedulable
{
    global void execute(SchedulableContext sc)
    {
    MSD_CORE_Identify_MT_Violations b = new MSD_CORE_Identify_MT_Violations(); //ur batch class
      database.executebatch(b);
    }
}