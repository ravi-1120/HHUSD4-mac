import VeevaFieldTranslator from 'c/veevaFieldTranslator';
import { getService } from 'c/veevaServiceFactory';
import { ACCOUNT_CHANGE, ALIGN_TYPES, CHALLENGE_STATUSES, CHALLENGE_TYPES, NULL_DISPLAY_STRING } from 'c/territoryFeedbackConstants';
import { COMMANDS } from 'c/accountsPageCommandFactory';

const EN_US_LOCALE = 'en-US';

class AccountRecordFieldTranslator extends VeevaFieldTranslator {
  static messageSvc;
  static messages;

  constructor(userLocale) {
    super(AccountRecordFieldTranslator.translationMap);

    this.userLocale = userLocale ?? EN_US_LOCALE;
    this.dateFormatter = new Intl.DateTimeFormat(userLocale, { year: 'numeric', month: 'numeric', day: 'numeric', timeZone: 'UTC' });
    this.dateTimeFormatter = new Intl.DateTimeFormat(userLocale, {
      year: 'numeric',
      month: 'numeric',
      day: 'numeric',
      hour: 'numeric',
      minute: 'numeric',
      timeZone: 'UTC',
    });
    this.numberFormatter = new Intl.NumberFormat(userLocale);
  }

  static get translationMap() {
    return !this.messages
      ? new Map()
      : new Map([
          [
            'person',
            new Map([
              [true, this.messages.person],
              [false, this.messages.business],
            ]),
          ],

          [
            'hasChallenge',
            new Map([
              [true, this.messages.yes],
              [false, this.messages.no],
            ]),
          ],

          [
            'change',
            new Map([
              [ACCOUNT_CHANGE.ADDED, this.messages.add],
              [ACCOUNT_CHANGE.DROPPED, this.messages.drop],
              [ACCOUNT_CHANGE.NO_CHANGE, NULL_DISPLAY_STRING],
            ]),
          ],

          [
            'challengeType',
            new Map([
              [CHALLENGE_TYPES.ADD_ACCOUNT, this.messages.addAccount],
              [CHALLENGE_TYPES.REMOVE_ACCOUNT, this.messages.removeAccount],
              [CHALLENGE_TYPES.KEEP_ACCOUNT, this.messages.keepAccount],
            ]),
          ],

          [
            'targetChallengeType',
            new Map([
              [CHALLENGE_TYPES.GOAL_EDIT, this.messages.editGoal],
              [CHALLENGE_TYPES.ADD_TARGET, this.messages.addTarget],
              [CHALLENGE_TYPES.REMOVE_TARGET, this.messages.removeTarget],
            ]),
          ],

          [
            'challengeStatus',
            new Map([
              [CHALLENGE_STATUSES.APPROVED, this.messages.approved],
              [CHALLENGE_STATUSES.REJECTED, this.messages.rejected],
              [CHALLENGE_STATUSES.CHALLENGED, this.messages.pending],
            ]),
          ],

          [
            'targetChallengeStatus',
            new Map([
              [CHALLENGE_STATUSES.APPROVED, this.messages.approved],
              [CHALLENGE_STATUSES.REJECTED, this.messages.rejected],
              [CHALLENGE_STATUSES.CHALLENGED, this.messages.pending],
            ]),
          ],

          [
            'commands',
            new Map([
              [COMMANDS.APPROVE_ADD_ACCOUNT_ONLY, this.messages.approveAddAccountOnly],
              [COMMANDS.APPROVE_KEEP_ACCOUNT_ONLY, this.messages.approveKeepAccountOnly],
              [COMMANDS.APPROVE_REMOVE_TARGET_ONLY, this.messages.approveRemoveTargetOnly],
              [COMMANDS.EDIT_GOALS, this.messages.editGoals],
              [COMMANDS.ADD_TARGET, this.messages.addAsTarget],
              [COMMANDS.KEEP_ACCOUNT, this.messages.keepAccount],
              [COMMANDS.REMOVE_TARGET, this.messages.removeAsTarget],
              [COMMANDS.REMOVE_ACCOUNT, this.messages.removeAccount],
            ]),
          ],
        ]);
  }

  localizeField(type, value) {
    if (!value) {
      return NULL_DISPLAY_STRING;
    }

    let localizedString;

    switch (type) {
      case ALIGN_TYPES.STRING:
        localizedString = value;
        break;
      case ALIGN_TYPES.BOOLEAN:
        localizedString = value.toLowerCase() === 'true' ? AccountRecordFieldTranslator.messages.true : AccountRecordFieldTranslator.messages.false;
        break;
      case ALIGN_TYPES.DATE:
        localizedString = this.dateFormatter.format(new Date(value));
        break;
      case ALIGN_TYPES.DATETIME:
        localizedString = this.dateTimeFormatter.format(new Date(value));
        break;
      case ALIGN_TYPES.NUMBER:
        localizedString = this.numberFormatter.format(value);
        break;
      default:
        localizedString = NULL_DISPLAY_STRING;
    }

    return localizedString;
  }
}

export default async function build(userLocale) {
  if (!AccountRecordFieldTranslator.messages) {
    AccountRecordFieldTranslator.messageSvc = AccountRecordFieldTranslator.messageSvc ?? getService('messageSvc');

    AccountRecordFieldTranslator.messages = await AccountRecordFieldTranslator.messageSvc
      .createMessageRequest()
      .addRequest('PERSON', 'Common', 'Person', 'person')
      .addRequest('BUSINESS', 'Common', 'Business', 'business')
      .addRequest('YES', 'Common', 'Yes', 'yes')
      .addRequest('NO', 'Common', 'No', 'no')
      .addRequest('ADD', 'Common', 'Add', 'add')
      .addRequest('DROP', 'Feedback', 'Drop', 'drop')
      .addRequest('APPROVED', 'Feedback', 'Approved', 'approved')
      .addRequest('REJECTED', 'Feedback', 'Rejected', 'rejected')
      .addRequest('PENDING', 'Feedback', 'Pending', 'pending')
      .addRequest('EDIT_GOAL', 'Feedback', 'Edit Goal', 'editGoal')
      .addRequest('ADD_TARGET_1', 'Feedback', 'Add Target', 'addTarget')
      .addRequest('REMOVE_TARGET_1', 'Feedback', 'Remove Target', 'removeTarget')
      .addRequest('ADD_ACCOUNT', 'Feedback', 'Add Account', 'addAccount')
      .addRequest('REMOVE_ACCOUNT', 'Feedback', 'Remove Account', 'removeAccount')
      .addRequest('KEEP_ACCOUNT', 'Feedback', 'Keep Account', 'keepAccount')
      .addRequest('BOOLEAN_TRUE', 'View', 'true', 'true')
      .addRequest('BOOLEAN_FALSE', 'View', 'false', 'false')
      .addRequest('APPROVE_ADD_ACCOUNT_ONLY', 'Feedback', 'Approve "Add Account" Only', 'approveAddAccountOnly')
      .addRequest('APPROVE_KEEP_ACCOUNT_ONLY', 'Feedback', 'Approve "Keep Account" Only', 'approveKeepAccountOnly')
      .addRequest('APPROVE_REMOVE_TARGET_ONLY', 'Feedback', 'Approve "Remove Target" Only', 'approveRemoveTargetOnly')
      .addRequest('EDIT_GOALS', 'Feedback', 'Edit Goals', 'editGoals')
      .addRequest('ADD_TARGET', 'Feedback', 'Add as Target', 'addAsTarget')
      .addRequest('REMOVE_TARGET', 'Feedback', 'Remove as Target', 'removeAsTarget')
      .sendRequest();
  }

  return new AccountRecordFieldTranslator(userLocale);
}