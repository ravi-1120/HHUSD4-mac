public inherited sharing virtual class VeevaMyAccountsService {
    private static Set<String> VIEW_ITEM_FIELDS = new Set<String>{
        'Id', 'Name', 'OwnerId', 'Public_vod__c', 'Profile_vod__c', 'Type_vod__c', 'Source_vod__c'
    };

    private static Set<String> ACCOUNT_LIST_REQUIRED_FIELDS = new Set<String>{
        'Id', 'Name', 'Icon_Name_vod__c', 'LastModifiedDate'
    };

    private static Set<String> ACCOUNT_LIST_ITEM_REQUIRED_FIELDS = new Set<String>{
        'Id', 'Account_vod__c'
    };

    private static Set<String> VIEW_FIELDS = new Set<String>{
        'Id', 'Name', 'OwnerId', 'Public_vod__c', 'Statement_vod__c', 'Address_Scope_vod__c', 'Ownership_Scope_vod__c',
        'Columns_vod__c', 'Criteria_vod__c', 'Source_vod__c', 'Profile_vod__c', 'Type_vod__c'
    };

    private static String DEFAULT_ACCOUNT_LIST_COLUMNS = 'Account.Name,Address_vod__c.Name,Address_vod__c.City_vod__c';

    public static final String ACCOUNT_LIST_COLS = 'ACCOUNT_LIST_COLS_vod__c';

    private static final Integer LIST_MAX_COLUMN_LENGTH = 19;

    private final Id userId;
    private final Id profileId;
    private final VeevaBaseObject viewBaseObject;
    private final VeevaBaseObject accountListBaseObject;
    private final VeevaBaseObject accountListItemBaseObject;
    private final VeevaDynamicAttributeService dynamicAttributeService;

    public VeevaMyAccountsService() {
        this(new VeevaDynamicAttributeService());
    }

    public VeevaMyAccountsService(VeevaDynamicAttributeService dynamicAttributeService) {
        this.userId = UserInfo.getUserId();
        this.profileId = UserInfo.getProfileId();
        this.viewBaseObject = VeevaBaseObject.create(View_vod__c.getSObjectType());
        this.accountListBaseObject = VeevaBaseObject.create(Account_List_vod__c.getSObjectType());
        this.accountListItemBaseObject = VeevaBaseObject.create(Account_List_Item_vod__c.getSObjectType());
        this.dynamicAttributeService = dynamicAttributeService;
    }

    public List<VeevaMyAccountsViewItem> getViews() {
        List<View_vod__c> accessibleViews = getAccessibleViews();
        List<VeevaMyAccountsViewItem> viewItems = new List<VeevaMyAccountsViewItem>();
        for (View_vod__c view : accessibleViews) {
            viewItems.add(new VeevaMyAccountsViewItem(view));
        }
        List<Account_List_vod__c> accessibleAccountLists = getAccessibleAccountLists();
        for (Account_List_vod__c accountList : accessibleAccountLists) {
            viewItems.add(new VeevaMyAccountsViewItem(accountList));
        }
        return viewItems;
    }

    public VeevaMyAccountsBaseView getViewDefinition(Id viewIdOrListId) {
        return getViewDefinition(viewIdOrListId, true);
    }

    public VeevaMyAccountsBaseView getViewDefinition(Id viewIdOrListId, boolean checkAccessible) {
        if (viewIdOrListId.getSObjectType() == View_vod__c.getSObjectType()) {
            return getViewDefinitionFromView(viewIdOrListId, checkAccessible);
        } else if (viewIdOrListId.getSObjectType() == Account_List_vod__c.getSObjectType()) {
            return getListDefinition(viewIdOrListId);
        } else {
            return null;
        }
    }

    public VeevaMyAccountsBaseView createDefaultView() {
        Set<String> viewUpdateableFields = new Set<String>{
            'Name', 'Public_vod__c', 'Statement_vod__c', 'Address_Scope_vod__c', 'Columns_vod__c',
            'Criteria_vod__c', 'Profile_vod__c', 'Type_vod__c'
        };
        if (!canCreateView() || !canUpdateFields(viewBaseObject, viewUpdateableFields)) {
            return null;
        }
        String defaultMyAccontsViewName = VeevaMessageController.getMsgWithDefault('MY_ACCOUNTS', 'MyAccounts', 'My Accounts');
        View_vod__c defaultView = new View_vod__c(
            Name=defaultMyAccontsViewName,
            Address_Scope_vod__c='mine',
            Columns_vod__c='Account.Name',
            Statement_vod__c='Select Id,Formatted_Name_vod__c From Account',
            Public_vod__c=false,
            Source_vod__c='Account',
            Type_vod__c='MyAccounts',
            Criteria_vod__c=null,
            Ownership_Scope_vod__c=null,
            Profile_vod__c=null
        );
        insert defaultView;
        return new VeevaMyAccountsViewDefn(defaultView, dynamicAttributeService);
    }

    private VeevaMyAccountsViewDefn getViewDefinitionFromView(Id viewId, boolean checkAccessible) {
        List<View_vod__c> views = Database.query(String.format(
            'SELECT {0} FROM View_vod__c WHERE Id = :viewId',
            new List<String>{String.join(new List<String>(VIEW_FIELDS), ',')}
        ));
        // Check to see if the view exists for viewId
        if (views.isEmpty()) {
            return null;
        }
        View_vod__c view = views.get(0);
        // If we are performing an accessibility check then we will check to see that the view we provided is returned
        if (checkAccessible && getAccessibleViews(new List<View_vod__c>{view}).isEmpty()) {
            return null;
        }

        return new VeevaMyAccountsViewDefn(view, dynamicAttributeService);
    }

    private VeevaMyAccountsListDefn getListDefinition(Id listId) {
        if (!canQueryAccountLists() || !canQueryAccountListItems()) {
            return null;
        }
        List<Account_List_vod__c> accountLists = Database.query(String.format(
            'SELECT {0}, (SELECT {1} FROM Mapped_Accounts_vod__r) FROM Account_List_vod__c WHERE Id = :listId AND OwnerId = :userId',
            new List<String>{
                String.join(new List<String>(ACCOUNT_LIST_REQUIRED_FIELDS), ','),
                String.join(new List<String>(ACCOUNT_LIST_ITEM_REQUIRED_FIELDS), ',')
            }
        ));
        if (accountLists.isEmpty()) {
            return null;
        }

        Account_List_vod__c accountList = accountLists.get(0);
        List<Account_List_Item_vod__c> listItems = getAccessibleAccountListItems(accountList.getSObjects('Mapped_Accounts_vod__r'));

        Object accountListCols = VeevaCustomSettingsService.getVeevaSettings(new List<String> {ACCOUNT_LIST_COLS}).get(ACCOUNT_LIST_COLS);
        String baseAccountListColumns = String.valueOf(accountListCols); 
        if(String.isBlank(baseAccountListColumns)) {
            baseAccountListColumns = DEFAULT_ACCOUNT_LIST_COLUMNS;
        }
        
        Integer baseAccountListColumnCount = baseAccountListColumns.split(',').size();

        return new VeevaMyAccountsListDefn(accountList, listItems, baseAccountListColumns, dynamicAttributeService, LIST_MAX_COLUMN_LENGTH - baseAccountListColumnCount);
    }

    private List<Account_List_vod__c> getAccessibleAccountLists() {
        if (!canQueryAccountLists() || !canQueryAccountListItems()) {
            return new List<Account_List_vod__c>();
        }
        return Database.query(String.format(
            'SELECT {0} FROM Account_List_vod__c WHERE OwnerId = :userId ORDER BY Name',
            new List<String>{String.join(new List<String>(ACCOUNT_LIST_REQUIRED_FIELDS), ',')}
        ));
    }

    private List<Account_List_Item_vod__c> getAccessibleAccountListItems(List<Account_List_Item_vod__c> accountListItemsToCheck) {
        if (accountListItemsToCheck == null) {
            return new List<Account_List_Item_vod__c>();
        }

        Map<Id, Account_List_Item_vod__c> accountIdsForAccountListItems = new Map<Id, Account_List_Item_vod__c>();
        for (Account_List_Item_vod__c listItem : accountListItemsToCheck) {
            if (listItem.Account_vod__c != null) {
                accountIdsForAccountListItems.put(listItem.Account_vod__c, listItem);
            }
        }

        Set<Id> accountIdsToCheck = accountIdsForAccountListItems.keySet();
        List<Account> accountsAccessibleToUser = [SELECT Id FROM Account WHERE Id IN :accountIdsToCheck];
        Set<Id> accessibleAccountIds = new Map<Id, Account>(accountsAccessibleToUser).keySet();

        List<Account_List_Item_vod__c> accountListItemsWithAccessibleAccounts = new List<Account_List_Item_vod__c>();
        for(Id accessibleAccountId : accessibleAccountIds) {
            Account_List_Item_vod__c accountListItem = accountIdsForAccountListItems.get(accessibleAccountId);
            // Performing a null check, however this value should not be null since we are only querying records that are from the map
            if (accountListItem != null) {
                accountListItemsWithAccessibleAccounts.add(accountListItem);
            }
        }
        return accountListItemsWithAccessibleAccounts; 
    }

    private Set<Id> getIds(List<VeevaMyAccountsFieldDefn> fields) {
        Set<Id> ids = new Set<Id>();
        for (VeevaMyAccountsFieldDefn field : fields) {
            ids.addAll(field.getReferenceIds());
        }
        return ids;
    }

    private List<View_vod__c> getAccessibleViews() {
        Set<String> accessibleViewFields = viewBaseObject.getAccessibleFields(VIEW_ITEM_FIELDS);
        String viewsQuery = String.format(
            'SELECT {0} FROM View_vod__c {1} ORDER BY Name ',
            new List<String>{String.join(new List<String>(accessibleViewFields), ','), getWhereClause(accessibleViewFields)}
        );
        List<View_vod__c> views = Database.query(viewsQuery);
        return getAccessibleViews(views);
    }

    private List<View_vod__c> getAccessibleViews(List<View_vod__c> views) {
        Profile userProfile = [SELECT Id, PermissionsViewSetup FROM Profile WHERE Id = :profileId];
        boolean canManageViewSetup = canManageViewSetup(userProfile);
        boolean hasProfileFieldAccess = doesUserHaveProfileFieldAccess();

        List<View_vod__c> accessibleViews = new List<View_vod__c>();
        for (View_vod__c view : views) {
            // Check if User is the Owner of the View, otherwise we must check to see if the user has access to this particular Public View
            if (view.OwnerId != userId && view.Public_vod__c && doesNotHaveAccessToView(view, canManageViewSetup, hasProfileFieldAccess)) {
                continue;
            } else if (view.OwnerId != userId && !view.Public_vod__c) {
                // User is not Owner of View and View is not Public
                continue;
            }
            accessibleViews.add(view);
        }
        return accessibleViews;
    }

    private String getWhereClause(Set<String> accessibleViewFields) {
        if (!accessibleViewFields.containsAll(new List<String>{'Type_vod__c', 'Public_vod__c'})) {
            throw new InvalidViewFLSException('User is missing FLS to Type_vod__c or Public_vod__c');
        }
        return 'WHERE Type_vod__c = \'MyAccounts\' AND (Public_vod__c = true OR OwnerId = :userId)';
    }

    private boolean doesNotHaveAccessToView(View_vod__c view, boolean canManageViewSetup, boolean hasProfileFieldAccess) {
        /*
            A user does not have access to a view if:
              - the user's profile does not have View Setup Access (admin profile)
              - the user's profile has access to Profile_vod__c for View_vod__c and the view has Profiles defined
                and the user's profile or owner id do not match the View
         */
        return !canManageViewSetup
                 && hasProfileFieldAccess && view.Profile_vod__c != null
                 && !view.Profile_vod__c.contains(profileId) && !view.OwnerId.equals(userId);
    }

    protected virtual boolean canManageViewSetup(Profile userProfile) {
        return userProfile.PermissionsViewSetup;
    }

    protected virtual boolean doesUserHaveProfileFieldAccess() {
        return !viewBaseObject.getAccessibleFields(new Set<String>{'Profile_vod__c'}).isEmpty();
    }

    protected virtual boolean canQueryAccountLists() {
        Set<String> accountListAccessibleFields = accountListBaseObject?.getAccessibleFields(ACCOUNT_LIST_REQUIRED_FIELDS);
        return accountListBaseObject != null
                && accountListBaseObject.getDescribe().isQueryable()
                && accountListAccessibleFields?.size() == ACCOUNT_LIST_REQUIRED_FIELDS.size();
    }

    protected virtual boolean canQueryAccountListItems() {
        Set<String> accountListItemAccessibleFields = accountListItemBaseObject?.getAccessibleFields(ACCOUNT_LIST_ITEM_REQUIRED_FIELDS);
        return accountListItemBaseObject.getDescribe().isQueryable() && accountListItemAccessibleFields?.size() == ACCOUNT_LIST_ITEM_REQUIRED_FIELDS.size();
    }

    protected virtual boolean canCreateView() {
        return viewBaseObject.getDescribe().isCreateable();
    }

    protected virtual boolean canUpdateFields(VeevaBaseObject baseObject, Set<String> updateableFields) {
        boolean canUpdateFields = true;
        for (String updateableField : updateableFields) {
            Schema.SObjectField field = viewBaseObject.getField(updateableField);
            canUpdateFields = field != null && field.getDescribe().isUpdateable();
            if (!canUpdateFields) {
                break;
            }
        }
        return canUpdateFields;
    }

    private class InvalidViewFLSException extends Exception {}
}