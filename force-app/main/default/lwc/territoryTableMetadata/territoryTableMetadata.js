export default class TerritoryTableMetadata {
    constructor(parentTerritoryName, allowNavigationUp, fieldPlanHasCycle, channelLabelsToProductLabels) {
        this.parentTerritoryName = parentTerritoryName;
        this.allowNavigationUp = allowNavigationUp;
        this.fieldPlanHasCycle = fieldPlanHasCycle;
        this.channelLabelsToProductLabels = channelLabelsToProductLabels;
    }
}