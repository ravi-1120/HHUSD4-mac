import { wire, track, api } from 'lwc';
import getTerritoryFeedbackSettings from '@salesforce/apex/TerritoryFeedbackSettings.getTerritoryFeedbackSettings';
import getVodInfo from '@salesforce/apex/SessionVod.getVodInfo';
import TerritoryFeedbackService from 'c/territoryFeedbackService';
import LANG from '@salesforce/i18n/lang';
import Id from '@salesforce/user/Id';
import { loadStyle } from 'lightning/platformResourceLoader';
import fieldPlansStyling from '@salesforce/resourceUrl/fieldPlansStyling';
import { NotManagerError, NoFieldPlansError, AsyncProcessRunningError } from 'c/territoryFeedbackErrors';
import { getService } from 'c/veevaServiceFactory';
import TerritoryFeedbackBasePage from 'c/territoryFeedbackBasePage';
import TerritoryFeedbackConstants from 'c/territoryFeedbackConstants';

export default class FieldPlansPage extends TerritoryFeedbackBasePage {
  @api fieldPlanId;
  @api forceDisplayFieldPlansPage;
  @api historyId;
  @api nextScreenName;

  @track isManager;
  @track fieldPlans;
  @track messageService;

  pageName = 'Territory Feedback - Field Plans Page';
  pageId = TerritoryFeedbackConstants.FIELD_PLANS;
  error;
  territoryFeedbackSvc;
  territoryFeedbackSettings;
  vodInfo;
  loading = true;

  // Veeva Messages
  fieldPlansHeader;
  dueLabel;
  cycleLabel;

  async connectedCallback() {
    super.connectedCallback();
    loadStyle(this, fieldPlansStyling);

    this.messageService = getService('messageSvc');
    await this.messageService.loadVeevaMessageCategories(['Feedback', 'TABLET']);
    await this.loadVeevaMessages();
  }

  initializeHistory() {
    // Overrides the superclass' implementation so that we can delay creation of the history entry until we know whether we're "skipping" the Field Plans page.
    if (this.isPageReady) {
      super.initializeHistory();
    }
  }

  registerEventListeners() {
    // Overrides the superclass' implementation so that we can delay creation of the history entry until we know whether we're "skipping" the Field Plans page.
    if (this.isPageReady) {
      super.registerEventListeners();
    }
  }

  async loadVeevaMessages() {
    [this.fieldPlansHeader, this.dueLabel, this.cycleLabel] = await Promise.all([
      this.messageService.getMessageWithDefault('FIELD_PLANS', 'Feedback', 'Field Plans'),
      this.messageService.getMessageWithDefault('DUE', 'Feedback', 'Due'),
      this.messageService.getMessageWithDefault('CYCLE', 'TABLET', 'Cycle'),
    ]);
  }

  @wire(getTerritoryFeedbackSettings)
  processTerritoryFeedbackSettingsResults({ error, data }) {
    this.processWiredMethodsThenLogin(error, data, 'territoryFeedbackSettings');
  }

  @wire(getVodInfo)
  processVodInfoResults({ error, data }) {
    this.processWiredMethodsThenLogin(error, data, 'vodInfo');
  }

  processWiredMethodsThenLogin(error, data, propertyName) {
    if (data) {
      this[propertyName] = data;
      if (this.territoryFeedbackSettings && this.vodInfo) {
        this.loginToTerritoryFeedback();
      }
    } else if (error) {
      this.loading = false;
      this.error = error;
      logError(error);
    }
  }

  async loginToTerritoryFeedback() {
    this.territoryFeedbackSvc = this.instantiateTerritoryService();

    try {
      const loginData = await this.territoryFeedbackSvc.login(Id, LANG, this.vodInfo.sfSession, this.vodInfo.sfEndpoint);
      this.isManager = loginData.isManager;
      if (this.isManager) {
        await this.loadFieldPlans();
      } else {
        throw new NotManagerError('Current user is not a manager.');
      }
    } catch (error) {
      this.handleError(error);
    }
  }

  async loadFieldPlans() {
    /*
     * For MVP, a flag will be returned by Align to indicate whether an async process
     * is running against any one of the user's assigned territories.
     */
    const fieldPlansResponse = await this.territoryFeedbackSvc.getFieldPlans();
    if (!fieldPlansResponse.asynchronousProcessRunning) {
      // If only one fieldPlan, then we want to direct user straight to the Territories screen instead of rendering the Field Plan
      if (fieldPlansResponse.fieldPlans.length === 1 && !this.forceDisplayFieldPlansPage) {
        this.navigateToFieldForceModelsPage(fieldPlansResponse.fieldPlans[0].id);
      } else if (!fieldPlansResponse.fieldPlans.length) {
        throw new NoFieldPlansError('Current user has no plans available for feedback.');
      } else {
        this.fieldPlans = fieldPlansResponse.fieldPlans;
        // Only intialize the page history when we know we're NOT skipping straight to the Territories screen
        this.initializeHistory();
        this.registerEventListeners();
        this.loading = false;
      }
    } else {
      throw new AsyncProcessRunningError("An asynchronous process is running against this user's data.");
    }
  }

  handleError(error) {
    logError(error);
    this.loading = false;
    this.errorHandler?.renderError(error);
    this.error = error;
  }

  instantiateTerritoryService() {
    return new TerritoryFeedbackService(this.territoryFeedbackSettings.alignServer, this.territoryFeedbackSettings.alignVersion);
  }

  handleTerritoryNavigation(event) {
    this.navigateToFieldForceModelsPage(event.target.value);
  }

  navigateToFieldForceModelsPage(selectedFieldPlanId) {
    this.fieldPlanId = selectedFieldPlanId;
    this.goToNextScreen(TerritoryFeedbackConstants.TERRITORIES);
  }

  get isPageReady() {
    return this.fieldPlans;
  }

  get hidePageContent() {
    return this.error || this.loading;
  }

  get errorHandler() {
    return this.template.querySelector('c-territory-feedback-error-handler');
  }
}

function logError(error) {
  // eslint-disable-next-line no-console
  console.error(error);
}