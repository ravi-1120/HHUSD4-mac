import TerritoryModelRecord from 'c/territoryModelRecord';

export default class RepLevelTerritoryModelRecord extends TerritoryModelRecord {    
    constructor(territoryModel, parentTerritoryModel) {
        super(territoryModel, parentTerritoryModel);
        this._truncateLifecycleActionNames();
    }

    get numChallenges() {
        return this._numChallenges;
    }

    get numPendingChallenges() {
        return this._numPendingChallenges;
    }

    set numPendingChallenges(numPendingChallenges) {
        this._numPendingChallenges = numPendingChallenges;
    }

    get numPersonAccounts() {
        return this._numPersonAccounts;
    }

    set numPersonAccounts(count) {
        this._numPersonAccounts = count;
    }

    get numBusinessAccounts() {
        return this._numBusinessAccounts;
    }

    set numBusinessAccounts(count) {
        this._numBusinessAccounts = count;
    }

    get numTargets() {
        return this._numTargets;
    }

    set numTargets(count) {
        this._numTargets = count;
    }

    get isRepLevelTerritoryModel() {
        return true;
    }

    get repLevelChildTerritories() {
        return [];
    }

    get feedbackComplete() {
        return this._feedbackComplete;
    }

    set feedbackComplete(feedbackComplete) {
        this._feedbackComplete = feedbackComplete;
    }

    get feedback() {
        return this._feedback;
    }

    set feedback(feedback) {
        this._feedback = feedback;
    }

    get availableLifecycleActions() {
        return this._availableLifecycleActions;
    }

    set availableLifecycleActions(lifecycleActions) {
        this._availableLifecycleActions = lifecycleActions;
        this._truncateLifecycleActionNames();
    }

    _truncateLifecycleActionNames() {
        this._availableLifecycleActions.forEach(lifecycleAction => {
            lifecycleAction.name = lifecycleAction.name.split('.').pop();
        });
    }

    _populateGeoAddedAndDropped() {
        if (!this._geoAdded || !this._geoDropped) {
            this._geoAdded = [];
            this._geoDropped = [];

            this.territoryGeographyData.forEach(geoData =>{
                if (geoData.change === 'ADDED') {
                    this._geoAdded.push(geoData.geography);
                } else if (geoData.change === 'DROPPED') {
                    this._geoDropped.push(geoData.geography);
                }
            });
        }
    }

    clearPendingChallenges() {
        this.numPendingChallenges = 0;
    }

    updatePlanChannels(updatedTerritoryWithPlanChannels) {
        updatedTerritoryWithPlanChannels.planChannels.forEach((channel, channelIndex) => {
            this.planChannels[channelIndex].activityCount = channel.activityCount;
            channel.products.forEach((product, prodIndex) => {
                this.planChannels[channelIndex].products[prodIndex].activityCount = product.activityCount;
            });
        });
    }

    updateNumAccounts(updatedTerritoryWithCounts) {
        this.numPersonAccounts = updatedTerritoryWithCounts.numPersonAccounts;
        this.numBusinessAccounts = updatedTerritoryWithCounts.numBusinessAccounts;
        this.numTargets = updatedTerritoryWithCounts.numTargets;
    }
}