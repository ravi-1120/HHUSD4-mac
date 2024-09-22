/*
* MSD_CORE_CaseCampaignProductTrigger
* Created By:    Samuel Rosen
* Created Date:  5/18/2015
* Description:   This trigger handler populates the Product on a newly created Request 
*                based on the Campaign that the Request is associated with.
*                The Request will inherit the Campaign that is populated on the
*                corresponding Interaction.
* Change Log:
* Updated Date: 7/7/2021
* Updated By:   Vamshi Bashyakarla
* Description: Commented the oldCaseMap and directly used oldCases map from the trigger 
			   and change the condtion the if condition logic for blank value check on Type.
* Change Log:
* Updated Date: 7/7/2021
* Description: Changed the whole logic from after insert to before insert
*/
public with sharing class MSD_CORE_CaseCampaignProductTrigger implements TriggersMVN.HandlerInterface{
    public void handle() {
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance(); 
        Id requestCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(settings.Request_Record_Type_MVN__c).getRecordTypeId();
        Set<ID> caseCampaignIDs = new Set<ID>();            
        List<Case> cases = Trigger.new;
        
        for(Case cs : cases)
        {
            if(cs.RecordTypeId == requestCaseRecordTypeId)
            {
                caseCampaignIDs.add(cs.MSD_CORE_Campaign__c);
            }
        }
        
        if(caseCampaignIDs.size() > 0)
        {
            Map<Id, Campaign> campProdMap = new Map<Id, Campaign>([
                Select id, MSD_CORE_Product__c from Campaign where Id in :caseCampaignIDs]);
            
            for(Case cs : cases)
            {
                if(campProdMap.containsKey(cs.MSD_CORE_Campaign__c))
                {
                    cs.Product_MVN__c = campProdMap.get(cs.MSD_CORE_Campaign__c).MSD_CORE_Product__c; 	   
                }
            }
        }
    }
    
}