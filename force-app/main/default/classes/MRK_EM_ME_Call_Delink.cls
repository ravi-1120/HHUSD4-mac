//Author--@SK

public class MRK_EM_ME_Call_Delink{
 
public string CallName {get;set;}

public Id RFMId {get;set;}

public boolean enableblock{get;set;}

public Call2_vod__c searchresult {get; set;}

public Call2_vod__c searchresult1 {get; set;}


public Pagereference Search(){
    system.debug('calling method'); 
   
    try{
        searchresult= [SELECT id,EM_Event_vod__c,Medical_Event_vod__c,Medical_Event_vod__r.name,Medical_Event_vod__r.Status_MRK__c,EM_Event_vod__r.name,EM_Event_vod__r.Status_vod__c  FROM Call2_vod__c where name = :CallName];
        enableblock = true;
         }
    catch(exception ae){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please Enter the Correct Call name'));
        enableblock = false;
        return null;
    }
    RFMId = searchresult.EM_Event_vod__c;
    //RFMId = searchresult.Medical_Event_vod__c;
    
   
    
    If(RFMId==null){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'No Medical/EM Event Linked to this Call'));
        enableblock = false;
    }
    else if (RFMId!=null){
        enableblock = true;
    }
      
    system.debug('EM event name :'+ searchresult.EM_Event_vod__r.name);
    return null;
}

 public Pagereference Search1(){
    system.debug('calling method'); 
   
    try{
        searchresult1 = [SELECT id,Medical_Event_vod__c,Medical_Event_vod__r.name FROM Call2_vod__c where name = :CallName];
        enableblock = true;
         }
    catch(exception ae){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please Enter the Correct Call name'));
        enableblock = false;
        return null;
    }
    
    RFMId = searchresult1.Medical_Event_vod__c;
    

If(RFMId==null){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'No Medical Event Linked to this Call'));
        enableblock = false;
    }
    else if (RFMId!=null){
        enableblock = true;
    }
      
    system.debug('EM event name :'+ searchresult1.Medical_Event_vod__r.name);
    return null;
}
public void Delink(){

    //List<Territory_Budget_Transaction_vod__c> BudTranList = [select id from Territory_Budget_Transaction_vod__c where Medical_Event_MRK__c =:RFMId];
   EM_Event_vod__c MedicalEvent = [select id,Status_vod__c from EM_Event_vod__c where id = :RFMId];
     
  
    If(MedicalEvent.Status_vod__c =='Closed_vod' || MedicalEvent.Status_vod__c== 'Canceled_vod' || MedicalEvent.Status_vod__c== 'MSD_CORE_Confirmed' || MedicalEvent.Status_vod__c == 'MSD_CORE_Planned'){
       // MedicalEvent.Status_MRK__c ='In Progress';
        //MedicalEvent.OverrideMedicalEvent_Lock_vod__c = TRUE;   
        MedicalEvent.Status_vod__c= MedicalEvent.Status_vod__c;
        MedicalEvent.Override_Lock_vod__c= True;  
        Update MedicalEvent;
        
        
  
        
        }
        system.debug ('RFMId'+ RFMId)  ;
        system.debug ('CallName'+ CallName)  ;
        
   list<Call2_vod__c>  callReport =[SELECT EM_Event_vod__c, Medical_Event_vod__c ,Override_Lock_vod__c FROM Call2_vod__c WHERE EM_Event_vod__c =:RFMId AND Name =:CallName]; 
    system.debug(callReport); 
    
        for(Call2_vod__c call :  callReport ){ 
        call.Override_Lock_vod__c = TRUE; 
        call.EM_Event_vod__c =null;
        call.Medical_Event_vod__c=null;
        
        } 
        
   
    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Call has been Delinked sucessfully'));
    enableblock = false;
    RFMId = null; 
    CallName = null;
    update callReport;
    
}

public void Delink1(){

   // List<Territory_Budget_Transaction_vod__c> BudTranList = [select id from Territory_Budget_Transaction_vod__c where Medical_Event_MRK__c =:RFMId];
    Medical_Event_vod__c MedicalEvent1 = [select id,Status_MRK__c from Medical_Event_vod__c where id = :RFMId];
    If(MedicalEvent1.Status_MRK__c == 'Submitted'){
       // MedicalEvent1.Status_MRK__c ='In Progress';
        MedicalEvent1.Override_Lock_vod__c = TRUE;   
        Update MedicalEvent1;
        }
        system.debug ('RFMId'+ RFMId)  ;
        system.debug ('CallName'+ CallName)  ;
        
    list<Call2_vod__c>  callReport1 =[SELECT Medical_Event_vod__c,Override_Lock_vod__c FROM Call2_vod__c WHERE Medical_Event_vod__c =:RFMId and Name =:CallName]; 
    system.debug(callReport1); 
    
        for(Call2_vod__c call :  callReport1 ){ 
        call.Override_Lock_vod__c = TRUE; 
        call.Medical_Event_vod__c =null ;
        
       } 
    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Call has been Delinked sucessfully'));
    enableblock = false;
    RFMId = null ; 
    CallName = null;
    update callReport1;
    
}

}