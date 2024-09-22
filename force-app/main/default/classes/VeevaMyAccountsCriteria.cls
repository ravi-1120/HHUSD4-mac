public inherited sharing class VeevaMyAccountsCriteria {
    @AuraEnabled
    public VeevaMyAccountsFieldDefn field { get; private set; }

    @AuraEnabled
    public String operator { get; private set; }

    @AuraEnabled
    public String value { get; private set; }

    @AuraEnabled
    public boolean hasError { get; set; }

    public VeevaMyAccountsCriteria(String criteriaString, String source) {
        List<String> parts = criteriaString.split(':::');
        if (parts?.size() >= 2) {
            this.field = VeevaMyAccountsFieldDefnFactory.create(parts.get(0), source);
            this.operator = parts.get(1);
            this.value = parts.size() > 2 ? parts.get(2) : '';
            this.hasError = this.field.hasError;
        } else {
            this.hasError = true;
        }
    }
}