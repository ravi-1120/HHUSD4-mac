/*
* Company       : Merck Co.
* Date          : 08/04/2021 
* Author        : Koushik
* Description   : handler class to publish message to salesforce event bus.
* History       : First version
*/



public class MSD_Core_gwetIntegrationHandler {    
    @invocableMethod(label='Publish Virtual Event Header' description='Method to publish Virtual event detail to Platform RTB.')
    public static void publishEventHeader(List<ID> veventId){
        publishAsync(veventId);
    }
    
    @future
    public static void publishAsync(List<ID> eventId){
        //User thisUser = [Select MSD_Core_Country_Code__c from User where Id =:UserInfo.GetUserId()];
        //get event details
        List<EM_Attendee_vod__c> toUpdateAttendee = new List<EM_Attendee_vod__c>();
        List<EM_Event_Speaker_vod__c> toUpdateSpeaker = new List<EM_Event_Speaker_vod__c>();
        List<String> organizerList = new List<String>();
        String organizerName;
        //get Remote Access Platform Name
        List<RecordType> RecordType_Id = [SELECT ID FROM RecordType WHERE DeveloperName = 'Remote_Access_Platform'];
        String RecTypeId = RecordType_Id[0].ID;
        Map<String,String> eventSubtypeValwithLabel = new Map<String,String>();
        Map<ID, Common_KPI__c> RemotePlatform = new Map<ID, Common_KPI__c>([SELECT ID, Name FROM Common_KPI__c where RecordTypeId = :RecTypeId]);
        for(schema.PicklistEntry each: EM_Event_vod__c.MSD_Core_Event_Subtype__c.getDescribe().getPicklistValues()){
            System.debug('This is API==>'+each.getValue());
            System.debug('This is Translated==>'+each.getLabel());
            eventSubtypeValwithLabel.put(each.getValue(),each.getLabel());
        }
        
        //Commented out Global version and created US version of the field list.
        /* List<EM_Event_vod__c> vevent = [Select ID,MSD_Core_Country_Code__c,End_Time_vod__c, Start_Time_vod__c,MSD_Core_Event_Subtype__c,
                                 MSD_Core_System_Id__c,Name,MSD_CORE_Event_Type__c,MSD_Core_Multi_Market__c,Status_vod__c,MSD_CORE_EVENT_CANCELED__c,MSD_Core_Published__c,MSD_CORE_Remote_Access_Platform__c,OwnerId,Owner.Name,Description_vod__c,MSD_CORE_Meeting_URL__c from EM_Event_vod__c  Where ID=:eventId[0]]; */   
        
        List<EM_Event_vod__c> vevent = [Select ID,End_Time_vod__c, Start_Time_vod__c,MSD_Core_Event_Subtype__c,
                                 MSD_CORE_Event_Id__c,Name,PW_Event_Type__c,Status_vod__c,MSD_Core_Published__c,OwnerId,Owner.Name,Description_vod__c from EM_Event_vod__c  Where ID=:eventId[0]];
                                 
                                 
        List<EM_Attendee_vod__c> relAttendeeList = [SELECT Id,MSD_CORE_Published__c,MSD_CORE_Ready_To_Publish__c FROM EM_Attendee_vod__c WHERE Event_vod__c =: eventId[0]];
        
        List<EM_Event_Speaker_vod__c> relSpeakerList = [SELECT Id,MSD_CORE_Published__c,MSD_CORE_Ready_To_Publish__c FROM EM_Event_Speaker_vod__c WHERE Event_vod__c =: eventId[0]];
        
        List<EM_Event_Team_Member_vod__c> relTeamMemList = [SELECT Id,First_Name_vod__c,Last_Name_vod__c  FROM EM_Event_Team_Member_vod__c WHERE Event_vod__c =: eventId[0] AND Role_vod__c = 'Organizer_vod'];
        
        for(EM_Event_Team_Member_vod__c eachTM: relTeamMemList){
            //String tempName = ';;';
            String tempName = '';
            if(eachTM.First_Name_vod__c != null && eachTM.First_Name_vod__c != ''){
                //tempName = tempName+eachTM.First_Name_vod__c;
                System.debug('This is tempname1===>'+tempName);
                System.debug('This is FirstName===>'+eachTM.First_Name_vod__c);
                tempName = eachTM.First_Name_vod__c;
                System.debug('This is tempname2===>'+tempName);
            }
            
            if(eachTM.Last_Name_vod__c != null && eachTM.Last_Name_vod__c != ''){
                System.debug('This is tempname3===>'+tempName);
                System.debug('This is LastName===>'+eachTM.Last_Name_vod__c);
                tempName = tempName+' '+eachTM.Last_Name_vod__c;
                System.debug('This is tempname4===>'+tempName);
            }

            organizerList.add(tempName);
        }
        
        System.debug('This is organizer list===>'+organizerList);
        
        if(organizerList.size()>0){
            for(String temp: organizerList){
                if(organizerName!= null && organizerName != ''){
                //organizerName += temp + ';;' ;
                organizerName = organizerName+ ';;'+temp;
                }else{
                    organizerName = temp;
                }
                System.debug('This is organizerName===>'+organizerName);
            }
        }
        
        MSD_Core_RTI_Switch_Utility rtiSwitch = new MSD_Core_RTI_Switch_Utility();
        String integrationSwitchStatus = rtiSwitch.getSwitchValue('US','GWET');  //Hardcoded "US" Code behind this call has been hard coded to always return ON
        if(integrationSwitchStatus == 'ON'){
            if(MSD_CORE_checkRecursiveEvent.runOnce(vevent[0])){             
                String contextKPIName = 'GWET';
                
/*              if(RemotePlatform.get(vevent[0].MSD_CORE_Remote_Access_Platform__c) != null){  //Not use used in the US Hard coded contextKPIName to GWET
                    contextKPIName = RemotePlatform.get(vevent[0].MSD_CORE_Remote_Access_Platform__c).Name;
                } */
                
                Id evntOwner = vevent[0].OwnerId;
                User currentUser = [Select TimeZoneSidKey from User where id =: evntOwner];
                String  userTZ = currentUser.TimeZoneSidKey;
                
                DateTime sysStDate = vevent[0].Start_Time_vod__c;
                DateTime sysEndDate = vevent[0].End_Time_vod__c;
                
                //Convert it into User's time zone
                String stUserDt = sysStDate.format('yyyy-MM-dd HH:mm:ss', userTZ);
                String endUserDt = sysEndDate.format('yyyy-MM-dd HH:mm:ss', userTZ);
                
                
                MSD_Virtual_Event__e virtualevent = new MSD_Virtual_Event__e(
                  //Event_End_Time__c = vevent[0].End_Time_vod__c,
                  Event_End_Time__c = dateTime.valueOfGmt(endUserDt),
                  //Event_Start_Time__c = vevent[0].Start_Time_vod__c,
                  Event_Start_Time__c = dateTime.valueOfGmt(stUserDt),
                  Event_Salesforce_Id__c = vevent[0].Id,
                  Event_Subtype__c = eventSubtypeValwithLabel.get(vevent[0].MSD_Core_Event_Subtype__c),
                  Event_ID__c = vevent[0].MSD_CORE_Event_Id__c,
                  Event_Title__c = vevent[0].Name,
                  Event_Type__c = vevent[0].PW_Event_Type__c,
                  //Multi_Market__c = vevent[0].MSD_Core_Multi_Market__c, //Not used in the US
                  Event_Status__c = vevent[0].Status_vod__c,
                  //Event_Cancelled__c = vevent[0].MSD_CORE_EVENT_CANCELED__c, //Not used in the US
                  Country_Code__c = 'US',
                  Remote_Access_Platform__c = contextKPIName,
                  Event_Owner_Name__c = vevent[0].Owner.Name,
                  Organizer_Names__c = organizerName,
                  Description__c = vevent[0].Description_vod__c
                  //MSD_CORE_Meeting_URL__c = vevent[0].MSD_CORE_Meeting_URL__c
                );
            
                Database.SaveResult publishResult = EventBus.publish(virtualevent);
            
                if(publishResult.isSuccess()){
                    System.debug('Published successfully'+publishResult);
                    
                    for(EM_Attendee_vod__c each: relAttendeeList){
                        System.debug('This is event status===>'+vevent[0].Status_vod__c);
                        if(!each.MSD_CORE_Ready_To_Publish__c && vevent[0].Status_vod__c != 'Closed_vod' && vevent[0].Status_vod__c != 'Canceled_vod'){
                            each.MSD_CORE_Ready_To_Publish__c = true;
                            toUpdateAttendee.add(each);
                        }
                    }
                    
                    for(EM_Event_Speaker_vod__c each1: relSpeakerList){
                        System.debug('This is event status===>'+vevent[0].Status_vod__c);
                        if(!each1.MSD_CORE_Ready_To_Publish__c && vevent[0].Status_vod__c != 'Closed_vod' && vevent[0].Status_vod__c != 'Canceled_vod'){
                            each1.MSD_CORE_Ready_To_Publish__c = true;
                            toUpdateSpeaker.add(each1);
                        }
                    }
                }
                else {
                    for(Database.Error err : publishResult.getErrors()) {
                      System.debug('Error returned: ' +
                                   err.getStatusCode() +
                                   ' - ' +
                                   err.getMessage());
                    }                
                }
                
                System.debug('This is attendee update size===>'+toUpdateAttendee.size());
                System.debug('This is speaker update size===>'+toUpdateSpeaker.size());
                
                if(toUpdateAttendee.size()>0){
                    update toUpdateAttendee;
                }
                if(toUpdateSpeaker.size()>0){
                    update toUpdateSpeaker;
                }
                
                
                if(!vevent[0].MSD_Core_Published__c && vevent[0].Status_vod__c != 'Closed_vod' && vevent[0].Status_vod__c != 'Canceled_vod'){
                    System.debug('Inside If===>');
                    vevent[0].MSD_Core_Published__c = true;
                    
                    EM_Event_vod__c temp = vevent[0];
                    update temp;
                }
            }else{
                EM_Event_vod__c tespEvent = vevent[0];              
                MSD_CORE_checkRecursiveEvent.isUpdate(tespEvent);
                List<Id> tempList = new List<Id>();
                tempList.add(tespEvent.Id);
                publishEventHeader(tempList);
            }            
        }       
    }
}