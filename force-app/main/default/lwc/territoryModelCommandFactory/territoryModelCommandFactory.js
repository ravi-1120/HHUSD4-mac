import ApproveOrRejectPendingChallengesCommand from './commands/approveOrRejectPendingChallengesCommand';
import RepMoveToLifecycleStateCommand from './commands/repMoveToLifecycleStateCommand';
import RepReturnToRosterMemberCommand from './commands/repReturnToRosterMemberCommand';
import ManagerMoveAllToLifecycleStateCommand from './commands/managerMoveAllToLifecycleStateCommand';
import ManagerReturnAllToRosterMembersCommand from './commands/managerReturnAllToRosterMembersCommand';
import AccountsPageAdapter from './pageAdapters/accountsPageAdapter';

export default class TerritoryModelCommandFactory {
  static getInstance(territoryFeedbackBasePage, targetTerritoryModel, commandName, label) {
    switch (commandName) {
      case 'approve_pending_challenges':
        return new ApproveOrRejectPendingChallengesCommand(territoryFeedbackBasePage, targetTerritoryModel, label, true);
      case 'reject_pending_challenges':
        return new ApproveOrRejectPendingChallengesCommand(territoryFeedbackBasePage, targetTerritoryModel, label, false);
      case 'return_to_roster_member':
        return new RepReturnToRosterMemberCommand(territoryFeedbackBasePage, targetTerritoryModel, label);
      case 'return_all_to_roster_members':
        return new ManagerReturnAllToRosterMembersCommand(territoryFeedbackBasePage, targetTerritoryModel, label);
      default:
        return getLifecycleStateCommand(territoryFeedbackBasePage, targetTerritoryModel, label, commandName);
    }
  }
}

function getLifecycleStateCommand(territoryFeedbackBasePage, targetTerritoryModel, label, commandName) {
  return targetTerritoryModel.isRepLevelTerritoryModel
    ? new RepMoveToLifecycleStateCommand(territoryFeedbackBasePage, targetTerritoryModel, label, commandName)
    : new ManagerMoveAllToLifecycleStateCommand(territoryFeedbackBasePage, targetTerritoryModel, label, commandName);
}

export { AccountsPageAdapter };