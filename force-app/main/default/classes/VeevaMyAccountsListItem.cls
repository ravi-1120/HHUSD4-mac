public inherited sharing class VeevaMyAccountsListItem {

    @AuraEnabled
    public String id;

    @AuraEnabled
    public String accountId;

    public VeevaMyAccountsListItem(Account_List_Item_vod__c accountListItem) {
        this.id = accountListItem.Id;
        this.accountId = accountListItem.Account_vod__c;
    }
}