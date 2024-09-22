/*
 * KRB 4/30/2021 21R2.0- called by the "Add Account Plan Tact" Flow
 * 
 */

global with sharing class MSD_CORE_ProcessSelectedTactics {
            
    /* Get list of individual product tactics to apply */
    @InvocableMethod
    public static List<Results> processSelectedTacticsString(List<Requests> requests) {
            
       Results curResults = new Results();           
       System.debug('processSelectedTacticsString: String recieved: ' + requests[0].selectedTactics);
       String delimiter = ';';
       List<String> productTacticIds = new List<String>();
       String tacticsSelected = requests[0].selectedTactics;
       
       if(tacticsSelected.contains(delimiter)){
          for(String ptId : requests[0].selectedTactics.split(';')){
             ptId = ptId.trim();
             productTacticIds.add(ptId);
             System.debug('processSelectedTacticsString: ptId: ' + ptId);
          }
       }else{
          productTacticIds.add(requests[0].selectedTactics.trim());
       }
                
       List<Product_Tactic_vod__c> productTacticRecordsSelected = new List<Product_Tactic_vod__c>(
            [SELECT Active_vod__c,CreatedById,CreatedDate,Description_vod__c,Id,
                    IsDeleted,IsLocked,LastModifiedById,LastModifiedDate,MayEdit,
                    MSD_CORE_Product_Plan_Product__c,MSD_CORE_Prod_Strat_Dsc__c,
                    MSD_CORE_Type__c,Name,Product_Strategy_vod__c,Product__c,SystemModstamp,Type_vod__c 
             FROM Product_Tactic_vod__c 
             WHERE id in : productTacticIds]);

        for(Product_Tactic_vod__c tact : productTacticRecordsSelected){
           System.debug('processSelectedTacticsString: pt name: ' + tact.Name);
        }
        
        if(!productTacticRecordsSelected.isEmpty()){
           curResults.selectedProductTactics = productTacticRecordsSelected;
        }
        
        List<Results> resultsList = new List<Results>();
        resultsList.add(curResults);
        return resultsList;
     }
    
    
    global class Requests{
                
        @InvocableVariable
        global String selectedTactics;        
    }
    
    global class Results{        
        @InvocableVariable
        global List<Product_Tactic_vod__c> selectedProductTactics;        
    }
       
}