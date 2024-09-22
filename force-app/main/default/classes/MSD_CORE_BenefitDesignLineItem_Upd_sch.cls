global class MSD_CORE_BenefitDesignLineItem_Upd_sch implements schedulable
{
    global void execute(SchedulableContext sc)
    {
    MSD_CORE_BenefitDesignLineItem_Update b = new MSD_CORE_BenefitDesignLineItem_Update(); //ur batch class
      database.executebatch(b);
    }
}