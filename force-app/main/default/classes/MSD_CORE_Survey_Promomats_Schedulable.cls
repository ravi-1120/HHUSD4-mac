public class MSD_CORE_Survey_Promomats_Schedulable implements Schedulable  {
    
    public void execute(SchedulableContext param1) {
        MSD_CORE_Survey_For_Promomats b = new MSD_CORE_Survey_For_Promomats();
        Database.executeBatch(b,200);
    }

}