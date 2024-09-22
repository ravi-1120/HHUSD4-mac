export const GOAL_CHALLENGE_TYPES = {
    ADD_GOAL: 'addGoal',
    EDIT_GOAL: 'editGoal'
};

export default class FeedbackProductGoalRequest {
    constructor(feedbackProductGoalRecord, isEditGoalsRequest) {
        if (!feedbackProductGoalRecord.planId) {
            this.productId = feedbackProductGoalRecord.id;
            if (isEditGoalsRequest) {
                this.type = GOAL_CHALLENGE_TYPES.ADD_GOAL;
            }
        } else {
            this.planProductId = feedbackProductGoalRecord.planId;
            if (isEditGoalsRequest) {
                this.type = GOAL_CHALLENGE_TYPES.EDIT_GOAL;
            }
        }

        this.feedbackProductGoal = feedbackProductGoalRecord.feedbackGoal;
    }
}