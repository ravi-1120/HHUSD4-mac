/*
 * MSD_CORE_CC_EditAccount
 * Created By: Kevin Brace 
 * Initial Version: REL 19R4.0 10/15/2019 - Story DGF-223
 * Description: Controller Class for the MSD_CORE_CC_EditAccount Aura Component. 
 */

public with sharing class MSD_CORE_CC_EditAccount {

    @AuraEnabled
    public static InteractionWrapper requiresDCRProcessing(Id accountId){
        
        InteractionWrapper wrap = new InteractionWrapper();
        boolean isDCRRecordType = false;
        
        //Get the Record Types that require DCR Processing...
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
        List<String> dcrRecordTypeDeveloperNames = UtilitiesMVN.splitCommaSeparatedString(settings.MSD_CORE_DCR_Record_Types__c);
        
        //Get the Accounts Record Type Id...
        Id acctRecordTypeId = [SELECT RecordTypeId FROM Account WHERE Id= :accountId].RecordTypeId;
        
        //Get the Orgs Record Types for Account (Developer Name/Id Map...avoiding SOQL Limits...)
        Map<Id, String> orgRecTypeIdMap=recordTypeMap('Account');
        
        for(String dcrRecordTypeDeveloperName : dcrRecordTypeDeveloperNames){
            if(( orgRecTypeIdMap.containsKey(acctRecordTypeId)) && (dcrRecordTypeDeveloperName == orgRecTypeIdMap.get(acctRecordTypeId))){
                isDCRRecordType = true;  
            }
        }
        
        wrap.requiresDCRProcessing = isDCRRecordType;
        
        return wrap;
    
    }
    
     //Method to get the map of recordType recordTypeId as key and DeveloperName as value 
     Public static Map<Id, String> recordTypeMap(string obj){
        Map<Id, String> recTypeNameWithIdMap=new Map<Id, String>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getRecordTypeId(), recInfo.getDeveloperName());
            }
        }
        return recTypeNameWithIdMap;
    } 
    
    public class InteractionWrapper{
        
        @AuraEnabled
        public boolean requiresDCRProcessing;
        
    }

}