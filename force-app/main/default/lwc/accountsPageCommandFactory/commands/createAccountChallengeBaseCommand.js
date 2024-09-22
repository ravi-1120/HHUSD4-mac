import { AlignError, NotImplementedError } from 'c/territoryFeedbackErrors';
import { publish, subscribe, unsubscribe } from 'lightning/messageService';
import FeedbackGoalEditorRecord from 'c/feedbackGoalEditorRecord';
import territoryFeedbackChannel from '@salesforce/messageChannel/TerritoryFeedback__c';
import AccountsPageBaseCommand from './accountsPageBaseCommand';

// Updating a command file without also touching the `accountsPageCommandFactory.js` file may result in Jenkins build failure.

export default class CreateAccountChallengeBaseCommand extends AccountsPageBaseCommand {
  constructor(territoryFeedbackService, accounts, territoryModelId, accountsMetadata, associatedAccounts) {
    super(territoryFeedbackService, accounts, territoryModelId, associatedAccounts);
    // To be used by any command that opens the goal editor modal (i.e. Edit Goals and Add Target commands)
    this.feedbackGoalEditorRecord = null;
    this.accountsMetadata = accountsMetadata;
  }

  get accountRecord() {
    return this.accounts[0];
  }

  // New commands need to implement: sendRequest and updateAccount functions, and potentially the following getters

  get shouldShowGoalEditorModal() {
    // Overridden in subclasses that require the modal
    return false;
  }

  get isAddTargetChallenge() {
    // Overridden in subclasses that need to make BulkFeedbackAddTargetsRequest
    return false;
  }

  get useDefaultGoals() {
    // Overridden in subclasses that need to render the goal editor modal with default goals instead of current values
    return false;
  }

  async execute() {
    if (this.shouldShowGoalEditorModal) {
      const feedbackGoalEditorRecord = await this.showGoalEditorModal();
      await this.setGoalEditorRecordAndExecute(feedbackGoalEditorRecord);
    } else {
      await this.beginChallengeExecution();
    }
    return [...this.accounts, ...this.associatedAccounts];
  }

  showGoalEditorModal() {
    // Prepares a promise so that caller can await the decision made by the user within the modal
    let resolveCallback;
    const modalDecisionPromise = new Promise(resolve => {
      resolveCallback = resolve;
    });

    const goalEditorModalSubscription = subscribe(this.messageContext, territoryFeedbackChannel, message => {
      if (message.destination === 'createAccountChallengeBaseCommand' && message.method === 'showGoalEditorModal') {
        // Modal may have returned null if user cancelled/closed - in this case, we want to resolve with undefined value
        let castedFeedbackGoalEditorRecord;
        if (message.feedbackGoalEditorRecord) {
          // The publish method will stringify objects, meaning the context of the original class is lost
          castedFeedbackGoalEditorRecord = Object.assign(new FeedbackGoalEditorRecord(), message.feedbackGoalEditorRecord);
          castedFeedbackGoalEditorRecord.channelGoalsToFeedbackGoalRecords();
        }
        resolveCallback(castedFeedbackGoalEditorRecord);
        unsubscribe(goalEditorModalSubscription);
      }
    });

    publish(this.messageContext, territoryFeedbackChannel, {
      destination: 'accountsPage',
      method: 'showGoalEditorModal',
      accountRecord: this.accountRecord,
      isAddTargetChallenge: this.isAddTargetChallenge,
      useDefaultGoals: this.useDefaultGoals,
    });

    return modalDecisionPromise;
  }

  async setGoalEditorRecordAndExecute(feedbackGoalEditorRecord) {
    // Short circuit evaluation of the command if record is falsy (e.g. if user cancelled/closed modal)
    if (!feedbackGoalEditorRecord) {
      return;
    }

    this.feedbackGoalEditorRecord = feedbackGoalEditorRecord;
    await this.beginChallengeExecution();
  }

  async beginChallengeExecution() {
    this.beginLoading();
    const response = await this.sendRequest();
    this.validateResponse(response);
    this.updateAccount(response);
    this.endLoading();
  }

  beginLoading() {
    this.showLoadingSpinner();
    this.closeAllModals();
  }

  async sendRequest() {
    // Implemented in subclasses
    throw new NotImplementedError('sendRequest() is not implemented in CreateAccountChallengeBaseCommand superclass');
  }

  validateResponse(response) {
    if (response.status !== 'SUCCESS') {
      throw new AlignError(response.message);
    }
  }

  // eslint-disable-next-line no-unused-vars
  updateAccount(response) {
    // Implemented in subclasses
    throw new NotImplementedError('updateAccount() is not implemented in CreateAccountChallengeBaseCommand superclass');
  }

  endLoading() {
    this.hideLoadingSpinner();
  }

  // Used for editGoalsCommand and addTargetCommand to update goals based on Align's response
  updateAccountGoals(channelGoalResponses) {
    channelGoalResponses?.forEach(updatedChannelGoalDetail => {
      let channel = this.accountRecord.goalDetails.find(channelDetail => channelDetail.planChannelId === updatedChannelGoalDetail.planChannelId);
      // If a particular channel goal is new to an account, then its planChannelId will not have been set yet
      let channelIndex;
      if (channel === undefined) {
        channelIndex = this.findChannelMetadataIndex(updatedChannelGoalDetail);
        // Order of channel metadata is guaranteed to match order of actual channel data
        channel = this.accountRecord.goalDetails[channelIndex];
        channel.planChannelId = updatedChannelGoalDetail.planChannelId;
      }
      channel.feedbackChannelGoal = updatedChannelGoalDetail.feedbackChannelGoal ?? channel.feedbackChannelGoal;
      channel.productGoals = channel.productGoals ?? [];

      updatedChannelGoalDetail.productGoalResponses?.forEach(updatedProductGoalDetail => {
        let product = channel.productGoals.find(productGoal => productGoal.planProductId === updatedProductGoalDetail.planProductId);
        // If a particular product goal is new to an account, then its planProductId will not have been set yet
        if (product === undefined) {
          channelIndex = channelIndex ?? this.findChannelMetadataIndex(updatedChannelGoalDetail);
          const productIndex = this.findProductMetadataIndex(channelIndex, updatedProductGoalDetail);
          // Order of product metadata is guaranteed to match order of actual product data
          product = channel.productGoals[productIndex];
          product.planProductId = updatedProductGoalDetail.planProductId;
        }
        product.feedbackProductGoal = updatedProductGoalDetail.feedbackProductGoal ?? product.feedbackProductGoal;
      });
    });
  }

  findChannelMetadataIndex(channelGoalDetail) {
    return this.accountsMetadata.goalMetadata.findIndex(goalMetadata => goalMetadata.channelId === channelGoalDetail.cycleChannelId);
  }

  findProductMetadataIndex(channelIndex, productGoalDetail) {
    return this.accountsMetadata.goalMetadata[channelIndex].products.findIndex(
      goalMetadata => goalMetadata.productId === productGoalDetail.cycleProductId
    );
  }
}