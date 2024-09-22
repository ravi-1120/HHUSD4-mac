global class MSD_CORE_Product_Country_Code_SCH implements schedulable
{
    global void execute(SchedulableContext sc)
    {
    MSD_CORE_Product_Country_Code b = new MSD_CORE_Product_Country_Code (); //ur batch class
      database.executebatch(b);
    }
}