import { CHALLENGE_TYPES } from 'c/territoryFeedbackConstants';
import CreateAccountChallengeBaseCommand from './createAccountChallengeBaseCommand';

// Updating a command file without also touching the `accountsPageCommandFactory.js` file may result in Jenkins build failure. 

export default class RemoveAccountCommand extends CreateAccountChallengeBaseCommand {
  get shouldRevertAddTarget() {
    return this.accountRecord.targetChallengeType === CHALLENGE_TYPES.ADD_TARGET 
      || this.associatedAccounts.find(account => account.targetChallengeType === CHALLENGE_TYPES.ADD_TARGET) !== undefined;
  }

  get shouldRevertEditGoals() {
    return this.accountRecord.targetChallengeType === CHALLENGE_TYPES.GOAL_EDIT 
      || this.associatedAccounts.find(account => account.targetChallengeType === CHALLENGE_TYPES.GOAL_EDIT) !== undefined;
  }

  get shouldRevertRejectedRemoveTarget() {
    return this.accountRecord.isRejectedRemoveTarget || this.associatedAccounts.find(account => account.isRejectedRemoveTarget) !== undefined;
  }

  get shouldRevertAddAccount() {
    return this.accountRecord.challengeType === CHALLENGE_TYPES.ADD_ACCOUNT 
      || this.associatedAccounts.find(account => account.challengeType === CHALLENGE_TYPES.ADD_ACCOUNT) !== undefined;
  }

  get shouldRevertKeepAccount() {
    return this.accountRecord.challengeType === CHALLENGE_TYPES.KEEP_ACCOUNT 
      || this.associatedAccounts.find(account => account.challengeType === CHALLENGE_TYPES.KEEP_ACCOUNT) !== undefined;
  }

  async sendRequest() {
    let parsedResponse;

    if (this.shouldRevertAddAccount || this.shouldRevertKeepAccount) {
      const response = await this.territoryFeedbackService.revertChallenges(
        this.territoryModelId,
        this.accountRecord.accountId,
        undefined,
        !this.shouldRevertAddTarget,
        false
      );
      [parsedResponse] = response.feedbackRevertChallengesResponses;
    } else {
      const response = await this.territoryFeedbackService.makeRemoveAccountsChallenge(
        this.territoryModelId,
        this.accountRecord.accountId,
        this.shouldRevertAddTarget || this.shouldRevertEditGoals || this.shouldRevertRejectedRemoveTarget
      );
      [parsedResponse] = response.feedbackRemoveAccountResponses;
    }

    return parsedResponse;
  }

  updateAccount(response) {
    if (!this.shouldRevertAddAccount) {
      if (this.shouldRevertAddTarget) {
        if (!this.shouldRevertAddAccount && !this.shouldRevertKeepAccount) {
          this.updateTargetChallenges(CHALLENGE_TYPES.REMOVE_TARGET, response.accountChallengeStatus);
        } else {
          this.nullifyTargetChallenges();
        }
      } else {
        // Remove Account on a targeted row implies a Remove Target challenge
        this.updateTargetChallenges(CHALLENGE_TYPES.REMOVE_TARGET, response.accountChallengeStatus);
      }

      if (this.shouldRevertKeepAccount) {
        this.nullifyAccountChallenges();
      } else {
        this.updateAccountChallenges(CHALLENGE_TYPES.REMOVE_ACCOUNT, response.accountChallengeStatus);
      }

      this.accountRecord.target = false;
      this.nullifyFeedbackGoalValues(this.accountRecord);
  
      this.associatedAccounts.forEach(associatedAccount => {
        associatedAccount.target = false;
        this.nullifyFeedbackGoalValues(associatedAccount);
      });
    } else {
      // Remove Account on an Add Account challenge should remove the account(s) from the table
      this.accountRecord.isRemoved = true;
      this.associatedAccounts.forEach(associatedAccount => {
        associatedAccount.isRemoved = true;
      });
    }
  }

  nullifyTargetChallenges() {
    this.accountRecord.targetChallengeType = null;
    this.accountRecord.targetChallengeStatus = null;

    this.associatedAccounts.forEach(associatedAccount => {
      associatedAccount.targetChallengeType = null;
      associatedAccount.targetChallengeStatus = null;
    })
  }

  updateTargetChallenges(updatedChallengeType, updatedChallengeStatus) {
    if (this.accountRecord.target || this.accountRecord.isRejectedAddTarget) {
      if (this.accountRecord.targetChallengeType === CHALLENGE_TYPES.ADD_TARGET) {
        this.accountRecord.targetChallengeType = null;
        this.accountRecord.targetChallengeStatus = null;
      } else {
        this.accountRecord.targetChallengeType = updatedChallengeType;
        this.accountRecord.targetChallengeStatus = updatedChallengeStatus;
      }
    }

    this.associatedAccounts.forEach(associatedAccount => {
      if (associatedAccount.target || associatedAccount.isRejectedAddTarget) {
        if (associatedAccount.targetChallengeType === CHALLENGE_TYPES.ADD_TARGET) {
          associatedAccount.targetChallengeType = null;
          associatedAccount.targetChallengeStatus = null;
        } else {
          associatedAccount.targetChallengeType = updatedChallengeType;
          associatedAccount.targetChallengeStatus = updatedChallengeStatus;
        }
      }
    });
  }

  nullifyFeedbackGoalValues(account) {
    account.goalDetails.forEach(channelGoalDetail => {
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