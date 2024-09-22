//Author--@SK

public class MRK_Call_Unlock{
 
public string CallName {get;set;}

public boolean enableblock{get;set;}

public Call2_vod__c searchresult {get; set;}

public Pagereference Search(){
    system.debug('calling method'); 
   
    try{
        searchresult= [SELECT Account_vod__c,Call_Type_vod__c,RecordType.name,Id,Is_Sampled_Call_vod__c,Name,Status_vod__c FROM Call2_vod__c where name = :CallName];
        enableblock = true;

    
         }
    catch(exception ae){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please Enter the Correct Call name'));
        enableblock = false;
        return null;
    }
    CallName = searchresult.name;
           
 
    return null;
}

public void Unlock(){

         
    list<Call2_vod__c>  callReport =[SELECT Override_Lock_vod__c,Unlock_vod__c,Is_Sampled_Call_vod__c FROM Call2_vod__c WHERE Name =:CallName]; 
    system.debug(callReport); 
    
      for(Call2_vod__c call :  callReport ){ 
      call.Override_Lock_vod__c = true; 
      call.Unlock_vod__c  =true;
      //call.Status_vod__c= 'Saved_vod';
        
        if (Call.Is_Sampled_Call_vod__c==true){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Sample Calls Can not be Unlocked'));
        enableblock = false;
        
       } 
       
      else{
      
    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Call has been Unlocked sucessfully'));
    enableblock = false;
    //RFMId = null ; 
   // CallName = null;
    update callReport;
    
}


}
}
}