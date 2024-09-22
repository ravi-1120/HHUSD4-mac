public without sharing class  VeevaDataGridConfigTriggerHandler extends VeevaTriggerHandler{
	private List<Data_Grid_Loader_Configuration_vod__c > newConfigs = new List<Data_Grid_Loader_Configuration_vod__c >();

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newConfigs = (List<Data_Grid_Loader_Configuration_vod__c>) triggerNew;
    }

    protected override String sObjectType() {
        return 'Data_Grid_Loader_Configuration_vod__c';
    }
    
    protected override void beforeInsert() {
		beforeInsUpd();
    }
    
    protected override void beforeUpdate() {
		beforeInsUpd();
    }
    
    private void beforeInsUpd() {
        Set<String> campaignTargetRequiredFields = getCampaignTargetRequiredFields();
        String fieldMissingErrorMessage = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('GRID_LOADER_REQUIRED_FIELDS_MISSING_ERROR','COMMON','Fields List missing required fields: {0}');
        String duplicateFieldsErrorMessage = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('GRID_LOADER_DUPLICATE_FIELDS_ERROR','COMMON','Fields List contains duplicate fields: {0}');

        for (Data_Grid_Loader_Configuration_vod__c config : newConfigs) {
            String errorMessage = '';
            List<String> missingFields = new List<String>();
            List<String> duplicateFields = new List<String>();

            // Check for duplicate fields
            List<String> fieldList = config.Field_List_vod__c.split(',');
            Set<String> uniqueFields = new Set<String>();
            for (String field : fieldList) {
                String lookupField = field.contains('.') ? field.split('\\.')[0] : field; // only needs the Lookup Field
                lookupField = lookupField.contains('<R>') ? lookupField.replace('<R>', '') : lookupField; // replaces <R> with an empty string
                lookupField = lookupField.trim(); //trim lookupField
                if (uniqueFields.contains(lookupField)) {
                    duplicateFields.add(lookupField);
                }
                uniqueFields.add(lookupField);
            }

            if (!duplicateFields.isEmpty()) {
                String duplicateFieldsString = String.join(duplicateFields, ',');
                errorMessage += duplicateFieldsErrorMessage.replace('{0}', duplicateFieldsString);
                config.addError(errorMessage);
                return;
            }

            for (String requiredField : campaignTargetRequiredFields) {
               if (!uniqueFields.contains(requiredField)) {
                   missingFields.add(requiredField);
               }
            }

            if (!missingFields.isEmpty()) {
                String missingFieldsString = String.join(missingFields, ',');
                errorMessage += fieldMissingErrorMessage.replace('{0}', missingFieldsString);
                config.addError(errorMessage);
                return;
            }
        }
    }

  private Set<String>  getCampaignTargetRequiredFields() {
        Set<String> requiredFields = new Set<String>();
        // Describe the object
        Map<String, Schema.SObjectField> fieldsMap = Campaign_Target_vod__c.sObjectType.getDescribe().fields.getMap();
        for (String fieldName : fieldsMap.keySet()) {
            // Describe each field
            Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();
            // Check if the field is required
            if (fieldDescribe.getName() != 'Campaign_vod__c' && fieldDescribe.isNillable() == false && fieldDescribe.isCreateable()) {
                requiredFields.add(fieldDescribe.getName());
            }
        }
        return requiredFields;
    }

}