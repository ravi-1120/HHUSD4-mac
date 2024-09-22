public inherited sharing class VeevaMyAccountsViewDefn extends VeevaMyAccountsBaseView {
    private static Set<String> ACCESSIBLE_VIEW_FIELDS = VeevaBaseObject.create(View_vod__c.getSObjectType()).getAccessibleFields(new Set<String>{
        'Id', 'Name', 'OwnerId', 'Public_vod__c', 'Statement_vod__c', 'Address_Scope_vod__c', 'Ownership_Scope_vod__c',
        'Columns_vod__c', 'Criteria_vod__c', 'Source_vod__c'
    });

    private static Map<Schema.SObjectType, Schema.SObjectField> FIELD_FOR_OBJECT_FOR_LABEL = new Map<Schema.SObjectType, Schema.SObjectField>{
        Product_vod__c.getSObjectType() => Product_vod__c.Name
    };

    private static final String ALL_SCOPE = 'ALL';
    private static final String MINE_SCOPE = 'MINE';

    @AuraEnabled
    public boolean isPublic { get; private set; }

    @AuraEnabled
    public String baseQuery { get; private set; }

    @AuraEnabled
    public List<VeevaMyAccountsCriteria> criteria { get; private set; }

    @AuraEnabled
    public String addresses { get; private set; }

    @AuraEnabled
    public String owners { get; private set; }

    @AuraEnabled
    public String source { get; private set; }

    @AuraEnabled
    public boolean isViewOwner { get; private set; }

    public VeevaMyAccountsViewDefn(View_vod__c view) {
        this(view, new VeevaDynamicAttributeService());
    }

    public VeevaMyAccountsViewDefn(View_vod__c view, VeevaDynamicAttributeService dynamicAttributeService) {
        super(dynamicAttributeService);
        this.hasErrors = false;
        this.id = view.Id;
        this.name = view.Name;
        this.isPublic = ACCESSIBLE_VIEW_FIELDS.contains('Public_vod__c') ? view.Public_vod__c : null;
        this.baseQuery = ACCESSIBLE_VIEW_FIELDS.contains('Statement_vod__c') ? view.Statement_vod__c : null;
        this.source = ACCESSIBLE_VIEW_FIELDS.contains('Source_vod__c') ? getSource(view.Source_vod__c) : null;
        this.columns = ACCESSIBLE_VIEW_FIELDS.contains('Columns_vod__c') ? getColumns(view.Columns_vod__c, this.source) : new List<VeevaMyAccountsFieldDefn>();
        this.criteria = ACCESSIBLE_VIEW_FIELDS.contains('Criteria_vod__c') ? getCriteria(view.Criteria_vod__c, this.source) : new List<VeevaMyAccountsCriteria>();
        this.addresses = ACCESSIBLE_VIEW_FIELDS.contains('Address_Scope_vod__c') ? getAddressScope(view.Address_Scope_vod__c) : null;
        this.owners = ACCESSIBLE_VIEW_FIELDS.contains('Ownership_Scope_vod__c') ? getOwnershipScope(view.Ownership_Scope_vod__c) : null;
        this.source = ACCESSIBLE_VIEW_FIELDS.contains('Source_vod__c') ? getSource(view.Source_vod__c) : null;
        this.requiresTerritory = hasCriteriaWithTSF(this.source);
        this.isViewOwner = view.OwnerId == UserInfo.getUserId();
        this.type = VeevaMyAccountsViewItem.VIEW_TYPE;
        updateColumnLabels(getColumnLabels());
    }

    private List<VeevaMyAccountsCriteria> getCriteria(String criteriasString, String source) {
        List<VeevaMyAccountsCriteria> criteria = new List<VeevaMyAccountsCriteria>();
        if (String.isBlank(criteriasString)) {
            return criteria;
        }
        List<String> separatedCriterias = criteriasString.split(';;;');
        for (String criteriaString : separatedCriterias) {
            VeevaMyAccountsCriteria criterion = new VeevaMyAccountsCriteria(criteriaString, source);
            Boolean shouldFilter = updateOrFilterField(criterion.field);
            if (shouldFilter) {
                criterion.hasError = true;
            }
            criteria.add(criterion);         
            this.hasErrors = this.hasErrors || criterion.hasError;
        }
        return criteria;
    }

    private boolean hasCriteriaWithTSF(String source) {
        boolean hasCriteriaWithTSF = false;
        Schema.SObjectType tsfObject;
        if ('LOCATION'.equalsIgnoreCase(source)) {
            tsfObject = ChildAccount_TSF_vod__c.getSObjectType();
        } else {
            tsfObject = TSF_vod__c.getSObjectType();
        }

        for (VeevaMyAccountsCriteria criterion : criteria) {
            hasCriteriaWithTSF = tsfObject == criterion.field.objectType;
            if (hasCriteriaWithTSF) {
                break;
            }
        }
        return hasCriteriaWithTSF;
    }

    private static String getAddressScope(String scopeString) {
        return getScope(scopeString, null);
    }

    private static String getOwnershipScope(String scopeString) {
        return getScope(scopeString, null);
    }

    private static String getScope(String scopeString, String defaultValue) {
        String scope;
        if (ALL_SCOPE.equalsIgnoreCase(scopeString)) {
            scope = ALL_SCOPE;
        } else if (MINE_SCOPE.equalsIgnoreCase(scopeString)) {
            scope = MINE_SCOPE;
        } else {
            scope = defaultValue;
        }
        return scope;
    }

    private static String getSource(String sourceString) {
        if ('Account Location'.equalsIgnoreCase(sourceString)) {
            return 'LOCATION';
        } else {
            return 'ACCOUNT';
        }
    }

    private Map<Id, String> getColumnLabels() {
        // After getting the view definition we need to determine the appropriate field labels for the view's columns
        // We will take the column's reference ids (any id that the column definition references)
        Map<Schema.SObjectType, Set<Id>> referenceIdsByObjectType = getColumnReferenceIdsByObjectType();
        // We will query Dynamic Attributes using VeevaDynamicAttributeService so we will ignore these specific ids here
        referenceIdsByObjectType.remove(Dynamic_Attribute_Configuration_vod__c.getSObjectType());
        Map<Id, String> referenceIdLabels = new Map<Id, String>();
        for(Schema.SObjectType key : referenceIdsByObjectType.keySet()) {
            Set<Id> referenceIds = referenceIdsByObjectType.get(key);
            if (!referenceIds.isEmpty()) {
                // We will retrieve the appropriate label for our reference ids
                referenceIdLabels.putAll(getReferenceIdLabels(key, referenceIds));
            }
        }

        if (hasDynamicAttributes) {
            // We will add the dynamic attribute label map to the referenceIdLabels so we can pass the whole map to the View Definition
            Map<Id, String> dynamicAttributeLabelById = getDynamicAttributeLabelById(null);
            referenceIdLabels.putAll(dynamicAttributeLabelById);
        }        

        return referenceIdLabels;
    }

    private Map<Id, String> getReferenceIdLabels(Schema.SObjectType objectType, Set<Id> referenceIds) {
        // Each Object Type has a different field that is used as the reference id's label
        Schema.SObjectField fieldForLabel = FIELD_FOR_OBJECT_FOR_LABEL.get(objectType);
        // We will query all reference ids of the same object type and the field that is the label for the reference ids
        List<SObject> records = Database.query(
            String.format(
                'SELECT {0} FROM {1} WHERE Id IN :referenceIds',
                new List<String>{ fieldForLabel.getDescribe().getName(), objectType.getDescribe().getName() }
            )
        );
        // For each record from our query we will use the fieldForLabel as the label for a particular reference id
        Map<Id, String> referenceIdLabels = new Map<Id, String>();
        for (SObject record : records) {
            Object fieldValue = record.get(fieldForLabel);
            if (fieldValue != null) {
                referenceIdLabels.put(record.Id, fieldValue.toString());
            }
        }
        return referenceIdLabels;
    }
}