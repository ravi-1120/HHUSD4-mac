global class MRK_DeleteVisRuleSalesTeamsSchedulable implements Schedulable{

   global void execute(SchedulableContext sc) {
      
       
       
       //US Instance
       String soql = 'SELECT Id FROM Visibility_Rule_Sales_Team_MRK__c where Sales_Team_MRK__c in ';
       soql = soql + '(SELECT Id FROM Sales_Team_MRK__c where Active_MRK__c = FALSE and LastModifiedDate = YESTERDAY)';
       
       
       
       
       //Global Instance
       /*
       String soql = 'SELECT Id FROM Visibility_Rule_Sales_Team_MRK__c where Sales_Team_MRK__c in ';
       soql = soql + '(SELECT Id FROM MSD_CORE_Sales_Team__c where MSD_CORE_Active__c = FALSE and LastModifiedDate = YESTERDAY)';
       */
       
       MRK_DeleteVisRuleSalesTeamsBatchable dvrst = 
          new MRK_DeleteVisRuleSalesTeamsBatchable (soql); 
      
       database.executebatch(dvrst, 1);
   }
}