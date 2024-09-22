global class MRK_FFMEventAttachmentVerify_Weekly implements Schedulable {
   global void execute(SchedulableContext sc) {
      MRK_FFMEventAttachmentVerify av = new MRK_FFMEventAttachmentVerify(); 
      av.EventVerify();
   }
}