public class PW_QueueableAddUpdateAttendee implements Queueable {
    public List<PW_Event_Attendee_Model> AttendeesFromTp{get;set;}
    
    public void execute(QueueableContext context){
        
        try
        {
            list<PW_Attendee_ID_Map_Model> eventAttendeeVeevaAndRowIds = new list<PW_Attendee_ID_Map_Model>();
            if(AttendeesFromTp!=null || AttendeesFromTp.size()>0){
              eventAttendeeVeevaAndRowIds=Pw_Update_Event_Attendee_From_Tp.Add_Update_Delete_Attendee_of_Veeva(AttendeesFromTp); //Manipulate veeva attendee
              }
             else{
                 Throw new Jsonexception('No Attendee has been passed, Attendeee Json not found');//throw exception in case no event has been passed
             }
             
            PW_QueueableAttendeeCallout attendeeCallOut = new PW_QueueableAttendeeCallout();
            
            attendeeCallOut.MessageId=AttendeesFromTp[0].Message_Id;
            attendeeCallOut.EventId = AttendeesFromTp[0].Event_Id;
            attendeeCallOut.eventAttendeeVeevaAndRowIds = eventAttendeeVeevaAndRowIds;
            
            for(PW_Attendee_ID_Map_Model attendee:eventAttendeeVeevaAndRowIds){
                 if(attendee.Message.startswith('error')){
                   attendeeCallOut.Message='Some records are not processed properly';
                   attendeeCallOut.Status='Fail';
                   break;
                 } else{
                       attendeeCallOut.Status='Success';  
                      attendeeCallOut.Message='All records are processed properly';
                 }
                 
             }
            
            System.enqueueJob(attendeeCallOut);
             
        }
        catch(exception ex){
                     
            PW_QueueableAttendeeCallout attendeeCallOut= new PW_QueueableAttendeeCallout();
            attendeeCallOut.Message = ex.getMessage();
            attendeeCallOut.Status='Fail';
            attendeeCallOut.MessageId=AttendeesFromTp[0].Message_Id;
            attendeeCallOut.EventId = AttendeesFromTp[0].Event_Id;
            PW_Log_Into_CustomLogger.Log(ex.getStackTraceString(),ex.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
            System.enqueueJob(attendeeCallOut);
            
        }
    }
}