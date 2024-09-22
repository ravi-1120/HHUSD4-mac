global class VEEVA_SCHEDULING_STATE_RESTRICTIONS implements Schedulable{

   global void execute(SchedulableContext sc) {
      
        VEEVA_BATCH_STATE_LEVEL_RESTRICTIONS b = new  VEEVA_BATCH_STATE_LEVEL_RESTRICTIONS();
        database.executebatch(b,200);
   }
}