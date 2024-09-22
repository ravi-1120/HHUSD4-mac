export default class TerritoryModelRecord {
    static  FEEDBACK_STATE = 'change_state_to_feedback__c';
    
    constructor(territoryModel, parentTerritoryModel) {
        this._id = territoryModel.id;
        this._name = territoryModel.name;
        this._lifecycleState = territoryModel.lifecycleState;
        this._feedbackComplete = territoryModel.feedbackComplete;
        this._feedback = territoryModel.feedback;
        this._availableLifecycleActions = territoryModel.availableLifecycleActions ?? [];
        this._rosterMembers = territoryModel.rosterMembers ?? [];
        this._numChallenges = territoryModel.numChallenges;
        this._numPendingChallenges = territoryModel.numPendingChallenges;
        this._territoryGeographyData = territoryModel.territoryGeographyData ?? [];
        this._parentTerritoryModelId = parentTerritoryModel?.id;
        this._canReview = territoryModel.canReview;
        this._numPersonAccounts = territoryModel.numPersonAccounts;
        this._numBusinessAccounts = territoryModel.numBusinessAccounts;
        this._numTargets = territoryModel.numTargets;
        this.planChannels = territoryModel.planChannels ?? [];
    }

    get numChallenges() {
        // Implemented in subclasses
        return this._numChallenges;
    }

    get numPendingChallenges() {
        // Implemented in subclasses
        return this._numPendingChallenges;
    }

    set numPendingChallenges(numPendingChallenges) {
        this._numPendingChallenges = numPendingChallenges;
    }

    get numPersonAccounts() {
        return this._numPersonAccounts;
    }

    get numBusinessAccounts() {
        return this._numBusinessAccounts;
    }

    get numTargets() {
        return this._numTargets;
    }

    get id() {
        return this._id;
    }

    get name() {
        return this._name;
    }

    get lifecycleState() {
        return this._lifecycleState;
    }

    set lifecycleState(lifecycleState) {
        this._lifecycleState = lifecycleState;
    }
    
    get feedbackComplete() {
        // Implemented in subclasses
        return this._feedbackComplete;
    }

    get availableLifecycleActions() {
        return this._availableLifecycleActions;
    }

    set availableLifecycleActions(lifecycleActions) {
        this._availableLifecycleActions = lifecycleActions;
    }

    get rosterMembers() {
        return this._rosterMembers;
    }

    get territoryGeographyData() {
        return this._territoryGeographyData;
    }

    get childTerritoryModels() {
        return this._childTerritoryModels;
    }

    set childTerritoryModels(childTerritoryModels) {
        this._childTerritoryModels = childTerritoryModels;
    }

    get numGeoAdded() {
        this._populateGeoAddedAndDropped();
        return this._geoAdded.length;
    }

    get numGeoDropped() {
        this._populateGeoAddedAndDropped();
        return this._geoDropped.length;
    }

    get parentTerritoryModelId() {
        return this._parentTerritoryModelId;
    }

    get statusIconName() {
        return this.feedbackComplete ? 'utility:success' : null;
    }

    get statusIconVariant() {
        return this.feedbackComplete ? 'success' : null;
    }

    get geoChangeDisabled() {
        return !this.numGeoAdded && !this.numGeoDropped;
    }

    get isRepLevelTerritoryModel() {
        return false;
    }

    get isManagerLevelTerritoryModel() {
        return false;
    }

    get geoAddedAndDropped() {
        this._populateGeoAddedAndDropped();
        return {geoAdded: this._geoAdded, geoDropped: this._geoDropped};
    }

    get canReview() {
        return this._canReview;
    }

    set canReview(canReview) {
        this._canReview = canReview;
    }

    get canReviewPendingChallenges() {
        return this.canReview && this.numPendingChallenges;
    }
    
    get moreActionsMenuClass() {
        return !this.availableActions?.length ? 'hide-more-actions' : '';
    }

    get hasNoPersonAccounts() {
        return !this.numPersonAccounts || !this.isRepLevelTerritoryModel;
    }

    get hasNoBusinessAccounts() {
        return !this.numBusinessAccounts || !this.isRepLevelTerritoryModel;
    }

    get hasNoTargets() {
        return !this.numTargets || !this.isRepLevelTerritoryModel;
    }

    _populateGeoAddedAndDropped() {
        // Implemented in subclasses
        this._geoAdded = [];
        this._geoDropped = [];
    }

    isValidLifecycleStateTransition(targetLifecycleStateName) {
        return this.availableLifecycleActions.some(availableAction => availableAction.name === targetLifecycleStateName);
    }

    clearPendingChallenges() {
        // Implemented in subclasses
        this.numPendingChallenges = 0;
    }

    refreshActivityCounts() {
        if (this.childTerritoryModels?.length) {
            this.clearPlanChannelActivityCounts();
            
            this.childTerritoryModels.forEach(childTerritoryModel => {
                childTerritoryModel.refreshActivityCounts();
                childTerritoryModel.planChannels.forEach((channel, channelIndex) => {
                    this.planChannels[channelIndex].activityCount += channel.activityCount;
                    channel.products.forEach((product, productIndex) => {
                        this.planChannels[channelIndex].products[productIndex].activityCount += product.activityCount
                    })
                })
            });
        }
    }

    clearPlanChannelActivityCounts() {
        this.planChannels.forEach(channel => {
            channel.activityCount = 0;
            channel.products.forEach(product => {
                product.activityCount = 0;
            });
        });
    }
}