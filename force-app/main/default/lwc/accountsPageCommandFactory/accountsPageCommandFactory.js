import { CHALLENGE_TYPES } from 'c/territoryFeedbackConstants';
import ApproveChallengeCommand from './commands/approveChallengeCommand';
import ApproveAddAccountOnlyCommand from './commands/approveAddAccountOnlyCommand';
import ApproveKeepAccountOnlyCommand from './commands/approveKeepAccountOnlyCommand';
import ApproveRemoveTargetOnlyCommand from './commands/approveRemoveTargetOnlyCommand';
import RejectChallengeCommand from './commands/rejectChallengeCommand';
import EditGoalsCommand from './commands/editGoalsCommand';
import AddTargetCommand from './commands/addTargetCommand';
import KeepAccountCommand from './commands/keepAccountCommand';
import RemoveTargetCommand from './commands/removeTargetCommand';
import RemoveAccountCommand from './commands/removeAccountCommand';
import AddAccountCommand from './commands/addAccountCommand';

// Updating a command file without also touching this file may result in Jenkins build failure. 

export const COMMANDS = {
  APPROVE: 'approve',
  APPROVE_ADD_ACCOUNT_ONLY: 'approveAddAccountOnly',
  APPROVE_KEEP_ACCOUNT_ONLY: 'approveKeepAccountOnly',
  APPROVE_REMOVE_TARGET_ONLY: 'approveRemoveTargetOnly',
  REJECT: 'reject',
  EDIT_GOALS: 'editGoals',
  ADD_TARGET: 'addTarget',
  KEEP_ACCOUNT: 'keepAccount',
  REMOVE_TARGET: 'removeTarget',
  REMOVE_ACCOUNT: 'removeAccount',
  ADD_ACCOUNT: 'addAccount',
};

export default class AccountsPageCommandFactory {
  static getInstance(territoryFeedbackService, commandName, accounts, territoryModelId, accountsMetadata, associatedAccounts) {
    switch (commandName) {
      case COMMANDS.APPROVE:
        return new ApproveChallengeCommand(territoryFeedbackService, accounts, territoryModelId, associatedAccounts);

      case COMMANDS.APPROVE_ADD_ACCOUNT_ONLY:
        return new ApproveAddAccountOnlyCommand(territoryFeedbackService, accounts, territoryModelId, associatedAccounts);

      case COMMANDS.APPROVE_KEEP_ACCOUNT_ONLY:
        return new ApproveKeepAccountOnlyCommand(territoryFeedbackService, accounts, territoryModelId, associatedAccounts);

      case COMMANDS.APPROVE_REMOVE_TARGET_ONLY:
        return new ApproveRemoveTargetOnlyCommand(territoryFeedbackService, accounts, territoryModelId, associatedAccounts);

      case COMMANDS.REJECT:
        return new RejectChallengeCommand(territoryFeedbackService, accounts, territoryModelId, associatedAccounts);

      case COMMANDS.EDIT_GOALS:
        // Spec dictates that the user sees "Edit Goals" as an option if an "Add Target" challenge exists -
        //   however, behind the scenes we will send an update "Add Target" challenge 
        if (accounts[0].targetChallengeType === CHALLENGE_TYPES.ADD_TARGET) {
          return new AddTargetCommand(territoryFeedbackService, accounts, territoryModelId, accountsMetadata, associatedAccounts);
        }
        return new EditGoalsCommand(territoryFeedbackService, accounts, territoryModelId, accountsMetadata, associatedAccounts);

      case COMMANDS.ADD_TARGET:
        return new AddTargetCommand(territoryFeedbackService, accounts, territoryModelId, accountsMetadata, associatedAccounts);

      case COMMANDS.KEEP_ACCOUNT:
        return new KeepAccountCommand(territoryFeedbackService, accounts, territoryModelId, accountsMetadata, associatedAccounts);

      case COMMANDS.REMOVE_TARGET:
        return new RemoveTargetCommand(territoryFeedbackService, accounts, territoryModelId, accountsMetadata, associatedAccounts);

      case COMMANDS.REMOVE_ACCOUNT:
        return new RemoveAccountCommand(territoryFeedbackService, accounts, territoryModelId, accountsMetadata, associatedAccounts);

      case COMMANDS.ADD_ACCOUNT:
        return new AddAccountCommand(territoryFeedbackService, accounts, territoryModelId, accountsMetadata, associatedAccounts);

      default:
        return null;
    }
  }
}