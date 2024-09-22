import { AlignError } from 'c/territoryFeedbackErrors';
import AccountsPageBaseCommand from './accountsPageBaseCommand';

// Updating a command file without also touching the `accountsPageCommandFactory.js` file may result in Jenkins build failure. 

export default class ApproveOrRejectBaseCommand extends AccountsPageBaseCommand {
  get accountIds() {
    return this.accounts.map(account => account.id);
  }

  get shouldApprove() {
    // Implemented in subclasses
    return null;
  }

  get filter() {
    // Implemented in subclasses
    return null;
  }

  get updatedChallengeStatus() {
    // Implemented in subclasses
    return null;
  }

  get updatedTargetChallengeStatus() {
    // Implemented in subclasses
    return null;
  }

  async execute() {
    this.showLoadingSpinner();
    await this.approveOrRejectChallenges();
    this.updateAccounts();
    this.hideLoadingSpinner();
    return [...this.accounts, ...this.associatedAccounts];
  }

  async approveOrRejectChallenges() {
    const response = await this.territoryFeedbackService.approveOrRejectChallenges(
      this.territoryModelId,
      this.accountIds,
      this.shouldApprove,
      this.filter
    );

    if (response.status !== 'SUCCESS') {
      throw new AlignError(response.message);
    }
  }

  updateAccounts() {
    this.updateAccountChallenges(this.updatedChallengeType, this.updatedChallengeStatus);
    this.updateTargetChallenges(this.updatedTargetChallengeType, this.updatedTargetChallengeStatus);
  }

  updateCollectionTargetChallenges(accountsCollection, updatedTargetChallengeType, updatedTargetChallengeStatus) {
    accountsCollection.map(account => {
      const updatedAccount = account;

      // Only set the target challenge status for a rejectChallenge command if there exists a set challengeType for the accounts
      if (updatedAccount.targetChallengeType) {
        updatedAccount.targetChallengeStatus = updatedTargetChallengeStatus ?? updatedAccount.targetChallengeStatus;
      }
      // Only update an account's `target` status if a new target challenge was made or an existing target challenge was updated
      if ((updatedTargetChallengeType || updatedTargetChallengeStatus) && updatedAccount.targetChallengeType) {
        updatedAccount.target = !updatedAccount.isPendingRemoveTarget && !updatedAccount.isRejectedAddTarget;
      }

      return updatedAccount;
    });
  }
}