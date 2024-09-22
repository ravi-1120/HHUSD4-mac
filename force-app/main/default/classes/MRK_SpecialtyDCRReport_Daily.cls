global class MRK_SpecialtyDCRReport_Daily implements Schedulable {
   global void execute(SchedulableContext sc) {
      MRK_SpecialtyDCRReport sr = new MRK_SpecialtyDCRReport(); 
      sr.runReport();
   }
}