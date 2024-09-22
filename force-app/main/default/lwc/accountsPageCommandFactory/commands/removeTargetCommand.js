import { CHALLENGE_TYPES } from 'c/territoryFeedbackConstants';
import CreateAccountChallengeBaseCommand from './createAccountChallengeBaseCommand';

// Updating a command file without also touching the `accountsPageCommandFactory.js` file may result in Jenkins build failure. 

export default class RemoveTargetCommand extends CreateAccountChallengeBaseCommand {
  get shouldRevertAddTarget() {
    return this.accountRecord.targetChallengeType === CHALLENGE_TYPES.ADD_TARGET;
  }

  async sendRequest() {
    let parsedResponse;

    if (this.shouldRevertAddTarget) {
      const response = await this.territoryFeedbackService.revertChallenges(this.territoryModelId, this.accountRecord.accountId, this.accountRecord.planTargetId, false, true);
      [parsedResponse] = response.feedbackRevertChallengesResponses;
    } else {
      const response = await this.territoryFeedbackService.makeRemoveTargetsChallenge(
        this.territoryModelId,
        this.accountRecord.accountId,
        this.accountRecord.planTargetId
      );
      [parsedResponse] = response.feedbackRemoveTargetsResponses;
    }

    return parsedResponse;
  }

  updateAccount(response) {
    this.accountRecord.target = false;
    this.nullifyFeedbackGoalValues();
    
    if (this.shouldRevertAddTarget) {
      this.nullifyTargetChallenges();
    } else {
      this.updateTargetChallenges(CHALLENGE_TYPES.REMOVE_TARGET, response.targetChallengeStatus);
    }
  }

  nullifyFeedbackGoalValues() {
    this.accountRecord.goalDetails.forEach(channelGoalDetail => {
      channelGoalDetail.previousPlanId = channelGoalDetail.planChannelId;
      channelGoalDetail.planChannelId = null;
      channelGoalDetail.feedbackChannelGoal = null;
      channelGoalDetail.productGoals.forEach(productGoalDetail => {
        productGoalDetail.previousPlanId = productGoalDetail.planProductId;
        productGoalDetail.planProductId = null;
        productGoalDetail.feedbackProductGoal = null;
      });
    });
  }
}