///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          Pw_Event_Speakers_Manipulation
///   Description:    This class will receive the event speakers from Tp and update the same in veeva
///   Author:         Snehal Asare                   
///   Notes:          Conatins methods which will add and delete a speaker
///   Date: 25-9-2016
///   Revision History:
///-----------------------------------------------------------------
public class Pw_Event_Speakers_Manipulation {
    
        /// <summary>
        ///     Update veeva speaker
        /// </summary>
        /// <param name="speakersFromTp">
        ///     'speakersFromTp' contains speakers which will get send from TP
        /// </param> 
        // <param name="eventId">
        ///     'eventId' contains event id
        /// </param> 
         public static void UpsertSpeakersInVeevaEvent(list<PW_Speaker_Model> speakersFromTp, id eventId){ 
            
                set<integer> setOfspeakers = new set<integer>(); 
            
                setOfspeakers = AddSpeakersToVeevaEvent(speakersFromTp,eventId,setOfspeakers);
            
                System.debug('set speaker' +setOfspeakers);
            
                DeleteSpeakersFromVeevaEvent(eventId,setOfspeakers);        
                
        }
    
        /// <summary>
        ///     Add veeva speaker
        /// </summary>
        /// <param name="speakersOfTp">
        ///     'speakersOfTp' contains speakers which will get send from TP
        /// </param> 
        // <param name="setOfspeakers">
        ///     'setOfspeakers' contains speaker tp id
        /// </param> 
         static set<integer> AddSpeakersToVeevaEvent(list<PW_Speaker_Model> speakersOfTp, id eventId,set<integer> setOfspeakers){ 
                List<EM_Event_Speaker_vod__c> eventSpeakerInsertLst = new List<EM_Event_Speaker_vod__c>();
                List<EM_Event_Speaker_vod__c> eventSpeakerUpdateLst = new List<EM_Event_Speaker_vod__c>();
                
                Map<String, Id> mapTPSPKIDAndSPKID = new Map<String, Id>();
                Map<String, Id> mapTPSPKIDAndEVTSPKID = new Map<String, Id>();
                //Creating the first MAP        
                List<String> lstTpSpeakerIDs = new List<string>();
                for(PW_Speaker_Model speak :speakersOfTp)
                { 
                    lstTpSpeakerIDs.add(string.valueOf(speak.TP_Speaker_Id));
                
                }
                
                for(EM_Speaker_vod__c objSPK : [select id, PW_Speaker_ID__c from EM_Speaker_vod__c where PW_Speaker_ID__c IN:lstTpSpeakerIDs ])
                        mapTPSPKIDAndSPKID.put(objSPK.PW_Speaker_ID__c, objSPK.id);
                        
                        
                
                //Creating the second MAP        
                for(EM_Event_Speaker_vod__c objEVTSPK : [select id, Speaker_vod__r.PW_Speaker_ID__c from EM_Event_Speaker_vod__c where Speaker_vod__r.PW_Speaker_ID__c IN:lstTpSpeakerIDs and Event_vod__c=: eventId])
                        mapTPSPKIDAndEVTSPKID.put(objEVTSPK.Speaker_vod__r.PW_Speaker_ID__c, objEVTSPK.id); 
                        
                        
                for(PW_Speaker_Model speak :speakersOfTp)
                {    
                       //add all tp speaker id to a set
                       setOfspeakers.add(speak.TP_Speaker_Id);                  
                    //   List<EM_Speaker_vod__c> speakerLocal = [select id from EM_Speaker_vod__c where PW_Speaker_ID__c =:string.valueOf(speak.TP_Speaker_Id) ]; 
                       //setOfspeakers.add(speak.TP_Speaker_Id); //added by nitesh
                       
                       //if(speakerLocal.size()>0){
                       if(mapTPSPKIDAndSPKID.get(string.valueOf(speak.TP_Speaker_Id))!=null){
                       
                          Id spkid=mapTPSPKIDAndSPKID.get(string.valueOf(speak.TP_Speaker_Id));
                              
                          // list<EM_Event_Speaker_vod__c> VeevaSpeakerList =[select id from EM_Event_Speaker_vod__c 
                          //                                                 where Speaker_vod__c =:speakerLocal[0].id and Event_vod__c=: eventId limit 1];
                           //check whether the speaker exists already or not
                           //setOfspeakers.add(speak.TP_Speaker_Id);//added
                           
                           //if(VeevaSpeakerList.size()==0){
                             if(mapTPSPKIDAndEVTSPKID.get(string.valueOf(speak.TP_Speaker_Id))==null){
                               EM_Event_Speaker_vod__c eveSpeak = new EM_Event_Speaker_vod__c();            
                               //eveSpeak.Speaker_vod__c = speakerLocal[0].id;
                               eveSpeak.Speaker_vod__c = spkid;
                               eveSpeak.Event_vod__c = eventId;
                               if(speak.PW_Speaker_Priority!=null && speak.PW_Speaker_Priority!='')
                               {
                                    eveSpeak.PW_Speaker_Priority__c = speak.PW_Speaker_Priority;
                               }
                               eventSpeakerInsertLst.add(eveSpeak);
                               system.debug('insert event speaker -- '+eveSpeak);                        
                            }
                            else
                            {
                                Id evtspkid=mapTPSPKIDAndEVTSPKID.get(string.valueOf(speak.TP_Speaker_Id));
                               EM_Event_Speaker_vod__c eveSpeak = new EM_Event_Speaker_vod__c();            
                               if(speak.PW_Speaker_Priority!=null && speak.PW_Speaker_Priority!='')
                               {
                                    eveSpeak.PW_Speaker_Priority__c = speak.PW_Speaker_Priority;
                               }
                               //eveSpeak.Id = VeevaSpeakerList[0].Id;
                               eveSpeak.Id = evtspkid;
                               eventSpeakerUpdateLst.add(eveSpeak);
                               system.debug('update event speaker -- '+eveSpeak);
                            }
                       }
                        
                       System.debug('inserted successfully speaker');
                } 
                if(eventSpeakerInsertLst!=null && eventSpeakerInsertLst.size()>0)
                    insert eventSpeakerInsertLst;
                    
                if(eventSpeakerUpdateLst!=null && eventSpeakerUpdateLst.size()>0)
                    update eventSpeakerUpdateLst;
                    
             return setOfspeakers;
         } 
        
        /// <summary>
        ///     Delete extra veeva speaker
        /// </summary>
        /// <param name="eventId">
        ///     'eventId' contains event id
        /// </param> 
        // <param name="setOfspeakers">
        ///     'setOfspeakers' contains speaker tp id
        /// </param> 
        static void DeleteSpeakersFromVeevaEvent(id eventId,set<integer> setOfspeakers){ 
                List<EM_Event_Speaker_vod__c> eventSpeakerDeleteLst = new List<EM_Event_Speaker_vod__c>();
                
                list<EM_Event_Speaker_vod__c> AllVeevaSpeakerList =[select id,Speaker_vod__r.PW_Speaker_ID__c from EM_Event_Speaker_vod__c 
                                                                    where Event_vod__c=: eventId and Speaker_vod__r.PW_Speaker_ID__c !=null];
                 //check whether the count of  speaker present in veeva is eqaul to the speaker send from tp
                 if(setOfspeakers.size()!=AllVeevaSpeakerList.size()){
                                                
                     System.debug('all speaker present' +AllVeevaSpeakerList);
                     for(EM_Event_Speaker_vod__c existedSpeaker :AllVeevaSpeakerList){
                    
                         System.debug('all set speaker present' +existedSpeaker.Speaker_vod__r.PW_Speaker_ID__c);
                         
                         if(!setOfspeakers.contains(Integer.valueof(existedSpeaker.Speaker_vod__r.PW_Speaker_ID__c.trim()))){
                                System.debug('not found speaker ' +existedSpeaker.Speaker_vod__c);
                                System.debug('delete speaker ' +existedSpeaker);
                                eventSpeakerDeleteLst.add(existedSpeaker);
                                System.debug('delete successfully ');
                           }
                      }  
                      if(eventSpeakerDeleteLst!=null && eventSpeakerDeleteLst.size()>0)
                            delete eventSpeakerDeleteLst;                                          
                }
        }
}