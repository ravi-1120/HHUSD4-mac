public with sharing class VeevaLookupDataHelper {
    @AuraEnabled(cacheable=true)
    public static Boolean isEnhancedLookupEnabled(){
        try {
            Veeva_Settings_vod__c veevaSettings = VeevaSettings.getVeevaSettings();
            if (veevaSettings == null) {
                return false;
            }
            return (veevaSettings.ENHANCED_LOOKUPS_vod__c == 1);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String, Object>> getLookupFiltersForObject(String objectName){
        try {
            Map<String, Map<String, Object>> lookupFilters = new Map<String, Map<String, Object>>();
            String searchTerm = objectName + '.%';
            List<Rule_Object_Header_vod__c> headers = new List<Rule_Object_Header_vod__c>();

            Set<String> ruleObjectHeaderQueryFields = new Set<String>{'Name', 'Predicate_vod__c'};
            VeevaBaseObject ruleObjectHeader = VeevaBaseObject.create('Rule_Object_Header_vod__c');
            Set<String> ruleObjectHeaderAccessibleFields = ruleObjectHeader?.getAccessibleFields(ruleObjectHeaderQueryFields, false, false);

            Set<String> ruleDefinitionQueryFields = new Set<String>{'Error_Condition_Formula_vod__c', 'Order_vod__c', 'Supported_vod__c'};
            VeevaBaseObject ruleDefinition = VeevaBaseObject.create('Rule_Definition_vod__c');
            Set<String> ruleDefinitionAccessibleFields = ruleDefinition?.getAccessibleFields(ruleDefinitionQueryFields, false, false);

            if(
                (ruleObjectHeaderAccessibleFields != null && ruleObjectHeaderAccessibleFields.size() == ruleObjectHeaderQueryFields.size()) &&
                (ruleDefinitionAccessibleFields != null && ruleDefinitionAccessibleFields.size() == ruleDefinitionQueryFields.size())
            ){
                headers = [
                    SELECT Name, Predicate_vod__c, (
                        SELECT Error_Condition_Formula_vod__c, Order_vod__c, Supported_vod__c
                        FROM Rule_Definition_vod__r
                        WHERE Active_vod__c = true
                            AND RecordType.DeveloperName = 'SFDC_Lookup_Filter_Line_vod'
                    )
                    FROM Rule_Object_Header_vod__c
                    WHERE Status_vod__c = 'Enabled_vod'
                        AND VExternal_Id_vod__c LIKE :searchTerm
                        AND RecordType.DeveloperName = 'SFDC_Lookup_Filter_Header_vod'
                ];
            }

            for (Rule_Object_Header_vod__c header : headers) {
               populateLookupFilters(lookupFilters, header);
            }
            
            return lookupFilters;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static void populateLookupFilters(Map<String, Map<String, Object>> lookupFilters, Rule_Object_Header_vod__c header) {
        Map<String, Object> headerObj = new Map<String, Object>();
        headerObj.put('Predicate', header.Predicate_vod__c);
        List<String> params = new List<String>();
        for (Rule_Definition_vod__c definition : header.Rule_Definition_vod__r) {
            Map<String, String> definitionObj = new Map<String, String>();
            String formula = definition.Error_Condition_Formula_vod__c;
            List<String> parts = formula.split(';', 4);
            if (parts.size() == 4) {
                definitionObj.put('Order', String.valueOf(definition.Order_vod__c));
                definitionObj.put('Supported', String.valueOf(definition.Supported_vod__c));
                headerObj.put(formula, definitionObj);
                List<String> left = parts[0].split('\\.');
                if (left[0].equals('$Source')) {
                    params.add(left[1]);
                }
                List<String> right = parts[3].split('\\.');
                if (right[0].equals('$Source')) {
                    params.add(right[1]);
                }
            }
        }
        headerObj.put('params', params);
        lookupFilters.put(header.Name, headerObj);
    }
}