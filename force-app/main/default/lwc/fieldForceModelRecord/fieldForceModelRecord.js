import ManagerLevelTerritoryModelRecord from "c/managerLevelTerritoryModelRecord";
import RepLevelTerritoryModelRecord from "c/repLevelTerritoryModelRecord";

export default class FieldForceModelRecord {
    constructor(fieldForceModel) {
        this.name = fieldForceModel.name;
        this.id = fieldForceModel.id;
        this.channelLabelsToProductLabels = fieldForceModel.channelLabelsToProductLabels;
        this.territoryModels = this.convertNestedTerritoryModels(fieldForceModel.territoryModels);
    }

    get statusIconName() {
        const allCompleted = this.territoryModels.every(territoryModel => territoryModel.feedbackComplete);
        return allCompleted ? 'utility:success' : null;
    }

    get hasMultipleParentTerritoryModels() {
        return this.territoryModels.length > 1;
    }

    convertNestedTerritoryModels(territoryModelsArray) {
        return territoryModelsArray.map(territoryModel => {
            if (territoryModel.childTerritoryModels?.length) {
                return new ManagerLevelTerritoryModelRecord(territoryModel, null);
            } else {
                return new RepLevelTerritoryModelRecord(territoryModel, null);
            }
        });
    }

    addTerritoriesToReferenceMap(referenceMap) {
        this.territoryModels.forEach(territory => {
            referenceMap.set(territory.id, territory);
            if (territory.childTerritoryModels?.length) {
                territory.addChildTerritoriesToReferenceMap(referenceMap);
            }
        });
    }
}