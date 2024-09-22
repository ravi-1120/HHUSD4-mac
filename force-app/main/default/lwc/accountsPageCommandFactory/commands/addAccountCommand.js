import { CHALLENGE_TYPES, ACCOUNT_CHANGE } from 'c/territoryFeedbackConstants';
import CreateAccountChallengeBaseCommand from './createAccountChallengeBaseCommand';

// Updating a command file without also touching the `accountsPageCommandFactory.js` file may result in Jenkins build failure. 

export default class AddAccountCommand extends CreateAccountChallengeBaseCommand {
  async sendRequest() {
    const response = await this.territoryFeedbackService.makeAddAccountsChallenge(this.territoryModelId, this.accountRecord.accountId);
    return response.feedbackAddAccountResponses[0];
  }

  updateAccount(response) {
    this.accountRecord.change = ACCOUNT_CHANGE.ADDED;
    this.associatedAccounts.forEach(account => { account.change = ACCOUNT_CHANGE.ADDED });

    this.updateAccountChallenges(CHALLENGE_TYPES.ADD_ACCOUNT, response.accountChallengeStatus);
  }
}