import { LightningElement, api, track } from 'lwc';
import FeedbackGoalEditorRecord from 'c/feedbackGoalEditorRecord';
import { getService } from 'c/veevaServiceFactory';

export default class TerritoryFeedbackGoalEditor extends LightningElement {
  @api accountRecord;
  @api goalMetadata;
  @api isAddTargetChallenge;
  @api useDefaultGoals;

  @track channelGoals;
  editGoalsRecord;

  @api
  get feedbackGoalEditorRecord() {
    return this.editGoalsRecord;
  }

  async connectedCallback() {
    await this.loadLabels();
    this.combineDataWithMetadata();
  }

  async loadLabels() {
    const messageService = getService('messageSvc');
    this.goalMessage = await messageService.getMessageWithDefault('GOAL', 'Feedback', 'Goal');
  }

  combineDataWithMetadata() {
    this.editGoalsRecord = new FeedbackGoalEditorRecord(this.accountRecord, this.goalMetadata, this.useDefaultGoals);
    this.refreshData();
  }

  handleProductCounterChange(event) {
    const channelGoal = this.editGoalsRecord.getChannelGoal(event.target.dataset.channelId);
    const productGoal = channelGoal.getProductGoal(event.target.dataset.productId);
    this.updateProductGoal(productGoal, channelGoal, event.detail.newValue);
    this.refreshData();
  }

  updateProductGoal(productGoal, channelGoal, newValue) {
    // Set the counter's value to the new value if it's valid
    productGoal.feedbackGoal = newValue;

    // Ensures the parent/channel counter is always greater than or equal to each of its child/product counters
    if (channelGoal.feedbackGoal < newValue) {
      this.updateChannelGoal(channelGoal, newValue);
    }
  }

  handleChannelCounterChange(event) {
    const channelGoal = this.editGoalsRecord.getChannelGoal(event.target.dataset.channelId);
    this.updateChannelGoal(channelGoal, event.detail.newValue);
    this.refreshData();
  }

  updateChannelGoal(channelGoal, newValue) {
    // Set the counter's value to the new value
    channelGoal.feedbackGoal = newValue;

    // Ensures the parent/channel counter is always greater than or equal to each of its child/product counters
    channelGoal.productGoals.forEach(productGoal => {
      if (productGoal.feedbackGoal > newValue) {
        this.updateProductGoal(productGoal, channelGoal, newValue);
      }
    });
  }

  refreshData() {
    this.channelGoals = [...this.editGoalsRecord.channelGoals];
  }
}