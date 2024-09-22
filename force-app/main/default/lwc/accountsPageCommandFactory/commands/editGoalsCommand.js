import { CHALLENGE_TYPES } from 'c/territoryFeedbackConstants';
import CreateAccountChallengeBaseCommand from './createAccountChallengeBaseCommand';

// Updating a command file without also touching the `accountsPageCommandFactory.js` file may result in Jenkins build failure. 

export default class EditGoalsCommand extends CreateAccountChallengeBaseCommand {
  // This getter is used by the superclass
  get shouldShowGoalEditorModal() {
    return true;
  }

  // Edit Goals challenge is made, but the goals are reset to pre-feedback values
  get shouldRevertEditGoalsChallenge() {
    return this.accountRecord.targetChallengeType === CHALLENGE_TYPES.GOAL_EDIT && !this.feedbackGoalEditorRecord?.hasGoalDifference;
  }

  async sendRequest() {
    let parsedResponse;

    if (this.shouldRevertEditGoalsChallenge) {
      const { accountId, planTargetId } = this.feedbackGoalEditorRecord;
      const response = await this.territoryFeedbackService.revertChallenges(this.territoryModelId, accountId, planTargetId, false, true);
      [parsedResponse] = response.feedbackRevertChallengesResponses;
    } else {
      const response = await this.territoryFeedbackService.makeEditGoalsChallenge(this.territoryModelId, this.feedbackGoalEditorRecord);
      [parsedResponse] = response.feedbackEditGoalsResponses;
    }

    return parsedResponse;
  }

  updateAccount(response) {
    if (this.shouldRevertEditGoalsChallenge) {
      this.resetAccountGoals();
      this.nullifyTargetChallenges();
    } else {
      this.updateAccountGoals(response.channelGoalResponse);
      this.updateTargetChallenges(CHALLENGE_TYPES.GOAL_EDIT, response.targetChallengeStatus);
    }
  }

  resetAccountGoals() {
    this.accountRecord.goalDetails.forEach(channelGoalDetail => {
      channelGoalDetail.feedbackChannelGoal = channelGoalDetail.channelGoal;
      channelGoalDetail.productGoals.forEach(productGoalDetail => {
        productGoalDetail.feedbackProductGoal = productGoalDetail.productGoal;
      });
    });
  }
}