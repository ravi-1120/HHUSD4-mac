import { getService } from 'c/veevaServiceFactory';
import { ALIGN_TYPES, CHALLENGE_STATUSES, CHALLENGE_TYPES, NULL_DISPLAY_STRING } from 'c/territoryFeedbackConstants';
import ColumnUtils from './columnUtils';

// Changing this file without touching the parent `FeedbackAccountsDatatable` JS or HTML could result in build failure.

export default class GoalColumnArray {
  constructor(accountRecordFieldTranslator, accountsTableDetailsRecord, messages) {
    this.translator = accountRecordFieldTranslator;
    this.accountsTableDetailsRecord = accountsTableDetailsRecord;
    this.messages = messages;
    this.columns = this.buildColumns();
  }

  static async createColumns(accountRecordFieldTranslator, accountsTableDetailsRecord) {
    const messages = await this.getVeevaMessages();

    return new GoalColumnArray(accountRecordFieldTranslator, accountsTableDetailsRecord, messages).columns;
  }

  static async getVeevaMessages() {
    const messageSvc = getService('messageSvc');

    return messageSvc
      .createMessageRequest()
      .addRequest('GOAL', 'Feedback', 'Goal', 'goal')
      .sendRequest();
  }

  buildColumns() {
    const columns = [];

    this.accountsTableDetailsRecord.goalMetadata.forEach((channelMetadata, channelIndex) => {
      const parentColumn = {
        text: channelMetadata.channelLabel,
        align: 'center',
      };
      ColumnUtils.addParentColumnToArray(parentColumn, columns);

      // Create a child column for the channel goal
      ColumnUtils.addChildColumnToParent(parentColumn, {
        id: channelMetadata.channelId,
        text: this.messages.goal,
        cellCls: 'goal channel-goal',
        renderer: ({ record }) => this.getChannelGoalDisplay(record.originalData, channelIndex, channelMetadata),

        ...ColumnUtils.getFilterableColumnProperties(ALIGN_TYPES.NUMBER, this.translator, ({ record, value, operator }) =>
          ColumnUtils.filter(ALIGN_TYPES.NUMBER, this.getChannelGoalValues(record.originalData, channelIndex, channelMetadata)?.goal, value, operator)
        ),

        sortable: (record1, record2) =>
          ColumnUtils.sort(
            ALIGN_TYPES.NUMBER,
            this.getChannelGoalValues(record1.originalData, channelIndex, channelMetadata)?.goal,
            this.getChannelGoalValues(record2.originalData, channelIndex, channelMetadata)?.goal
          ),
      });

      // Then create a child column for each product within the channel
      channelMetadata.products.forEach((product, productIndex) => {
        ColumnUtils.addChildColumnToParent(parentColumn, {
          id: product.productId,
          text: product.productLabel,
          cls: 'product-goal-column',
          cellCls: 'goal product-goal',
          renderer: ({ record }) => this.getProductGoalDisplay(record.originalData, channelIndex, productIndex, channelMetadata),

          ...ColumnUtils.getFilterableColumnProperties(ALIGN_TYPES.NUMBER, this.translator, ({ record, value, operator }) =>
            ColumnUtils.filter(ALIGN_TYPES.NUMBER, this.getProductGoalValues(record.originalData, channelIndex, productIndex, channelMetadata)?.goal, value, operator)
          ),

          sortable: (record1, record2) =>
            ColumnUtils.sort(
              ALIGN_TYPES.NUMBER,
              this.getProductGoalValues(record1.originalData, channelIndex, productIndex, channelMetadata)?.goal,
              this.getProductGoalValues(record2.originalData, channelIndex, productIndex, channelMetadata)?.goal
            ),
        });
      });
    });

    return columns;
  }

  getChannelGoalDisplay(accountRecord, channelIndex, channelMetadata) {
    const channelGoalDetail = accountRecord.goalDetails?.[channelIndex];

    return this.getGoalDisplay(accountRecord, channelGoalDetail?.feedbackChannelGoal, channelGoalDetail?.channelGoal, channelMetadata);
  }

  getProductGoalDisplay(accountRecord, channelIndex, productIndex, channelMetadata) {
    const productGoalDetail = accountRecord.goalDetails?.[channelIndex]?.productGoals?.[productIndex];

    return this.getGoalDisplay(accountRecord, productGoalDetail?.feedbackProductGoal, productGoalDetail?.productGoal, channelMetadata);
  }

  getChannelGoalValues(accountRecord, channelIndex, channelMetadata) {
    const channelGoalDetail = accountRecord.goalDetails?.[channelIndex];

    return this.getGoalValues(accountRecord, channelGoalDetail?.feedbackChannelGoal, channelGoalDetail?.channelGoal, channelMetadata);
  }

  getProductGoalValues(accountRecord, channelIndex, productIndex, channelMetadata) {
    const productGoalDetail = accountRecord.goalDetails?.[channelIndex]?.productGoals?.[productIndex];

    return this.getGoalValues(accountRecord, productGoalDetail?.feedbackProductGoal, productGoalDetail?.productGoal, channelMetadata);
  }

  getGoalDisplay(accountRecord, feedbackGoal, goal, channelMetadata) {
    const { goal: goalToDisplay, difference } = this.getGoalValues(accountRecord, feedbackGoal, goal, channelMetadata);
    let cellContents;
    if (difference) {
      cellContents = {
        tag: 'div',
        children: [
          {
            tag: 'span',
            class: 'feedback-goal-text',
            text: this.translator.localizeField(ALIGN_TYPES.NUMBER, goalToDisplay),
          },
          {
            tag: 'span',
            class: 'goal-text',
            children: [
              {
                tag: 'span',
                text: '(',
              },
              {
                tag: 'i',
                class: `b-fa b-fa-caret-${difference > 0 ? 'up positive' : 'down negative'}`,
              },
              {
                tag: 'span',
                text: `${this.translator.localizeField(ALIGN_TYPES.NUMBER, Math.abs(difference))})`,
              },
            ],
          },
        ],
      };
    } else if (goalToDisplay) {
      cellContents = { html: this.translator.localizeField(ALIGN_TYPES.NUMBER, goal) };
    } else {
      cellContents = { html: NULL_DISPLAY_STRING };
    }

    return cellContents;
  }

  getGoalValues(accountRecord, feedbackGoal, goal, channelMetadata) {
    const goalValues = {
      goal: null,
      difference: null,
    };

    if (!accountRecord.target || (accountRecord.location && channelMetadata.channelObject !== 'Call2_vod__c')) {
      return goalValues;
    }

    goalValues.difference = this.getGoalDifference(accountRecord, feedbackGoal, goal);

    if (goalValues.difference) {
      goalValues.goal = feedbackGoal;
    } else if (goal) {
      goalValues.goal = goal;
    }

    return goalValues;
  }

  // eslint-disable-next-line class-methods-use-this
  getGoalDifference(accountRecord, feedbackGoal, goal) {
    if (feedbackGoal == null || !accountRecord.shouldUseFeedbackGoalIfAvailable) {
      return null;
    }

    // If account has an Add Target challenge that isn't rejected, we want to display the difference as the feedbackGoal.
    // The reason for this is that after an Add Target challenge is made, the Account's feedbackGoal necessarily equals the goal.
    // However, before this challenge, both feedbackGoal and goal are 0. Thus, the PM would like to represent the fact that the
    // feedbackGoal and goal were recently increased as a result of the Add Target challenge.
    const hasAddTargetChallenge =
      accountRecord.targetChallengeType === CHALLENGE_TYPES.ADD_TARGET && accountRecord.targetChallengeStatus !== CHALLENGE_STATUSES.REJECTED;
    const difference = hasAddTargetChallenge ? feedbackGoal : feedbackGoal - (goal ?? 0);

    return difference !== 0 ? difference : null;
  }
}