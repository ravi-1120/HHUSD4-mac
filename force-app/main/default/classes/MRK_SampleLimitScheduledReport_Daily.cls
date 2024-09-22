global class MRK_SampleLimitScheduledReport_Daily implements Schedulable {
   global void execute(SchedulableContext sc) {
      MRK_SampleLimitScheduledReport s= new MRK_SampleLimitScheduledReport(); 
      s.SampleLimit_report();
   }
}