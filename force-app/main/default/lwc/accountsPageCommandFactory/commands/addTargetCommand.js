import { AlignError } from 'c/territoryFeedbackErrors';
import { CHALLENGE_TYPES, ACCOUNT_CHANGE } from 'c/territoryFeedbackConstants';
import FeedbackGoalRecord from 'c/feedbackGoalRecord';
import CreateAccountChallengeBaseCommand from './createAccountChallengeBaseCommand';

// Updating a command file without also touching the `accountsPageCommandFactory.js` file may result in Jenkins build failure. 

export default class AddTargetCommand extends CreateAccountChallengeBaseCommand {
  // This getter is used by the superclass
  get shouldShowGoalEditorModal() {
    return !this.shouldRevertRemoveTarget;
  }

  get isAddTargetChallenge() {
    return true;
  }

  get useDefaultGoals() {
    return !this.hasPreviousAddTargetChallenge;
  }

  get shouldRevertRemoveAccount() {
    return this.accountRecord.challengeType === CHALLENGE_TYPES.REMOVE_ACCOUNT;
  }

  get shouldRevertRemoveTarget() {
    return this.accountRecord.targetChallengeType === CHALLENGE_TYPES.REMOVE_TARGET;
  }

  get hasPreviousAddTargetChallenge() {
    return this.accountRecord.targetChallengeType === CHALLENGE_TYPES.ADD_TARGET;
  }

  async sendRequest() {
    let parsedResponse;

    if (this.shouldRevertRemoveTarget) {
      const response = await this.territoryFeedbackService.revertChallenges(
        this.territoryModelId,
        this.accountRecord.accountId,
        this.accountRecord.planTargetId,
        false,
        !this.shouldRevertRemoveAccount
      );
      [parsedResponse] = response.feedbackRevertChallengesResponses;
    } else if (this.accountRecord.isRejectedKeepAccount || this.accountRecord.isRejectedAddAccount) {
      // The Rejected account-level challenge must be approved before the Add Target challenge can be made
      const approvalResponse = await this.territoryFeedbackService.approveOrRejectChallenges(
        this.territoryModelId,
        [this.accountRecord.id],
        true,
        null
      );

      if (approvalResponse.status !== 'SUCCESS') {
        throw new AlignError(approvalResponse.message);
      } else {
        const addTargetResponse = await this.territoryFeedbackService.makeAddTargetsChallenge(
          this.territoryModelId,
          this.feedbackGoalEditorRecord,
          false
        );
        [parsedResponse] = addTargetResponse.feedbackAddTargetResponses;
      }
    } else if (!this.shouldRevertRemoveAccount && this.accountRecord.isDropped) {
      // Align has an endpoint for simulataneously keeping an account to the current territory and then adding the account as a target
      const response = await this.territoryFeedbackService.makeKeepAccountsAddTargetsChallenge(this.territoryModelId, this.feedbackGoalEditorRecord);
      [parsedResponse] = response.feedbackKeepAddTargetResponses;
    } else if (this.accountRecord.isInTerritory === false) {
      // Align has an endpoint for simultaneously adding an account to the current territory and then adding the account as a target
      const response = await this.territoryFeedbackService.makeAddAccountsAddTargetsChallenge(this.territoryModelId, this.feedbackGoalEditorRecord);
      [parsedResponse] = response.feedbackAddAddTargetResponses;
    } else {
      const response = await this.territoryFeedbackService.makeAddTargetsChallenge(
        this.territoryModelId,
        this.feedbackGoalEditorRecord,
        this.shouldRevertRemoveAccount
      );
      [parsedResponse] = response.feedbackAddTargetResponses;
    }

    return parsedResponse;
  }

  updateAccount(response) {
    this.accountRecord.target = true;
    if (this.shouldRevertRemoveTarget) {
      if (this.shouldRevertRemoveAccount) {
        this.nullifyAccountChallenges();
      }
      this.resetFeedbackGoalProperties();
      this.nullifyTargetChallenges();
    } else {
      // Add Targets endpoint returns `targetChallengeStatus`, while Add Accounts and Add Targets endpoint returns `challengeStatus`
      const challengeStatus = response.targetChallengeStatus ?? response.challengeStatus;
      this.updateTargetChallenges(CHALLENGE_TYPES.ADD_TARGET, challengeStatus);
      // If we are not reverting a challenge, then the outgoing request is an "Add Targets" request,
      //   and we need to instantiate goal records and goal column values.
      this.createAndUpdateAccountGoals(response);

      // If account is new to territory (e.g. from outside territory search), then we need to designate it as an "Added" account.
      // Otherwise, if reverting an existing "Remove Account" challenge, then we need to nullify the old "Remove Account" challenge.
      if (this.accountRecord.isInTerritory === false) {
        this.accountRecord.change = ACCOUNT_CHANGE.ADDED;
        this.associatedAccounts.forEach(account => { account.change = ACCOUNT_CHANGE.ADDED });
        this.updateAccountChallenges(CHALLENGE_TYPES.ADD_ACCOUNT, challengeStatus);
      } else if (this.accountRecord.isRejectedKeepAccount) {
        this.updateAccountChallenges(CHALLENGE_TYPES.KEEP_ACCOUNT, challengeStatus);
      } else if (this.accountRecord.isRejectedAddAccount) {
        this.updateAccountChallenges(CHALLENGE_TYPES.ADD_ACCOUNT, challengeStatus);
      } else if (this.shouldRevertRemoveAccount) {
        this.nullifyAccountChallenges();
      }  else if (this.accountRecord.isDropped) {
        this.updateAccountChallenges(CHALLENGE_TYPES.KEEP_ACCOUNT, challengeStatus);   
      }
    }
  }

  createAndUpdateAccountGoals(addTargetResponse) {
    // Create "placeholder" goal records if they do not yet exist for the account
    if (this.accountRecord.goalDetails?.length < addTargetResponse.channelGoalResponse.length) {
      this.accountRecord.goalDetails = [];
      this.accountsMetadata.goalMetadata.forEach(channelMetadata => {
        this.accountRecord.goalDetails.push(new FeedbackGoalRecord({ productGoals: channelMetadata?.products }, channelMetadata, false, null));
      });
    }

    // Update the account's planTargetId; then update the goal, planId, and cycleId for each channel and product that was created or updated by the user
    this.accountRecord.planTargetId = addTargetResponse.planTargetId ?? this.accountRecord.planTargetId;
    this.updateAccountGoals(addTargetResponse.channelGoalResponse);
  }

  resetFeedbackGoalProperties() {
    // If AddTarget reverts RemoveTarget, we should restore the planId (if available) and pre-feedback channel/goal values
    this.accountRecord.goalDetails.forEach(goalDetail => {
      goalDetail.planId = goalDetail.previousPlanId;
      goalDetail.feedbackChannelGoal = null;
      goalDetail.productGoals.forEach(productGoal => {
        productGoal.planId = productGoal.previousPlanId;
        productGoal.feedbackProductGoal = null;
      });
    });
  }
}