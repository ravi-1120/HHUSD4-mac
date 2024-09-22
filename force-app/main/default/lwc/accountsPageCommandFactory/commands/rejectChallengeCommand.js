import { CHALLENGE_STATUSES, CHALLENGE_TYPES } from 'c/territoryFeedbackConstants';
import ApproveOrRejectBaseCommand from './approveOrRejectBaseCommand';

// Updating a command file without also touching the `accountsPageCommandFactory.js` file may result in Jenkins build failure. 

export default class RejectChallengeCommand extends ApproveOrRejectBaseCommand {
  get shouldApprove() {
    return false;
  }

  get filter() {
    return null;
  }

  get updatedChallengeStatus() {
    return CHALLENGE_STATUSES.REJECTED;
  }

  get updatedTargetChallengeStatus() {
    return CHALLENGE_STATUSES.REJECTED;
  }

  get associatedTargetLevelChallengesToReject() {
    return this.associatedAccounts.filter(
      acct => acct.challengeType 
      && acct.challengeType !== CHALLENGE_TYPES.REMOVE_ACCOUNT 
      && acct.targetChallengeType 
      && acct.targetChallengeType === CHALLENGE_TYPES.ADD_TARGET
    );
  }

  get accountIds() {
    const accountIds = this.accounts.map(acct => acct.id);
    accountIds.push(...this.associatedTargetLevelChallengesToReject.map(acct => acct.id));
    return accountIds;
  }

  updateTargetChallenges(updatedTargetChallengeType, updatedTargetChallengeStatus) {
    this.updateCollectionTargetChallenges(this.accounts, updatedTargetChallengeType, updatedTargetChallengeStatus);
    this.updateCollectionTargetChallenges(this.associatedTargetLevelChallengesToReject, updatedTargetChallengeType, updatedTargetChallengeStatus);
  }
}