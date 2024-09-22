public inherited sharing virtual class VeevaDynamicAttributeService  {
    private static final Set<String> REQUIRED_CONFIGURATION_FIELDS = new Set<String>{
        'Id',
        'Name',
        'Attribute_Label_vod__c',
        'Available_Values_vod__c',
        'Section_Name_vod__c',
        'RecordTypeId'
    };

    private final VeevaMySetupService mySetupService;

    public VeevaDynamicAttributeService() {
        this(new VeevaMySetupService());
    }

    public VeevaDynamicAttributeService(VeevaMySetupService mySetupService) {
        this.mySetupService = mySetupService;
    }

    public List<Dynamic_Attribute_Configuration_vod__c> getDynamicAttributeConfigurationsById(Set<Id> configurationIds) {
        VeevaBaseObject dynamicAttributeBaseObject = VeevaBaseObject.create(Dynamic_Attribute_Configuration_vod__c.getSObjectType());
        if (dynamicAttributeBaseObject == null) {
            return new List<Dynamic_Attribute_Configuration_vod__c>();
        }

        Set<String> accessibleFields = dynamicAttributeBaseObject.getAccessibleFields(REQUIRED_CONFIGURATION_FIELDS);
        if (accessibleFields.size() != REQUIRED_CONFIGURATION_FIELDS.size()) {
            return new List<Dynamic_Attribute_Configuration_vod__c>();
        }

        List<String> fieldsToQuery = getRequiredFieldsToQuery();
        return Database.query(String.format(
            'SELECT {0} FROM Dynamic_Attribute_Configuration_vod__c WHERE Id IN :configurationIds',
            new List<String>{String.join(fieldsToQuery, ',')}
        ));
    }

    public List<Dynamic_Attribute_Configuration_vod__c> getActiveDynamicAttributeConfigurations() {
        return getActiveDynamicAttributeConfigurations(null);
    }

    /**
     * Retrieves all Active Dynamic Attribute Configurations sorted by Section and Attribute Label.
     *
     * maxConfigurationsToRetrieve - if null we will return all records,
     *                               no records if <= 0,
     *                               otherwise a subset of the number specified
     */
    public List<Dynamic_Attribute_Configuration_vod__c> getActiveDynamicAttributeConfigurations(Integer maxConfigurationsToRetrieve) {
        if (maxConfigurationsToRetrieve <= 0) {
            return new List<Dynamic_Attribute_Configuration_vod__c>();
        }

        VeevaBaseObject dynamicAttributeBaseObject = VeevaBaseObject.create(Dynamic_Attribute_Configuration_vod__c.getSObjectType());
        if (dynamicAttributeBaseObject == null) {
            return new List<Dynamic_Attribute_Configuration_vod__c>();
        }

        Set<String> accessibleFields = dynamicAttributeBaseObject.getAccessibleFields(REQUIRED_CONFIGURATION_FIELDS);
        if (accessibleFields.size() != REQUIRED_CONFIGURATION_FIELDS.size()) {
            return new List<Dynamic_Attribute_Configuration_vod__c>();
        }

        boolean hasAccessToProduct = hasAccessToProductField(dynamicAttributeBaseObject);
        boolean hasAccessToDetailGroup = hasAccessToDetailField(dynamicAttributeBaseObject);

        // These are the required fields for query
        // We check these fields in our above accessible check
        List<String> fieldsToQuery = getRequiredFieldsToQuery();
        if (hasAccessToProduct) {
            fieldsToQuery.add('Product_vod__c');
        }
        if (hasAccessToDetailGroup) {
            fieldsToQuery.add('Detail_Group_vod__c');
        }

        List<Dynamic_Attribute_Configuration_vod__c> configurations = Database.query(String.format(
            'SELECT {0} FROM Dynamic_Attribute_Configuration_vod__c WHERE Status_vod__c = \'Active_vod\' ORDER BY Section_Name_vod__c, Attribute_Label_vod__c',
            new List<String>{String.join(new List<String>(fieldsToQuery), ',')}
        ));
        Map<String, List<Product_vod__c>> mySetupProductsByProductType = mySetupService.getMySetupProductsByProductType(new Set<String>(), UserInfo.getUserId());
        List<Product_vod__c> mySetupDetails = mySetupProductsByProductType.get('Detail');
        Set<Id> mySetupDetailIds = getIds(mySetupDetails);
        List<Product_vod__c> mySetupDetailGroups = mySetupProductsByProductType.get('Detail Group');
        Set<Id> mySetupDetailGroupIds = getIds(mySetupDetailGroups);
        Map<Id, Product_Group_vod__c> productGroupByProductId = getProductGroupsByProductId(mySetupDetailIds, mySetupDetailGroupIds);
        configurations = filterProductInMySetup(configurations, hasAccessToProduct, mySetupDetailIds);
        configurations = filterDetailGroupInMySetup(configurations, hasAccessToDetailGroup, mySetupDetailGroupIds);
        configurations = filterProductDetailGroupIntersection(configurations, hasAccessToProduct && hasAccessToDetailGroup, productGroupByProductId);

        return subset(configurations, maxConfigurationsToRetrieve);
    }

    private Set<Id> getIds(List<SObject> records) {
        return records != null ? new Map<Id, SObject>(records).keySet() : new Set<Id>();
    }

    private List<Dynamic_Attribute_Configuration_vod__c> filterProductInMySetup(List<Dynamic_Attribute_Configuration_vod__c> records, boolean hasAccessToProduct, Set<Id> mySetupDetailIds) {
        if (!hasAccessToProduct) {
            return records;
        }
        List<Dynamic_Attribute_Configuration_vod__c> filtered = new List<Dynamic_Attribute_Configuration_vod__c>();
        for (Dynamic_Attribute_Configuration_vod__c record : records) {
            if (record.Product_vod__c == null || mySetupDetailIds.contains(record.Product_vod__c)) {
                filtered.add(record);
            }
        }
        return filtered;
    }

    private List<Dynamic_Attribute_Configuration_vod__c> filterDetailGroupInMySetup(List<Dynamic_Attribute_Configuration_vod__c> records, boolean hasAccessToDetailGroup, Set<Id> mySetupDetailGroupIds) {
        if (!hasAccessToDetailGroup) {
            return records;
        }
        List<Dynamic_Attribute_Configuration_vod__c> filtered = new List<Dynamic_Attribute_Configuration_vod__c>();
        for (Dynamic_Attribute_Configuration_vod__c record : records) {
            if (record.Detail_Group_vod__c == null || mySetupDetailGroupIds.contains(record.Detail_Group_vod__c)) {
                filtered.add(record);
            }
        }
        return filtered;
    }

    private List<Dynamic_Attribute_Configuration_vod__c> filterProductDetailGroupIntersection(List<Dynamic_Attribute_Configuration_vod__c> records, boolean hasAccessToProductAndDetailGroup, Map<Id, Product_Group_vod__c> productGroupByProductId) {
        if (!hasAccessToProductAndDetailGroup) {
            return records;
        }
        List<Dynamic_Attribute_Configuration_vod__c> filtered = new List<Dynamic_Attribute_Configuration_vod__c>();
        for (Dynamic_Attribute_Configuration_vod__c record : records) {
            Product_Group_vod__c productGroupForRecord = productGroupByProductId.get(record.Product_vod__c);
            boolean productIsNotInProductGroup = record.Product_vod__c != null && productGroupForRecord == null;
            boolean productAndDetailGroupMatchProductGroup = productGroupForRecord?.Product_Catalog_vod__c == record.Detail_Group_vod__c;
            if (
                (record.Detail_Group_vod__c == null && record.Product_vod__c == null) ||
                (record.Detail_Group_vod__c != null && record.Product_vod__c == null) ||
                (record.Detail_Group_vod__c == null && productIsNotInProductGroup) ||
                (record.Product_vod__c != null && productAndDetailGroupMatchProductGroup)
            ) {
                filtered.add(record);
            }
        }
        return filtered;
    } 


    /**
     * Creates a subset of the records passed in.
     * Note: when size is null we will return all
     */
    private List<Dynamic_Attribute_Configuration_vod__c> subset(List<Dynamic_Attribute_Configuration_vod__c> records, Integer size) {
        if (size == null) {
            return records;
        }
        if (size <= 0) {
            return new List<Dynamic_Attribute_Configuration_vod__c>();
        }
        List<Dynamic_Attribute_Configuration_vod__c> subset = new List<Dynamic_Attribute_Configuration_vod__c>();
        for (Integer i = 0; i < size && i < records.size(); i++) {
            subset.add(records.get(i));
        }
        return subset;
    }

    private Map<Id, Product_Group_vod__c> getProductGroupsByProductId(Set<Id> detailIds, Set<Id> detailGroupIds) {
        List<Product_Group_vod__c> productGroups = getProductGroups(detailIds, detailGroupIds);
        Map<Id, Product_Group_vod__c> productGroupsByProductId = new Map<Id, Product_Group_vod__c>();
        for (Product_Group_vod__c productGroup : productGroups) {
            productGroupsByProductId.put(productGroup.Product_vod__c, productGroup);
        }
        return productGroupsByProductId;
    }

    private List<String> getRequiredFieldsToQuery() {
        List<String> fieldsToQuery = new List<String>(REQUIRED_CONFIGURATION_FIELDS);
        fieldsToQuery.add('RecordType.DeveloperName');
        return fieldsToQuery;
    }

    protected virtual List<Product_Group_vod__c> getProductGroups(Set<Id> detailIds, Set<Id> detailGroupIds) {
        VeevaBaseObject productGroupBaseObject = VeevaBaseObject.create(Product_Group_vod__c.getSObjectType());
        Set<String> requiredQueryFields = new Set<String>{'Id', 'Name', 'Product_vod__c', 'Product_Catalog_vod__c'};
        Set<String> accessibleQueryFields = productGroupBaseObject?.getAccessibleFields(requiredQueryFields);
        if (productGroupBaseObject == null && accessibleQueryFields?.size() != requiredQueryFields.size()) {
            return new List<Product_Group_vod__c>();
        }

        return Database.query(String.format(
            'SELECT {0} FROM Product_Group_vod__c WHERE Product_vod__c IN :detailIds AND Product_Catalog_vod__c IN :detailGroupIds',
            new List<String>{String.join(new List<String>(accessibleQueryFields), ',')}
        ));
    }

    protected virtual boolean hasAccessToProductField(VeevaBaseObject dynamicAttributeBaseObject) {
        return dynamicAttributeBaseObject.getAccessibleField('Product_vod__c', false, false) != null;
    }

    protected virtual boolean hasAccessToDetailField(VeevaBaseObject dynamicAttributeBaseObject) {
        return dynamicAttributeBaseObject.getAccessibleField('Detail_Group_vod__c', false, false) != null;
    }
}