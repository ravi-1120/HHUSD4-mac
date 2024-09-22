public without sharing class StakeholderNavigatorController {

    @AuraEnabled
    public static VeevaSNInitData initializeGraph(Id rootId) {
        ID accountId = VeevaSNQueryService.getAccountIdOfAccountPlan(rootId);
        VeevaSNInitData initData;
        if (accountId == null) {
            initData = getInitialData(rootId, null);
        } else {
            initData = getInitialData(accountId, rootId);
        }
        return initData;
    }

    @AuraEnabled
    public static VeevaSNHierarchyResult loadInitialHierarchy(Id rootId){
        return getHierarchy(new Set<Id>{rootId}, true);
    }

    @AuraEnabled
    public static VeevaSNHierarchyResult loadHierarchy(List<Id> ids){
        return getHierarchy(new Set<Id>(ids), false);
    }

    @AuraEnabled
    public static VeevaSNHierarchyResult loadParentHierarchy(Id childId){
        return getParentHierarchy(childId);
    }

    @AuraEnabled
    public static VeevaSNAccountBatch loadAccountBatch(String batchId, List<String> accountIds, List<String> accountFields, List<String> affiliationFields) {
        return VeevaSNAccountBatchService.getAccountBatchResponse(batchId, accountIds, accountFields, affiliationFields);
    }

    @AuraEnabled
    public static VeevaGASTerritoryAssignmentResult addToTerritory(Id accountId, List<String> terrsToAdd) {
        return addToTerr(accountId, terrsToAdd);
    }

    @AuraEnabled
    public static VeevaSNRelatedObjectResponse loadAccountRelatedObjectFields(VeevaSNRelatedObjectRequest relatedObjectRequest) {
        return VeevaSNRelatedObjectService.getRelatedObjectResponse(relatedObjectRequest);
    }

    @AuraEnabled
    public static VeevaSNOOHAccountResponse loadOOHAccounts(VeevaSNOOHAccountRequest outOfHierarchyAccountRequest) {
        return VeevaSNOOHAccountService.getOOHAccountResponse(outOfHierarchyAccountRequest);
    }

    @AuraEnabled
    public static VeevaSNAffiliationViewDataInitRequest getRootAccountDataWithRelatedAffiliationIds(String rootAccountId, List<String> accountFields) {
        return VeevaSNAffiliationViewDataService.getRootAccountDataWithRelatedAffiliationIds(rootAccountId, accountFields);
    }

    @AuraEnabled
    public static List<VeevaSNAffiliation> getRootAccountsAffiliationData(List<String> affiliationIdChunk, List<String> accountFields, List<String> affiliationFields) {
        return VeevaSNAffiliationViewDataService.getRootAccountsAffiliationData(affiliationIdChunk, accountFields, affiliationFields);
    }

    @AuraEnabled
    public static Map<String, Object> queryAccountDataWithRelatedAffiliationData(String accountId, List<String> accountFields) {
        return VeevaSNAffiliationViewDataService.queryAccountDataWithRelatedAffiliationData(accountId, accountFields);
    }

    @AuraEnabled
    public static String checkPermissions(Id id) {
        return getPermissionErrorString(id);
    }

    private static VeevaSNInitData getInitialData(Id graphRootId, Id accountPlanId) {
        Map<String, String> veevaMessages = VeevaSNQueryService.getStakeholderNavigatorVeevaMessages();
        List<Id> keyStakeholders = null;
        if (accountPlanId != null && hasKeyStakeholderPermission()) {
            keyStakeholders = VeevaSNQueryService.getKeyStakeholders(accountPlanId);
        } else {
            keyStakeholders = new List<Id>();
        }
        List<Map<String, String>> userTerritories = getUserTerritories();
        VeevaSNCustomDisplayOverrides displayFieldOverrides = VeevaSNCustomDisplayService.getDisplayFieldOverrides();
        Boolean hasAccessToAffiliations = checkMinimumAffiliationAccess();
        Boolean enableAffiliationView = hasAccessToAffiliations && checkMinimumAffiliationViewAccess();
        return new VeevaSNInitData(graphRootId, keyStakeholders, veevaMessages, userTerritories, displayFieldOverrides, hasAccessToAffiliations, enableAffiliationView);
    }

    private static VeevaSNHierarchyResult getHierarchy(Set<Id> ids, Boolean isInitialHierarchy) {
        //Salesforce governer limit is 50000 query records per transaction.  
        //The initial query to getParentId has in indeterminate number of queries records based on number of parents
        //Thus, 50 queries records is subtracted from the 50000 limit to be safe
        Integer queryLimit = 49950;
        Boolean hasUnloadedParent = false;

        if (isInitialHierarchy && ids.size() == 1 && getParentId(new List<Id>(ids)[0]) != null) {
            hasUnloadedParent = true;
        }

        VeevaSNHierarchyResult firstLevel = getChildrenHierarchy(ids, queryLimit, true);
        Set<Id> firstLevelIds = new Set<Id>();
        for (Id acctId : ids) {
            Set<Id> children = firstLevel.hierarchy.get(acctId);
            if (children != null) {
                firstLevelIds.addAll(children);
            }
        }
        if (firstLevel.queryLimitTriggered || firstLevelIds == null || !isInitialHierarchy ) {
            firstLevel.setRootHasUnloadedParent(hasUnloadedParent);
            return firstLevel;
        }
        queryLimit = queryLimit - firstLevel.queryResultCount;

        VeevaSNHierarchyResult secondLevel = getChildrenHierarchy(firstLevelIds, queryLimit, false);
        if (secondLevel.queryLimitTriggered || firstLevelIds.size() > 499) {
            VeevaSNHierarchyResult mergedHierarchy = mergeHierarchies(new VeevaSNHierarchyResult[]{firstLevel, secondLevel}, 1);
            mergedHierarchy.setRootHasUnloadedParent(hasUnloadedParent);
            return mergedHierarchy;
        }
        queryLimit = queryLimit - secondLevel.queryResultCount;
        Set<Id> secondLevelIds = new Set<Id>();
        for (Id acctId : firstLevelIds) {
            Set<Id> children = secondLevel.hierarchy.get(acctId);
            if (children != null) {
                secondLevelIds.addAll(children);
            }
        }

        VeevaSNHierarchyResult thirdLevel = getChildrenHierarchy(secondLevelIds, queryLimit, false);
        VeevaSNHierarchyResult finalHierarchy = mergeHierarchies(new VeevaSNHierarchyResult[]{firstLevel, secondLevel, thirdLevel}, 2);
        finalHierarchy.setRootHasUnloadedParent(hasUnloadedParent);
        return finalHierarchy;
    }

    private static VeevaSNHierarchyResult getParentHierarchy(Id childId) {
        Integer queryLimit = 49950;
        Id rootId = getParentId(childId);
        Boolean newRootHasParent = hasParent(rootId);

        VeevaSNHierarchyResult firstLevel = getChildrenHierarchy(new Set<Id>{rootId}, queryLimit, true);
        Set<Id> firstLevelIds = new Set<Id>();
        Set<Id> children = firstLevel.hierarchy.get(rootId);
        if (children != null) {
            firstLevelIds.addAll(children);
        }
        Boolean containsRootChild = firstLevelIds.contains(childId);
        if (firstLevel.queryLimitTriggered || firstLevelIds == null) {
            //check to ensure the childId was included in the children list
            if (!containsRootChild && children != null) {
                children.add(childId);
            }
            firstLevel.setNewRoot(rootId);
            firstLevel.setRootHasUnloadedParent(newRootHasParent);
            return firstLevel;
        }

        if (containsRootChild) {
            firstLevelIds.remove(childId);
        }

        queryLimit = queryLimit - firstLevel.queryResultCount;
        VeevaSNHierarchyResult secondLevel = getChildrenHierarchy(firstLevelIds, queryLimit, false);
        VeevaSNHierarchyResult mergedHierarchy = mergeHierarchies(new VeevaSNHierarchyResult[]{firstLevel, secondLevel}, 1);
        mergedHierarchy.setNewRoot(rootId);
        mergedHierarchy.setRootHasUnloadedParent(newRootHasParent);
        return mergedHierarchy;
    }

    private static VeevaSNHierarchyResult mergeHierarchies(List<VeevaSNHierarchyResult> hierarchyResults, Integer depth) {
        Map<Id, Set<Id>> mergedHierarchy = new Map<Id, Set<Id>>();
        Set<Id> rootAccounts = new Set<Id>();
        Integer mergedQueryResultCount = 0;
        Boolean mergedQueryLimitTriggered = false;
        for (Integer i = 0; i < hierarchyResults.size(); i++) {
            VeevaSNHierarchyResult hierarchyResult = hierarchyResults.get(i);
            if (i == 0) {
                rootAccounts = hierarchyResult.rootAccounts;
            }
            mergedHierarchy.putAll(hierarchyResult.hierarchy);
            mergedQueryResultCount += hierarchyResult.queryResultCount;
            mergedQueryLimitTriggered = mergedQueryLimitTriggered || hierarchyResult.queryLimitTriggered;
        }
        return new VeevaSNHierarchyResult(mergedHierarchy, rootAccounts, mergedQueryResultCount, mergedQueryLimitTriggered, depth);
    }

    public static VeevaSNHierarchyResult getChildrenHierarchy(Set<Id> parentIds, Integer queryLimit, Boolean limitFirstQuery){
        Integer queryCounter = 0;
        Map<Id, Set<Id>> hierarchy = new Map<Id, Set<Id>>();
        List<Id> childrenToVerify = new List<Id>();
        Integer firstQueryLimit = queryLimit;
        if (limitFirstQuery && queryLimit > 20000) {
            firstQueryLimit = 20000;
        }
        for (Child_Account_vod__c child : [
            SELECT Parent_Account_vod__c, Child_Account_vod__c, Primary_vod__c, Parent_Account_vod__r.Formatted_Name_vod__c,
                Child_Account_vod__r.RecordType.IsPersonType, Child_Account_vod__r.Primary_Parent_vod__c
            FROM Child_Account_vod__c 
            WHERE Parent_Account_vod__c in :parentIds
            LIMIT :firstQueryLimit
        ]) {
            queryCounter++;
            if (child.Child_Account_vod__r.Primary_Parent_vod__c == child.Parent_Account_vod__c || child.Child_Account_vod__r.RecordType.IsPersonType) {
                //if primary then no need to check if there exists a "better" parent
                if (!hierarchy.containsKey(child.Parent_Account_vod__c)) {
                    hierarchy.put(child.Parent_Account_vod__c, new Set<Id>());
                }
                hierarchy.get(child.Parent_Account_vod__c).add(child.Child_Account_vod__c);
            } else {
                childrenToVerify.add(child.Child_Account_vod__c);
            }
        }
        
        Boolean firstQueryCapHit = queryCounter == firstQueryLimit;

        //if non-primary, all Child_Account records need to be checked for multiple parents and the best one chosen
        Map<Id, Child_Account_vod__c> childToParentMap = new Map<Id, Child_Account_vod__c>();

        Integer newLimit = queryLimit - queryCounter;
        for (Child_Account_vod__c child : [
            SELECT Parent_Account_vod__c, Child_Account_vod__c, Primary_vod__c, Parent_Account_vod__r.Formatted_Name_vod__c, Child_Account_vod__r.Primary_Parent_vod__c
            FROM Child_Account_vod__c 
            WHERE Child_Account_vod__c in :childrenToVerify
            LIMIT :newLimit
        ]) {
            queryCounter++;
            Id childId = child.Child_Account_vod__c;
            if (isValidChildAccountRecord(child)) {
                Child_Account_vod__c oldChild = childToParentMap.get(childId);
                if (isBetterChildAcct(oldChild, child)) {
                    childToParentMap.put(childId, child);
                }
            }
        }

        //go through non-primary "winners" and add them to hierarchy
        for (Child_Account_vod__c child : childToParentMap.values()) {
            if (parentIds.contains(child.Parent_Account_vod__c)) {
                if (!hierarchy.containsKey(child.Parent_Account_vod__c)) {
                     hierarchy.put(child.Parent_Account_vod__c, new Set<Id>());
                }
                hierarchy.get(child.Parent_Account_vod__c).add(child.Child_Account_vod__c);
            }
        }

        return new VeevaSNHierarchyResult(hierarchy, parentIds, queryCounter, queryCounter == queryLimit || firstQueryCapHit, 1);
    }

    private static List<Map<String, String>> getUserTerritories() {
        List<Map<String, String>> userTerrList = new List<Map<String, String>>();
        TerritoryManagement tm = TerritoryManagementFactory.getInstance();
        Set<Id> userTerrs = tm.getUserTerritories(UserInfo.getUserId());
        Map<Id, Map<String, String>> territories = tm.getTerritories(userTerrs);
        for (Id terrId : territories.keySet()) {
            userTerrList.add(territories.get(terrId));
        }
        return userTerrList;
    }

    private static Boolean hasParent(Id id) {
        ID parentId = getParentId(id);
        return parentId != null;
    }

    private static Boolean isValidChildAccountRecord(Child_Account_vod__c child) {
        return child.Parent_Account_vod__c != null &&
               child.Child_Account_vod__c != null &&
               String.isNotBlank(child.Parent_Account_vod__r.Formatted_Name_vod__c);
    }

    private static Id getParentId(Id id) {
        List<Child_Account_vod__c> allRelationships = VeevaSNQueryService.getParentChildRelationshipsFromChild(new List<Id>{id});
        Child_Account_vod__c winner = null;
        for (Child_Account_vod__c childAcct : allRelationships) {
            if (isValidChildAccountRecord(childAcct) && isBetterChildAcct(winner, childAcct)) {
                winner = childAcct;
            }
        }
        return winner != null ? winner.Parent_Account_vod__c : null;
    }

    @TestVisible
    private static Boolean isBetterChildAcct(Child_Account_vod__c oldChild, Child_Account_vod__c newChild) {
        return (
            oldChild == null || 
            newChild.Parent_Account_vod__c == newChild.Child_Account_vod__r.Primary_Parent_vod__c ||
            (oldChild.Parent_Account_vod__c != oldChild.Child_Account_vod__r.Primary_Parent_vod__c && 
                newChild.Parent_Account_vod__r.Formatted_Name_vod__c.compareTo(oldChild.Parent_Account_vod__r.Formatted_Name_vod__c) < 0)
        );
    }

    private static String getPermissionErrorString(Id id) {
        //first check if user has access to root account of stakeholder navigator
        Id accountId = VeevaSNQueryService.getAccountIdOfAccountPlan(id);
        if (accountId == null) {
            accountId = id;
        }
        if (!VeevaSNQueryService.hasAccountAccess(accountId)) {
            String defaultString = 'Stakeholder Navigator cannot open because you do not have access to this Account.';
            String vm = VeevaSNQueryService.getSNVeevaMessageWithDefault('NO_ACCOUNT_ACCESS', defaultString);
            return vm;
        }

        //then check that object and field permission
        List<String> objectsWithoutPermission = getObjectsWithoutPermissions();
        List<String> fieldsWithoutPermission = getFieldsWithoutPermissions();

        if (objectsWithoutPermission.size() > 0 || fieldsWithoutPermission.size() > 0) {
            String defaultString = 'Stakeholder Navigator cannot open because you do not have access to the following:\nObjects: {0}\nObject Fields: {1}';
            String vm = VeevaSNQueryService.getSNVeevaMessageWithDefault('NO_FLS_ACCESS', defaultString);
            vm = vm.replace('{0}', String.join(objectsWithoutPermission, ', '));
            vm = vm.replace('{1}', String.join(fieldsWithoutPermission, ', '));
            return vm;
        }

        return '';
    }

    private static List<String> getObjectsWithoutPermissions() {
        List<String> objectsWithoutPermission = new List<String>();
        DescribeSobjectResult accountObj = Account.sObjectType.getDescribe();
        DescribeSobjectResult childAccountObj = Child_Account_vod__c.sObjectType.getDescribe();
        if (!accountObj.isQueryable() || !accountObj.isAccessible()) {
            objectsWithoutPermission.add(accountObj.getName());
        }
        if (!childAccountObj.isQueryable() || !childAccountObj.isAccessible()) {
            objectsWithoutPermission.add(childAccountObj.getName());
        }
        return objectsWithoutPermission;
    }

    private static List<String> getFieldsWithoutPermissions() {
        List<String> fieldsWithoutPermission = new List<String>();
        List<String> accountFields = new List<String>{'Id', 'Formatted_Name_vod__c'};
        List<String> childAccountFields = new List<String>{'Id', 'Child_Account_vod__c', 'Parent_Account_vod__c', 'Primary_vod__c'};

        fieldsWithoutPermission.addAll(checkObjectFieldPermissions(Account.sObjectType.getDescribe(), accountFields));
        fieldsWithoutPermission.addAll(checkObjectFieldPermissions(Child_Account_vod__c.sObjectType.getDescribe(), childAccountFields));

        return fieldsWithoutPermission;
    }

    private static List<String> checkObjectFieldPermissions(DescribeSObjectResult obj, List<String> fields) {
        List<String> fieldsWithoutPermission = new List<String>();
        String objectlabel = obj.getName();
        Map<String, SObjectField> objectFields = obj.fields.getMap();
        for (String field : fields) {
            SObjectField objectField = objectFields.get(field);
            if (objectField == null) {
                //field doesn't exist in org or user does not have visibility
                fieldsWithoutPermission.add(objectLabel + '.' + field);
                continue;
            }
            DescribeFieldResult fieldResult = objectField.getDescribe();
            if (!fieldResult.isAccessible()) {
                fieldsWithoutPermission.add(objectLabel + '.' + fieldResult.getName());
            }
        }
        return fieldsWithoutPermission;
    }

    private static Boolean hasKeyStakeholderPermission() {
        DescribeSobjectResult keyStakeholderObj = Key_Stakeholder_vod__c.sObjectType.getDescribe();
        if (keyStakeholderObj != null && keyStakeholderObj.isQueryable() && keyStakeholderObj.isAccessible()) {
            DescribeFieldResult accountPlanField = Key_Stakeholder_vod__c.Account_Plan_vod__c.getDescribe();
            if (accountPlanField != null && accountPlanField.isAccessible()) {
                return true;
            }
        }
        return false;
    }

    private static VeevaGASTerritoryAssignmentResult addToTerr(Id accountId, List<String> terrsToAdd) {
        VeevaGASTerritoryAssignmentResult result;
        try {
            VeevaGASAccountManagement gasAccountManagement = new VeevaGASAccountManagement();
            result = gasAccountManagement.assignAccountsToTerritories(new List<String>{String.valueOf(accountId)}, terrsToAdd, 'CRM_Online_vod', 'Stakeholder_Navigator_vod');
        } catch (Exception e) {
            result = new VeevaGASTerritoryAssignmentResult(false, e.getMessage());
        }
        return result;
    }

    private static Boolean checkMinimumAffiliationAccess() {
        VeevaBaseObject affiliationBaseObject = VeevaBaseObject.create('Affiliation_vod__c');
        if (affiliationBaseObject == null) {
            return false;
        }
        String fromAccountField = affiliationBaseObject.getAccessibleField('From_Account_vod__c', false, false);
        String toAccountField = affiliationBaseObject.getAccessibleField('To_Account_vod__c', false, false);
        if (fromAccountField == null || toAccountField == null) {
            return false;
        }
        return true;
    }

    private static Boolean checkMinimumAffiliationViewAccess() {
        return VeevaBaseObject.create('Affiliation_vod__c')?.getAccessibleField('Child_affiliation_vod__c', false, false) != null;
    }
}