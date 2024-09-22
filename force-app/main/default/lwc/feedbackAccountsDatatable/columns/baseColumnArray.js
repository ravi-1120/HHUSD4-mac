import { getService } from 'c/veevaServiceFactory';
import { COMMANDS } from 'c/accountsPageCommandFactory';
import { ACCOUNT_CHANGE, ALIGN_TYPES, CHALLENGE_STATUSES, CHALLENGE_TYPES, NULL_DISPLAY_STRING } from 'c/territoryFeedbackConstants';
import ColumnUtils from './columnUtils';

const STATUS_CONTAINER_CLASS = 'status-container';

// Controls both the order of menu items and the conditions upon which they're rendered
const CHALLENGE_COMMAND_TO_RENDER_CONDITION = new Map([
  [COMMANDS.KEEP_ACCOUNT, 'shouldAllowKeepAccount'],
  [COMMANDS.ADD_TARGET, 'shouldAllowAddTarget'],
  [COMMANDS.EDIT_GOALS, 'shouldAllowEditGoals'],
  [COMMANDS.REMOVE_TARGET, 'shouldAllowRemoveTarget'],
  [COMMANDS.REMOVE_ACCOUNT, 'shouldAllowRemoveAccount'],
]);
const REVIEW_COMMAND_TO_RENDER_CONDITION = new Map([
  [COMMANDS.APPROVE_ADD_ACCOUNT_ONLY, 'shouldAllowApproveAddAccountOnly'],
  [COMMANDS.APPROVE_KEEP_ACCOUNT_ONLY, 'shouldAllowApproveKeepAccountOnly'],
  [COMMANDS.APPROVE_REMOVE_TARGET_ONLY, 'shouldAllowApproveRemoveTargetOnly'],
]);

export const COLUMN_IDS = {
  TARGET: 'target',
  PERSON: 'person',
  HAS_CHALLENGE: 'hasChallenge',
  CHALLENGE_STATUS: 'challengeStatus',
  CHANGE: 'change',
};

// Changing this file without touching the parent `FeedbackAccountsDatatable` JS or HTML could result in build failure.

export default class BaseColumnArray {
  constructor(accountRecordFieldTranslator, accountsTableDetailsRecord, messages) {
    this.translator = accountRecordFieldTranslator;
    this.accountsTableDetailsRecord = accountsTableDetailsRecord;
    this.messages = messages;
    this.columns = this.buildColumns();
  }

  static async createColumns(accountRecordFieldTranslator, accountsTableDetailsRecord) {
    const messages = await this.getVeevaMessages();

    return new BaseColumnArray(accountRecordFieldTranslator, accountsTableDetailsRecord, messages).columns;
  }

  static async getVeevaMessages() {
    const messageSvc = getService('messageSvc');

    return messageSvc
      .createMessageRequest()
      .addRequest('Account', 'Common', 'Account', 'account')
      .addRequest('LOCATION', 'Common', 'Location', 'location')
      .addRequest('ACTIONS', 'TABLET', 'Actions', 'actions')
      .addRequest('ACCOUNT_TYPE', 'Feedback', 'Account Type', 'accountType')
      .addRequest('ADDDROP', 'Feedback', 'Add / Drop', 'addDrop')
      .addRequest('CHALLENGE', 'ALIGN', 'Challenge', 'challenge')
      .addRequest('ISCHALLENGED', 'Feedback', 'Challenged?', 'isChallenged')
      .addRequest('TYPE', 'Common', 'Type', 'type')
      .addRequest('STATUS', 'Common', 'Status', 'status')
      .addRequest('REASONS', 'Feedback', 'Reason(s)', 'reasons')
      .addRequest('ADD_ACCOUNT_APPROVED', 'Feedback', 'Add Account Approved', 'addAccountApproved')
      .addRequest('ADD_TARGET_REJECTED_BROWSER', 'Feedback', 'Add Target Rejected', 'addTargetRejected')
      .addRequest('ADD_TARGET_PENDING_BROWSER', 'Feedback', 'Add Target Pending', 'addTargetPending')
      .addRequest('KEEP_ACCOUNT_APPROVED', 'Feedback', 'Keep Account Approved', 'keepAccountApproved')
      .addRequest('REMOVE_TARGET_APPROVED', 'Feedback', 'Remove Target Approved', 'removeTargetApproved')
      .addRequest('REMOVE_TARGET_PENDING_BROWSER', 'Feedback', 'Remove Target Pending', 'removeTargetPending')
      .addRequest('REMOVE_ACCOUNT_REJECTED_BROWSER', 'Feedback', 'Remove Account Rejected', 'removeAccountRejected')
      .addRequest('BOOLEAN_TRUE', 'View', 'true', 'true')
      .addRequest('BOOLEAN_FALSE', 'View', 'false', 'false')
      .sendRequest();
  }

  buildColumns() {
    const columns = [];

    if (this.accountsTableDetailsRecord.canReview || this.accountsTableDetailsRecord.canChallenge) {
      ColumnUtils.addParentColumnToArray(
        {
          text: this.messages.actions,
          locked: true,
          resizable: false,
          sortable: false,
          filterable: false,
          type: 'widget',
          width: 136,
          widgets: this.getActionsColumnWidgets(this.accountsTableDetailsRecord.canReview, this.accountsTableDetailsRecord.canChallenge, this.accountsTableDetailsRecord.cyclePresent),
          cellCls: 'actions',
          renderer: ({ record, widgets }) => BaseColumnArray.renderWidgets(record, widgets, this.accountsTableDetailsRecord.canReview, this.accountsTableDetailsRecord.cyclePresent),
        },
        columns
      );
    }

    if (this.accountsTableDetailsRecord.cyclePresent) {
      ColumnUtils.addParentColumnToArray(
        {
          id: COLUMN_IDS.TARGET,
          field: 'target',
          icon: 'b-fa b-fa-bullseye',
          cls: 'header-icon target-icon',
          width: 70,
          locked: true,
          align: 'center',
          resizable: false,
          renderer: ({ value }) => (value ? { tag: 'i', class: 'b-fa b-fa-bullseye target-icon' } : { html: '' }),
          ...ColumnUtils.getComboFilterableProperties([
            { value: true, text: this.messages.true },
            { value: false, text: this.messages.false },
          ]),
          sortable: (record1, record2) => ColumnUtils.sort(ALIGN_TYPES.BOOLEAN, !record1.target, !record2.target)
        },
        columns
      );
    }

    ColumnUtils.addParentColumnToArray(
      {
        text: this.messages.account,
        field: 'name',
        locked: true,
        width: 175,
        sortable: (record1, record2) => ColumnUtils.sort(ALIGN_TYPES.STRING, record1.name, record2.name)
      },
      columns
    );

    if (this.accountsTableDetailsRecord.locationBasedTargeting) {
      ColumnUtils.addParentColumnToArray(
        {
          text: this.messages.location,
          field: 'location.name',
          locked: true,
          width: 175,
          renderer: ({ value }) => value ?? NULL_DISPLAY_STRING,
          // Sorts null-location account rows after populated-location account rows
          sortable: (record1, record2) => (!record1.location - !record2.location) || ColumnUtils.sort(ALIGN_TYPES.STRING, record1.location?.name, record2.location?.name)
        },
        columns
      );
    }

    ColumnUtils.addParentColumnToArray(
      {
        id: COLUMN_IDS.PERSON,
        text: this.messages.accountType,
        field: 'person',
        width: 130,
        renderer: ({ value }) => this.translateField('person', value),
        ...ColumnUtils.getComboFilterableProperties([
          { value: true, text: this.translateField('person', true) },
          { value: false, text: this.translateField('person', false) },
        ]),
        sortable: (record1, record2) =>
          ColumnUtils.sort(ALIGN_TYPES.STRING, this.translateField('person', record1.person), this.translateField('person', record2.person)),
      },
      columns
    );

    ColumnUtils.addParentColumnToArray(
      {
        id: COLUMN_IDS.CHANGE,
        text: this.messages.addDrop,
        // Need to use the `originalData` property to reference ES6 getters.
        // Note that the `record` and `originalData` properties stay in sync automatically (i.e. updating record will update `originalData`).
        renderer: ({ record }) => this.translateField('change', record.originalData.addDropStatus),
        ...ColumnUtils.getComboFilterableProperties(
          [
            { value: ACCOUNT_CHANGE.ADDED, text: this.translateField('change', ACCOUNT_CHANGE.ADDED) },
            { value: ACCOUNT_CHANGE.DROPPED, text: this.translateField('change', ACCOUNT_CHANGE.DROPPED) },
            { value: ACCOUNT_CHANGE.NO_CHANGE, text: this.translateField('change', ACCOUNT_CHANGE.NO_CHANGE) },
          ],
          ({ record, value }) => record.originalData.addDropStatus === value
        ),
        sortable: (record1, record2) =>
          ColumnUtils.sort(
            ALIGN_TYPES.STRING,
            this.translateField('change', record1.originalData.addDropStatus),
            this.translateField('change', record2.originalData.addDropStatus)
          ),
      },
      columns
    );

    const challengeParentColumn = {
      text: this.messages.challenge,
      align: 'center',
    };
    ColumnUtils.addParentColumnToArray(challengeParentColumn, columns);

    ColumnUtils.addChildColumnToParent(challengeParentColumn, {
      id: COLUMN_IDS.HAS_CHALLENGE,
      text: this.messages.isChallenged,
      // Need to use the `originalData` property to reference ES6 getters.
      // Note that the `record` and `originalData` properties stay in sync automatically (i.e. updating record will update `originalData`).
      renderer: ({ record }) => this.translateField('hasChallenge', record.originalData.hasChallenge),
      ...ColumnUtils.getComboFilterableProperties(
        [
          { value: true, text: this.translateField('hasChallenge', true) },
          { value: false, text: this.translateField('hasChallenge', false) },
        ],
        ({ record, value }) => record.originalData.hasChallenge === value
      ),
      sortable: (record1, record2) =>
        ColumnUtils.sort(
          ALIGN_TYPES.STRING,
          this.translateField('hasChallenge', record1.originalData.hasChallenge),
          this.translateField('hasChallenge', record2.originalData.hasChallenge)
        ),
    });

    ColumnUtils.addChildColumnToParent(challengeParentColumn, {
      text: this.messages.type,
      renderer: ({ record }) => this.getChallengeTypeDisplay(record.challengeType, record.targetChallengeType),
      ...ColumnUtils.getComboFilterableProperties(
        [
          { value: CHALLENGE_TYPES.KEEP_ACCOUNT, text: this.translateField('challengeType', CHALLENGE_TYPES.KEEP_ACCOUNT) },
          { value: CHALLENGE_TYPES.ADD_ACCOUNT, text: this.translateField('challengeType', CHALLENGE_TYPES.ADD_ACCOUNT) },
          { value: CHALLENGE_TYPES.ADD_TARGET, text: this.translateField('targetChallengeType', CHALLENGE_TYPES.ADD_TARGET) },
          { value: CHALLENGE_TYPES.GOAL_EDIT, text: this.translateField('targetChallengeType', CHALLENGE_TYPES.GOAL_EDIT) },
          { value: CHALLENGE_TYPES.REMOVE_TARGET, text: this.translateField('targetChallengeType', CHALLENGE_TYPES.REMOVE_TARGET) },
          { value: CHALLENGE_TYPES.REMOVE_ACCOUNT, text: this.translateField('challengeType', CHALLENGE_TYPES.REMOVE_ACCOUNT) },
        ],
        ({ record, value }) => record.challengeType === value || record.targetChallengeType === value
      ),
      sortable: (record1, record2) =>
        ColumnUtils.sort(
          ALIGN_TYPES.STRING,
          this.getChallengeTypeDisplay(record1.challengeType, record1.targetChallengeType),
          this.getChallengeTypeDisplay(record2.challengeType, record2.targetChallengeType)
        ),
    });

    ColumnUtils.addChildColumnToParent(challengeParentColumn, {
      id: COLUMN_IDS.CHALLENGE_STATUS,
      text: this.messages.status,
      cellCls: 'challenge-status',
      renderer: ({ record }) =>
        this.getChallengeStatusDisplay(record.challengeType, record.challengeStatus, record.targetChallengeType, record.targetChallengeStatus),
      ...ColumnUtils.getComboFilterableProperties(
        [
          { value: CHALLENGE_STATUSES.APPROVED, text: this.translateField('challengeStatus', CHALLENGE_STATUSES.APPROVED) },
          { value: CHALLENGE_STATUSES.CHALLENGED, text: this.translateField('challengeStatus', CHALLENGE_STATUSES.CHALLENGED) },
          { value: CHALLENGE_STATUSES.REJECTED, text: this.translateField('challengeStatus', CHALLENGE_STATUSES.REJECTED) },
        ],
        ({ record, value }) => record.challengeStatus === value || record.targetChallengeStatus === value
      ),
      sortable: (record1, record2) => {
        const statusMessages1 = this.getChallengeStatusMessages(
          record1.challengeType,
          record1.challengeStatus,
          record1.targetChallengeType,
          record1.targetChallengeStatus
        );
        const concattedStatus1 = statusMessages1.secondary ? `${statusMessages1.primary} ${statusMessages1.secondary}` : statusMessages1.primary;

        const statusMessages2 = this.getChallengeStatusMessages(
          record2.challengeType,
          record2.challengeStatus,
          record2.targetChallengeType,
          record2.targetChallengeStatus
        );
        const concattedStatus2 = statusMessages2.secondary ? `${statusMessages2.primary} ${statusMessages2.secondary}` : statusMessages2.primary;

        return ColumnUtils.sort(ALIGN_TYPES.STRING, concattedStatus1, concattedStatus2);
      },
    });

    ColumnUtils.addChildColumnToParent(challengeParentColumn, {
      text: this.messages.reasons,
      renderer: ({ record }) => BaseColumnArray.getChallengeReasonsDisplay(record.challengeReasons, record.targetChallengeReasons),
      ...ColumnUtils.getFilterableColumnProperties(ALIGN_TYPES.STRING, this.translator, ({ record, value, operator }) =>
        ColumnUtils.filter(
          ALIGN_TYPES.STRING,
          BaseColumnArray.getChallengeReasonsDisplay(record.challengeReasons, record.targetChallengeReasons),
          value,
          operator
        )
      ),
      sortable: (record1, record2) =>
        ColumnUtils.sort(
          ALIGN_TYPES.STRING,
          BaseColumnArray.getChallengeReasonsDisplay(record1.challengeReasons, record1.targetChallengeReasons),
          BaseColumnArray.getChallengeReasonsDisplay(record2.challengeReasons, record2.targetChallengeReasons)
        ),
    });

    return columns;
  }

  getActionsColumnWidgets(canReview, canChallenge) {
    const buttonGroup = {
      type: 'buttongroup',
      onItem(event) {
        this.trigger('rowaction', {
          bubbles: true,
          row: this.cellInfo.record.originalData,
          action: {
            name: event.item.target,
          },
        });
      },
      onClick(event) {
        const action = event?.source?.target;
        if (action === COMMANDS.APPROVE || action === COMMANDS.REJECT) {
          this.trigger('rowaction', {
            bubbles: true,
            row: this.cellInfo.record.originalData,
            action: {
              name: action,
            },
          });
        }
      },
      items: [
        {
          cls: 'more-actions-button',
          menu: {
            icon: 'b-fa-caret-down',
            items: this.getTranslatedActions(canReview, canChallenge),
          },
          disabled: true,
        },
        {
          icon: 'b-fa-thumbs-up',
          disabled: true,
          target: COMMANDS.APPROVE,
          cls: BaseColumnArray.getApproveRejectButtonClass(canReview),
        },
        {
          icon: 'b-fa-thumbs-down',
          disabled: true,
          target: COMMANDS.REJECT,
          cls: BaseColumnArray.getApproveRejectButtonClass(canReview),
        },
      ],
      cls: 'actions-button-group',
    };

    return [buttonGroup];
  }

  getTranslatedActions(canReview, canChallenge) {
    const translatedActions = [];
    if (canReview) {
      [...REVIEW_COMMAND_TO_RENDER_CONDITION.keys()].forEach(commandName =>
        translatedActions.push(BaseColumnArray.buildAction(this.translateField('commands', commandName), commandName))
      );
    }
    if (canChallenge) {
      [...CHALLENGE_COMMAND_TO_RENDER_CONDITION.keys()].forEach(commandName =>
        translatedActions.push(BaseColumnArray.buildAction(this.translateField('commands', commandName), commandName))
      );
    }

    return translatedActions;
  }

  static buildAction(label, name) {
    return {
      text: label,
      target: name,
      hidden: true,
    };
  }

  static getApproveRejectButtonClass(canReview) {
    return canReview ? '' : 'hidden-actions';
  }

  static renderWidgets(accountRecord, widgets, canReview, cyclePresent) {
    const isGroupingRow = accountRecord.name == null;
    if (isGroupingRow) {
      return;
    }

    const buttonGroup = widgets[0];
    BaseColumnArray.renderMoreActionsWidget(accountRecord, buttonGroup.items[0], cyclePresent);

    if (canReview) {
      BaseColumnArray.renderApproveRejectWidgets(accountRecord, buttonGroup.items[1], buttonGroup.items[2]);
    }
  }

  /* eslint-disable no-param-reassign */
  static renderMoreActionsWidget(accountRecord, moreActionsWidget, cyclePresent) {
    if (moreActionsWidget?.menu?.items == null) {
      return;
    }

    let shouldDisableWidget = true;
    moreActionsWidget.menu.items.forEach(actionItem => {
      const renderConditionField =
        CHALLENGE_COMMAND_TO_RENDER_CONDITION.get(actionItem.target) ?? REVIEW_COMMAND_TO_RENDER_CONDITION.get(actionItem.target);
      const shouldRenderActionItem = accountRecord.originalData[renderConditionField];

      if (((actionItem.target === COMMANDS.ADD_TARGET || actionItem.target === COMMANDS.REMOVE_TARGET) && !cyclePresent)) {
        actionItem.hidden = true;
      } else {
        actionItem.hidden = !shouldRenderActionItem;
      }

      // Disable the More Actions dropdown when there are no available items to select
      shouldDisableWidget = shouldDisableWidget && actionItem.hidden;
    });
    moreActionsWidget.disabled = shouldDisableWidget;
  }

  static renderApproveRejectWidgets(accountRecord, approveWidget, rejectWidget) {
    if (approveWidget == null || rejectWidget == null) {
      return;
    }

    approveWidget.disabled = !accountRecord.originalData.shouldAllowApprove;
    rejectWidget.disabled = !accountRecord.originalData.shouldAllowReject;
  }
  /* eslint-enable no-param-reassign */

  getChallengeTypeDisplay(challengeType, targetChallengeType) {
    let challengeTypeDisplay;

    if (challengeType && targetChallengeType) {
      challengeTypeDisplay = `${this.translateField('challengeType', challengeType)}, ${this.translateField(
        'targetChallengeType',
        targetChallengeType
      )}`;
    } else if (challengeType) {
      challengeTypeDisplay = this.translateField('challengeType', challengeType);
    } else if (targetChallengeType) {
      challengeTypeDisplay = this.translateField('targetChallengeType', targetChallengeType);
    } else {
      challengeTypeDisplay = NULL_DISPLAY_STRING;
    }

    return challengeTypeDisplay;
  }

  getChallengeStatusDisplay(challengeType, challengeStatus, targetChallengeType, targetChallengeStatus) {
    let translatedStatusMarkup;
    const statusMessages = this.getChallengeStatusMessages(challengeType, challengeStatus, targetChallengeType, targetChallengeStatus);

    if (statusMessages.primary && statusMessages.secondary) {
      // Special LBT scenario with a Pending Remove Target, Rejected Remove Account
      // Status cell highlighting should be identical to Pending highlighting.
      const statusHighlight = (
        challengeType === CHALLENGE_TYPES.REMOVE_ACCOUNT &&
        targetChallengeType === CHALLENGE_TYPES.REMOVE_TARGET &&
        challengeStatus === CHALLENGE_STATUSES.REJECTED &&
        targetChallengeStatus === CHALLENGE_STATUSES.CHALLENGED 
      ) ? 'challenged' : 'approved';

      translatedStatusMarkup = BaseColumnArray.getMultiLineStatusMarkup(statusMessages.primary, statusMessages.secondary, statusHighlight);
    } else if (statusMessages.primary) {
      const statusToDisplay = BaseColumnArray.getStatusToDisplay(challengeStatus, targetChallengeStatus);
      translatedStatusMarkup = {
        tag: 'div',
        class: `${STATUS_CONTAINER_CLASS} ${statusToDisplay.toLowerCase()}`,
        children: [
          {
            tag: 'div',
            class: 'primary-text',
            text: this.translateField('challengeStatus', statusToDisplay),
          },
        ],
      };
    } else {
      translatedStatusMarkup = {
        tag: 'div',
        class: STATUS_CONTAINER_CLASS,
        text: NULL_DISPLAY_STRING,
      };
    }

    return translatedStatusMarkup;
  }

  getChallengeStatusMessages(challengeType, challengeStatus, targetChallengeType, targetChallengeStatus) {
    const statusMessages = {
      primary: null,
      secondary: null,
    };

    // Handles the display of special combinations of account and target-level challenge statuses.
    // If not a special scenario, the populated account/target-level challenge status is returned.
    if (
      challengeType === CHALLENGE_TYPES.ADD_ACCOUNT &&
      targetChallengeType === CHALLENGE_TYPES.ADD_TARGET &&
      challengeStatus === CHALLENGE_STATUSES.APPROVED &&
      targetChallengeStatus === CHALLENGE_STATUSES.REJECTED
    ) {
      statusMessages.primary = this.messages.addAccountApproved;
      statusMessages.secondary = this.messages.addTargetRejected;
    } else if (
      challengeType === CHALLENGE_TYPES.KEEP_ACCOUNT &&
      targetChallengeType === CHALLENGE_TYPES.ADD_TARGET &&
      challengeStatus === CHALLENGE_STATUSES.APPROVED &&
      targetChallengeStatus === CHALLENGE_STATUSES.REJECTED
    ) {
      statusMessages.primary = this.messages.keepAccountApproved;
      statusMessages.secondary = this.messages.addTargetRejected;
    } else if (
      challengeType === CHALLENGE_TYPES.REMOVE_ACCOUNT &&
      targetChallengeType === CHALLENGE_TYPES.REMOVE_TARGET &&
      challengeStatus === CHALLENGE_STATUSES.REJECTED &&
      targetChallengeStatus === CHALLENGE_STATUSES.APPROVED
    ) {
      statusMessages.primary = this.messages.removeTargetApproved;
      statusMessages.secondary = this.messages.removeAccountRejected;
    } else if (
      challengeType === CHALLENGE_TYPES.ADD_ACCOUNT &&
      targetChallengeType === CHALLENGE_TYPES.ADD_TARGET &&
      challengeStatus === CHALLENGE_STATUSES.APPROVED &&
      targetChallengeStatus === CHALLENGE_STATUSES.CHALLENGED 
    ) {
      statusMessages.primary = this.messages.addAccountApproved;
      statusMessages.secondary = this.messages.addTargetPending;
    } else if (
      challengeType === CHALLENGE_TYPES.KEEP_ACCOUNT &&
      targetChallengeType === CHALLENGE_TYPES.ADD_TARGET &&
      challengeStatus === CHALLENGE_STATUSES.APPROVED &&
      targetChallengeStatus === CHALLENGE_STATUSES.CHALLENGED 
    ) {
      statusMessages.primary = this.messages.keepAccountApproved;
      statusMessages.secondary = this.messages.addTargetPending;
    } else if (
      challengeType === CHALLENGE_TYPES.REMOVE_ACCOUNT &&
      targetChallengeType === CHALLENGE_TYPES.REMOVE_TARGET &&
      challengeStatus === CHALLENGE_STATUSES.REJECTED &&
      targetChallengeStatus === CHALLENGE_STATUSES.CHALLENGED 
    ) {
      statusMessages.primary = this.messages.removeTargetPending;
      statusMessages.secondary = this.messages.removeAccountRejected;
    } else {
      // Display Account Challenge's status; if null, then use Target Challenge's status instead.
      const statusToDisplay = BaseColumnArray.getStatusToDisplay(challengeStatus, targetChallengeStatus);
      if (statusToDisplay) {
        statusMessages.primary = this.translateField('challengeStatus', statusToDisplay);
      }
    }

    return statusMessages;
  }

  static getChallengeReasonsDisplay(challengeReasons, targetChallengeReasons) {
    if (!challengeReasons?.length && !targetChallengeReasons?.length) {
      return NULL_DISPLAY_STRING;
    }

    const reasonSet = new Set();
    challengeReasons?.forEach(reason => reasonSet.add(reason.label));
    targetChallengeReasons?.forEach(reason => reasonSet.add(reason.label));
    return [...reasonSet].join(', ');
  }

  static getStatusToDisplay(challengeStatus, targetChallengeStatus) {
    return challengeStatus ?? targetChallengeStatus;
  }

  static getMultiLineStatusMarkup(primaryMessage, secondaryMessage, statusHighlight) {
    return {
      tag: 'div',
      class: `${STATUS_CONTAINER_CLASS} ${statusHighlight}`,
      children: [
        {
          tag: 'div',
          class: 'primary-text',
          text: primaryMessage,
        },
        {
          tag: 'div',
          class: 'secondary-text',
          children: [
            {
              tag: 'span',
              text: '*',
            },
            {
              tag: 'span',
              text: secondaryMessage,
            },
          ],
        },
      ],
    };
  }

  translateField(fieldName, fieldValue) {
    return this.translator.getMessageForFieldAndValue(fieldName, fieldValue);
  }
}