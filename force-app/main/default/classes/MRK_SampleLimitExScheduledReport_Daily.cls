global class MRK_SampleLimitExScheduledReport_Daily implements Schedulable {
   global void execute(SchedulableContext sc) {
      MRK_SampleLimitExtractScheduledReport sk= new MRK_SampleLimitExtractScheduledReport(); 
      sk.SampleLimitExtract_report();
   }
}