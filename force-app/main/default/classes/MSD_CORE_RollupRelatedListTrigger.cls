/*
* MSD_CORE_RollupRelatedListTrigger
* Created By:    Samuel Rosen
* Created Date:  5/18/2015
* Description:   This class along with workflows for the Case object work
*                as a rollup summary for text fields.  Namely the workflow
*                rules populate a text field on the Case whenever a related record
*                such as a Case Document is added.  The trigger fires when a record
*                is deleted and forces a recalculation of the text field by clearing
*                out the text field and updating the remaining records.
*/
public with sharing class MSD_CORE_RollupRelatedListTrigger implements TriggersMVN.HandlerInterface{

    private String lookUpToCase;
    private String caseFieldToClear;
    private Schema.SObjectType relatedObjectType; 
    
    public MSD_CORE_RollupRelatedListTrigger(String caseFieldToClear, String lookUpToCase) {
        this.caseFieldToClear = caseFieldToClear;
        this.lookUpToCase = lookUpToCase;
    }

    public void handle() {
        List<SObject> deleteList =  Trigger.old;
        if(deleteList.size() > 0) {
            this.relatedObjectType = deleteList[0].getSobjectType();
            processUpdate(deleteList);
        }
    }

    private void processUpdate(List<SObject> deleteList) {
        Set<Id> caseIds = new Set<Id>(); 
        for(SObject obj:deleteList){
            caseIds.add((Id) obj.get(lookUpToCase)); 
        }

        List<Case> cases = new List<Case>();
        if(caseIds.size() > 0) {
            for(Id caseId:caseIds){
                Case cs = new Case(Id = caseId);
                cs.put(caseFieldToClear, ''); 
                
                if(caseFieldToClear == 'MSD_CORE_Product_Name__c')
                    cs.put('MSD_CORE_Generic_Product_Name__c', '');
                    
                cases.add(cs);
            }
            if(cases.size() > 0) {
                update cases;  
            }
        } 

        List<SObject> updateList = Database.query('SELECT Id FROM ' + relatedObjectType.getDescribe().getName() + ' WHERE ' + lookUpToCase + ' IN :caseIds');
        if(updateList.size() > 0) {
            update updateList;
        }  
    }
    
    public static void updateCaseLotNumber(List<MSD_CORE_AE_Product__c> newList)
    {
        try
        {
            Set<String> caseIds = new Set<String>();
            for(MSD_CORE_AE_Product__c a : newList)
            {
                caseIds.add(a.MSD_CORE_Adverse_Event__c);
            }
            
            if(caseIds.size() > 0)
            {
                Map<String, List<String>> lotnumberMap = new Map<String, List<String>>();
                
                for(Case c : [select id, MSD_CORE_PQC_Lot_Numbers__c, 
                             (select id, MSD_CORE_Lot_Number__c from AE_Products__r where MSD_CORE_Lot_Number__c != null) 
                              from Case where id in : caseIds])
                {
                    for(MSD_CORE_AE_Product__c p : c.AE_Products__r)
                    {
                        List<String> tempList = lotnumberMap.get(c.Id);
                        
                        if(tempList == null)
                            tempList = new List<String>();
                            
                        tempList.add(p.MSD_CORE_Lot_Number__c);
                        
                        lotnumberMap.put(c.Id, tempList);
                    }
                }
                
                List<Case> caseUpdateList = new List<Case>();
                for(String s : lotnumberMap.keyset())
                {
                    List<String> tempList = lotnumberMap.get(s);
                    
                    if(tempList != null)
                    {
                        caseUpdateList.add(new Case(id = s,
                                                    MSD_CORE_PQC_Lot_Numbers__c = String.join(tempList, ',')));
                    }
                }
                
                if(caseUpdateList.size() > 0)
                    update caseUpdateList;
            }
        }
        catch(Exception ex){
        
        }
    }
}