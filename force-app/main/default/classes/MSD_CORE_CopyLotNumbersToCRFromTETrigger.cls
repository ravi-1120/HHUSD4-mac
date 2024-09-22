/*
* MSD_CORE_CopyLotNumbersToCRFromTETrigger
* Created By:    Samuel Rosen
* Created Date:  5/18/2015
* Description:   This trigger handler adds Temperature Excursion Lot Numbers to 
*                Compensation Requests created under the same Interaction as the
*                Temperature Excursion.  Lot Numbers are added for all of the
*                Temperature Excursion Products where the outcome is "Not Supported."
*/
public with sharing class MSD_CORE_CopyLotNumbersToCRFromTETrigger implements TriggersMVN.HandlerInterface{
     public void handle() {
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance(); 
        List<Case> caseList = (List<Case>) Trigger.new;
        system.debug('krb1');
        Id lotNumberRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName =: settings.MSD_CORE_Comp_Request_Lot_Number__c].Id;
system.debug('krb2');
        // Identify all of the compensation requests
        Map<Id, Id> compRequestToInteractionMap = new Map<Id, Id>();
         system.debug('krb3');
        for(Case cs:caseList) {
            system.debug('krb4');
            if(UtilitiesMVN.matchCaseRecordTypeIdToName(cs.RecordTypeId, settings.MSD_CORE_Compensation_Req_Record_Type__c)) {
                system.debug('krb5');
                compRequestToInteractionMap.put(cs.Id, cs.ParentId); 
            }
        }
system.debug('krb6');
        // Retrieve all of the interactions with their corresponding Temperature Excursions
        Map<Id, Case> interactionsWithTempExcursionsMap = new Map<Id, Case>([SELECT Id, 
                                                                                    (SELECT Id 
                                                                                            FROM Cases 
                                                                                            WHERE (RecordType.DeveloperName =: settings.MSD_CORE_Temp_Excursion_Record_Type__c 
                                                                                            OR RecordType.DeveloperName =: settings.MSD_CORE_Temp_Exc_Closed_Record_Type__c)
                                                                                            AND Status != :settings.Cancelled_Status_MVN__c
                                                                                            ORDER BY CreatedDate desc LIMIT 1) 
                                                                            FROM Case WHERE Id IN :compRequestToInteractionMap.values()]); 
        system.debug('krb7');
        // Add all of the Temperature Excursion record ids into a set
        Set<Id> tempExcursionIdSet = new Set<Id>();
        for(Id interactionId:interactionsWithTempExcursionsMap.keySet()) {
            system.debug('krb8');
            List<Case> temperatureExcursionList = interactionsWithTempExcursionsMap.get(interactionId).Cases;
            system.debug('krb9');
            if(temperatureExcursionList != null && temperatureExcursionList.size() == 1) {
                tempExcursionIdSet.add(temperatureExcursionList[0].Id); 
            }
        }
system.debug('krb10');
        Set<String> outcomeNotSupportedValues = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(settings.MSD_CORE_Temp_Not_Supported_Outcome__c));
        
        // Retrieve the Temperature Excursion Product records for the Temperature Excursions
        List<MSD_CORE_Temperature_Excursion_Product__c> tempExProdList =  [SELECT Id, MSD_CORE_Case__c, MSD_CORE_Lot_Number__c, MSD_CORE_Expiration_Date__c, MSD_CORE_Product__c 
                                                                                FROM MSD_CORE_Temperature_Excursion_Product__c 
                                                                                WHERE  MSD_CORE_Outcome__c IN :outcomeNotSupportedValues 
                                                                                AND MSD_CORE_Case__c IN :tempExcursionIdSet];

        // Create a map of temperature excursions to their related products
        Map<Id, List<MSD_CORE_Temperature_Excursion_Product__c>> tempExToTempExProdMap = new Map<Id, List<MSD_CORE_Temperature_Excursion_Product__c>> (); 
        for(MSD_CORE_Temperature_Excursion_Product__c prod:tempExProdList) {
            if(tempExToTempExProdMap.get(prod.MSD_CORE_Case__c) == null) {
                tempExToTempExProdMap.put(prod.MSD_CORE_Case__c, new List<MSD_CORE_Temperature_Excursion_Product__c>());
                tempExToTempExProdMap.get(prod.MSD_CORE_Case__c).add(prod);
            }else{
                tempExToTempExProdMap.get(prod.MSD_CORE_Case__c).add(prod);
            }
        }

        List<MSD_CORE_Lot_Number__c> lotNumberList = new List<MSD_CORE_Lot_Number__c>(); 

        // Create Lot Numbers which correspond to unsupported Temperature Excursion Products
        for(Id compRequestId:compRequestToInteractionMap.keySet()) {
            Id interactionId = compRequestToInteractionMap.get(compRequestId);
            Case interaction = interactionsWithTempExcursionsMap.get(interactionId);
            List<Case> tempExcursionList = interaction.Cases;

            if(tempExcursionList != null && tempExcursionList.size() == 1) {
                List<MSD_CORE_Temperature_Excursion_Product__c> tempExcursionProducts 
                                                                            = tempExToTempExProdMap.get(tempExcursionList[0].Id);

                if(interaction != null && interaction.Cases.size() > 0 
                    && tempExcursionProducts != null && tempExcursionProducts.size() > 0) {
                    
                    Case tempExRequest = interactionsWithTempExcursionsMap.get(interactionId).Cases[0];

                    List<MSD_CORE_Temperature_Excursion_Product__c> tempExpProdListForInteraction = tempExToTempExProdMap.get(tempExRequest.Id);
                    for(MSD_CORE_Temperature_Excursion_Product__c tempExProd:tempExpProdListForInteraction) {
                        MSD_CORE_Lot_Number__c newLot = new MSD_CORE_Lot_Number__c(); 
                        newLot.MSD_CORE_Case__c = compRequestId; 
                        newLot.MSD_CORE_Product__c = tempExProd.MSD_CORE_Product__c; 
                        newLot.MSD_CORE_Lot_Number__c = tempExProd.MSD_CORE_Lot_Number__c; 
                        newLot.MSD_CORE_Product_Expiration_Date__c = tempExProd.MSD_CORE_Expiration_Date__c;
                        newLot.RecordTypeId = lotNumberRecordTypeId; 
                        lotNumberList.add(newLot); 
                    }
                }
            }
        }

        insert lotNumberList; 
    }
}