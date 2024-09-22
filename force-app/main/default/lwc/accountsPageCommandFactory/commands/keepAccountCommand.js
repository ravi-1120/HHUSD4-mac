import { CHALLENGE_TYPES } from 'c/territoryFeedbackConstants';
import CreateAccountChallengeBaseCommand from './createAccountChallengeBaseCommand';

// Updating a command file without also touching the `accountsPageCommandFactory.js` file may result in Jenkins build failure. 

export default class KeepAccountCommand extends CreateAccountChallengeBaseCommand {
  get shouldRevertRemoveAccount() {
    return this.accountRecord.challengeType === CHALLENGE_TYPES.REMOVE_ACCOUNT;
  }

  async sendRequest() {
    let parsedResponse;

    if (this.shouldRevertRemoveAccount) {
      const response = await this.territoryFeedbackService.revertChallenges(this.territoryModelId, this.accountRecord.accountId, undefined, true, false);
      [parsedResponse] = response.feedbackRevertChallengesResponses;
    } else {
      const response = await this.territoryFeedbackService.makeKeepAccountsChallenge(this.territoryModelId, this.accountRecord.accountId);
      [parsedResponse] = response.feedbackKeepAccountResponses;
    }

    return parsedResponse;
  }

  updateAccount(response) {
    if (this.shouldRevertRemoveAccount) {
      this.nullifyAccountChallenges();
    } else {
      this.updateAccountChallenges(CHALLENGE_TYPES.KEEP_ACCOUNT, response.accountChallengeStatus);
    }
  }
}