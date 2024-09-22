public inherited sharing class VeevaMyScheduleAccountsService {
    private static final Set<String> CYCLE_PLAN_FIELDS = new Set<String>{'Id', 'Name', 'Active_vod__c', 'Start_Date_vod__c', 'End_Date_vod__c', 'Territory_vod__c'};
    private static final Set<String> CYCLE_PLAN_TARGET_FIELDS = new Set<String>{'Cycle_Plan_Account_vod__c', 'Cycle_Plan_vod__c', 'Actual_Calls_vod__c', 'Planned_Calls_vod__c', 'Scheduled_Calls_vod__c', 'Attainment_vod__c', 'Remaining_vod__c', 'Remaining_Schedule_vod__c'};

    private VeevaMyAccountsService myAccountsService;
    private Id userId;

    public VeevaMyScheduleAccountsService() {
        this.myAccountsService = new VeevaMyAccountsService();
        this.userId = UserInfo.getUserId();
    }

    public List<VeevaMyAccountsTerritory> getUserTerritories() {
        return VeevaMyAccountsController.getUserTerritories();
    }

    public List<VeevaMyAccountsViewItem> getViews() {
        return this.myAccountsService.getViews();
    }

    public VeevaMyAccountsBaseView getViewDefinition(Id viewIdOrListId) {
        return this.myAccountsService.getViewDefinition(viewIdOrListId);
    }

    public List<Cycle_Plan_vod__c> getCyclePlans() {
        if (!hasRequiredCyclePlanPermissions()) {
            return new List<Cycle_Plan_vod__c>();
        }
        List<Map<String, String>> userTerritoryHierarchy = VeevaTerritoryController.getUserTerritoryHierarchy(UserInfo.getUserId());
        List<String> territoryNames = new List<String>();

        for (Map<String, String> territory : userTerritoryHierarchy) {
            territoryNames.add(territory.get('Name'));
        }
        List<Cycle_Plan_vod__c> cyclePlans = [SELECT Id, Name, Active_vod__c, Start_Date_vod__c, End_Date_vod__c FROM Cycle_Plan_vod__c WHERE Active_vod__c = true AND (Territory_vod__c IN :territoryNames OR OwnerId = :userId) ORDER BY Name, Start_Date_vod__c DESC];

        return cyclePlans;
    }

    public List<Cycle_Plan_Target_vod__c> getCyclePlanTargets(Id cyclePlanId) {
        VeevaBaseObject cyclePlanTargetObj = VeevaBaseObject.create(Cycle_Plan_Target_vod__c.getSObjectType());
        Set<String> accessibleCyclePlanTargetFields = cyclePlanTargetObj?.getAccessibleFields(CYCLE_PLAN_TARGET_FIELDS);

        if (accessibleCyclePlanTargetFields?.size() != CYCLE_PLAN_TARGET_FIELDS.size()) {
            return new List<Cycle_Plan_Target_vod__c>(); // all cycle plan target fields are required
        }
        return [SELECT Cycle_Plan_Account_vod__r.RecordType.DeveloperName, Cycle_Plan_Account_vod__r.IsPersonAccount, Cycle_Plan_Account_vod__r.Formatted_Name_vod__c, Cycle_Plan_Account_vod__r.Account_Identifier_vod__c, Cycle_Plan_Account_vod__r.Medical_Identifier_vod__c, Actual_Calls_vod__c, Planned_Calls_vod__c, Scheduled_Calls_vod__c, Attainment_vod__c, Remaining_vod__c, Remaining_Schedule_vod__c FROM Cycle_Plan_Target_vod__c WHERE Cycle_Plan_vod__r.Id = :cyclePlanId AND Cycle_Plan_Account_vod__r.Formatted_Name_vod__c != null];
    }

    private static Boolean hasRequiredCyclePlanPermissions() {
        VeevaBaseObject cyclePlanObj = VeevaBaseObject.create(Cycle_Plan_vod__c.getSObjectType());
        VeevaBaseObject cyclePlanTargetObj = VeevaBaseObject.create(Cycle_Plan_Target_vod__c.getSObjectType());

        Set<String> accessibleCyclePlanFields = cyclePlanObj?.getAccessibleFields(CYCLE_PLAN_FIELDS);

        return cyclePlanObj != null && cyclePlanObj.getDescribe().isQueryable() && cyclePlanTargetObj != null && cyclePlanTargetObj.getDescribe().isQueryable()
            && accessibleCyclePlanFields?.size() == CYCLE_PLAN_FIELDS.size();
    }

}