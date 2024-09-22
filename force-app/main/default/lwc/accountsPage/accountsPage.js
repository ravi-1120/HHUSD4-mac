import { api, track, wire } from 'lwc';
import TerritoryModelRecord from 'c/territoryModelRecord';
import TerritoryFeedbackConstants from 'c/territoryFeedbackConstants';
import TerritoryFeedbackService from 'c/territoryFeedbackService';
import getTerritoryFeedbackSettings from '@salesforce/apex/TerritoryFeedbackSettings.getTerritoryFeedbackSettings';
import AccountsPageCommandFactory, { COMMANDS } from 'c/accountsPageCommandFactory';
import AccountsTableDetailsRecord from 'c/accountsTableDetailsRecord';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import { MessageContext, subscribe, unsubscribe, publish } from 'lightning/messageService';
import territoryFeedbackChannel from '@salesforce/messageChannel/TerritoryFeedback__c';
import TerritoryFeedbackBasePage from 'c/territoryFeedbackBasePage';
import FeedbackLocalDataService from 'c/feedbackLocalDataService';
import RepLevelTerritoryModelRecord from 'c/repLevelTerritoryModelRecord';
import TerritoryModelCommandFactory, { AccountsPageAdapter } from 'c/territoryModelCommandFactory';
import getTerritoryFeedbackReportId from '@salesforce/apex/FeedbackMyInsightsService.getTerritoryFeedbackReportId';
import LANG from '@salesforce/i18n/lang';

const PADDING_OFFSET = 32;

export default class AccountsPage extends TerritoryFeedbackBasePage {
  @api selectedTerritoryModelId;
  @api selectedAccountsFilter;
  @api nextScreenName;
  @api forceDisplayFieldPlansPage;
  @api historyId;

  @track tableMetadata;
  @track error;

  @wire(MessageContext)
  messageContext;

  pageName = 'Territory Feedback - Accounts Page';
  pageId = TerritoryFeedbackConstants.ACCOUNTS;
  data = [];
  dataStore;
  messageService;
  veevaMessagesLoaded = false;
  isPanelOpen;
  loading = true;
  isInitialized = false;
  hasTableRendered = false;
  displayGoalEditorModal = false;
  goalEditorAccountRecord;
  goalEditorHeader;
  goalEditorIsAddTargetChallenge;
  goalEditorUseDefaultGoals;
  displayOutsideTerritorySearchModal;
  inTerritoryAccountsById;
  numSelectedRecords = 0;
  numFilters = 0;
  territoryModel;

  get isPageReady() {
    return this.hasTableRendered;
  }

  get accountsDatatable() {
    return this.template.querySelector('c-feedback-accounts-datatable');
  }

  get selectedRows() {
    return this.accountsDatatable?.selectedAccounts ?? [];
  }

  set selectedRows(selectedAccounts) {
    if (this.accountsDatatable?.selectedAccounts) {
      this.accountsDatatable.selectedAccounts = selectedAccounts;
    }
  }

  get pageHeaderTitle() {
    if (!this.tableMetadata) {
      return null;
    }
    const rosterMemberName = this.tableMetadata.rosterMembers.length ? this.tableMetadata.rosterMembers[0].name : `<${this.messages.vacant}>`;
    return `${rosterMemberName} (${this.tableMetadata.name})`;
  }

  get sidePanelClass() {
    return this.isPanelOpen ? 'slds-p-left_medium' : 'slds-hide';
  }

  get accountsTableSize() {
    if (!this.isPanelOpen) {
      return '12';
    }

    return this.shouldRenderMyInsights ? '6' : '9';
  }

  get infoPanelSize() {
    return this.shouldRenderMyInsights ? '6' : '3';
  }

  get shouldRenderMyInsights() {
    return this.htmlReportId;
  }

  get fieldPlanInfoPanel() {
    return this.template.querySelector('c-field-plan-info-panel');
  }

  get selectedAccountIds() {
    return this.selectedRows.map(row => row.id);
  }

  get territoryFeedbackService() {
    return this.territoryFeedbackSvc;
  }

  get hidePageContent() {
    return this.loading || this.error;
  }

  get containerClass() {
    return this.hidePageContent ? 'slds-hide' : 'slds-show';
  }

  get territoryModelActionsMenuClass() {
    const baseClasses = 'slds-p-left_x-small slds-p-top_x-small';
    const shouldHideMenu = this.territoryModelActionsMenu?.isEmpty ?? true;

    return `${baseClasses} ${shouldHideMenu ? 'slds-hide' : 'slds-show'}`;
  }

  get territoryModelActionsMenu() {
    return this.template.querySelector('c-feedback-territory-model-actions-menu');
  }

  get errorHandler() {
    return this.template.querySelector('c-territory-feedback-error-handler');
  }

  get allAccounts() {
    return this.tableMetadata?.accounts;
  }

  get isTableRendering() {
    return !this.hasTableRendered;
  }

  get isTableUnfiltered() {
    return !this.numFilters;
  }

  get areNoSelectedRecords() {
    return !this.numSelectedRecords;
  }

  get territoryFeedbackModal() {
    return this.template.querySelector('c-territory-feedback-modal');
  }

  get territoryModelActionCallback() {
    return this.territoryFeedbackModal.confirmationCallback;
  }

  set territoryModelActionCallback(confirmationCallback) {
    this.territoryFeedbackModal.confirmationCallback = confirmationCallback;
  }

  get translatedActionsForTerritoryModel() {
    const actions = this.territoryModel?.availableLifecycleActions.map(lifecycleStateAction => {
      if (lifecycleStateAction.name === TerritoryModelRecord.FEEDBACK_STATE) {
        return {
          label: this.messages.returnToRosterMember,
          name: 'return_to_roster_member',
          displayIndex: 3,
        };
      }
      return {
        label: lifecycleStateAction.label,
        name: lifecycleStateAction.name,
        displayIndex: 2,
      };
    });

    if (this.territoryModel?.canReviewPendingChallenges) {
      actions.push({ label: this.messages.approvePendingChallenges, name: 'approve_pending_challenges', displayIndex: 0 });
      actions.push({ label: this.messages.rejectPendingChallenges, name: 'reject_pending_challenges', displayIndex: 1 });
    }

    return actions.sort(sortTerritoryModelActions);
  }

  renderedCallback() {
    super.renderedCallback();
    this.updateTablePanelContainerHeight();
  }

  // Dynamically updates the CSS variable so that the table and info panel do not grow beyond the viewport. Instead, nested components will have their own scrollbar.
  updateTablePanelContainerHeight() {
    const topOffset = this.template.querySelector('.table-panel-container')?.getBoundingClientRect().top;
    if (topOffset != null) {
      const tableTopOffsetAmount = PADDING_OFFSET + topOffset;
      this.template.querySelector('div.page-container').style.setProperty('--vertical-offset', `${tableTopOffsetAmount}px`);
    }
  }

  async connectedCallback() {
    super.connectedCallback();
    this.subscribeToMessageChannel();
  }

  disconnectedCallback() {
    super.disconnectedCallback();
    this.unsubscribeFromMessageChannel();
    
    if (this.feedbackLocalDataService?.territoryModelDetailsStoreId) {
      this.dataStore.remove(this.feedbackLocalDataService.territoryModelDetailsStoreId);
      this.feedbackLocalDataService.territoryModelDetailsStoreId = null;
    }
  }

  subscribeToMessageChannel() {
    if (!this.subscription) {
      this.subscription = subscribe(this.messageContext, territoryFeedbackChannel, message => this.handleMessage(message));
    }
  }

  unsubscribeFromMessageChannel() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  @wire(getTerritoryFeedbackSettings)
  getTerritoryModelDetails({ error, data }) {
    this.processWiredMethodsThenFetch(error, data, 'territoryFeedbackSettings');
  }

  processWiredMethodsThenFetch(error, data, propertyName) {
    if (data) {
      this[propertyName] = data;
      if (this.territoryFeedbackSettings) {
        this.territoryFeedbackSvc = new TerritoryFeedbackService(
          this.territoryFeedbackSettings.alignServer,
          this.territoryFeedbackSettings.alignVersion
        );
        this.loadTable();
      }
    } else if (error) {
      this.handleError(error);
    }
  }

  async loadTable() {
    await this.instantiateMessageService();
    this.dataStore = getService(SERVICES.BYPASS_PROXY_DATA_STORE);

    try {
      this.isInitialized = false;

      this.tableMetadata = new AccountsTableDetailsRecord(
        await this.territoryFeedbackService.getTerritoryModelDetails(this.selectedTerritoryModelId)
      );
      this.inTerritoryAccountsById = new Map(this.tableMetadata.accounts.map(account => [account.id, account]));

      this.feedbackLocalDataService = new FeedbackLocalDataService(this.tableMetadata);
      const terrModelDetails = this.feedbackLocalDataService.territoryModelDetails;
      this.feedbackLocalDataService.territoryModelDetailsStoreId = this.dataStore.put(terrModelDetails);

      this.territoryModel = new RepLevelTerritoryModelRecord(this.tableMetadata, null);
      this.territoryModel.numPendingChallenges = terrModelDetails.pendingChallengeAccounts;

      this.htmlReportId = await this.getHTMLReportId();

      this.loading = false;
      this.isInitialized = true;
    } catch (serviceError) {
      this.handleError(serviceError);
    }
  }

  async instantiateMessageService() {
    this.messageService = getService(SERVICES.MESSAGE);

    this.messages = await this.messageService
      .createMessageRequest()
      .addRequest('ALL_CHALLENGES', 'Feedback', 'All Challenges', 'allChallenges')
      .addRequest('TARGETS', 'Feedback', 'Targets', 'targets')
      .addRequest('PENDING_CHALLENGES', 'Feedback', 'Pending Challenges', 'pendingChallenges')
      .addRequest('FIELD_PLANS', 'Feedback', 'Field Plans', 'fieldPlans')
      .addRequest('VACANT', 'Feedback', 'vacant', 'vacant')
      .addRequest('SEARCH', 'Common', 'Search', 'search')
      .addRequest('PERSON_ACCOUNTS', 'Common', 'Person Accounts', 'personAccounts')
      .addRequest('BUSINESS_ACCOUNTS', 'Common', 'Business Accounts', 'businessAccounts')
      .addRequest('CHALLENGE_TYPE', 'Feedback', 'Challenge Type', 'challenge')
      .addRequest('ACCOUNT_NAME', 'Account', 'Account Name', 'accountName')
      .addRequest('STATUS', 'Common', 'Status', 'status')
      .addRequest('REASONS', 'Feedback', 'Reason(s)', 'reasons')
      .addRequest('APPROVE', 'Common', 'Approve', 'approve')
      .addRequest('REJECT', 'Common', 'Reject', 'reject')
      .addRequest('SEGMENT', 'Feedback', 'Segment: {0}', 'segment')
      .addRequest('EDIT_GOALS', 'Feedback', 'Edit Goals', 'editGoals')
      .addRequest('ADD_TARGET', 'Feedback', 'Add as Target', 'addTarget')
      .addRequest('ADD_ACCOUNTS', 'Feedback', 'Add Accounts', 'addAccounts')
      .addRequest('CLEAR_FILTERS', 'Common', 'Clear Filters', 'clearFilters')
      .addRequest('SUMMARY', 'Feedback', 'Summary', 'summary')
      .addRequest('RETURN_TO_ROSTER_MEMBER', 'Feedback', 'Return to Roster Member', 'returnToRosterMember')
      .addRequest('APPROVE_PENDING_CHALLENGES', 'Feedback', 'Approve Pending Challenges', 'approvePendingChallenges')
      .addRequest('REJECT_PENDING_CHALLENGES', 'Feedback', 'Reject Pending Challenges', 'rejectPendingChallenges')
      .sendRequest();

    this.veevaMessagesLoaded = true;
  }

  async getHTMLReportId() {
    if (!this.tableMetadata.htmlReportExternalId || !this.tableMetadata.htmlReportHeight) {
      return null;
    }

    let htmlReportId;
    try {
      htmlReportId = await getTerritoryFeedbackReportId({ externalId: this.tableMetadata.htmlReportExternalId });
    } catch (error) {
      this.handleError(error);
    }

    return htmlReportId;
  }

  // Sets hasTableRendered only once, which is important for tracking initial page load time for VeevaMainPage
  handleRenderRows() {
    if (!this.hasTableRendered) {
      this.hasTableRendered = true;
    }
  }

  handleRowAction(event) {
    const { row, associatedRows } = event.detail;
    const action = event.detail.action.name;

    this.executeChallengesCommand(action, [row], associatedRows);
  }

  handleSelectionChange(event) {
    this.numSelectedRecords = event.detail.numSelected;
  }

  handleFilterUpdate(event) {
    this.numFilters = event.detail.numFilters;
  }

  handleClearFilters() {
    this.accountsDatatable?.resetFiltersAndSort();
  }

  handleApproveChallenges() {
    this.executeChallengesCommand(
      COMMANDS.APPROVE,
      this.selectedRows.filter(account => account.shouldAllowApprove)
    );
  }

  handleRejectChallenges() {
    this.executeChallengesCommand(
      COMMANDS.REJECT,
      this.selectedRows.filter(account => account.shouldAllowReject)
    );
  }

  handleFieldPlanNavigation() {
    this.forceDisplayFieldPlansPage = true;
    this.goToNextScreen(TerritoryFeedbackConstants.FIELD_PLANS);
  }

  handleTerritoriesNavigation() {
    this.goToNextScreen(TerritoryFeedbackConstants.TERRITORIES);
  }

  handleInfoEvent() {
    if (!this.isPanelOpen) {
      this.showInfoPanel();
    } else {
      this.closeInfoPanel();
    }
  }

  handlePanelCloseEvent() {
    this.closeInfoPanel();
  }

  showInfoPanel() {
    if (this.fieldPlanInfoPanel) {
      // Only render start and end dates when targeting is enabled (i.e. when `cyclePresent` is true)
      const startDate = this.tableMetadata.cyclePresent ? this.tableMetadata.startDate : null;
      const endDate = this.tableMetadata.cyclePresent ? this.tableMetadata.endDate : null;
      this.fieldPlanInfoPanel.populateInfoPanel({
        header: this.tableMetadata.name,
        dueDate: this.tableMetadata.dueDate,
        instructions: this.tableMetadata.instructions,
        geoAdded: this.tableMetadata.geoAdded,
        geoDropped: this.tableMetadata.geoDropped,
        startDate,
        endDate,
      });

      this.isPanelOpen = true;
    }
  }

  closeInfoPanel() {
    this.isPanelOpen = false;
  }

  async executeChallengesCommand(commandName, accounts, associatedAccounts) {
    try {
      const associatedAccountRows = [];
      if (this.tableMetadata.locationBasedTargeting) {
        associatedAccountRows.push(...this.getAssociatedAccountRows(accounts));

        // Add associated accounts not already in the table to command processing
        if (associatedAccounts) {
          associatedAccountRows.push(...associatedAccounts);
        }
      }
      
      const accountRecords = await AccountsPageCommandFactory.getInstance(
        this.territoryFeedbackService,
        commandName,
        accounts,
        this.selectedTerritoryModelId,
        this.tableMetadata,
        associatedAccountRows
      )?.execute();

      this.unselectRows();
      this.refreshAccountRecords(accountRecords);

      // Keep the territory model pending challenges count up to date with the local data service count after refresh.      
      this.territoryModel.numPendingChallenges = this.feedbackLocalDataService.territoryModelDetails.pendingChallengeAccounts;
    } catch (error) {
      this.handleError(error);
    }
  }
  
  getAssociatedAccountRows(accounts) {
    let associatedAccounts = accounts.flatMap(
      selectedAcct => this.tableMetadata.accounts.filter(
        acct => acct.id !== selectedAcct.id && acct.accountId === selectedAcct.accountId
      )
    );

    // During multiselect approval/rejection actions, accounts can contain more than one accountRecord
    if (accounts.length > 1) {
      const selectedAccountIds = accounts.map(acct => acct.id);
      // Remove duplicate accounts with the selected accounts
      associatedAccounts = associatedAccounts.filter(acct => !selectedAccountIds.includes(acct.id));
      // Remove duplicates among the associated accounts
      associatedAccounts = [...new Map(associatedAccounts.map(acct => [acct.id, acct])).values()];
    }

    return associatedAccounts;
  }

  async refreshAccountRecords(accountRecords) {
    this.renderLoadingSpinner(true);

    const updatedAccounts = [];
    const addedAccounts = [];
    const removedAccounts = [];
    accountRecords.forEach(accountRecord => {
      if (accountRecord.isRemoved) {
        removedAccounts.push(accountRecord);
        this.removeAccountFromTerritory(accountRecord);
      } else if (accountRecord.isInTerritory === false) {
        addedAccounts.push(accountRecord);
        this.addAccountToTerritory(accountRecord);
      } else {
        updatedAccounts.push(accountRecord);
      }
    });
    this.accountsDatatable?.applyChangeset({ updated: updatedAccounts, added: addedAccounts, removed: removedAccounts });
    this.refreshLocalDataService();

    this.renderLoadingSpinner(false);
  }

  addAccountToTerritory(accountRecord) {
    accountRecord.isInTerritory = true;
    if (!this.inTerritoryAccountsById.has(accountRecord.accountId)) {
      this.inTerritoryAccountsById.set(accountRecord.accountId, accountRecord);
    }
    this.tableMetadata.accounts.push(accountRecord);
  }

  removeAccountFromTerritory(accountRecord) {
    const { accountId } = accountRecord;
    accountRecord.isInTerritory = false;
    if (this.inTerritoryAccountsById.has(accountId)) {
      this.inTerritoryAccountsById.delete(accountId);
      this.removeAccountFromTable(accountId);
    }
  }

  // Removes all account rows with the provided ID from the datatable
  removeAccountFromTable(accountId) {
    let i = 0; 
    while (i < this.tableMetadata.accounts.length) {
      const account = this.tableMetadata.accounts[i];
      if (account.accountId === accountId) {
        this.tableMetadata.accounts.splice(i, 1);
      } else {
        i++;
      }
    }
  }

  refreshLocalDataService() {
    this.dataStore.remove(this.feedbackLocalDataService.territoryModelDetailsStoreId);
    this.feedbackLocalDataService = new FeedbackLocalDataService(this.tableMetadata);
    const terrModelDetails = this.feedbackLocalDataService.territoryModelDetails;
    this.feedbackLocalDataService.territoryModelDetailsStoreId = this.dataStore.put(terrModelDetails);
  }

  unselectRows() {
    this.selectedRows = [];
  }

  handleErrorEvent(event) {
    this.handleError(event.detail.error);
  }

  handleError(error) {
    logError(error);
    this.closeAllModals();
    this.loading = false;
    this.errorHandler?.renderError(error);
    this.error = error;
  }

  showGoalEditorModal(accountRecord, isAddTargetChallenge, useDefaultGoals) {
    this.goalEditorIsAddTargetChallenge = isAddTargetChallenge;
    this.goalEditorUseDefaultGoals = useDefaultGoals;
    this.goalEditorAccountRecord = accountRecord;
    this.goalEditorHeader = this.getGoalEditorHeaderForAccount(accountRecord, isAddTargetChallenge);
    this.displayGoalEditorModal = true;
  }

  getGoalEditorHeaderForAccount(accountRecord, isAddTargetChallenge) {
    const displayName = accountRecord.person ? `${accountRecord.firstName} ${accountRecord.lastName}` : accountRecord.name;
    return isAddTargetChallenge ? `${this.messages.addTarget} - ${displayName}` : `${this.messages.editGoals} - ${displayName}`;
  }

  closeGoalEditorModal() {
    this.displayGoalEditorModal = false;
    this.goalEditorAccountRecord = null;
  }

  handleCloseEditGoalsModal() {
    this.closeGoalEditorModal();
    // Send a null record to command to indiciate that user cancelled/closed the modal
    this.publishGoalEditorRecordToCommand(null);
  }

  // Sends the "completed" feedbackGoalEditorRecord back to calling command in order to finish execution (e.g. updating the affected account)
  handleSubmitGoals(event) {
    const {
      detail: { feedbackGoalEditorRecord },
    } = event;
    this.publishGoalEditorRecordToCommand(feedbackGoalEditorRecord);
  }

  publishGoalEditorRecordToCommand(feedbackGoalEditorRecord) {
    publish(this.messageContext, territoryFeedbackChannel, {
      destination: 'createAccountChallengeBaseCommand',
      method: 'showGoalEditorModal',
      feedbackGoalEditorRecord,
    });
  }

  handleUpdateFiltersEvent({ detail: { columnId, filterValue, filterOperator } }) {
    this.replaceFilter(columnId, filterValue, filterOperator);
  }

  replaceFilter(columnId, filterValue, filterOperator) {
    this.accountsDatatable.clearFilters();
    this.accountsDatatable.filter(columnId, filterValue, filterOperator);
  }

  openOutsideTerritorySearchModal() {
    this.displayOutsideTerritorySearchModal = true;
  }

  closeOutsideTerritorySearchModal() {
    this.displayOutsideTerritorySearchModal = false;
  }

  closeAllModals() {
    this.closeGoalEditorModal();
    this.closeOutsideTerritorySearchModal();
  }

  handleMessage(message) {
    if (message.destination !== 'accountsPage') {
      return;
    }

    switch (message.method) {
      case 'renderLoadingSpinner':
        this.renderLoadingSpinner(message.shouldRenderSpinner);
        break;
      case 'closeAllModals':
        this.closeAllModals();
        break;
      case 'showGoalEditorModal':
        this.showGoalEditorModal(message.accountRecord, message.isAddTargetChallenge, message.useDefaultGoals);
        break;
      default:
        break;
    }
  }

  handleTerritoryModelAction(event) {
    const { command, label } = event.detail;
    this.executeTerritoryModelCommand(command, this.territoryModel, label);
  }

  async executeTerritoryModelCommand(command, territoryModel, label) {
    try {
      await TerritoryModelCommandFactory.getInstance(new AccountsPageAdapter(this), territoryModel, command, label)?.execute();
    } catch (error) {
      this.handleError(error);
    }
  }

  showTerritoryModelCommandModal(modalConfig, confirmationCallback) {
    this.territoryFeedbackModal?.showModal(modalConfig);
    this.territoryModelActionCallback = confirmationCallback;
  }

  clearTerritoryModelCommandModal() {
    this.territoryFeedbackModal?.clearModal();
    this.territoryModelActionCallback = null;
  }

  async handleConfirmCommand(event) {
    const { selectedButton } = event.detail;
    if (this.territoryModelActionCallback) {
      try {
        await this.territoryModelActionCallback(selectedButton);
      } catch (error) {
        this.clearTerritoryModelCommandModal();
        this.handleError(error);
      }
    }
  }

  handleCancelCommand() {
    this.clearTerritoryModelCommandModal();
  }

  renderLoadingSpinner(shouldRenderSpinner) {
    this.loading = shouldRenderSpinner;
  }
}

function logError(error) {
  // eslint-disable-next-line no-console
  console.error(error);
}

function sortTerritoryModelActions(action1, action2) {
  const indexComparison = action1.displayIndex - action2.displayIndex;
  return indexComparison || action1.label.localeCompare(action2.label, LANG);
}