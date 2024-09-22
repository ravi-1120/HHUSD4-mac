import { LightningElement, api } from 'lwc';
import { getService } from 'c/veevaServiceFactory';

export default class FieldPlanInfoPanel extends LightningElement {
  type;
  header;

  geoInfo;

  cycleDates;
  dueDate;
  instructions;

  @api feedbackLocalDataService;
  @api htmlReportId;
  @api htmlReportHeight;

  @api
  get isGeoChangePanel() {
    return this.type === 'geoChange';
  }

  get isInfoPanel() {
    return this.type === 'info';
  }

  get hasGeoChanges() {
    return this.geoInfo?.some(info => info.geos.length);
  }

  get shouldRenderTerritoryModelMetrics() {
    return this.territoryModelDetails;
  }

  get shouldRenderGoalMetrics() {
    return this.shouldRenderTerritoryModelMetrics && this.territoryModelDetails.targetingEnabled;
  }

  get territoryModelDetails() {
    return this.feedbackLocalDataService?.territoryModelDetails;
  }

  get shouldRenderMyInsights() {
    return this.htmlReportId && this.feedbackLocalDataService;
  }

  get panelBodyClass() {
    // The MyInsights component has some vertical spacing, so we do not need to add extra.
    const verticalSpacingClass = this.isInfoPanel && this.shouldRenderMyInsights ? '' : 'slds-m-top_large';
    return `${verticalSpacingClass} slds-p-left_medium slds-p-right_medium`; 
  }

  async connectedCallback() {
    await this.loadVeevaMessages();
  }

  @api
  populateGeoChangePanel(panelConfig) {
    this.type = 'geoChange';
    this.header = panelConfig.header;
    this.geoInfo = [
      { header: this.messages.addedHeader, geos: panelConfig.geoAdded.sort() },
      { header: this.messages.droppedHeader, geos: panelConfig.geoDropped.sort() },
    ];
  }

  @api
  populateInfoPanel(panelConfig) {
    this.type = 'info';
    this.header = panelConfig.header;

    this.geoInfo = [
      { header: this.messages.addedHeader, geos: panelConfig.geoAdded.sort() },
      { header: this.messages.droppedHeader, geos: panelConfig.geoDropped.sort() },
    ];

    this.cycleDates = [
      { label: this.messages.startLabel, date: panelConfig.startDate },
      { label: this.messages.endLabel, date: panelConfig.endDate },
    ];
    this.dueDate = panelConfig.dueDate;
    this.instructions = panelConfig.instructions;
  }

  handleCloseEvent() {
    this.dispatchEvent(new CustomEvent('close'));
  }

  handleUpdateFiltersEvent({ detail }) {
    this.dispatchEvent(
      new CustomEvent('updatefilters', {
        detail,
      })
    );
  }

  async loadVeevaMessages() {
    const messageService = getService('messageSvc');
    this.messages = await messageService
      .createMessageRequest()
      .addRequest('Added', 'Common', 'Added', 'addedHeader')
      .addRequest('Dropped', 'Common', 'Dropped', 'droppedHeader')
      .addRequest('NONE_NO_DASH', 'Common', 'None', 'noneLabel')
      .addRequest('CYCLE_START', 'Feedback', 'Cycle Start', 'startLabel')
      .addRequest('CYCLE_END', 'Feedback', 'Cycle End', 'endLabel')
      .addRequest('FEEDBACK_DUE', 'Feedback', 'Feedback Due', 'dueLabel')
      .addRequest('INSTRUCTIONS', 'Feedback', 'Instructions', 'instructionsHeader')
      .addRequest('GEO_CHANGES', 'Feedback', 'Geo Changes', 'geoChangesHeader')
      .addRequest('CHALLENGES', 'Feedback', 'Challenges', 'challengesHeader')
      .addRequest('ACCOUNTS', 'ALIGN', 'Accounts', 'accountsHeader')
      .addRequest('TOTAL_GOALS', 'Feedback', 'Total Goals', 'totalGoalsHeader')
      .sendRequest();
  }
}