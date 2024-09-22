import { LightningElement, api } from 'lwc';
import { getService } from 'c/veevaServiceFactory';
import { COLUMN_IDS, OPERATOR } from 'c/feedbackAccountsDatatable';
import { ACCOUNT_CHANGE, CHALLENGE_STATUSES } from 'c/territoryFeedbackConstants';

const METRIC_IDS = {
  TOTAL_CHALLENGES: 'totalChallenges',
  PENDING_CHALLENGES: 'pendingChallenges',
  TARGET_ACCOUNTS: 'targetAccounts',
  PERSON_ACCOUNTS: 'personAccounts',
  BUSINESS_ACCOUNTS: 'businessAccounts',
  ADDED_ACCOUNTS: 'addedAccounts',
  DROPPED_ACCOUNTS: 'droppedAccounts',
};

const METRIC_IDS_TO_FILTER_ARGS = new Map([
  [METRIC_IDS.TOTAL_CHALLENGES, { columnId: COLUMN_IDS.HAS_CHALLENGE, filterValue: true, filterOperator: OPERATOR.CONTAINS }],
  [
    METRIC_IDS.PENDING_CHALLENGES,
    { columnId: COLUMN_IDS.CHALLENGE_STATUS, filterValue: CHALLENGE_STATUSES.CHALLENGED, filterOperator: OPERATOR.CONTAINS },
  ],
  [METRIC_IDS.TARGET_ACCOUNTS, { columnId: COLUMN_IDS.TARGET, filterValue: true, filterOperator: OPERATOR.CONTAINS }],
  [METRIC_IDS.PERSON_ACCOUNTS, { columnId: COLUMN_IDS.PERSON, filterValue: true, filterOperator: OPERATOR.CONTAINS }],
  [METRIC_IDS.BUSINESS_ACCOUNTS, { columnId: COLUMN_IDS.PERSON, filterValue: false, filterOperator: OPERATOR.CONTAINS }],
  [METRIC_IDS.ADDED_ACCOUNTS, { columnId: COLUMN_IDS.CHANGE, filterValue: ACCOUNT_CHANGE.ADDED, filterOperator: OPERATOR.CONTAINS }],
  [METRIC_IDS.DROPPED_ACCOUNTS, { columnId: COLUMN_IDS.CHANGE, filterValue: ACCOUNT_CHANGE.DROPPED, filterOperator: OPERATOR.CONTAINS }],
]);
export default class FeedbackTerritoryModelMetrics extends LightningElement {
  @api section;

  @api
  get territoryModelDetails() {
    return this._territoryModelDetails;
  }

  set territoryModelDetails(details) {
    this._territoryModelDetails = details;
    this.populateRows();
  }

  rows = [];
  messages;

  get hasProductGoals() {
    return this.territoryModelDetails.totalGoals?.some(channelGoal => channelGoal.products.length > 0);
  }

  async connectedCallback() {
    await this.fetchVeevaMessages();
    this.populateRows();
  }

  async fetchVeevaMessages() {
    this.messageService = getService('messageSvc');
    this.messages = await this.messageService
      .createMessageRequest()
      .addRequest('TOTAL', 'Feedback', 'Total', 'total')
      .addRequest('PENDING', 'Feedback', 'Pending', 'pending')
      .addRequest('TARGETS', 'Feedback', 'Targets', 'targets')
      .addRequest('PERSON', 'Common', 'Person', 'person')
      .addRequest('BUSINESS', 'Common', 'Business', 'business')
      .addRequest('ADDS', 'Feedback', 'Adds', 'adds')
      .addRequest('DROPS', 'Feedback', 'Drops', 'drops')
      .sendRequest();
  }

  populateRows() {
    if (this.territoryModelDetails && this.messages) {
      this.rows = this.formatDataForTemplate(this.getData());
    }
  }

  getData() {
    let rows;
    switch (this.section) {
      case 'challenges':
        rows = this.getChallengesData();
        break;
      case 'accounts':
        rows = this.getAccountsData();
        break;
      case 'goals':
        rows = this.getGoalsData();
        break;
      default:
        rows = [];
    }

    return rows;
  }

  formatDataForTemplate(rows) {
    const styledRows = this.applyStyling(rows);

    // Need to set some unique key on each row, since LWC will not let you use an iterator's `index` property as a key.
    return styledRows.map((row, index) => ({ items: row, key: index }));
  }

  applyStyling(rows) {
    const styledRows = rows.map(row =>
      row.map(metric => ({
        ...metric,
        labelCSS: `slds-text-title label ${metric.labelCSS}`,
      }))
    );

    return styledRows;
  }

  getChallengesData() {
    const challengesRow = [];
    challengesRow.push(this.getMetricConfig(this.messages.total, this.territoryModelDetails.totalChallengeAccounts, METRIC_IDS.TOTAL_CHALLENGES));
    challengesRow.push(
      this.getMetricConfig(this.messages.pending, this.territoryModelDetails.pendingChallengeAccounts, METRIC_IDS.PENDING_CHALLENGES)
    );

    return [challengesRow];
  }

  getAccountsData() {
    const accountsTypeRow = [];
    if (this.territoryModelDetails.targetingEnabled) {
      accountsTypeRow.push(this.getMetricConfig(this.messages.targets, this.territoryModelDetails.targetAccounts, METRIC_IDS.TARGET_ACCOUNTS));
    }
    accountsTypeRow.push(this.getMetricConfig(this.messages.person, this.territoryModelDetails.personAccounts, METRIC_IDS.PERSON_ACCOUNTS));
    accountsTypeRow.push(this.getMetricConfig(this.messages.business, this.territoryModelDetails.businessAccounts, METRIC_IDS.BUSINESS_ACCOUNTS));

    const addsDropsRow = [];
    addsDropsRow.push(this.getMetricConfig(this.messages.adds, this.territoryModelDetails.addedAccounts, METRIC_IDS.ADDED_ACCOUNTS));
    addsDropsRow.push(this.getMetricConfig(this.messages.drops, this.territoryModelDetails.droppedAccounts, METRIC_IDS.DROPPED_ACCOUNTS));

    return [accountsTypeRow, addsDropsRow];
  }

  getGoalsData() {
    const channelRows = [];
    if (!this.territoryModelDetails.targetingEnabled) {
      return channelRows;
    }

    let channelRow = [];
    this.territoryModelDetails.totalGoals.forEach(channelGoal => {
      if (!channelGoal.products.length) {
        // If there are no Products, then just push the Channel into the current row and let the next iteration decide whether to create a new row or not.
        channelRow.push(this.getGoalConfig(channelGoal.label, channelGoal.totalGoal, channelGoal.channelOrProductId, true));
      } else {
        // If this Channel has Products, it needs to be its own row.
        // First, if the previous row was 1+ Channels with 0 Products, push that row before creating a new one.
        if (channelRow.length > 0) {
          channelRows.push(channelRow);
          channelRow = [];
        }

        // Then create and push a new row with just this Channel and its Products.
        channelRow.push(this.getGoalConfig(channelGoal.label, channelGoal.totalGoal, channelGoal.channelOrProductId, true));
        channelGoal.products.forEach(productGoal => {
          channelRow.push(this.getGoalConfig(productGoal.label, productGoal.totalGoal, productGoal.channelOrProductId, false));
        });
        channelRows.push(channelRow);
        channelRow = [];
      }
    });

    // Finally, if the last row was Channels with no Products, then it hasn't been pushed yet. So we need to go ahead and push it.
    if (channelRow.length > 0) {
      channelRows.push(channelRow);
    }

    return channelRows;
  }

  getMetricConfig(label, value, id) {
    // For some reason, the MyInsights API defines the goal values as strings instead of numbers
    const intValue = parseInt(value, 10);
    return {
      label,
      value: intValue,
      id,
      disabled: intValue === 0,
      isNumeric: true,
    };
  }

  getGoalConfig(label, value, id, isChannel) {
    return {
      ...this.getMetricConfig(label, value, id),
      labelCSS: isChannel ? 'channel-label' : '',
    };
  }

  handleMetricClick(event) {
    const metricId = event.currentTarget.value;
    this.dispatchEvent(
      new CustomEvent('updatefilters', {
        detail: getUpdateFiltersDetailsForMetric(metricId),
      })
    );
  }

  handleUpdateFiltersEvent({ detail }) {
    this.dispatchEvent(new CustomEvent('updatefilters', { detail }));
  }
}

function getUpdateFiltersDetailsForMetric(metricId) {
  return (
    METRIC_IDS_TO_FILTER_ARGS.get(metricId) ?? {
      columnId: metricId,
      filterValue: 0,
      filterOperator: OPERATOR.GREATER_THAN,
    }
  );
}