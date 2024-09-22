//Author--@SK

public class MRK_RFM_FFM_unlock{
 
public string EventName {get;set;}

public boolean enableblock{get;set;}

public EM_Event_vod__c searchresult {get; set;}



public Pagereference Search(){
    system.debug('calling method'); 
   
    try{
        searchresult= [SELECT id,Name,Status_vod__c,MSD_CORE_Event_Id__c,Lock_vod__c,PW_Event_Type__c,MSD_CORE_Event_Owner__c,RecordType.name FROM EM_Event_vod__c where name= :EventName];
        enableblock = true;
         }
    catch(exception ae){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please Enter the Correct Event Name'));
        enableblock = false;
        return null;
    }
    EventName = searchresult.name;
 

      
    system.debug('EM event name :'+ searchresult.Name);
    return null;
}

    

public void Eventunlock(){
         
    list<EM_Event_vod__c> EM =[SELECT id,name,Lock_vod__c,Status_vod__c,Override_Lock_vod__c,PW_Event_Type__c,MSD_CORE_Event_Owner__c,RecordType.name  from EM_Event_vod__c WHERE name =:EventName]; 
    system.debug(EM); 
    
      for(EM_Event_vod__c ev: EM ){ 
      ev.Lock_vod__c=false;
      ev.Status_vod__c= 'MSD_CORE_Planned';
      
      
        if (ev.PW_Event_Type__c!='MSD_CORE_FFM'){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Only FFM Events Can be Unlocked'));
        enableblock = false;
        
       } 
       
      else{
          
         
     
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'FFM Event has been Unlocked sucessfully'));
    enableblock = false;
    update EM ;        
        
        
        }
 }
}
}