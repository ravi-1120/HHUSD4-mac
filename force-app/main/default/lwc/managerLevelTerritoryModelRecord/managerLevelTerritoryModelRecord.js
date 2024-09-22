import TerritoryModelRecord from "c/territoryModelRecord";
import RepLevelTerritoryModelRecord from "c/repLevelTerritoryModelRecord";

export default class ManagerLevelTerritoryModelRecord extends TerritoryModelRecord {
    static  FEEDBACK_STATE = 'change_state_to_feedback__c';
    
    constructor(territoryModel, parentTerritoryModel) {
        super(territoryModel, parentTerritoryModel);
        this._childTerritoryModels = this.convertChildTerritories(territoryModel.childTerritoryModels);
    }

    get numChallenges() {
        return this.repLevelChildTerritories.reduce((sum, childTerritory) => sum + childTerritory.numChallenges, 0);
    }

    get numPendingChallenges() {
        return this.repLevelChildTerritories.reduce((sum, childTerritory) => sum + childTerritory.numPendingChallenges, 0);
    }

    get numPersonAccounts() {
        return this.repLevelChildTerritories.reduce((sum, childTerritory) => sum + childTerritory.numPersonAccounts, 0);
    }

    get numBusinessAccounts() {
        return this.repLevelChildTerritories.reduce((sum, childTerritory) => sum + childTerritory.numBusinessAccounts, 0);
    }
    
    get numTargets() {
        return this.repLevelChildTerritories.reduce((sum, childTerritory) => sum + childTerritory.numTargets, 0);
    }

    get feedbackComplete() {
        return this.repLevelChildTerritories.every(childTerritory => childTerritory.feedbackComplete);
    }

    get isManagerLevelTerritoryModel() {
        return true;
    }

    // Returns array of all of the repLevelTerritoryModelRecord instances that are children of this territory
    get repLevelChildTerritories() {
        if (!this._repLevelChildTerritories) {
            this._repLevelChildTerritories = [];

            this.childTerritoryModels.forEach(childTerritory => {
                if (childTerritory instanceof RepLevelTerritoryModelRecord) {
                    this._repLevelChildTerritories.push(childTerritory);
                } else {
                    this._repLevelChildTerritories.push(...childTerritory.repLevelChildTerritories);
                }
            });
        }
        return this._repLevelChildTerritories;
    }

    // Aggregates added and dropped geographies of all rep-level territories underneath this territory
    _populateGeoAddedAndDropped() {
        if (!this._geoAdded || !this._geoDropped) {
            this._geoAdded = [];
            this._geoDropped = [];

            this.repLevelChildTerritories.forEach(childTerritory => {
                const {geoAdded, geoDropped} = childTerritory.geoAddedAndDropped;

                this._geoAdded.push(...geoAdded);
                this._geoDropped.push(...geoDropped);
            });
        }
    }

    clearPendingChallenges() {
        this.repLevelChildTerritories.forEach(childTerritory => childTerritory.clearPendingChallenges());
    }

    // Recursively converts child territories array(s) into "known" TerritoryModel instance(s)
    convertChildTerritories(childTerritoriesArray) {
        if (childTerritoriesArray) {
            return childTerritoriesArray.map(childTerritory => {
                if (childTerritory.childTerritoryModels?.length) {
                    return new ManagerLevelTerritoryModelRecord(childTerritory, this);
                } 
                    return new RepLevelTerritoryModelRecord(childTerritory, this);
                
            });
        } 
            return [];
        
    }

    addChildTerritoriesToReferenceMap(referenceMap) {
        this.childTerritoryModels.forEach(childTerritory => {
            referenceMap.set(childTerritory.id, childTerritory);
            if (childTerritory.childTerritoryModels?.length) {
                childTerritory.addChildTerritoriesToReferenceMap(referenceMap);
            }
        });
    }

    // Returns a sub-array of the rep-level child territories that can move to the targetLifecycleState
    getChildrenThatCanTransition(targetLifecycleStateName) {
        return this.repLevelChildTerritories.filter(childTerritory => childTerritory.isValidLifecycleStateTransition(targetLifecycleStateName));
    }

    // Recursively rolls up numPersonAccounts, numBusinessAccounts, numTargets properties from updatedTerritoryWithCounts for top-level parent and each of its children
    updateNumAccounts(updatedTerritoryWithCounts) {
        // Update counts for child territory models with response data
        updatedTerritoryWithCounts?.childTerritoryModels?.forEach(updatedChildTerritory => {
            const childTerritoryModel = this.childTerritoryModels.find(child => child.id === updatedChildTerritory.id);
            if (childTerritoryModel) {
                childTerritoryModel.updateNumAccounts(updatedChildTerritory);
            }
        });
    }
    
    // Recursively updates itself and children based on updated territory model details from Align
    updatePlanChannels(updatedTerritoryWithPlanChannels) {
        // Clear current plan channel data from this node
        this.clearPlanChannelActivityCounts();

        // Update plan channel data for child territory models with response data
        const updatedPlanChannels = [];
        updatedTerritoryWithPlanChannels?.childTerritoryModels?.forEach(updatedChildTerritory => {
            const childTerritoryModel = this.childTerritoryModels.find(child => child.id === updatedChildTerritory.id);
            if (childTerritoryModel) {
                childTerritoryModel.updatePlanChannels(updatedChildTerritory);
                updatedPlanChannels.push(childTerritoryModel.planChannels);
            }
        });

        // Update planChannel data for territory by rolling up child territory
        // activity count data. 
        updatedPlanChannels.forEach((planChannel) => {
            planChannel.forEach((channel, channelIndex) => {
                this.planChannels[channelIndex].activityCount += channel.activityCount;
                channel.products.forEach((product, prodIndex) => {
                    this.planChannels[channelIndex].products[prodIndex].activityCount += product.activityCount;
                });
            })
        });
    }
}