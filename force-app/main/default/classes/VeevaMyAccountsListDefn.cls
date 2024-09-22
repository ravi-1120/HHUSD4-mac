public inherited sharing class VeevaMyAccountsListDefn extends VeevaMyAccountsBaseView {

    @AuraEnabled
    public List<VeevaMyAccountsListItem> accounts;

    private Integer dynamicAttributeLimit = 0;

    public VeevaMyAccountsListDefn(Account_List_vod__c accountList, List<Account_List_Item_vod__c> accountListItems, String columnsString, Integer dynamicAttributeLimit) {
        this(accountList, accountListItems, columnsString, new VeevaDynamicAttributeService(), dynamicAttributeLimit);
    }

    public VeevaMyAccountsListDefn(Account_List_vod__c accountList, List<Account_List_Item_vod__c> accountListItems, 
                                    String columnsString, VeevaDynamicAttributeService dynamicAttributeService,
                                    Integer dynamicAttributeLimit) {
        super(dynamicAttributeService);
        this.dynamicAttributeLimit = dynamicAttributeLimit;
        this.id = accountList.Id;
        this.name = accountList.Name;
        this.requiresTerritory = false;
        this.hasErrors = false;
        this.columns = getColumns(appendDynamicAttributeColumns(columnsString), 'ACCOUNT');
        this.accounts = getAccounts(accountListItems);
        this.type = VeevaMyAccountsViewItem.ACCOUNT_LIST_TYPE;
        updateColumnLabels(getDynamicAttributeLabelById(this.dynamicAttributeLimit));
    }

    private List<VeevaMyAccountsListItem> getAccounts(List<Account_List_Item_vod__c> accountListItems) {
        List<VeevaMyAccountsListItem> accounts = new List<VeevaMyAccountsListItem>();
        if (accountListItems != null) {
            for (Account_List_Item_vod__c listItem : accountListItems) {
                accounts.add(new VeevaMyAccountsListItem(listItem));
            }
        }
        return accounts;
    }

    private String appendDynamicAttributeColumns(String baseColumns) {
        String dynamicAttributeColumnsString = getDynamicAttributeColumnString();
        return String.join(new List<String>{baseColumns, dynamicAttributeColumnsString}, ',');
    }

    private String getDynamicAttributeColumnString() {
        Map<Id, Dynamic_Attribute_Configuration_vod__c> configurations = getActiveDynamicAttributeConfigurations(dynamicAttributeLimit);
        List<String> dynamicAttributeColumnStrings = new List<String>();
        for (Dynamic_Attribute_Configuration_vod__c configuration : configurations.values()) {
            dynamicAttributeColumnStrings.add('Dynamic_Attribute_Configuration_vod__c.' + configuration.Id);
        }
        return String.join(dynamicAttributeColumnStrings, ',');
    }        
}