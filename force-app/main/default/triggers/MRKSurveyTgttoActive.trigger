/**
 * MRK Most Recent Flag Update. 
 * Trigger Name : MRKSurveyTgttoActive
 * When an New Survey Target is Created by the User. The Trigger updates the most recent flag as true & set the old one to false.
 * Survey Product Field is getting populated which is being used in the VMOC Sync Rule.
 * @version        1.2
 * @version        1.3 : Code has been added to exclude this trigger for Advanced Coaching Report.
 */

trigger MRKSurveyTgttoActive on Survey_Target_vod__c (after insert, after update) {

    if (MRKSurveyUTLCls.BypasssMRKSurveyTgttoActiveTrigger) {
        return;
    }
    
    //Added as part of 8.0 release to fix the issue in which Admin has to inactivate the trigger before any survey update.
    Id profileId=userinfo.getProfileId();
    String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
    
    //Added 9.0 Release
    String RTName;
    for(Survey_Target_vod__c STR : trigger.new){
    //RTName = [Select Id,Name from RecordType where Id=:STR.RecordTypeId].Name;
    RTName= Schema.SObjectType.Survey_Target_vod__c.getRecordTypeInfosById().get(STR.RecordTypeId).getname();   // Addedd 01/19  10.0.3 SK 
    }
        
    if (profileName == 'System Administrator' || profileName == 'MRK - Integration User' || RTName == 'Coaching Report'|| RTName == 'Suggestion Survey'){
        return;
    }
        
if(!MRKSurveyUTLCls.TriggerExecuting) { //Check the trigger isnt already executing 
       MRKSurveyUTLCls.TriggerExecuting=true; //set it to true so it doesnt go in a recursive loop 

//Sets to hold Account Id, Survey Id, Current Survey Target Id.
Set<Id> AccountIds = new Set<Id>();
Set<Id> SurveyIds = new Set<Id>();    
Set <Id> SurveyTgtIds = new Set <Id>();
Map<String, List< Survey_Target_vod__c >> survvsTarg = new Map<String, List< Survey_Target_vod__c > >(); 


if (Trigger.isInsert || Trigger.isUpdate) {
for(Survey_Target_vod__c ST : Trigger.new) {
       // a status changing from "Development_vod" to "Pending_vod" indicates survey publishing is occurring
    if (!((Trigger.isUpdate) && (Trigger.oldMap.get(ST.Id).Status_vod__c == 'Development_vod') && (ST.Status_vod__c == 'Pending_vod'))) {
        AccountIds.add(ST.Account_vod__c);
        SurveyIds.add(ST.Survey_vod__c);
        SurveyTgtIds.add(ST.Id);                
    }
 }
}

system.debug('AccountId ' + AccountIds);
system.debug('SurveyIds ' + SurveyIds);
system.debug('SurveyTgtIds ' + SurveyTgtIds);

List <Survey_Target_vod__c> stargets = [Select Id,Account_vod__c,MRK_Most_Recent__c,Survey_vod__c from Survey_Target_vod__c Where Account_vod__c IN :AccountIds and Survey_vod__c IN :SurveyIds order by CreatedDate desc]; //added 05/10 
for(Survey_Target_vod__c STV : stargets)
{
         String key = STV.Account_vod__c+'__'+ STV.Survey_vod__c;     
         
         If(survvsTarg.get(key) == null){      
             List< Survey_Target_vod__c > targList = new List< Survey_Target_vod__c >(); 
             survvsTarg.put(key, targList);    
        }  
                 survvsTarg.get(key).add(STV);   
}

Map<Id,Survey_vod__c> SurveyProduct = new Map<Id,Survey_vod__c>();
SurveyProduct = new Map<Id,Survey_vod__c>([Select Id,Product_vod__c from Survey_vod__c where Id in :SurveyIds]);

system.debug('ProductId ' + SurveyProduct);

//List to update the records.
List <Survey_Target_vod__c> SurveyTgttoupdate = new List <Survey_Target_vod__c>();

system.debug('Pre SurveyTgttoupdate ' + SurveyTgttoupdate);

for(Id AID : AccountIds)
{
        for(Id SID : SurveyIds){ 
                If (survvsTarg.ContainsKey(AID  +'__'+ SID) == true)
                {                
                 Boolean firstrecord = true;
              
               system.debug('survvsTarg ' + survvsTarg);
               system.debug('AID & SID ' + AID + ' ' + SID );
            
                  for(Survey_Target_vod__c STU : survvsTarg.get(AID  +'__'+ SID))  // Added on 05/10
                  {
                
                      if(firstrecord)
                             {
                             STU.MRK_Most_Recent__c=true;
                             STU.Survey_Product__c = SurveyProduct.get(STU.Survey_vod__c).Product_vod__c;
                             firstrecord=false;
                             system.debug('FirstRecord STU ' + STU);
                             SurveyTgttoupdate.add(STU);
                             }
                             else if(STU.MRK_Most_Recent__c)
                             { 
                             system.debug('Second Record ' +STU);    
                             STU.MRK_Most_Recent__c=false;
                             STU.Survey_Product__c = SurveyProduct.get(STU.Survey_vod__c).Product_vod__c;
                             system.debug('NextRecord STU ' + STU);
                             SurveyTgttoupdate.add(STU);
                             }
                
                }
             }    
        
        }
     }
    
system.debug('Post SurveyTgttoupdate ' + SurveyTgttoupdate);
Update(SurveyTgttoupdate);

}
}