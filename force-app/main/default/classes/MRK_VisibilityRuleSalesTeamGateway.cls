public class MRK_VisibilityRuleSalesTeamGateway{
    /* Copyright, 2016 MERCK & CO, INC., Kevin Brace ALL RIGHTS RESERVED */

    /* KRB - 1/27/2014 - Visibility_Rule_Sales_Team_MRK__c Object Data Access Methods.
    */

    public static List <Visibility_Rule_Sales_Team_MRK__c> retrieveVisibilityRuleSalesTeamRecordsBySalesTeamIdList(List<Id> salesTeamIdList){
    
       List <Visibility_Rule_Sales_Team_MRK__c> vrstList = new List <Visibility_Rule_Sales_Team_MRK__c>();
           
       vrstList = new List<Visibility_Rule_Sales_Team_MRK__c>(
           [SELECT Sales_Team_MRK__c, Visibility_Rule_MRK__c
            FROM   Visibility_Rule_Sales_Team_MRK__c
            WHERE  Sales_Team_MRK__c in : salesTeamIdList]);
        
        return vrstList;
        
    }
    
    
}