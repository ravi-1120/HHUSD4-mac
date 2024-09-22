public inherited sharing class VeevaGASConfigOnline extends VeevaGASConfigBase {

    private String CUSTOM_COLUMN_SETTING_NAME = 'GAS_Online_Columns_vod__c';
    private Map<String, List<String>> BASE_FIELDS = new Map<String, List<String>> { 'account' => new List<String>{'Account.Id', 'Account.RecordTypeId.Id', 'Account.RecordTypeId.DeveloperName', 'Account.RecordTypeId.Name', 'Account.IsPersonAccount' },
        'address_vod__c' => new List<String> { 'Address_vod__c.Id', 'Address_vod__c.Account_vod__c', 'Address_vod__c.Primary_vod__c', 'Address_vod__c.CreatedDate' }};
    private List<String> DEFAULT_RESULT_FIELDS = new List<String> { 'Account.Specialty_1_vod__c', 'Account.Primary_Parent_vod__c', 'Address_vod__c.Name', 'Address_vod__c.City_vod__c', 'Address_vod__c.State_vod__c', 'Address_vod__c.Zip_vod__c' };
    private String FIRST_RESULT_COLUMN = 'Account.Formatted_Name_vod__c';
    private String MAX_ROW_LIMIT = '100';
    private Integer MAX_COLUMNS_LIMIT = 15;

    public VeevaGASConfigOnline(){
        this.columnConfig = getConfiguredColumns(CUSTOM_COLUMN_SETTING_NAME, BASE_FIELDS, DEFAULT_RESULT_FIELDS, FIRST_RESULT_COLUMN, MAX_COLUMNS_LIMIT);
    }

    public override String getMaxRowLimit(){
        return MAX_ROW_LIMIT;
    }

    public override List<Map<String, String>> getResultSetColumnInfo(){
        List<Map<String, String>> resultSetInfo = columnConfig.getResultSetMetadata();
        return resultSetInfo;
    }
}