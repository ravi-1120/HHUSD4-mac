global class MRK_ScheduledReport_Monthly implements Schedulable {
   global void execute(SchedulableContext sc) {
      MRK_ScheduledReport sr = new MRK_ScheduledReport(); 
      sr.run_report();
   }
}