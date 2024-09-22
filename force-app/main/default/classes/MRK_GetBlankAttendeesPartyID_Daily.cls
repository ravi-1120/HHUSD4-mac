global class MRK_GetBlankAttendeesPartyID_Daily implements Schedulable {
    global void execute(SchedulableContext sc) {
       MRK_GetBlankAttendeesPartyID s= new MRK_GetBlankAttendeesPartyID(); 
       s.GetBlankAttendeesPartyID();
    }
 }