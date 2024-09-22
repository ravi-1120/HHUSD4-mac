import { CHALLENGE_STATUSES } from 'c/territoryFeedbackConstants';
import ApproveOrRejectBaseCommand from './approveOrRejectBaseCommand';

// Updating a command file without also touching the `accountsPageCommandFactory.js` file may result in Jenkins build failure. 

export default class ApproveAddAccountOnlyCommand extends ApproveOrRejectBaseCommand {
  get shouldApprove() {
    return true;
  }

  get filter() {
    return 'ADD_ACCOUNT_ONLY';
  }

  get updatedChallengeStatus() {
    return CHALLENGE_STATUSES.APPROVED;
  }

  get updatedTargetChallengeStatus() {
    return CHALLENGE_STATUSES.REJECTED;
  }
}