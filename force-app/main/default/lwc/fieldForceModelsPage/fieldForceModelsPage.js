import { api, track, wire } from 'lwc';
import TerritoryFeedbackConstants from 'c/territoryFeedbackConstants';
import TerritoryFeedbackService from 'c/territoryFeedbackService';
import getTerritoryFeedbackSettings from '@salesforce/apex/TerritoryFeedbackSettings.getTerritoryFeedbackSettings';
import TerritoryTableMetadata from 'c/territoryTableMetadata';
import TerritoryModelCommandFactory from 'c/territoryModelCommandFactory';
import { AsyncProcessRunningError } from 'c/territoryFeedbackErrors';
import { getService } from 'c/veevaServiceFactory';
import TerritoryFeedbackBasePage from 'c/territoryFeedbackBasePage';

const PADDING_OFFSET = 26;

export default class FieldForceModelsPage extends TerritoryFeedbackBasePage {
  @api fieldPlanId;
  @api selectedFieldForceId;
  @api nextScreenName;
  @api selectedTerritoryModelId;
  @api selectedAccountsFilter;
  @api forceDisplayFieldPlansPage;
  @api historyId;

  @track fieldPlan;
  @track childTerritories;
  @track activeFieldForceTableMetadata;
  @track error;
  pageName = 'Territory Feedback - Field Force Models Page';
  pageId = TerritoryFeedbackConstants.TERRITORIES;
  sortDirection = 'asc';
  sortedBy = 'name';
  fieldForceIdToTerritoryIdToTerritoryMap;
  fieldForceCurrentParentMap;
  fieldForceReferenceMap;
  activeFieldForceId;
  availableActionsForActiveParent;
  territoryFeedbackSvc;
  confirmationCallback;
  isPanelOpen;
  messageService;
  messages = {};
  loading = true;
  isInitialized = false;

  renderedCallback() {
    super.renderedCallback();
    this.updateBodyContainerHeight();
  }

  // Dynamically updates the CSS variable so that the table and info panel do not grow beyond the viewport. Instead, nested components will have their own scrollbar.
  updateBodyContainerHeight() {
    const topOffset = this.template.querySelector('.body-container')?.getBoundingClientRect().top;
    if (topOffset != null) {
      const bodyContainerOffsetAmount = PADDING_OFFSET + topOffset;
      this.template.querySelector('div.page-container').style.setProperty('--vertical-offset', `${bodyContainerOffsetAmount}px`);
    }
  }

  async connectedCallback() {
    super.connectedCallback();
    await this.instantiateMessageService();
  }

  async instantiateMessageService() {
    this.messageService = getService('messageSvc');
    this.messages = await this.messageService
      .createMessageRequest()
      .addRequest('FIELD_PLANS', 'Feedback', 'Field Plans', 'fieldPlans')
      .addRequest('MORE_INFO', 'Common', 'More Info', 'moreInfo')
      .sendRequest();
  }

  @wire(getTerritoryFeedbackSettings)
  getFieldPlanInfo({ error, data }) {
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

        this.fetchFieldPlanInfo();
      }
    } else if (error) {
      this.error = error;
      this.fieldPlan = undefined;
    }
  }

  async fetchFieldPlanInfo() {
    try {
      const asyncProcessRunning = await this.territoryFeedbackService.getAsynchronousProcessFlag();
      if (!asyncProcessRunning) {
        this.fieldPlan = await this.territoryFeedbackService.getFieldPlanInfo(this.fieldPlanId);
        this.sortFieldForceTabs();
        this.populateReferenceMaps();
        this.updateParentOfActiveFieldForce(this.parentTerritoryIdOfActiveFieldForce);
        this.loading = false;
        this.isInitialized = true;
      } else {
        throw new AsyncProcessRunningError("An asynchronous process is running against this user's data.");
      }
    } catch (serviceError) {
      this.error = serviceError;
      this.handleError(serviceError);
    }
  }

  sortFieldForceTabs() {
    this.fieldPlan.fieldForceModels.sort((fieldForceA, fieldForceB) => fieldForceA.name.localeCompare(fieldForceB.name));
  }

  populateReferenceMaps() {
    this.fieldForceIdToTerritoryIdToTerritoryMap = this.fieldPlan.createReferenceMapOfFieldForcesToTerritories();
    this.fieldForceReferenceMap = this.fieldPlan.createReferenceMapOfFieldForces();

    // Upon first page load, instantiate objects that keep track of the active field force,
    //     the table metadata associated with the active field force,
    //     and a map of all field forces' current parent territories
    if (!this.fieldForceCurrentParentMap) {
      // Sets active field force to previous active field force when user navigates back from AccountsPage -> FieldForceModelsPage
      this.activeFieldForceId = this.fieldForceReferenceMap.get(this.selectedFieldForceId) ? this.selectedFieldForceId : this.fieldPlan.fieldForceModels[0].id;

      this.activeFieldForceTableMetadata = new TerritoryTableMetadata();
      this.activeFieldForceTableMetadata.fieldPlanHasCycle = this.fieldPlan.hasCycle;
      this.setParentTerritoryOfEachFieldForce();
    }
  }

  setParentTerritoryOfEachFieldForce() {
    this.fieldForceCurrentParentMap = new Map();
    this.fieldPlan.fieldForceModels.forEach(fieldForce => {
      let parentId;

      if (fieldForce.id === this.selectedFieldForceId) {
        // If user navigated back to AccountsPage from another page, then set this fieldForce's parent to the parent of the territoryModel they originally navigated from.
        const accountsScreenTerritory = this.fieldForceIdToTerritoryIdToTerritoryMap.get(fieldForce.id).get(this.selectedTerritoryModelId);
        parentId = accountsScreenTerritory?.parentTerritoryModelId;
      } else {
        // If a field force has multiple top-level territories, then set parent as 'null', which indicates that we should display all top-level territories.
        // Otherwise, when only 1 top-level territory, set that as the default parent since the user will have no other choice for navigation.
        parentId = fieldForce.hasMultipleParentTerritoryModels ? null : fieldForce.territoryModels[0]?.id;
      }

      this.fieldForceCurrentParentMap.set(fieldForce.id, parentId);
    });
  }

  updateParentOfActiveFieldForce(newParentTerritoryId) {
    const newParent = this.territoryMapForActiveFieldForce.get(newParentTerritoryId);
    this.fieldForceCurrentParentMap.set(this.activeFieldForceId, newParent?.id);
    this.updateAvailableActionsForActiveParent();
    this.childTerritories = newParent ? newParent.childTerritoryModels : this.fieldForceReferenceMap.get(this.activeFieldForceId).territoryModels;
    this.updateActiveFieldForceTableMetadata(newParent);
    // The exact child we choose is not important. We simply want to store the ID of a child of the current parent so that we can potentially return to this parent in the future.
    // A null/undefined ID here is valid - it simply means that we are at the top of the current hierarchy.
    this.selectedTerritoryModelId = this.activeParentTerritory?.childTerritoryModels[0].id;
    this.selectedFieldForceId = this.activeFieldForceId;
  }

  updateAvailableActionsForActiveParent() {
    if (this.activeParentTerritory) {
      this.availableActionsForActiveParent = this.territoryModelsTable?.getAvailableActionsForTerritory(this.activeParentTerritory) ?? [];
    } else {
      this.availableActionsForActiveParent = [];
    }
  }

  updateActiveFieldForceTableMetadata(parentTerritory) {
    const activeFieldForce = this.fieldForceReferenceMap.get(this.activeFieldForceId);
    const grandparentTerritoryId = parentTerritory?.parentTerritoryModelId;

    this.activeFieldForceTableMetadata.channelLabelsToProductLabels = activeFieldForce.channelLabelsToProductLabels;
    this.activeFieldForceTableMetadata.parentTerritoryName = parentTerritory?.name;
    this.activeFieldForceTableMetadata.allowNavigationUp = this.shouldAllowNavigationUp(grandparentTerritoryId, parentTerritory, activeFieldForce);
  }

  // User should be able to navigate up when the current parent has its own parent,
  //   or when there are multiple top-level territories underneath the active field force
  shouldAllowNavigationUp(grandparentTerritoryId, parentTerritory, activeFieldForce) {
    return grandparentTerritoryId || (parentTerritory && activeFieldForce.hasMultipleParentTerritoryModels);
  }

  handleFieldPlanNavigation() {
    this.forceDisplayFieldPlansPage = true;
    this.goToNextScreen(TerritoryFeedbackConstants.FIELD_PLANS);
  }

  handleAccountsNavigationEvent(event) {
    const { territoryId, filter } = event.detail;
    this.navigateToAccountsScreen(territoryId, filter);
  }

  navigateToAccountsScreen(selectedTerritoryModelId, selectedAccountsFilter) {
    this.selectedFieldForceId = this.activeFieldForceId;
    this.selectedTerritoryModelId = selectedTerritoryModelId;
    this.selectedAccountsFilter = selectedAccountsFilter;
    this.goToNextScreen(TerritoryFeedbackConstants.ACCOUNTS);
  }

  handleGeoChangeEvent(event) {
    const targetTerritoryId = event.detail.territoryId;
    this.showGeoChangePanel(targetTerritoryId);
  }

  handleInfoEvent() {
    if (this.isPanelOpen && !this.fieldPlanInfoPanel.isGeoChangePanel) {
      this.closePanel();
    } else {
      this.showInfoPanel();
    }
  }

  handlePanelCloseEvent() {
    this.closePanel();
  }

  handleFieldForceTabChange(event) {
    const newFieldForceId = event.target.value;
    if (this.activeFieldForceId !== newFieldForceId) {
      this.handleSamePageNavigation();
      this.closePanel();
      this.activeFieldForceId = newFieldForceId;
      this.updateParentOfActiveFieldForce(this.parentTerritoryIdOfActiveFieldForce);
    }
  }

  handleChildNavigationEvent(event) {
    this.handleSamePageNavigation();
    this.closePanel();
    const childTerritory = this.territoryMapForActiveFieldForce.get(event.detail.territoryId);
    if (childTerritory.isRepLevelTerritoryModel) {
      this.navigateToAccountsScreen(childTerritory.id, null);
    } else {
      this.updateParentOfActiveFieldForce(childTerritory.id);
    }
  }

  handleParentNavigationEvent() {
    this.handleSamePageNavigation();
    this.closePanel();
    this.updateParentOfActiveFieldForce(this.activeParentTerritory.parentTerritoryModelId);
  }

  handleParentMoreActionsEvent(event) {
    const command = event.detail.value;
    const label = this.getLabelForAction(command);
    this.executeCommand(command, this.activeParentTerritory, label);
  }

  getLabelForAction(name) {
    return this.availableActionsForActiveParent.find(action => action.name === name).label;
  }

  handleCommand(event) {
    const { territoryModel, command, label } = event.detail;
    this.executeCommand(command, territoryModel, label);
  }

  async executeCommand(command, targetTerritory, label) {
    try {
      await TerritoryModelCommandFactory.getInstance(this, targetTerritory, command, label)?.execute();
    } catch (error) {
      this.handleError(error);
    }
  }

  async handleConfirmCommand(event) {
    const { selectedButton } = event.detail;
    if (this.confirmationCallback) {
      try {
        await this.confirmationCallback(selectedButton);
      } catch (error) {
        this.clearModal();
        this.handleError(error);
      }
    }
  }

  handleCancelCommand() {
    this.clearModal();
  }

  handleUpdateSortParamsEvent(event) {
    ({ sortDirection: this.sortDirection, sortedBy: this.sortedBy } = event.detail);
  }

  updatePendingChallenges(territoryId) {
    // Find other field forces with the same territory to update
    this.fieldForceIdToTerritoryIdToTerritoryMap.forEach(territoryIdToTerritoryMap => {
      const targetTerritory = territoryIdToTerritoryMap.get(territoryId);
      if (targetTerritory) {
        targetTerritory.clearPendingChallenges();
      }
    });
  }

  updateNumAccounts(territoryId, updatedTerritoryWithCounts) {
    // Find other field forces with the same territory to update
    this.fieldForceIdToTerritoryIdToTerritoryMap.forEach(territoryIdToTerritoryMap => {
      const targetTerritory = territoryIdToTerritoryMap.get(territoryId);
      if (targetTerritory) {
        targetTerritory.updateNumAccounts(updatedTerritoryWithCounts);
      }
    });
  }

  updateActivityCounts(territoryId, updatedTerritoryWithPlanChannels) {
    const updatedFieldForceIds = [];

    this.fieldForceIdToTerritoryIdToTerritoryMap.forEach((territoryIdToTerritoryMap, fieldForceId) => {
      const targetTerritory = territoryIdToTerritoryMap.get(territoryId);
      if (targetTerritory) {
        targetTerritory.updatePlanChannels(updatedTerritoryWithPlanChannels);
        updatedFieldForceIds.push(fieldForceId);
      }
    });

    updatedFieldForceIds.forEach(fieldForceId => {
      const fieldForce = this.fieldForceReferenceMap.get(fieldForceId);
      fieldForce.territoryModels.forEach(territory => {
        territory.refreshActivityCounts();
      });
    });
  }

  updateTerritoryModels(updatedTerritoryIds, updatedStatus, updatedLifecycleActions, isFeedbackComplete, isFeedback, canReview) {
    updatedTerritoryIds.forEach(territoryId => {
      // Territory Models may appear under more than 1 Field Force Model, so we need to iterate over every Field Force Model.
      this.fieldForceIdToTerritoryIdToTerritoryMap.forEach(territoryIdToTerritoryMap => {
        const territory = territoryIdToTerritoryMap.get(territoryId);
        if (!territory) {
          return;
        }

        territory.lifecycleState = updatedStatus;
        territory.availableLifecycleActions = updatedLifecycleActions;
        territory.canReview = canReview;
        if (territory.isRepLevelTerritoryModel) {
          territory.feedbackComplete = isFeedbackComplete;
          territory.feedback = isFeedback;
        }
      });
    });
    this.updateAvailableActionsForActiveParent();
  }

  // LWCs don't always track changes to properties of "complex" objects stored in arrays,
  //   so re-assigning the array is necessary to force a refresh of the view/component
  refreshTable() {
    this.childTerritories = [...this.childTerritories];
  }

  showModal(modalConfig, confirmationCallback) {
    this.territoryFeedbackModal?.showModal(modalConfig);
    this.confirmationCallback = confirmationCallback;
  }

  clearModal() {
    this.territoryFeedbackModal?.clearModal();
    this.confirmationCallback = null;
  }

  showLoadingSpinner() {
    this.loading = true;
  }

  hideLoadingSpinner() {
    this.loading = false;
  }

  showGeoChangePanel(targetTerritoryId) {
    const targetTerritory = this.territoryMapForActiveFieldForce.get(targetTerritoryId);

    this.fieldPlanInfoPanel?.populateGeoChangePanel({
      header: targetTerritory.name,
      ...targetTerritory.geoAddedAndDropped,
    });

    this.isPanelOpen = true;
  }

  showInfoPanel() {
    this.fieldPlanInfoPanel?.populateInfoPanel({
      header: this.activeParentTerritory?.name,
      startDate: this.fieldPlan.cycleStartDate,
      endDate: this.fieldPlan.cycleEndDate,
      dueDate: this.fieldPlan.dueDate,
      instructions: this.fieldPlan.instructions,
      ...this.geosForActiveParent,
    });

    this.isPanelOpen = true;
  }

  closePanel() {
    this.isPanelOpen = false;
  }

  handleError(error) {
    logError(error);
    this.loading = false;
    this.errorHandler?.renderError(error);
    this.error = error;
  }

  get isPageReady() {
    return this.isInitialized;
  }

  get errorHandler() {
    return this.template.querySelector('c-territory-feedback-error-handler');
  }

  get hidePageContent() {
    return this.hasErrorOccurred || this.loading;
  }

  get containerClass() {
    return this.hidePageContent ? 'slds-hide' : 'slds-show';
  }

  get hasErrorOccurred() {
    return this.error;
  }

  get territoryFeedbackService() {
    return this.territoryFeedbackSvc;
  }

  get isSingleFieldForceModel() {
    return !this.loading && this.fieldPlan?.fieldForceModels.length === 1;
  }

  get territoryFeedbackModal() {
    return this.template.querySelector('c-territory-feedback-modal');
  }

  get fieldPlanInfoPanel() {
    return this.template.querySelector('c-field-plan-info-panel');
  }

  get territoryModelsTable() {
    return this.template.querySelector('c-territory-models-table');
  }

  get territoryTableSize() {
    return this.isPanelOpen ? '9' : '12';
  }

  get sidePanelClass() {
    // lightning-tabset adds additional padding below the table, so if the tabset renders (i.e. !this.isSingleFieldForceModel),
    // then we need to add the same padding to the bottom of the info panel so that the table and panel align along the bottom
    const paddingClasses = this.isSingleFieldForceModel ? 'slds-p-left_medium' : 'slds-p-left_medium slds-p-bottom_small';
    return this.isPanelOpen ? paddingClasses : 'slds-hide';
  }

  get parentTerritoryIdOfActiveFieldForce() {
    return this.fieldForceCurrentParentMap.get(this.activeFieldForceId);
  }

  get activeParentTerritory() {
    return this.territoryMapForActiveFieldForce.get(this.parentTerritoryIdOfActiveFieldForce);
  }

  get territoryMapForActiveFieldForce() {
    return this.fieldForceIdToTerritoryIdToTerritoryMap.get(this.activeFieldForceId);
  }

  // Returns geos for the active parent territory.
  // If no active parent (i.e. there are multiple top-level territories), then aggregate geos of all top-level territories.
  get geosForActiveParent() {
    if (this.activeParentTerritory) {
      return this.activeParentTerritory.geoAddedAndDropped;
    }
    const accumulatedGeoChanges = { geoAdded: [], geoDropped: [] };
    this.childTerritories.forEach(childTerritory => {
      const childTerrGeoChanges = childTerritory.geoAddedAndDropped;
      accumulatedGeoChanges.geoAdded.push(...childTerrGeoChanges.geoAdded);
      accumulatedGeoChanges.geoDropped.push(...childTerrGeoChanges.geoDropped);
    });
    return accumulatedGeoChanges;
  }
}

function logError(error) {
  // eslint-disable-next-line no-console
  console.error(error);
}