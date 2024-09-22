public inherited sharing class VeevaGASConfigMobile extends VeevaGASConfigBase{
    private String CUSTOM_COLUMN_SETTING_NAME = 'GAS_Preview_Fields_vod__c';
    private Map<String, List<String>> BASE_FIELDS = new Map<String, List<String>> { 'account' => new List<String>{'Account.Id', 'Account.RecordTypeId.Id', 'Account.RecordTypeId.Name', 'Account.IsPersonAccount', 'Account.Name', 'Account.Specialty_1_vod__c', 'Account.Primary_Parent_vod__c.Name', 'Account.Formatted_Name_vod__c' },
        'address_vod__c' => new List<String> { 'Address_vod__c.Id', 'Address_vod__c.Account_vod__c', 'Address_vod__c.Primary_vod__c', 'Address_vod__c.CreatedDate', 'Address_vod__c.Name', 'Address_vod__c.City_vod__c', 'Address_vod__c.State_vod__c', 'Address_vod__c.Zip_vod__c' }};
    private String MAX_ROW_LIMIT = '50';
    //Set 0 for no limit to preview columns for iPad
    private Integer MAX_COLUMN_LIMIT = 0;

    public VeevaGASConfigMobile(){
        this.columnConfig = getConfiguredColumns(CUSTOM_COLUMN_SETTING_NAME, BASE_FIELDS, new List<String>(), '', MAX_COLUMN_LIMIT);
    }

    public override String getMaxRowLimit(){
        return MAX_ROW_LIMIT;
    }

    public override List<Map<String, String>> getResultSetColumnInfo(){
        List<Map<String, String>> resultSetInfo = columnConfig.getResultSetMetadata();
        resultSetInfo.addAll(getAdditionalResultSetFieldsInfo('Account'));
        return resultSetInfo;
    }

    private List<Map<String, String>> getAdditionalResultSetFieldsInfo(String objectName){
        List<Map<String, String>> resultSetInfo = new List<Map<String, String>>();
        Map<String, String> fieldInfo = new Map<String, String>();
        if (objectName == 'Account'){
            fieldInfo.put('label', 'Parent Accounts');
            fieldInfo.put('objectName', 'Account');                
            fieldInfo.put('fieldName', objectName + '.Parents');
            fieldInfo.put('fieldType', 'Array');
        }
        resultSetInfo.add(fieldInfo);
        return resultSetInfo;
    }
}