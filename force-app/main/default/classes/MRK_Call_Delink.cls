//Author--@SK

public class MRK_Call_Delink{
 
public string CallName {get;set;}

public Id RFMId {get;set;}

public boolean enableblock{get;set;}

public Call2_vod__c searchresult {get; set;}


public Pagereference Search(){
    system.debug('calling method'); 
   
    try{
        searchresult= [SELECT id,Medical_Event_vod__c,Medical_Event_vod__r.name FROM Call2_vod__c where name = :CallName];
        enableblock = true;
         }
    catch(exception ae){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please Enter the Correct Call name'));
        enableblock = false;
        return null;
    }
    RFMId = searchresult.Medical_Event_vod__c;
    
    If(RFMId==null){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'No Medical Event/FFM Linked to this Call'));
        enableblock = false;
    }
    else if (RFMId!=null){
        enableblock = true;
    }
      
    system.debug('Medical event name :'+ searchresult.Medical_Event_vod__r.name);
    return null;
}

public void Delink(){

    List<Territory_Budget_Transaction_vod__c> BudTranList = [select id from Territory_Budget_Transaction_vod__c where Medical_Event_MRK__c =:RFMId];
    Medical_Event_vod__c MedicalEvent = [select id,Status_MRK__c from Medical_Event_vod__c where id = :RFMId];
    If(MedicalEvent.Status_MRK__c == 'Submitted'){
       // MedicalEvent.Status_MRK__c ='In Progress';
        //MedicalEvent.Override_Lock_vod__c = TRUE;   
        Update MedicalEvent;
        }
        system.debug ('RFMId'+ RFMId)  ;
        system.debug ('CallName'+ CallName)  ;
        
    list<Call2_vod__c>  callReport =[SELECT Medical_Event_vod__c,Override_Lock_vod__c FROM Call2_vod__c WHERE Medical_Event_vod__c =:RFMId and Name =:CallName]; 
    system.debug(callReport); 
    
        for(Call2_vod__c call :  callReport ){ 
        call.Override_Lock_vod__c = TRUE; 
        call.Medical_Event_vod__c =null ;
        
       } 
    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Call has been Delinked sucessfully'));
    enableblock = false;
    RFMId = null ; 
    CallName = null;
    update callReport;
    
}




}