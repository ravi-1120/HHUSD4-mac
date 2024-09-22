import { createMessageContext, publish } from 'lightning/messageService';
import territoryFeedbackChannel from '@salesforce/messageChannel/TerritoryFeedback__c';

// Updating a command file without also touching the `accountsPageCommandFactory.js` file may result in Jenkins build failure. 

export default class AccountsPageBaseCommand {
  constructor(territoryFeedbackService, accounts, territoryModelId, associatedAccounts) {
    this.territoryFeedbackService = territoryFeedbackService;
    this.accounts = accounts;
    this.territoryModelId = territoryModelId;
    this.messageContext = createMessageContext();
    this.associatedAccounts = associatedAccounts;
  }

  showLoadingSpinner() {
    publish(this.messageContext, territoryFeedbackChannel, {
      destination: 'accountsPage',
      method: 'renderLoadingSpinner',
      shouldRenderSpinner: true,
    });
  }

  hideLoadingSpinner() {
    publish(this.messageContext, territoryFeedbackChannel, {
      destination: 'accountsPage',
      method: 'renderLoadingSpinner',
      shouldRenderSpinner: false,
    });
  }

  closeAllModals() {
    publish(this.messageContext, territoryFeedbackChannel, {
      destination: 'accountsPage',
      method: 'closeAllModals',
    });
  }

  updateAccountChallenges(updatedChallengeType, updatedChallengeStatus) {
    this.accounts = this.updateCollectionAccountChallenges(this.accounts, updatedChallengeType, updatedChallengeStatus);
    this.associatedAccounts = this.updateCollectionAccountChallenges(this.associatedAccounts, updatedChallengeType, updatedChallengeStatus);
  }

  updateCollectionAccountChallenges(accountCollection, updatedChallengeType, updatedChallengeStatus) {
    return accountCollection.map(account => {
      const updatedAccount = account;
      updatedAccount.challengeType = updatedChallengeType ?? account.challengeType;
      if (updatedAccount.challengeType) {
        updatedAccount.challengeStatus = updatedChallengeStatus ?? account.challengeStatus;
      }

      return updatedAccount;
    });
  }

  updateTargetChallenges(updatedTargetChallengeType, updatedTargetChallengeStatus) {
    this.accounts = this.accounts.map(account => {
      const updatedAccount = account;
      updatedAccount.targetChallengeType = updatedTargetChallengeType ?? account.targetChallengeType;
      if (updatedAccount.targetChallengeType) {
        updatedAccount.targetChallengeStatus = updatedTargetChallengeStatus ?? account.targetChallengeStatus;
      }
      // Only update an account's `target` status if a new target challenge was made or an existing target challenge was updated
      if ((updatedTargetChallengeType || updatedTargetChallengeStatus) && updatedAccount.targetChallengeType) {
        updatedAccount.target = !updatedAccount.isPendingRemoveTarget && !updatedAccount.isRejectedAddTarget;
      }

      return updatedAccount;
    });
  }

  nullifyAccountChallenges() {
    this.accounts = this.nullifyCollectionChallenges(this.accounts);
    this.associatedAccounts = this.nullifyCollectionChallenges(this.associatedAccounts);
  }
  
  nullifyCollectionChallenges(accountCollection) {
    return accountCollection.map(account => {
      const updatedAccount = account;
      updatedAccount.challengeType = null;
      updatedAccount.challengeStatus = null;

      return updatedAccount;
    });
  }

  nullifyTargetChallenges() {
    this.accounts = this.accounts.map(account => {
      const updatedAccount = account;
      updatedAccount.targetChallengeType = null;
      updatedAccount.targetChallengeStatus = null;

      return updatedAccount;
    });
  }
}