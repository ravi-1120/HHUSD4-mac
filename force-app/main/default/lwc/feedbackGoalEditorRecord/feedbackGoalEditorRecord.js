import FeedbackGoalRecord from "c/feedbackGoalRecord";

export default class FeedbackGoalEditorRecord {
    constructor(accountRecord, goalMetadata, useDefaultGoals) {
        this.accountId = accountRecord?.accountId;
        this.planTargetId = accountRecord?.planTargetId ?? null;
        this.locationId = accountRecord?.location?.id ?? null;
        this.channelGoals = this._instantiateChannelGoals(accountRecord, goalMetadata, useDefaultGoals);
    }

    get editedChannels() {
        return this.channelGoals.filter(channelGoalDetail => channelGoalDetail.hasBeenEdited);
    }

    get hasGoalDifference() {
        return this.channelGoals.find(channelGoalDetail => channelGoalDetail.hasGoalDifference);
    }

    getChannelGoal(channelId) {
        return this.channelGoals.find(channelGoal => channelGoal.id === channelId);
    }

    _instantiateChannelGoals(accountRecord, goalMetadata, useDefaultGoals) {
        const accountHasLocation = (accountRecord?.location !== null);
        return goalMetadata?.map((channelMetadata, channelIndex) =>
            new FeedbackGoalRecord(accountRecord?.goalDetails[channelIndex], channelMetadata, useDefaultGoals, undefined, accountHasLocation)
        );
    }

    // Essentially casts channelGoals elements (and their children productGoals) into the FeedbackGoalRecord type. Used by the controller since
    //   objects passed through the message channel are converted to plain Javascript objects, thus losing context of the original class.
    channelGoalsToFeedbackGoalRecords() {
        this.channelGoals = this.channelGoals?.map(channelGoal => {
            const castedChannelGoal = Object.assign(new FeedbackGoalRecord(), channelGoal);
            castedChannelGoal.productGoals = 
                channelGoal?.productGoals?.map(productGoal => (
                    Object.assign(new FeedbackGoalRecord(), productGoal)
                ))
                ?? [];

            return castedChannelGoal;
        });
    }
}