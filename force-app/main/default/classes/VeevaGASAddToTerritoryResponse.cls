global inherited sharing class VeevaGASAddToTerritoryResponse extends VeevaBaseResponse {
    @TestVisible private final Map<String, Object> meta;
    @TestVisible private final List<Map<String, Object>> data;

    public VeevaGASAddToTerritoryResponse(VeevaGASAccountWithDetails accountWithDetails) {
        this.meta = new Map<String, Object>();
        this.data = new List<Map<String, Object>>();

        meta.put('includedAllRecords', accountWithDetails.includedAllRecords);

        data.add(accountWithDetails.getAccountAsMap());
        data.addAll(accountWithDetails.getAddressAsMapList());
        data.addAll(accountWithDetails.getParentAccountsAsMapList());
        data.addAll(accountWithDetails.getChildAccountsAsMapList());
    }
}