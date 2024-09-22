public class MedicalEventsSignInSheetController {
        String medEventId = ApexPages.currentPage().getParameters().get('MedicalEventid');
    
    public List<Medical_Event_vod__c> getMedicalEventDetails(){
            List<Medical_Event_vod__c> meList = new List<Medical_Event_vod__c>();

      
         meList = [Select name, 
       (select Attendee_Name_vod__c
        From Event_Attendee_vod__r)
From Medical_Event_vod__c
Where id =: medEventId];   //'a0pK00000018FIYIA2'];
        return meList;
    }


    public List<Event_Attendee_vod__c> getMedicalEventAttendees(){
            List<Event_Attendee_vod__c> meList = new List<Event_Attendee_vod__c>();

      
         meList = [select Attendee_Name_vod__c
        From Event_Attendee_vod__c

Where Medical_Event_vod__c =: medEventId];   //'a0pK00000018FIYIA2'];
        return meList;
    }

    
    public String getMedicalEventId(){
        return medEventId;
    }
}