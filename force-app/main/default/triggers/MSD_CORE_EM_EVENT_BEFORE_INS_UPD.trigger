/*
 * Trigger: MSD_CORE_EM_EVENT_BEFORE_INS_UPD
 * If Location override flag is set, just copy the Planned version of the field into the ootb field for all fields  i.e.  Location Planned -> Location for all fields
 * If the Venue is set, use the lookup to copy the Venue data to all the location fields,  Venue_vod.name -> Location and Location Planned 
 * If the HCO location is set, use the lookup to copy the HCO Primary address to all the location fields.  I.e. Account Name -> Location and Location Planned

 * Author: Ramesh Elapakurthi
 * 
 * Change Log: 
 * KRB 6/5/2019 - Added logic to only fire Address logic when the Status of the Event is Planning.
 * KRB 6/5/2019 - Added logic to assign a Visibility Value to the record. Uses Custom Label MSD_CORE_Medical_App_User_Profiles to determine if user if sales of medical.
 *                NOTE: only want to do this on INSERTS and if recordType is an Event wo Speakers
 * KRB 6/11/2019 - added the use of the new Singleton Pattern Class to retrieve User information. This Class gets called serval times in a given 
 *                 transaction and it will help reduce the number of SOQL Stmts executed. 
 * KV  2/12/2020 - Moved Interface Update Flag Logic from workflow to Trigger
*/
trigger MSD_CORE_EM_EVENT_BEFORE_INS_UPD on EM_Event_vod__c (before insert, before update) {

    List<Id> venueIds=new List<Id>();
    List<Id> accountIds = new List<Id>();
    List<Id> addressIds = new List<Id>();
    List<Id> eventIds = new List<Id>();
    Map<Id,EM_Venue_vod__c> venueMap=new Map<Id,EM_Venue_vod__c>();
    Map<Id,Account> accountMap=new Map<Id,Account>();
    Map<Id,Address_vod__c> addressMap=new Map<Id,Address_vod__c>();
    
    //KRB 6/5/2019 
    Boolean isMedicalAppUser = false;
    
    //KRB 6/11/2019
    MSD_CORE_Event_User eventUser = MSD_CORE_Event_User.getInstance();
    String usrProfileName = eventUser.profileName;
    
    String medicalAppProfiles = System.Label.MSD_CORE_Medical_App_User_Profiles;
    
    if (usrProfileName == Null) {                                      // Check to see if the user is Automated Process since it does not have a profile name.
        isMedicalAppUser = false;
    }
    else{                                                               //if the user has a profile
        isMedicalAppUser = medicalAppProfiles.contains(usrProfileName); 
    }
    
    Map<Id, Schema.RecordTypeInfo> eventRtMap = EM_Event_vod__c.SObjectType.getDescribe().getRecordTypeInfosByID();

    for(EM_Event_vod__c emEvent:trigger.new){
        
        //KRB 6/5/2019 - added if Condition 
        if(emEvent.Status_vod__c == 'MSD_CORE_Planned'){
           if(emEvent.Venue_vod__c!=null && (trigger.isInsert || trigger.oldMap.get(emEvent.Id).Venue_vod__c != emEvent.Venue_vod__c)) venueIds.add(emEvent.Venue_vod__c);
           if(emEvent.Account_vod__c!=null && (trigger.isInsert || trigger.oldMap.get(emEvent.Id).Account_vod__c != emEvent.Account_vod__c)) accountIds.add(emEvent.Account_vod__c);
           if(emEvent.Address_vod__c!=null && (trigger.isInsert || trigger.oldMap.get(emEvent.Id).Address_vod__c != emEvent.Address_vod__c)) addressIds.add(emEvent.Address_vod__c);
           eventIds.add(emEvent.Id);
        }
    }
    
    if(!venueIds.isEmpty()){
        
        venueMap=new Map<Id,EM_Venue_vod__c>([Select Id,Name,Address_vod__c,Address_Line_2_vod__c,City_vod__c,State_Province_vod__c,Postal_Code_vod__c from EM_Venue_vod__c where Id in:venueIds]);
    } 
    if(!accountIds.isEmpty()){
        
        accountMap=new Map<Id,Account>([Select Id,Formatted_Name_vod__c,MSD_CORE_Primary_Address_Line_1__c,MSD_CORE_Primary_Address_Line_2__c,MSD_CORE_Primary_City__c,MSD_CORE_Primary_State__c,MSD_CORE_Primary_Zip__c from Account where Id in:accountIds]); 
    }
    if(!addressIds.isEmpty()){
        
        addressMap=new Map<Id,Address_vod__c>([Select Id,Name,Address_Line_2_vod__c,City_vod__c,State_vod__c,Zip_vod__c, License_vod__c, License_Status_vod__c from Address_vod__c where Id in:addressIds]);    
    }
    
    for(EM_Event_vod__c e: Trigger.New){
        
       //KRB 6/5/2019 
       //Kalyan 9/12/2019 Removed the Record Type check code "&& eventRtMap.get(e.RecordtypeId).getName() == 'Events without Speaker'" from below if statement
       
       if (Trigger.isInsert){
          
          if(isMedicalAppUser){
             e.MSD_CORE_Bus_Visibility__c = 'Medical';
          }else{
             e.MSD_CORE_Bus_Visibility__c = 'Sales';
          }
       } 
         
 
  //Kalyan 2/12/2020 - Moved Interface Update Flag Logic from workflow to Trigger
        if(usrProfileName != 'MRK - Integration User' && (e.MSD_CORE_Interface_Update_Flag__c == true || e.MSD_CORE_SAP_Interface_Flag__c != 'U')){
             e.MSD_CORE_Interface_Update_Flag__c = False;
             e.MSD_CORE_SAP_Interface_Flag__c= 'U';
             }
 
 
       //KRB 6/5/2019 - added if Condition 
       if(e.Status_vod__c == 'MSD_CORE_Planned'){
        
          if(e.MSD_CORE_Location_Override__c == true && e.Venue_vod__c == null && e.Account_vod__c == null ){
             System.debug('Location override is true');
             e.Location_vod__c = e.MSD_CORE_Location_Planned__c;
             e.Location_Address_vod__c = e.MSD_CORE_Location_Address_Planned__c;
             e.Location_Address_Line_2_vod__c = e.MSD_CORE_Location_Address_Line_2__c;
             e.City_vod__c = e.MSD_CORE_City_Planned__c;
             e.State_Province_vod__c = e.State_Province_Planned__c;
             e.Postal_Code_vod__c = e.MSD_CORE_Postal_Code_Planned__c;
          }
        
          else if(e.Venue_vod__c != null  && e.Account_vod__c == null && !venueMap.isEmpty() &&  venueMap.containsKey(e.Venue_vod__c)){
            
             EM_Venue_vod__c v = venueMap.get(e.Venue_vod__c);
            
             e.Location_vod__c = e.MSD_CORE_Location_Planned__c = v.Name;
             e.Location_Address_vod__c = e.MSD_CORE_Location_Address_Planned__c = v.Address_vod__c;
             e.Location_Address_Line_2_vod__c = e.MSD_CORE_Location_Address_Line_2__c =  v.Address_Line_2_vod__c;
             e.City_vod__c = e.MSD_CORE_City_Planned__c =  v.City_vod__c;
             e.State_Province_vod__c = e.State_Province_Planned__c =  v.State_Province_vod__c;
             e.Postal_Code_vod__c = e.MSD_CORE_Postal_Code_Planned__c =  v.Postal_Code_vod__c;
          }
        
          else if(e.Account_vod__c != null && !accountMap.isEmpty() && accountMap.containsKey(e.Account_vod__c)){
            
             Account acct=accountMap.get(e.Account_vod__c);
             if(e.Address_vod__c == null){
                e.Location_vod__c = e.MSD_CORE_Location_Planned__c = acct.Formatted_Name_vod__c;
                e.Location_Address_vod__c = e.MSD_CORE_Location_Address_Planned__c  = acct.MSD_CORE_Primary_Address_Line_1__c;
                e.Location_Address_Line_2_vod__c = e.MSD_CORE_Location_Address_Line_2__c = acct.MSD_CORE_Primary_Address_Line_2__c;
                e.City_vod__c = e.MSD_CORE_City_Planned__c = acct.MSD_CORE_Primary_City__c;
                e.State_Province_vod__c = e.State_Province_Planned__c = acct.MSD_CORE_Primary_State__c;
                e.Postal_Code_vod__c = e.MSD_CORE_Postal_Code_Planned__c = acct.MSD_CORE_Primary_Zip__c;
                   
             }
             else{
                if(!addressMap.isEmpty() && addressMap.containsKey(e.Address_vod__c)){
                    Address_vod__c address = addressMap.get(e.Address_vod__c);
                    e.Location_vod__c = e.MSD_CORE_Location_Planned__c = acct.Formatted_Name_vod__c;
                    e.Location_Address_vod__c = e.MSD_CORE_Location_Address_Planned__c  = address.Name;
                    e.Location_Address_Line_2_vod__c = e.MSD_CORE_Location_Address_Line_2__c = address.Address_line_2_vod__c;
                    e.City_vod__c = e.MSD_CORE_City_Planned__c = address.City_vod__c;
                    e.State_Province_vod__c = e.State_Province_Planned__c =  address.State_vod__c;
                    e.Postal_Code_vod__c = e.MSD_CORE_Postal_Code_Planned__c =  address.Zip_vod__c;
        
                }
                                
             }
       }
      }
    }
    
 
}