///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          Pw_Update_Event_Attendee_From_Tp
///   Description:    This class is used to add, update and delete attendee in veeva
///   Author:         Snehal Asare                   
///   Notes:          Conatins methods create and get the json
///   Date: 25-11-2016
///   Revision History:
///-----------------------------------------------------------------
public class Pw_Update_Event_Attendee_From_Tp {
    
    public static list<PW_Attendee_ID_Map_Model> Add_Update_Delete_Attendee_of_Veeva(List<PW_Event_Attendee_Model> AttendeesOfTp){
        
            //Declarartion  
            id eventId =AttendeesOfTp[0].Event_Id ;  
            Map<string,PW_Event_Attendee_Model> mapOfAttendeeOfTp = new Map<string,PW_Event_Attendee_Model>(); 
            Map<string,EM_Attendee_vod__c> mapOfAttendeesOfVeeva = new Map<string,EM_Attendee_vod__c>(); 
            Map<string, Event_Attendee_vod__c> mapOfTpSpeakerIdAndEventAttendees = new Map<string,  Event_Attendee_vod__c>();
            Map<string,EM_Event_Speaker_vod__c> mapOfEventSpeaker = new Map<string,EM_Event_Speaker_vod__c>();
            Map<id,Event_Attendee_vod__c> mapOfEventAttendeesAndAttendee = new Map<id,  Event_Attendee_vod__c>();
            list<PW_Attendee_ID_Map_Model> ResponseList = new list<PW_Attendee_ID_Map_Model>();
            Map<string,Account> mapOfAccount = new Map<string,Account>();
            Map<string,User> mapOfUser= new Map<string,User>();             
            Map<string, Event_Attendee_vod__c> mapOfRowIdAndEventAttendee = new Map<string, Event_Attendee_vod__c>();
        
            //Queries                       
            List<EM_Event_Speaker_vod__c> eventSpeakerList = [SELECT id,Status_vod__c,Speaker_vod__r.PW_Speaker_ID__c FROM EM_Event_Speaker_vod__c where Event_vod__c=: eventId limit: Limits.getLimitQueryRows() - Limits.getQueryRows()];
           
            //Fiiling maps
                    
            Map<ID, Event_Attendee_vod__c> mapOdIdsOfEventAttendee = new Map<ID, Event_Attendee_vod__c>([select id,PW_Event_Attendee_Row_ID__c,EM_Attendee_vod__c,PW_Participant_ID__c,Signature_Datetime_vod__c,EM_Event_Speaker_vod__c,User_vod__r.EmployeeNumber,
                                                                                                        EM_Event_Speaker_vod__r.Speaker_vod__r.PW_Speaker_ID__c,Account_vod__r.PW_Client_ID__c,Status_vod__c from Event_Attendee_vod__c
                                                                                                        where Medical_Event_vod__r.EM_Event_vod__c=: eventId limit :Limits.getLimitQueryRows() - Limits.getQueryRows()]);             
            
            List<Account> accountList = new List<Account>(); //[SELECT id, PW_Client_ID__c,Speaker__c FROM Account  where PW_Client_ID__c!=null and PW_Client_ID__c!=''  limit :Limits.getLimitQueryRows() - Limits.getQueryRows()];
            List<User> userList = [SELECT id,EmployeeNumber FROM User where EmployeeNumber!=null and EmployeeNumber!=''  limit: Limits.getLimitQueryRows() - Limits.getQueryRows()];        
            
            //Filling values
            String accountQuery= 'SELECT id, PW_Client_ID__c,Speaker__c FROM Account  where PW_Client_ID__c in (';
            boolean firstattendee=true;
            integer acccount=0;
            for(PW_Event_Attendee_Model attendee :AttendeesOfTp){                    
                //add all tp attendee id to a set
                    mapOfAttendeeOfTp.put(attendee.PW_Event_Attendee_Row_ID,attendee);  
                    if(attendee.Pw_Client_ID != null || attendee.Pw_Client_ID !='')
                    {
                        acccount++;
                        if(firstattendee==true)
                        {
                            firstattendee=false;
                            accountQuery += '\'' + attendee.Pw_Client_ID  + '\'';
                            
                        }
                        else
                        {
                            
                            accountQuery += ',\'' + attendee.Pw_Client_ID  + '\'';
                    
                        }    
                    }
                }  
                
            accountQuery += ')';
            if(acccount>0)
            {
                accountList = Database.query(accountQuery);
                
            }                                        
        
           for(Event_Attendee_vod__c attendee :mapOdIdsOfEventAttendee.values()){                                
                    mapOfTpSpeakerIdAndEventAttendees.put(attendee.EM_Event_Speaker_vod__r.Speaker_vod__r.PW_Speaker_ID__c, attendee);
                    mapOfEventAttendeesAndAttendee.put(attendee.EM_Attendee_vod__c, attendee);                  
                    mapOfRowIdAndEventAttendee.put(attendee.PW_Event_Attendee_Row_ID__c, attendee);
           } 
           for(EM_Event_Speaker_vod__c eventSpeakertLocal :eventSpeakerList){
                   mapOfEventSpeaker.put(eventSpeakertLocal.Speaker_vod__r.PW_Speaker_ID__c, eventSpeakertLocal);
                }
            
           for(Account accountLocal :accountList){
                 mapOfAccount.put(accountLocal.PW_Client_ID__c,accountLocal);   
                }
        
            for(User userLocal :userList){
                mapOfUser.put(userLocal.EmployeeNumber ,userLocal);   
            }
        
            System.debug('map of  attendee' +mapOfAttendeeOfTp);
            System.debug('Attendee Data of veeva ' +mapOfAttendeesOfVeeva); 
            //System.debug('map of  attendee id' +mapOfIdsOfAttendee);
            System.debug('Attendee Data of event  veeva id ' +mapOdIdsOfEventAttendee); 
        
            Map<ID, EM_Attendee_vod__c> mapOfIdsOfAttendee = new Map<ID, EM_Attendee_vod__c>([select id,PW_Event_Attendee_Row_ID__c,PW_Participant_ID__c, Signature_Datetime_vod__c,Status_vod__c from EM_Attendee_vod__c 
                                                                             where Event_vod__c=: eventId  limit :Limits.getLimitQueryRows() - Limits.getQueryRows()]);
        
            //Add or Update the Attendee             
            AddOrUpdateAttendeesOfVeevaEvent(AttendeesOfTp,mapOdIdsOfEventAttendee,mapOfRowIdAndEventAttendee,mapOfEventSpeaker,mapOfEventAttendeesAndAttendee,mapOfTpSpeakerIdAndEventAttendees,mapOfAccount,mapOfUser,ResponseList,mapOfIdsOfAttendee);
          
            for(EM_Attendee_vod__c attendee :mapOfIdsOfAttendee.values()){    
                if(attendee.PW_Event_Attendee_Row_ID__c!=null){                         
                    mapOfAttendeesOfVeeva.put(attendee.PW_Event_Attendee_Row_ID__c, attendee);
                } 
            }
                      
            // Delete extra attendees from the veeva event    
             DeleteAttendeesFromVeevaEvent(mapOfAttendeesOfVeeva,mapOfAttendeeOfTp,mapOfEventAttendeesAndAttendee,ResponseList); 
           
            //Clear Junk data from Event Attendee   
             ClearJunkEventAttendees(eventId);
             System.debug('Response result' +ResponseList);           
            return ResponseList;        
        }  
    
    static list<PW_Attendee_ID_Map_Model> AddOrUpdateAttendeesOfVeevaEvent(List<PW_Event_Attendee_Model> AttendeesOfTp,Map<id,Event_Attendee_vod__c> EventAttendeesOfVeeva,Map<string,  Event_Attendee_vod__c> mapOfRowIdAndEventAttendee,
                                                                           Map<string,EM_Event_Speaker_vod__c> mapOfEventSpeaker,Map<id,Event_Attendee_vod__c> mapOfEventAttendeesAndAttendee,Map<string,Event_Attendee_vod__c> mapOfTpSpeakerIdAndEventAttendees,
                                                                           Map<string,Account> mapOfAccount,Map<string,User> mapOfUser,list<PW_Attendee_ID_Map_Model> ResponseList,Map<ID, EM_Attendee_vod__c> mapOfIdsOfAttendee){ 
        
         List<sObject> EventAttendeeListToBeUpdated = new List<sObject>();
         List<Event_Attendee_vod__c> eventAttendeeExtraUpdation = new List<Event_Attendee_vod__c>();
         List<EM_Attendee_vod__c> AttendeeListToBeInserted = new List<EM_Attendee_vod__c>();
         EM_Attendee_vod__c attendee;
         //list<PW_Attendee_ID_Map_Model> ResponseList = new  list<PW_Attendee_ID_Map_Model> ();
                                    
         for(PW_Event_Attendee_Model attendeeModel : AttendeesOfTp){  
             System.debug('Attendee Data in for loop '+attendeeModel.Veeva_Attendee_Id);
              System.debug('Attendee Data in for loop '+EventAttendeesOfVeeva.keySet()); 
            
             CheckDuplicatesAndStatus(attendeeModel,mapOfRowIdAndEventAttendee);
             
             if(attendeeModel.Veeva_Attendee_Id==null || string.isBlank(string.valueOf(attendeeModel.Veeva_Attendee_Id)))
             {
                 system.debug('Attendee Data in for loop if ');
                 if(attendeeModel.Attendee_Type!='Speaker')
                 { 
                     system.debug('Attendee Data in for loop if ');
                     attendee = Pw_Event_Attendee_Manipulation.AddingAttendee(attendeeModel,mapOfAccount,mapOfUser,ResponseList);
                     system.debug('Attendee Data value  '+attendee);
                     if(attendee!=null)
                     {
                         AttendeeListToBeInserted.add(attendee);   
                     }
                 }else{ 
                     system.debug('Attendee Data in for loop else ');
                     Pw_Event_Attendee_Manipulation.UpdatingSpekerAttendee(attendeeModel,EventAttendeesOfVeeva,EventAttendeeListToBeUpdated,mapOfTpSpeakerIdAndEventAttendees,ResponseList,mapOfEventSpeaker);
                 }
            }else {
                 
                  if(EventAttendeesOfVeeva.keySet().contains(attendeeModel.Veeva_Attendee_Id)){ 
                         System.debug('Attendee Data in else '); 
                         System.debug('attendeeModel '+attendeeModel);
                         System.debug('EventAttendeesOfVeeva '+EventAttendeesOfVeeva);
                         System.debug('mapOfEventSpeaker '+mapOfEventSpeaker);
                         System.debug('mapOfIdsOfAttendee '+mapOfIdsOfAttendee);
                         EventAttendeeListToBeUpdated.addAll(Pw_Event_Attendee_Manipulation.UpdatingAttendee(attendeeModel,EventAttendeesOfVeeva,mapOfEventSpeaker,mapOfIdsOfAttendee,eventAttendeeExtraUpdation));
                    }else{
                      ResponseList.add(new PW_Attendee_ID_Map_Model(attendeeModel.Veeva_Attendee_Id,
                                                                    attendeeModel.PW_Event_Attendee_Row_ID,
                                                                    attendeeModel.PW_Participant_ID,
                                                                    'Skipped Record'));                 
                    } 
             }
         }
        
         Pw_Event_Attendee_Manipulation.InsertOrUpdateAttendee(EventAttendeeListToBeUpdated,AttendeeListToBeInserted,ResponseList,AttendeesOfTp[0].Event_Id,eventAttendeeExtraUpdation );
         System.debug('loop in insert and update attendee after insertion done and map fill back to add'+ResponseList);
        return ResponseList;
     }        
    
    static void DeleteAttendeesFromVeevaEvent(Map<string,EM_Attendee_vod__c> AttendeesOfVeeva,Map<string,PW_Event_Attendee_Model> mapOfAttendeeFromTp,
                                                                        Map<ID, Event_Attendee_vod__c> mapOfEventAttendeesAndAttendee,list<PW_Attendee_ID_Map_Model> ResponseList){ 
        //list<PW_Attendee_ID_Map_Model> ResponseList= new  list<PW_Attendee_ID_Map_Model> ();
            List<EM_Attendee_vod__c> AttendeeListToBeDeleted = new List<EM_Attendee_vod__c>();            
            
            for(String rowId : AttendeesOfVeeva.keySet()){
                  if(!mapOfAttendeeFromTp.keySet().contains(rowId)){
                      if(AttendeesOfVeeva.get(rowId).Signature_Datetime_vod__c!=null)
                      {  
                         System.debug('in signed attendee');
                        ResponseList.add(new PW_Attendee_ID_Map_Model(mapOfEventAttendeesAndAttendee.get(AttendeesOfVeeva.get(rowId).id).id,
                                                                      AttendeesOfVeeva.get(rowId).PW_Event_Attendee_Row_ID__c,
                                                                      AttendeesOfVeeva.get(rowId).PW_Participant_ID__c,
                                                                     'error: Signed Attendee cannot be deleted')) ; 
                      }else{
                           AttendeeListToBeDeleted.add(AttendeesOfVeeva.get(rowId));
                      }
                  }              
              } 
            if(AttendeeListToBeDeleted.size()>0){
               // Database.DeleteResult[] drList = Database.delete(AttendeeListToBeDeleted, false);
                Pw_Event_Attendee_Manipulation.DeleteAttendee(AttendeeListToBeDeleted,mapOfEventAttendeesAndAttendee,ResponseList);
               // Delete AttendeeListToBeDeleted;
            }
        
        // return ResponseList;
     }

    static void ClearJunkEventAttendees(id eventId){
       list<Event_Attendee_vod__c> juckDataList = new list<Event_Attendee_vod__c> (); 
      juckDataList.addall([select id from Event_Attendee_vod__c where Medical_Event_vod__r.EM_Event_vod__c=: eventId and 
                            EM_Attendee_vod__c=null and  EM_Event_Speaker_vod__c=null and EM_Event_Team_Member_vod__c=null ]); // Added 'and EM_Event_Team_Member_vod__c=null' for ticket 68021 
        
        delete juckDataList;
    }
        
    static void CheckDuplicatesAndStatus(PW_Event_Attendee_Model attendeeModel,Map<string,Event_Attendee_vod__c> mapOfRowIdAndEventAttendee){
       if(attendeeModel.Veeva_Attendee_Id==null || string.isBlank(string.valueOf(attendeeModel.Veeva_Attendee_Id)))
          {
               if(string.isNotBlank(attendeeModel.PW_Event_Attendee_Row_ID)) 
                 {
                     if(mapOfRowIdAndEventAttendee.keyset().contains(attendeeModel.PW_Event_Attendee_Row_ID))
                     {
                        attendeeModel.Veeva_Attendee_Id= mapOfRowIdAndEventAttendee.get(attendeeModel.PW_Event_Attendee_Row_ID).id;  
                     } 
                 }              
         }
        if(string.isBlank(attendeeModel.Status)){
            attendeeModel.Status='Invited';
        }  
        
    }
}