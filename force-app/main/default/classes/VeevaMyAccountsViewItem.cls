public inherited sharing class VeevaMyAccountsViewItem {
    public static final String VIEW_TYPE = 'VIEW';
    public static final String ACCOUNT_LIST_TYPE = 'ACCOUNT_LIST';

    @AuraEnabled
    public Id id { get; private set; }

    @AuraEnabled
    public String name { get; private set; }

    @AuraEnabled
    public String type { get; private set; }

    @AuraEnabled
    public String color { get; private set; }

    @AuraEnabled
    public String source { get; private set; }

    public VeevaMyAccountsViewItem(View_vod__c view) {
        this.id = view.Id;
        this.name = view.Name;
        this.type = VIEW_TYPE;
        this.color = null;
        if(Schema.SObjectType.View_vod__c.fields.Source_vod__c.isAccessible()) {
            this.source = getSource(view.Source_vod__c);
        }
    }

    public VeevaMyAccountsViewItem(Account_List_vod__c accountList) {
        this.id = accountList.Id;
        this.name = accountList.Name;
        this.type = ACCOUNT_LIST_TYPE;
        this.color = accountList.Icon_Name_vod__c;
    }

    private String getSource(String source) {
        if ('Account Location'.equalsIgnoreCase(source)) {
            return 'LOCATION';
        } else {
            return 'ACCOUNT';
        }
    }
}