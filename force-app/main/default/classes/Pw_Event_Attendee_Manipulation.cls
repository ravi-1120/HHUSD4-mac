///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          Pw_Event_Attendee_Manipulation
///   Description:    This class is used to add, update and delete attendee in veeva
///   Author:         Snehal Asare                   
///   Notes:         
///   Date: 25-12-2016
///   Revision History:
///-----------------------------------------------------------------
public class Pw_Event_Attendee_Manipulation {
    
    public static EM_Attendee_vod__c AddingAttendee(PW_Event_Attendee_Model newAttendee,Map<string,Account> mapOfVeevaAccounts,Map<string,User> mapOfVeevaUsers,list<PW_Attendee_ID_Map_Model> ResponseList){
      
        EM_Attendee_vod__c  newlyCreatedAttendee = new  EM_Attendee_vod__c(); 
        system.debug('Attendee Data in for loop if ' +newAttendee.Attendee_Type);
        //Adding of event speaker would not be their, so no check for it
        if(string.isBlank(newAttendee.Attendee_Type)){
           ResponseList.add(new PW_Attendee_ID_Map_Model(null,
                                                         newAttendee.PW_Event_Attendee_Row_ID,
                                                         newAttendee.Pw_Participant_ID,
                                                         'error: Attendee Type is blank, Please provide attendee type')); 
                return null; 
        }         
        
        if(newAttendee.Attendee_Type=='User') {
            if(string.isNotBlank(newAttendee.Pw_Employee_number) && mapOfVeevaUsers.get(newAttendee.Pw_Employee_number)!=null){
            newlyCreatedAttendee.User_vod__c=mapOfVeevaUsers.get(newAttendee.Pw_Employee_number).id;  
            }else{
               ResponseList.add(new PW_Attendee_ID_Map_Model(null,
                                                             newAttendee.PW_Event_Attendee_Row_ID,
                                                             newAttendee.Pw_Participant_ID,
                                                             'error: User Not Found, Please check the Employee Number')); 
                return null;
            }
        } 
        
        if(newAttendee.Attendee_Type=='Account') {
            
            if(string.isNotBlank(newAttendee.Pw_Client_ID) && mapOfVeevaAccounts.get(newAttendee.Pw_Client_ID)!=null){
            newlyCreatedAttendee.Account_vod__c =mapOfVeevaAccounts.get(newAttendee.Pw_Client_ID).id;  
            newlyCreatedAttendee.PW_Client_ID__c =newAttendee.Pw_Client_ID;
            }else{
               ResponseList.add(new PW_Attendee_ID_Map_Model(null,
                                                             newAttendee.PW_Event_Attendee_Row_ID,
                                                             newAttendee.Pw_Participant_ID,
                                                             'error: Account Not Found, Please check the Pw_Client_Id')); 
                return null;
            }
        } 
        
        if(newAttendee.Attendee_Type=='Walk In') {
            newlyCreatedAttendee.Walk_In_Status_vod__c ='Needs_Reconciliation_vod';  
            newlyCreatedAttendee.Credentials_vod__c=newAttendee.Pw_Credentials;
            newlyCreatedAttendee.PW_Specialty__c=newAttendee.Pw_Specialty; 
            newlyCreatedAttendee.First_Name_vod__c=newAttendee.First_Name;
            newlyCreatedAttendee.Last_Name_vod__c=newAttendee.Last_Name;
            newlyCreatedAttendee.Address_Line_1_vod__c=newAttendee.Address_Line_1;
            newlyCreatedAttendee.PW_Salutation__c=newAttendee.Pw_Salutation;
            newlyCreatedAttendee.Pw_Address_Type__c=newAttendee.Pw_Address_Type;
            newlyCreatedAttendee.PW_Office_Name__c=newAttendee.Pw_Office_Name;
            newlyCreatedAttendee.City_vod__c=newAttendee.City;
            newlyCreatedAttendee.PW_State__c=newAttendee.Pw_State;
            newlyCreatedAttendee.Zip_vod__c=newAttendee.Zip; 
            newlyCreatedAttendee.PW_Attendee_Type__c =newAttendee.Pw_Attendee_Type;
            newlyCreatedAttendee.PW_SL_State__c =newAttendee.PW_SL_State;
            newlyCreatedAttendee.PW_SL__c =newAttendee.PW_SL;
            newlyCreatedAttendee.PW_NPI__c =newAttendee.PW_NPI;
            newlyCreatedAttendee.PW_Position__c =newAttendee.PW_Position;
            newlyCreatedAttendee.Email_vod__c =newAttendee.Email;      //Added for Merck
            newlyCreatedAttendee.Phone_vod__c =newAttendee.Phone;      //Added for Merck
            newlyCreatedAttendee.PW_MobNo__c =newAttendee.PW_MobNo;      //Added for Merck
            newlyCreatedAttendee.Walk_In_Type_vod__c =newAttendee.Walk_In_Type;      // 51076 Support new Veeva Walk-In field -> TP to Veeva
            
        }   
        
        newlyCreatedAttendee.Event_vod__c = newAttendee.Event_Id;
        newlyCreatedAttendee.Status_vod__c = newAttendee.Status;
        newlyCreatedAttendee.PW_Participant_ID__c = newAttendee.Pw_Participant_ID;
        newlyCreatedAttendee.Meal_Opt_In_vod__c = newAttendee.Meal_Opt_In;
        newlyCreatedAttendee.PW_Event_Attendee_Row_ID__c = newAttendee.PW_Event_Attendee_Row_ID;
        
        // For Merck
        newlyCreatedAttendee.PW_Samples__c=newAttendee.PW_Samples;
        newlyCreatedAttendee.PW_SKit__c=newAttendee.PW_Sample_Kit;
        newlyCreatedAttendee.PW_SLotNo__c=newAttendee.PW_Samples_Lot_Number;
        
        // 49142 Supports the designation with the EM Integration - May Release 2021
        newlyCreatedAttendee.PW_Professional_Designation__c=newAttendee.PW_Professional_Designation;
        
        
       return newlyCreatedAttendee;
    }
       
    public static List<sobject> UpdatingAttendee(PW_Event_Attendee_Model newAttendee,Map<id,Event_Attendee_vod__c> EventAttendeesOfVeeva,Map<string,EM_Event_Speaker_vod__c> mapOfEventSpeaker,Map<ID, EM_Attendee_vod__c> mapOfIdsOfAttendee,List<Event_Attendee_vod__c> eventAttendeeExtraUpdation){
         List<sobject> updatedSobjectList = new List<sobject>();
         List<Event_Attendee_vod__c> updatingEventattendeetList = new List<Event_Attendee_vod__c>();        
        System.debug('Attendee Data in speaker in first');
        if(newAttendee.Attendee_Type=='Speaker'){
            
            EM_Event_Speaker_vod__c eventSpeakerLocal = new EM_Event_Speaker_vod__c();
                eventSpeakerLocal.Meal_Opt_In_vod__c=newAttendee.Meal_Opt_In;
                if(newAttendee.Status.contains('Attended') && mapOfEventSpeaker.get(newAttendee.Speaker_Tp_Id).Status_vod__c.contains('Signed')){
                    eventSpeakerLocal.Status_vod__c = mapOfEventSpeaker.get(newAttendee.Speaker_Tp_Id).Status_vod__c;
                } 
                else
                {
                    eventSpeakerLocal.Status_vod__c = newAttendee.Status;
                }
                eventSpeakerLocal.id = mapOfEventSpeaker.get(newAttendee.Speaker_Tp_Id).id; 
                updatedSobjectList.add(eventSpeakerLocal);
            
             System.debug('Attendee Data in event speaker '+eventSpeakerLocal);
             Event_Attendee_vod__c  existingAttendee = new  Event_Attendee_vod__c();   
               if(newAttendee.Status.contains('Attended') && EventAttendeesOfVeeva.get(newAttendee.Veeva_Attendee_Id).Status_vod__c.contains('Signed')){      
                    existingAttendee.Status_vod__c = EventAttendeesOfVeeva.get(newAttendee.Veeva_Attendee_Id).Status_vod__c; 
               }
               else
               {
                    existingAttendee.Status_vod__c = newAttendee.Status; 
               }
               existingAttendee.Meal_Opt_In_vod__c = newAttendee.Meal_Opt_In;
               existingAttendee.id=newAttendee.Veeva_Attendee_Id;
               existingAttendee.PW_Participant_ID__c=newAttendee.Pw_Participant_ID; 
               existingAttendee.PW_Event_Attendee_Row_ID__c=newAttendee.PW_Event_Attendee_Row_ID;
               updatedSobjectList.add(existingAttendee);
              
               System.debug('Attendee Data in speaker '+existingAttendee);             
                            
                return updatedSobjectList;            
            
        }else{            
             EM_Attendee_vod__c  existingAttendee = new  EM_Attendee_vod__c(); 
            
            if(newAttendee.Attendee_Type=='Walk In'){   
                 System.debug('Attendee Data in walk in ');
                existingAttendee.Credentials_vod__c=newAttendee.Pw_Credentials;
                existingAttendee.PW_Specialty__c=newAttendee.Pw_Specialty; 
                existingAttendee.First_Name_vod__c=newAttendee.First_Name;
                existingAttendee.Last_Name_vod__c=newAttendee.Last_Name;
                existingAttendee.Address_Line_1_vod__c=newAttendee.Address_Line_1;
                existingAttendee.PW_Salutation__c=newAttendee.Pw_Salutation;
                existingAttendee.Pw_Address_Type__c=newAttendee.Pw_Address_Type;
                existingAttendee.PW_Office_Name__c=newAttendee.Pw_Office_Name;
                existingAttendee.City_vod__c=newAttendee.City;
                existingAttendee.PW_State__c=newAttendee.Pw_State;
                existingAttendee.Zip_vod__c=newAttendee.Zip; 
                existingAttendee.PW_Attendee_Type__c =newAttendee.Pw_Attendee_Type;  
                existingAttendee.PW_SL_State__c =newAttendee.PW_SL_State;
                existingAttendee.PW_SL__c =newAttendee.PW_SL;
                existingAttendee.PW_NPI__c =newAttendee.PW_NPI; 
                existingAttendee.PW_Position__c =newAttendee.PW_Position;
                existingAttendee.Email_vod__c =newAttendee.Email;      //Added for Merck
              existingAttendee.Phone_vod__c =newAttendee.Phone;      //Added for Merck
              existingAttendee.PW_MobNo__c =newAttendee.PW_MobNo;      //Added for Merck
              existingAttendee.Walk_In_Type_vod__c =newAttendee.Walk_In_Type;      // 51076 Support new Veeva Walk-In field -> TP to Veeva
            }
             System.debug('Attendee Data in general ');
               if(newAttendee.Status.contains('Attended') && mapOfIdsOfAttendee.get(EventAttendeesOfVeeva.get(newAttendee.Veeva_Attendee_Id).EM_Attendee_vod__c).Status_vod__c.contains('Signed')){
                    existingAttendee.Status_vod__c = mapOfIdsOfAttendee.get(EventAttendeesOfVeeva.get(newAttendee.Veeva_Attendee_Id).EM_Attendee_vod__c).Status_vod__c;
               }
               else
               {
                 existingAttendee.Status_vod__c = newAttendee.Status;
               } 
               existingAttendee.Meal_Opt_In_vod__c = newAttendee.Meal_Opt_In;
               existingAttendee.id= EventAttendeesOfVeeva.get(newAttendee.Veeva_Attendee_Id).EM_Attendee_vod__c;
               existingAttendee.PW_Participant_ID__c=newAttendee.Pw_Participant_ID; 
               existingAttendee.PW_Event_Attendee_Row_ID__c=newAttendee.PW_Event_Attendee_Row_ID;
              System.debug('Attendee Data in general '+existingAttendee);
               // For Merck
               existingAttendee.PW_Samples__c=newAttendee.PW_Samples;
              existingAttendee.PW_SKit__c=newAttendee.PW_Sample_Kit;
              existingAttendee.PW_SLotNo__c=newAttendee.PW_Samples_Lot_Number;
              
              // 49142 Supports the designation with the EM Integration - May Release 2021
              existingAttendee.PW_Professional_Designation__c=newAttendee.PW_Professional_Designation;
               
               
              Event_Attendee_vod__c  existingEventAttendee = new  Event_Attendee_vod__c();
              existingEventAttendee.Status_vod__c = existingAttendee.Status_vod__c;
              existingEventAttendee.id= newAttendee.Veeva_Attendee_Id;
              existingEventAttendee.PW_Participant_ID__c= existingAttendee.PW_Participant_ID__c;
              existingEventAttendee.PW_Event_Attendee_Row_ID__c= existingAttendee.PW_Event_Attendee_Row_ID__c;
              existingEventAttendee.Meal_Opt_In_vod__c = existingAttendee.Meal_Opt_In_vod__c;
              
             // For Merck
               existingEventAttendee.PW_Samples__c=existingAttendee.PW_Samples__c;
              existingEventAttendee.PW_SKit__c=existingAttendee.PW_SKit__c;
              existingEventAttendee.PW_SLotNo__c=existingAttendee.PW_SLotNo__c;
              
              // 49142 Supports the designation with the EM Integration - May Release 2021
              existingEventAttendee.PW_Professional_Designation__c=existingAttendee.PW_Professional_Designation__c;
            
              updatedSobjectList.add(existingAttendee);
              eventAttendeeExtraUpdation.add(existingEventAttendee);
                
               return updatedSobjectList;
          }               
      // System.debug('updating attendee'+existingAttendee);               
    }  
    
    public static void UpdatingSpekerAttendee(PW_Event_Attendee_Model newAttendee,Map<id,Event_Attendee_vod__c> EventAttendeesOfVeeva,List<sobject> EventAttendeeListToBeUpdated,
                                                       Map<string,Event_Attendee_vod__c> mapOfTpSpeakerIdAndEventAttendees,list<PW_Attendee_ID_Map_Model> ResponseList,Map<string,EM_Event_Speaker_vod__c> mapOfEventSpeaker){         
            if(newAttendee.Speaker_Tp_Id!=null && mapOfTpSpeakerIdAndEventAttendees.keySet().contains(newAttendee.Speaker_Tp_Id)){
             
                    Event_Attendee_vod__c attendee =mapOfTpSpeakerIdAndEventAttendees.get(newAttendee.Speaker_Tp_Id);          
                    system.debug('Attendee speaker null veeva id if'+attendee+'apeaker');
                                  
                     Event_Attendee_vod__c  existingAttendee = new  Event_Attendee_vod__c();  
                        if(newAttendee.Status.contains('Attended') && attendee.Status_vod__c.contains('Signed')){      
                            existingAttendee.Status_vod__c = attendee.Status_vod__c;
                        }
                        else
                        {
                            existingAttendee.Status_vod__c = newAttendee.Status;
                        } 
                        existingAttendee.Meal_Opt_In_vod__c = newAttendee.Meal_Opt_In;
                        existingAttendee.id= attendee.id;
                        existingAttendee.PW_Participant_ID__c=newAttendee.Pw_Participant_ID; 
                        existingAttendee.PW_Event_Attendee_Row_ID__c=newAttendee.PW_Event_Attendee_Row_ID;                     
                     EventAttendeeListToBeUpdated.add(existingAttendee);
              
                     EM_Event_Speaker_vod__c eventSpeakerLocal = new EM_Event_Speaker_vod__c();
                        eventSpeakerLocal.Meal_Opt_In_vod__c=newAttendee.Meal_Opt_In;
                        if(newAttendee.Status.contains('Attended') && mapOfEventSpeaker.get(newAttendee.Speaker_Tp_Id).Status_vod__c.contains('Signed')){   
                            eventSpeakerLocal.Status_vod__c = mapOfEventSpeaker.get(newAttendee.Speaker_Tp_Id).Status_vod__c;
                        }
                        else
                        {
                            eventSpeakerLocal.Status_vod__c = newAttendee.Status;
                        } 
                        eventSpeakerLocal.id = attendee.EM_Event_Speaker_vod__c; 
                        EventAttendeeListToBeUpdated.add(eventSpeakerLocal); 
                        system.debug('Event Speaker --- '+eventSpeakerLocal);                                                                              
                         
        }else{
             ResponseList.add(new PW_Attendee_ID_Map_Model(null,
                                                             newAttendee.PW_Event_Attendee_Row_ID,
                                                             newAttendee.Pw_Participant_ID,
                                                             'error: Speaker Not Found, Please check Tp Speaker Id'));                 
        } 
        //system.debug('Attendee speaker null veeva id'+updatedSobjectList);
       
    }
    
    public static void InsertOrUpdateAttendee(List<sObject> EventAttendeeListToBeUpdated,List<EM_Attendee_vod__c> AttendeeListToBeInserted,
                                                                        list<PW_Attendee_ID_Map_Model> ResponseList,id eventId,List<Event_Attendee_vod__c> eventAttendeeExtraUpdation ){
      
       Map<id,string> mapOfIdsAndErrors = new  Map<id,string>();
      // list<PW_Attendee_ID_Map_Model> ResponseList = new  list<PW_Attendee_ID_Map_Model>();
       Map<id,Event_Attendee_vod__c> mapOfEventAttendeesAndAttendeeAfterUpdationAndInsertion = new Map<id,  Event_Attendee_vod__c>();
       Database.SaveResult[] srUpdatedList;
       Database.SaveResult[] srInsertedList;
      
       if(AttendeeListToBeInserted.size()>0){
              system.debug('Attendee Data in for loop if inserted');
               srInsertedList = Database.insert(AttendeeListToBeInserted, false);                            
         }

        if(EventAttendeeListToBeUpdated.size()>0){
              system.debug('Attendee Data in for loop if upserted');
              EventAttendeeListToBeUpdated.sort(); //Added *******
              srUpdatedList = Database.update(EventAttendeeListToBeUpdated, false); 
              system.debug('srUpdatedList  --- '+srUpdatedList);             
         }
         
         if(eventAttendeeExtraUpdation .size()>0){
             system.debug('Attendee Data in for loop if upserted');
             Database.update(eventAttendeeExtraUpdation , false);              
         }
         
         
        
        
         Map<ID, Event_Attendee_vod__c> mapOdIdsOfEventAttendeeAfterUpdation = new Map<ID, Event_Attendee_vod__c>([select id,PW_Event_Attendee_Row_ID__c,EM_Attendee_vod__c,PW_Participant_ID__c from Event_Attendee_vod__c 
                                                                                   where Medical_Event_vod__r.EM_Event_vod__c=: eventId limit :Limits.getLimitQueryRows() - Limits.getQueryRows()]);             

         for(Event_Attendee_vod__c attendee :mapOdIdsOfEventAttendeeAfterUpdation.values()){                                
            mapOfEventAttendeesAndAttendeeAfterUpdationAndInsertion.put(attendee.EM_Attendee_vod__c, attendee);                     
            }
        
        System.debug('loop in insert and update attendee ');
        if(srInsertedList!=null && srInsertedList.size()>0){
              System.debug('loop in insert attendee ');
           FillMapOfResponseFromSaveResultForInsertion(srInsertedList,mapOfEventAttendeesAndAttendeeAfterUpdationAndInsertion,AttendeeListToBeInserted,ResponseList);                         
         System.debug('loop in insert attendee end');
         }
        if(srUpdatedList!=null && srUpdatedList.size()>0){
            System.debug('loop in update attendee ');
          FillMapOfResponseFromSaveResultForUpdation(srUpdatedList,mapOfEventAttendeesAndAttendeeAfterUpdationAndInsertion,EventAttendeeListToBeUpdated,ResponseList);
         System.debug('loop in update attendee end ');
        }
         
         System.debug('loop in insert and update attendee after insertion done ');
        // ResponseList.addall(PW_Attendee_ID_Map_Model.FillAttendeeIdMapModel(mapOfIdsAndErrors,mapOdIdsOfEventAttendeeAfterUpdation));
       System.debug('loop in insert and update attendee after insertion done and map fill '+ResponseList);

       // return ResponseList;
    }

    public static void FillMapOfResponseFromSaveResultForUpdation(Database.SaveResult[] srList,Map<id,Event_Attendee_vod__c> mapOfEventAttendeesAndAttendeeAfterUpdationAndInsertion,
                                                                            List<sObject> EventAttendeeListToBeUpdated,list<PW_Attendee_ID_Map_Model> ResponseList){
        Map<id,string> mapOfIdsAndErrors = new  Map<id,string>();       
        //list<PW_Attendee_ID_Map_Model> newResponseList = new list<PW_Attendee_ID_Map_Model>();        
       
        for(Integer i=0;i<srList.size();i++){ 
            
            string objectName=(srList[i].getId()!=null)?srList[i].getId().getSObjectType().getDescribe().getName():'';
            System.debug('in fails '+objectName+'fgj'+srList[i].getId());
            if(srList[i].isSuccess()){   
               
               if(EventAttendeeListToBeUpdated[i].getSObjectType().getDescribe().getName() == 'Event_Attendee_vod__c'){
                   Event_Attendee_vod__c eventAttendee = (Event_Attendee_vod__c)EventAttendeeListToBeUpdated[i];
                   ResponseList.add(new PW_Attendee_ID_Map_Model(srList[i].getId(),
                                                                        eventAttendee.PW_Event_Attendee_Row_ID__c,
                                                                        eventAttendee.PW_Participant_ID__c,
                                                                        'Successfully Updated'));  
   
                 //  mapOfIdsAndErrors.put(srList[i].getId(),'Successfully Updated');  
                }else if(EventAttendeeListToBeUpdated[i].getSObjectType().getDescribe().getName() == 'EM_Attendee_vod__c'){                    
                    EM_Attendee_vod__c attendee = (EM_Attendee_vod__c)EventAttendeeListToBeUpdated[i]; 
                   
                     ResponseList.add(new PW_Attendee_ID_Map_Model(mapOfEventAttendeesAndAttendeeAfterUpdationAndInsertion.get(attendee.id).id,
                                                                      mapOfEventAttendeesAndAttendeeAfterUpdationAndInsertion.get(attendee.id).PW_Event_Attendee_Row_ID__c,
                                                                      mapOfEventAttendeesAndAttendeeAfterUpdationAndInsertion.get(attendee.id).PW_Participant_ID__c,
                                                                      'Successfully Updated')); 
                 
                   // mapOfIdsAndErrors.put(mapOfEventAttendeesAndAttendeeAfterUpdationAndInsertion.get(srList[i].getId()).id,'Successfully Updated');                                        
                }                
            }else{
                System.debug('in fails '+objectName);
                if(EventAttendeeListToBeUpdated[i].getSObjectType().getDescribe().getName() == 'Event_Attendee_vod__c'){
                   Event_Attendee_vod__c eventAttendee = (Event_Attendee_vod__c)EventAttendeeListToBeUpdated[i];
                    
                     System.debug('in fails if');
                     ResponseList.add(new PW_Attendee_ID_Map_Model(eventAttendee.id,
                                                                        eventAttendee.PW_Event_Attendee_Row_ID__c,
                                                                        eventAttendee.PW_Participant_ID__c,
                                                                        'error: '+srList[i].getErrors()[0].getMessage()));  
           
  
                    //mapOfIdsAndErrors.put(eventAttendee.id, 'error: '+ srList[i].getErrors()[0].getMessage());  
                }else if(EventAttendeeListToBeUpdated[i].getSObjectType().getDescribe().getName() == 'EM_Attendee_vod__c'){                    
                    EM_Attendee_vod__c attendee = (EM_Attendee_vod__c)EventAttendeeListToBeUpdated[i];                   
                    ResponseList.add(new PW_Attendee_ID_Map_Model(mapOfEventAttendeesAndAttendeeAfterUpdationAndInsertion.get(attendee.Id).id,
                                                                     mapOfEventAttendeesAndAttendeeAfterUpdationAndInsertion.get(attendee.Id).PW_Event_Attendee_Row_ID__c,
                                                                     mapOfEventAttendeesAndAttendeeAfterUpdationAndInsertion.get(attendee.Id).PW_Participant_ID__c,
                                                                     'error: '+srList[i].getErrors()[0].getMessage()));
                                        
                    //mapOfIdsAndErrors.put(mapOfEventAttendeesAndAttendeeAfterUpdationAndInsertion.get(attendee.Id).id, 'error: '+ srList[i].getErrors()[0].getMessage());                                        
                }
                
                 System.debug('in after suceess ');
            }                          
        }  
        System.debug('in after suceess '+ mapOfIdsAndErrors);
       // return mapOfIdsAndErrors;
    }
    
    public static void FillMapOfResponseFromSaveResultForInsertion(Database.SaveResult[] srList,Map<id,Event_Attendee_vod__c> mapOfEventAttendeesAndAttendeeAfterUpdationAndInsertion,
                                                                                             List<EM_Attendee_vod__c> AttendeeListToBeInserted,list<PW_Attendee_ID_Map_Model> ResponseList){
            //list<PW_Attendee_ID_Map_Model> newResponseList = new list<PW_Attendee_ID_Map_Model>();
            System.debug('in fill map insert save result '+srList);
           for(Integer i=0;i<srList.size();i++){ 
               System.debug('in fill map insert save result '+srList[i]);           
            if(srList[i].isSuccess()){   
                System.debug('in fill map insert save result   is success'+mapOfEventAttendeesAndAttendeeAfterUpdationAndInsertion);
                System.debug('in fill map insert save result   is success'+AttendeeListToBeInserted[i].PW_Event_Attendee_Row_ID__c);  
                System.debug('in fill map insert save result   is success'+AttendeeListToBeInserted[i].PW_Participant_ID__c);                
               ResponseList.add(new PW_Attendee_ID_Map_Model(mapOfEventAttendeesAndAttendeeAfterUpdationAndInsertion.get(srList[i].getId()).id,
                                                                   AttendeeListToBeInserted[i].PW_Event_Attendee_Row_ID__c,
                                                                   AttendeeListToBeInserted[i].PW_Participant_ID__c,
                                                                   'Successfully Created'));                                 
            }else{
                System.debug('in fails ');
               
                    ResponseList.add(new PW_Attendee_ID_Map_Model(null,
                                                                   AttendeeListToBeInserted[i].PW_Event_Attendee_Row_ID__c,
                                                                   AttendeeListToBeInserted[i].PW_Participant_ID__c,
                                                                    'error: '+ srList[i].getErrors()[0].getMessage())); 
                                  
             }                                
        }
            //return newResponseList;
     }
      
    public static void DeleteAttendee( List<EM_Attendee_vod__c> AttendeeListToBeDeleted,Map<ID,Event_Attendee_vod__c> mapOfEventAttendeesAndAttendee,list<PW_Attendee_ID_Map_Model> ResponseList){
       //list<PW_Attendee_ID_Map_Model> newResponseList = new list<PW_Attendee_ID_Map_Model>();
        
        Database.DeleteResult[] drList = Database.delete(AttendeeListToBeDeleted, false);
        System.debug('in deletion'+ drList);
        for(Integer i=0;i<drList.size();i++){ 
            if(drList[i].isSuccess()){                 
                ResponseList.add(new PW_Attendee_ID_Map_Model(mapOfEventAttendeesAndAttendee.get(drList[i].getId()).id,
                                                                   AttendeeListToBeDeleted[i].PW_Event_Attendee_Row_ID__c,
                                                                   AttendeeListToBeDeleted[i].PW_Participant_ID__c,
                                                                   'Successfully Deleted')) ;   
                
            }else{
                System.debug('in fails of deletion');
                ResponseList.add(new PW_Attendee_ID_Map_Model(mapOfEventAttendeesAndAttendee.get(drList[i].getId()).id,
                                                                   AttendeeListToBeDeleted[i].PW_Event_Attendee_Row_ID__c,
                                                                   AttendeeListToBeDeleted[i].PW_Participant_ID__c,
                                                                    'error: '+ drList[i].getErrors()[0].getMessage()));            
                
            }
        }
       // return newResponseList;
    }
}