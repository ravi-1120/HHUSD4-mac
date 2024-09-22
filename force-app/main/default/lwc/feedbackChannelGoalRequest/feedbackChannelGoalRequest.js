import FeedbackProductGoalRequest, { GOAL_CHALLENGE_TYPES } from "c/feedbackProductGoalRequest";

export default class FeedbackChannelGoalRequest {
    constructor(feedbackChannelGoalRecord, isEditGoalsRequest) {
        if (!feedbackChannelGoalRecord.planId) {
            this.channelId = feedbackChannelGoalRecord.id;
            if (isEditGoalsRequest) {
                this.type = GOAL_CHALLENGE_TYPES.ADD_GOAL;
            }
        } else {
            this.planChannelId = feedbackChannelGoalRecord.planId;
            if (isEditGoalsRequest) {
                this.type = GOAL_CHALLENGE_TYPES.EDIT_GOAL;
            }
        }

        // Add Targets requests cannot have null values for feedbackChannelGoal
        if (!isEditGoalsRequest || feedbackChannelGoalRecord.hasChannelGoalBeenEdited) {
            this.feedbackChannelGoal = feedbackChannelGoalRecord.feedbackGoal;
        } else {
            this.feedbackChannelGoal = null;
        }

        this.productGoalRequests = this._instantiateProductGoalRequests(feedbackChannelGoalRecord, isEditGoalsRequest);
    }

    _instantiateProductGoalRequests(feedbackChannelGoalRecord, isEditGoalsRequest) {
        return feedbackChannelGoalRecord.editedProductGoals.map(productGoal => new FeedbackProductGoalRequest(productGoal, isEditGoalsRequest));
    }
}