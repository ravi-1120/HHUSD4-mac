public inherited sharing abstract class VeevaMyAccountsBaseView {
    @AuraEnabled
    public String id { get; protected set; }

    @AuraEnabled
    public String name { get; protected set; }

    @AuraEnabled
    public boolean requiresTerritory { get; protected set; }

    @AuraEnabled
    public List<VeevaMyAccountsFieldDefn> columns { get; protected set; }

    @AuraEnabled
    public boolean hasErrors { get; protected set; }

    @AuraEnabled
    public String type { get; protected set; }

    public Boolean hasDynamicAttributes { get; protected set; }

    private Map<Id, Dynamic_Attribute_Configuration_vod__c> activeDynamicAttributeConfigurations = null;
    private final VeevaDynamicAttributeService dynamicAttributeService;

    public VeevaMyAccountsBaseView() {
        this(new VeevaDynamicAttributeService());
    }

    public VeevaMyAccountsBaseView(VeevaDynamicAttributeService dynamicAttributeService) {
        this.dynamicAttributeService = dynamicAttributeService;
        this.hasDynamicAttributes = false;
    }

    protected List<VeevaMyAccountsFieldDefn> getColumns(String columnsString, String source) {
        List<VeevaMyAccountsFieldDefn> columns = new List<VeevaMyAccountsFieldDefn>();
        if (String.isBlank(columnsString)) {
            return columns;
        }
        List<String> separatedColumns = columnsString.split(',');
        for (String columnString : separatedColumns) {
            VeevaMyAccountsFieldDefn fieldDefn = VeevaMyAccountsFieldDefnFactory.create(columnString, source);
            Boolean shouldFilter = updateOrFilterField(fieldDefn);
            if (!shouldFilter) {
                columns.add(fieldDefn);
            }
            this.hasErrors = this.hasErrors || fieldDefn.hasError;
        }
        return columns;
    }

    public Map<Schema.SObjectType, Set<Id>> getColumnReferenceIdsByObjectType() {
        Map<Schema.SObjectType, Set<Id>> columnReferenceIdsByObjectType = new Map<Schema.SObjectType, Set<Id>>();
        Set<Id> columnReferenceIds = getColumnReferenceIds();
        for (Id referenceId : columnReferenceIds) {
            Schema.SObjectType objectType = referenceId.getSObjectType();
            Set<Id> referenceIdsForObjectType = columnReferenceIdsByObjectType.get(objectType);
            if (referenceIdsForObjectType == null) {
                referenceIdsForObjectType = new Set<Id>();
                columnReferenceIdsByObjectType.put(objectType, referenceIdsForObjectType);
            }
            referenceIdsForObjectType.add(referenceId);
        }
        return columnReferenceIdsByObjectType;
    }

    public void updateColumnLabels(Map<Id, String> referenceIdLabels) {
        for (VeevaMyAccountsFieldDefn column : columns) {
            column.updateLabel(referenceIdLabels);
        }
    }

    protected Set<Id> getColumnReferenceIds() {
        Set<Id> columnReferenceIds = new Set<Id>();
        for (VeevaMyAccountsFieldDefn column : columns) {
            columnReferenceIds.addAll(column.getReferenceIds());
        }
        return columnReferenceIds;
    }

    protected Boolean updateOrFilterField(VeevaMyAccountsFieldDefn fieldDefn) {
        Boolean shouldFilter = false;
        if (Dynamic_Attribute_Configuration_vod__c.getSObjectType() == fieldDefn.objectType) {
            Map<Id, Dynamic_Attribute_Configuration_vod__c> dynamicAttributeConfigurations = getActiveDynamicAttributeConfigurations(null);
            Dynamic_Attribute_Configuration_vod__c configuration = dynamicAttributeConfigurations.get(fieldDefn.name);
            if (configuration == null) {
                shouldFilter = true;
            } else {
                fieldDefn.updateFieldType(configuration.RecordType.DeveloperName);
                fieldDefn.setPicklistValues(configuration.RecordType.DeveloperName, configuration.Available_Values_vod__c?.split(';;'));
            }
        }
        return shouldFilter;
    }

    protected Map<Id, Dynamic_Attribute_Configuration_vod__c> getActiveDynamicAttributeConfigurations(Integer dynamicAttributLimit) {
        if (this.activeDynamicAttributeConfigurations == null) {
            this.hasDynamicAttributes = true;
            List<Dynamic_Attribute_Configuration_vod__c> dynamicAttributeConfigurations = dynamicAttributeService.getActiveDynamicAttributeConfigurations(dynamicAttributLimit);
            this.activeDynamicAttributeConfigurations = new Map<Id, Dynamic_Attribute_Configuration_vod__c>(dynamicAttributeConfigurations);
        }
        return this.activeDynamicAttributeConfigurations;
    }

    protected Map<Id, String> getDynamicAttributeLabelById(Integer dynamicAttributeLimit) {
        Map<Id, Dynamic_Attribute_Configuration_vod__c> configurations = getActiveDynamicAttributeConfigurations(dynamicAttributeLimit);
        Map<Id, String> labelById = new Map<Id, String>();
        for (Dynamic_Attribute_Configuration_vod__c configuration : configurations.values()) {
            labelById.put(configuration.Id, String.format(
                '{0} - {1}',
                new List<String>{configuration.Section_Name_vod__c, configuration.Attribute_Label_vod__c}
            ));
        }
        return labelById;
    }
}