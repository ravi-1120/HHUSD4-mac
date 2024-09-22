public class MSD_CORE_CC_SelectedRequesterController {
    @AuraEnabled
    public static Map<String,Map<String,String>> getFieldsMapPicklists(){
        Map<String,Map<String,String>> optionsMap = new Map<String,Map<String,String>>();   
        optionsMap.put('State_vod__c',new Map<String,String>());
        optionsMap.put('Country_vod__c',new Map<String,String>());
        
        for(Schema.PicklistEntry pickListValFamily : Address_vod__c.State_vod__c.getDescribe().getPicklistValues()) {
            optionsMap.get('State_vod__c').put(pickListValFamily.getvalue(),pickListValFamily.getlabel());
        }
        for(Schema.PicklistEntry pickListValFamily : Address_vod__c.Country_vod__c.getDescribe().getPicklistValues()) {            
            optionsMap.get('Country_vod__c').put(pickListValFamily.getvalue(),pickListValFamily.getlabel());
        }
        return optionsMap;
    }
}