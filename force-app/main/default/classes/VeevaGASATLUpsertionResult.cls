public inherited sharing class VeevaGASATLUpsertionResult {

    private List<String> expectedTerritoryIds;
    private Map<Id, Territory2> territoryMap;
    private Map<String, Set<String>> afterAssignmentAccountToTerritoryIdMap;

    public VeevaGASATLUpsertionResult(List<String> expectedTerritoryIds, List<Territory2> territories, Map<String, Set<String>> afterAssignmentAccountToTerritoryIdMap) {
        this.expectedTerritoryIds = expectedTerritoryIds;
        this.afterAssignmentAccountToTerritoryIdMap = afterAssignmentAccountToTerritoryIdMap;

        this.territoryMap = new Map<Id, Territory2>();
        for (Territory2 territory : territories) {
            this.territoryMap.put(territory.Id, territory);
        }
    }

    public Map<String, List<String>> findSuccessAssignments() {
        Map<String, List<String>> successAssignmentsAccountToTerritoryNameMap = new Map<String, List<String>>();

        for (String accountId : afterAssignmentAccountToTerritoryIdMap.keySet()) {
            for (String expectedTerritoryId : expectedTerritoryIds) {
                if (afterAssignmentAccountToTerritoryIdMap.get(accountId).contains(expectedTerritoryId)) {
                    String territoryName = territoryMap.get(expectedTerritoryId)?.Name;
                    List<String> successfulTerritoryNamesForAccountSoFar = successAssignmentsAccountToTerritoryNameMap.get(accountId);
                    if (successfulTerritoryNamesForAccountSoFar == null) {
                        successAssignmentsAccountToTerritoryNameMap.put(accountId, new List<String>{territoryName});
                    } else {
                        successfulTerritoryNamesForAccountSoFar.add(territoryName);
                    }
                }
            }
        }

        return successAssignmentsAccountToTerritoryNameMap;
    }

    public Map<String, List<String>> findFailedAssignments() {
        Map<String, List<String>> failedAssignmentsAccountToTerritoryNameMap = new Map<String, List<String>>();

        for (String accountId : afterAssignmentAccountToTerritoryIdMap.keySet()) {
            for (String expectedTerritoryId : expectedTerritoryIds) {
                if (!afterAssignmentAccountToTerritoryIdMap.get(accountId).contains(expectedTerritoryId)) {
                    String territoryName = territoryMap.get(expectedTerritoryId)?.Name;
                    List<String> failedTerritoryNamesForAccountSoFar = failedAssignmentsAccountToTerritoryNameMap.get(accountId);
                    if (failedTerritoryNamesForAccountSoFar == null) {
                        failedAssignmentsAccountToTerritoryNameMap.put(accountId, new List<String>{territoryName});
                    } else {
                        failedTerritoryNamesForAccountSoFar.add(territoryName);
                    }
                }
            }
        }

        return failedAssignmentsAccountToTerritoryNameMap;
    }

    public String getFailedAssignmentsMessages(Map<String, List<String>> failedAssignmentsAccountToTerritoryNameMap) {

        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN :failedAssignmentsAccountToTerritoryNameMap.keySet()]);
        List<String> missingAssignmentMessages = new List<String>();

        for (String accountId : failedAssignmentsAccountToTerritoryNameMap.keySet()) {
            missingAssignmentMessages.add(accountMap.get(accountId).Name + ' : ' + String.join(failedAssignmentsAccountToTerritoryNameMap.get(accountId), ', '));
        }

        return String.join(missingAssignmentMessages, '\n');
    }
}