public inherited sharing class VeevaMyAccountsProductMetricsDefn extends VeevaMyAccountsFieldDefn {

    public VeevaMyAccountsProductMetricsDefn(String objectAndFieldString, String source) {
        super(objectAndFieldString);
        if(!this.hasError) {
            this.hasError = this.hasError(source);
        }
    }
    
    private boolean hasError(String source) {
        return 'LOCATION'.equalsIgnoreCase(source) && !Schema.SObjectType.Product_Metrics_vod__c.fields.Location_vod__c.isAccessible();
    }

    public override Set<Id> getReferenceIds() {
        Set<Id> referenceIds = new Set<Id>();
        for (String qualifier : this.qualifiers) {
            referenceIds.add(qualifier);
        }
        return referenceIds;
    }

    protected override String getLabel(Schema.SObjectField field) {
        String fieldLabel = super.getLabel(field);

        List<String> parts = new List<String>();
        // Make sure we only add upto two qualifier ids.
        for (Integer i = 0; i < qualifiers.size() && i < 2; i++) {
            parts.add(qualifiers.get(i));
        }
        parts.add(fieldLabel);

        // There are currently a few different scenarios for product metrics:
        //  - there are no qualifiers (less likely),
        //  - there is a single qualifier (product id)
        //  - there are two qualifiers (product id + metric Id)
        if (qualifiers.isEmpty()) {
            return fieldLabel;
        } else if (qualifiers.size() == 1) {
            return String.format('{0}-{1}', parts);
        }

        return String.format('{0}-{1}-{2}', parts);
    }
}