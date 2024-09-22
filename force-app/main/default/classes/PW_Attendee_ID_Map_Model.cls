///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_Attendee_ID_Map_Model
///   Description:    This class is a Model class for attendee object 
///   Author:         Nitesh Kodle                   
///   Notes:          Conatins methods to initialize data members of class for attendee objecr
///    Date: 20-12-2016
///   Revision History:
global class PW_Attendee_ID_Map_Model{

    public string Veeva_ID{get;set;}
    public string PW_Event_Attendee_Row_ID{get;set;} //TP Attendee Id
    public string PW_Participant_ID{get;set;}
    public string Message{get;set;}
    
    public PW_Attendee_ID_Map_Model()
    {
        
        
    }
    public PW_Attendee_ID_Map_Model(String attendeeid, String rowid, String participantId, String errorMessage)
    {
        
        	Veeva_ID=attendeeid;
            PW_Event_Attendee_Row_ID=rowid;
            PW_Participant_ID=participantId;
            Message=errorMessage;
    }
    
    public static list<PW_Attendee_ID_Map_Model> FillAttendeeIdMapModel(Map<id,string> mapOfIdsAndErrors,Map<ID, Event_Attendee_vod__c> mapOdIdsOfEventAttendee){
        
        System.debug('Attendee id and error' +mapOfIdsAndErrors);
        list<PW_Attendee_ID_Map_Model> ResponseList = new list<PW_Attendee_ID_Map_Model>();
        
        for(id IdOfErrorMap:mapOfIdsAndErrors.keySet()){
                             
            if(mapOdIdsOfEventAttendee.keySet().contains(IdOfErrorMap)){
                
                  ResponseList.add(new PW_Attendee_ID_Map_Model(IdOfErrorMap,
                                                                mapOdIdsOfEventAttendee.get(IdOfErrorMap).PW_Event_Attendee_Row_ID__c,
                                                                mapOdIdsOfEventAttendee.get(IdOfErrorMap).PW_Participant_ID__c,
                                                                mapOfIdsAndErrors.get(IdOfErrorMap)));                                  
            }
          }                                
        
       	System.debug('Attendee id and error' +ResponseList); 
        return ResponseList;
        
    }
    
    
}