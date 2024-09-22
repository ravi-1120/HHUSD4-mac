trigger MSD_CORE_Process_Edited_Goal on MC_Cycle_Plan_Product_vod__c ( after update) {

  //Kevin Brace Release 8.0 7/13/2016
  
  //Stop Recursive Behavior...
  if(MSD_CORE_Process_Edited_Goals_Helper.runOnce()){
    
    //although Bulkified, Integration inserts and updates should not be processed
    //Only single User sessions should be processed.
    
    List<Id> changedRecordIdList = new List<Id>();
    List<MC_Cycle_Plan_Product_vod__c> changedRecordExtendedInfoList = new List<MC_Cycle_Plan_Product_vod__c>();
    List<MC_Cycle_Plan_Product_vod__c> updateList = new List<MC_Cycle_Plan_Product_vod__c>();
      
    for (MC_Cycle_Plan_Product_vod__c MCCPproductRec : Trigger.new) {
        
    	MC_Cycle_Plan_Product_vod__c oldMCCPproductRec = Trigger.oldMap.get(MCCPproductRec.Id);
        
        if((MCCPproductRec.Team_Activity_Goal_Edit_vod__c >=1) &&
           (MCCPproductRec.Team_Activity_Goal_Edit_vod__c <> oldMCCPproductRec.Team_Activity_Goal_Edit_vod__c)){
           
            changedRecordIdList.add(MCCPproductRec.id); 
           
        }
    }
    
    //For all the changed Records, Lets get a list of all the necessary extended information for the records. 
    if(!changedRecordIdList.isEmpty()){
        
        changedRecordExtendedInfoList = new List<MC_Cycle_Plan_Product_vod__c>([
            SELECT MC_Cycle_Plan_Product_vod__c.Cycle_Product_vod__c, 
                   MC_Cycle_Plan_Product_vod__c.id,
       
                   MC_Cycle_Plan_Product_vod__c.Team_Activity_Goal_Edit_vod__c,

                   Cycle_Plan_Channel_vod__r.Cycle_Channel_vod__c,
                   
                   Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__r.Target_vod__c,
                   
                   Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__r.Cycle_Plan_vod__r.Cycle_vod__c,
                   Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__r.Cycle_Plan_vod__r.Goal_Edit_Status_vod__c

            FROM   MC_Cycle_Plan_Product_vod__c
            WHERE  id in: changedRecordIdList
               
        ]);
        
    }
    
    //now, for each record thrown into the Trigger, need to get a list of all the Records that have the same:
    //cycle Product
    //cycle Channel
    //Cycle Target
    //Cycle
    //and are in "Edit" mode.
    
    if(!changedRecordExtendedInfoList.isEmpty()){
        
        List<Id> cyclesToMatch = new List<Id>();
        List<Id> cycleProductsToMatch = new List<Id>();
        List<Id> cyclePlanTargetsToMatch = new List<Id>();
        List<Id> cyclechannelsToMatch = new List<Id>();
        
        
        for (MC_Cycle_Plan_Product_vod__c rec : changedRecordExtendedInfoList){
            cyclesToMatch.add(rec.Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__r.Cycle_Plan_vod__r.Cycle_vod__c);
            cycleProductsToMatch.add(rec.Cycle_Product_vod__c);
            cyclePlanTargetsToMatch.add(rec.Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__r.Target_vod__c);
            cyclechannelsToMatch.add(rec.Cycle_Plan_Channel_vod__r.Cycle_Channel_vod__c);
            
        }
        
        List<MC_Cycle_Plan_Product_vod__c> possibleMatchingRecords = new List<MC_Cycle_Plan_Product_vod__c>();
        possibleMatchingRecords = new List<MC_Cycle_Plan_Product_vod__c>([
            
           SELECT MC_Cycle_Plan_Product_vod__c.Cycle_Product_vod__c, 
                  MC_Cycle_Plan_Product_vod__c.id,
       
                  MC_Cycle_Plan_Product_vod__c.Team_Activity_Goal_Edit_vod__c,

                  Cycle_Plan_Channel_vod__r.Cycle_Channel_vod__c,
                  Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__r.Target_vod__c,

                  Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__r.Cycle_Plan_vod__r.Cycle_vod__c

            FROM  MC_Cycle_Plan_Product_vod__c
            WHERE Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__r.Cycle_Plan_vod__r.Cycle_vod__c in: cyclesToMatch
            AND   Cycle_Plan_Channel_vod__r.Cycle_Channel_vod__c in: cyclechannelsToMatch
            AND   Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__r.Target_vod__c in: cyclePlanTargetsToMatch
            AND   Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__r.Cycle_Plan_vod__r.Goal_Edit_Status_vod__c in ('New_vod', 'Saved_vod', 'Submitted_vod')
            AND   MC_Cycle_Plan_Product_vod__c.Cycle_Product_vod__c in: cycleProductsToMatch

        ]);
            
     
        //Loop through all the changed records and find matches in the possible match list...to update
        for (MC_Cycle_Plan_Product_vod__c changedRec : changedRecordExtendedInfoList){
            
            for(MC_Cycle_Plan_Product_vod__c possibleMatchRec: possibleMatchingRecords){
                
               if(
                  //Exact Match on the Cycle, Target, Channel, Cycle Product, 
                   (possibleMatchRec.Cycle_Product_vod__c == changedRec.Cycle_Product_vod__c) &&
                   (possibleMatchRec.Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__r.Cycle_Plan_vod__r.Cycle_vod__c == changedRec.Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__r.Cycle_Plan_vod__r.Cycle_vod__c) &&
                   (possibleMatchRec.Cycle_Plan_Channel_vod__r.Cycle_Channel_vod__c == changedRec.Cycle_Plan_Channel_vod__r.Cycle_Channel_vod__c) &&
                   (possibleMatchRec.Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__r.Target_vod__c == changedRec.Cycle_Plan_Channel_vod__r.Cycle_Plan_Target_vod__r.Target_vod__c )
                 ){
                    possibleMatchRec.Team_Activity_Goal_Edit_vod__c = changedRec.Team_Activity_Goal_Edit_vod__c;
                    updateList.add(possibleMatchRec);                  
                 }
            }
        }
        
    }
    
    update updateList;
      
      
    // Notes loop -> determine if the _edited Field changed -> old value does not = new Value
    //    need to limit this to sales reps, managers and Jami...system admin -> 
    //    Exclude the MCCP process Engine that is blanking out the value...
    //    Note: users can not enter a value less then 1...so, look for all records where:
    //    
    //    1. The Team_Activity_Goal_Edit_vod__c field has changed old<>new
    //    2. Team_Activity_Goal_Edit_vod__c value is > 1 - only the MCCP can make it 0/blank
    //    
    //    Territory not taken into account in SOQL : When setting team-based goals for a target, a team is any territory aligned to that target. 
  
 }   
}