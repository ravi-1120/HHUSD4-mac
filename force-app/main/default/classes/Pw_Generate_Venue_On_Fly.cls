public class Pw_Generate_Venue_On_Fly {

    public static EM_Venue_vod__c GenerateVenue(EM_Event_vod__c event){
        
        if(event.Venue_vod__c == null && event.PW_Location_Type__c == Pw_Constants.LOCATION_TYPE_RESTRAURANT_OR_HOTEL){
            if(validateVenueFieldsOfEvents(event))
            {
                EM_Venue_vod__c venueLocal = new EM_Venue_vod__c();
                             
                venueLocal.Address_Line_2_vod__c=  event.Location_Address_Line_2_vod__c;
                venueLocal.Address_vod__c=  event.Location_Address_vod__c;
                venueLocal.City_vod__c=  event.City_vod__c;
                venueLocal.State_Province_vod__c=  event.State_Province_vod__c;
                venueLocal.Postal_Code_vod__c=  event.Postal_Code_vod__c;
                venueLocal.Name=  event.Location_vod__c.left(80);
                venueLocal.Status_vod__c= Pw_Constants.ELIGIBLE_VOD;
                venueLocal.PW_Venue_Category__c= event.PW_Venue_Category__c;//April2020 /// For Future
                
                insert venueLocal;
            
                System.Debug('venue is created in clas function');
                return venueLocal;
            }else{
               System.Debug('All the fields to create the venue is not present in the event');                  
            }
            
        }
        return null ;
    }
    
    private static boolean validateVenueFieldsOfEvents(EM_Event_vod__c event){
        
        if( string.isNotBlank(event.Location_Address_vod__c) && string.isNotBlank(event.City_vod__c)
          && string.isNotBlank(event.State_Province_vod__c)&& string.isNotBlank(event.Location_vod__c) && string.isNotBlank(event.Postal_Code_vod__c)){
          return true;
        }
        else{
           return false; 
        }
    }
    
}