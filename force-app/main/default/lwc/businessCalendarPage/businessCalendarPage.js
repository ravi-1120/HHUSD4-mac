import { wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { getService } from 'c/veevaServiceFactory';
import VeevaMainPage from 'c/veevaMainPage';
import getCalendarEvents from '@salesforce/apex/VeevaBusinessCalendarController.getCalendarEvents';
import getMCCycles from '@salesforce/apex/VeevaBusinessCalendarController.getMCCycles';
import getCampaigns from '@salesforce/apex/VeevaBusinessCalendarController.getCampaigns';
import getAccountPlans from '@salesforce/apex/VeevaBusinessCalendarController.getAccountPlans';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import CALENDAR_EVENT_OBJECT from '@salesforce/schema/Calendar_Event_vod__c';
import MC_CYCLE_OBJECT from '@salesforce/schema/MC_Cycle_vod__c';
import CAMPAIGN_OBJECT from '@salesforce/schema/Campaign_vod__c';
import ACCOUNT_PLAN_OBJECT from '@salesforce/schema/Account_Plan_vod__c';

export default class BusinessCalendarPage extends NavigationMixin(VeevaMainPage) {
  pageName = 'Business Calendar';
  loading = true;
  eventData = [];
  messages = {};
  areMessagesLoaded = false;

  _hasMappedCalendarEvents = false;
  _calendarEvents = [];
  _calendarEventFields;
  _hasMappedMCCycles = false;
  _mcCycles = [];
  _mcCycleFields;
  _hasMappedCampaigns = false;
  _campaigns = [];
  _campaignFields;
  _hasMappedAccountPlans = false;
  _accountPlans = [];
  _accountPlanFields;

  @wire(getObjectInfos, { objectApiNames: [CALENDAR_EVENT_OBJECT, MC_CYCLE_OBJECT, CAMPAIGN_OBJECT, ACCOUNT_PLAN_OBJECT] })
  wiredObjectInfos({ data }) {
    if (data) {
      [
        {
          result: { fields: this._calendarEventFields },
        },
        {
          result: { fields: this._mcCycleFields },
        },
        {
          result: { fields: this._campaignFields },
        },
        {
          result: { fields: this._accountPlanFields },
        },
      ] = data.results;
      this.mapCalendarEvents();
      this.mapMCCycles();
      this.mapCampaigns();
      this.mapAccountPlans();
    }
  }

  async connectedCallback() {
    super.connectedCallback();
    await this.loadVeevaMessages();
    this.fetchCalendarEvents();
    this.fetchMCCycles();
    this.fetchCampaigns();
    this.fetchAccountPlans();
  }

  async loadVeevaMessages() {
    this.messageService = getService('messageSvc');
    this.messages = await this.messageService
      .createMessageRequest()
      .addRequest('BUSINESS_CALENDAR_GROUP_COMPANY_CALENDAR', 'Campaign', 'Company Calendar', 'companyCalendar')
      .addRequest('BUSINESS_CALENDAR_GROUP_CYCLES', 'Campaign', 'Cycles', 'cycles')
      .addRequest('BUSINESS_CALENDAR_GROUP_CAMPAIGNS', 'Campaign', 'Campaigns', 'campaigns')
      .addRequest('BUSINESS_CALENDAR_GROUP_ACCOUNT_PLANS', 'Campaign', 'Account Plans', 'accountPlans')
      .addRequest('BUSINESS_CALENDAR_VIEW_TODAY', 'Campaign', 'Today', 'today')
      .addRequest('BUSINESS_CALENDAR_VIEW_QUARTERS', 'Campaign', 'Quarters', 'quarters')
      .addRequest('BUSINESS_CALENDAR_VIEW_MONTHS', 'Campaign', 'Months', 'months')
      .addRequest('BUSINESS_CALENDAR_VIEW_WEEKS', 'Campaign', 'Weeks', 'weeks')
      .addRequest('BUSINESS_CALENDAR_VIEW_DAYS', 'Campaign', 'Days', 'days')
      .addRequest('BUSINESS_CALENDAR_MORE_DETAILS', 'Campaign', 'More Details', 'moreDetails')
      .addRequest('BUSINESS_CALENDAR_CAMPAIGN', 'Campaign', 'Campaign', 'campaign')
      .addRequest('BUSINESS_CALENDAR_NO_PRODUCT', 'Campaign', 'No product', 'noProduct')
      .addRequest('BUSINESS_CALENDAR_CALENDAR_EVENT', 'Campaign', 'Calendar Event', 'calendarEvent')
      .addRequest('BUSINESS_CALENDAR_CYCLE', 'Campaign', 'Cycle', 'cycle')
      .addRequest('BUSINESS_CALENDAR_ACCOUNT_PLAN', 'Campaign', 'Account Plan', 'accountPlan')
      .sendRequest();

    this.areMessagesLoaded = true;
  }

  async fetchCalendarEvents() {
    this._calendarEvents = await getCalendarEvents();
    this._calendarEventURLs = await this.getDetailPageUrls(this._calendarEvents);
    this.mapCalendarEvents();
  }

  mapCalendarEvents() {
    // Ensures function only completes once, even though it's invoked by both a wired function and a function in connectedCallback
    if (this._hasMappedCalendarEvents || this._calendarEvents.length === 0 || !this._calendarEventFields) {
      return;
    }
    this._hasMappedCalendarEvents = true;

    const fieldNamesToLabels = Object.entries(this._calendarEventFields).reduce(
      (namesToLabels, [fieldName, fieldInfo]) => ({ ...namesToLabels, [fieldName]: fieldInfo.label }),
      {}
    );

    this.eventData = [
      ...this.eventData,
      ...this._calendarEvents.map((calendarEvent, index) => ({
        ...calendarEvent,
        fieldNamesToLabels,
        type: 'Calendar_Event_vod__c',
        detailPageUrl: this._calendarEventURLs[index],
      })),
    ];
  }

  async fetchMCCycles() {
    this._mcCycles = await getMCCycles();
    this._mcCycleEventURLs = await this.getDetailPageUrls(this._mcCycles);
    this.mapMCCycles();
  }

  mapMCCycles() {
    // Ensures function only completes once, even though it's invoked by both a wired function and a function in connectedCallback
    if (this._hasMappedMCCycles || this._mcCycles.length === 0 || !this._mcCycleFields) {
      return;
    }
    this._hasMappedMCCycles = true;

    const fieldNamesToLabels = Object.entries(this._mcCycleFields).reduce(
      (namesToLabels, [fieldName, fieldInfo]) => ({ ...namesToLabels, [fieldName]: fieldInfo.label }),
      {}
    );

    this.eventData = [
      ...this.eventData,
      ...this._mcCycles.map((mcCycle, index) => ({
        ...mcCycle,
        fieldNamesToLabels,
        type: 'MC_Cycle_vod__c',
        detailPageUrl: this._mcCycleEventURLs[index],
      })),
    ];
  }

  async fetchCampaigns() {
    this._campaigns = await getCampaigns();
    this._campaignURLs = await this.getDetailPageUrls(this._campaigns);
    this.mapCampaigns();
  }

  mapCampaigns() {
    // Ensures function only completes once, even though it's invoked by both a wired function and a function in connectedCallback
    if (this._hasMappedCampaigns || this._campaigns.length === 0 || !this._campaignFields) {
      return;
    }
    this._hasMappedCampaigns = true;

    const fieldNamesToLabels = Object.entries(this._campaignFields).reduce(
      (namesToLabels, [fieldName, fieldInfo]) => ({ ...namesToLabels, [fieldName]: fieldInfo.label }),
      {}
    );

    this.eventData = [
      ...this.eventData,
      ...this._campaigns.map((campaign, index) => ({
        ...campaign,
        fieldNamesToLabels,
        type: 'Campaign_vod__c',
        detailPageUrl: this._campaignURLs[index],
      })),
    ];
  }

  async fetchAccountPlans() {
    this._accountPlans = await getAccountPlans();
    this._accountPlanURLs = await this.getDetailPageUrls(this._accountPlans);
    this.mapAccountPlans();
  }

  mapAccountPlans() {
    // Ensures function only completes once, even though it's invoked by both a wired function and a function in connectedCallback
    if (this._hasMappedAccountPlans || this._accountPlans.length === 0 || !this._accountPlanFields) {
      return;
    }
    this._hasMappedAccountPlans = true;

    const fieldNamesToLabels = Object.entries(this._accountPlanFields).reduce(
      (namesToLabels, [fieldName, fieldInfo]) => ({ ...namesToLabels, [fieldName]: fieldInfo.label }),
      {}
    );

    this.eventData = [
      ...this.eventData,
      ...this._accountPlans.map((accountPlan, index) => ({
        ...accountPlan,
        fieldNamesToLabels,
        type: 'Account_Plan_vod__c',
        detailPageUrl: this._accountPlanURLs[index],
      })),
    ];
  }

  handleFirstRender() {
    this.loading = false;
  }

  // NavigationMixin.GenerateUrl function returns a promise, so we'll collect all of the promises at once and return them all as an array
  async getDetailPageUrls(records) {
    return Promise.all(
      records.map(record =>
        this[NavigationMixin.GenerateUrl]({
          type: 'standard__recordPage',
          attributes: {
            recordId: record.Id,
            actionName: 'view',
          },
        })
      )
    );
  }

  get businessCalendarScheduler() {
    return this.template.querySelector('c-business-calendar-scheduler');
  }

  @wire(CurrentPageReference)     
  getStateParameters() {
      this.resetBryntumStylesheet();
  }

  resetBryntumStylesheet() {
    let display;
    if (this.businessCalendarScheduler) {
        display = this.businessCalendarScheduler.style.display;
        // hide page ui issues while switching bryntum styling sheets
        this.businessCalendarScheduler.style.display = 'none'; 
    }
    // eslint-disable-next-line @lwc/lwc/no-document-query
    const schedulerStyleSheet = document.querySelector('link[href*="schedulerpro"][rel="stylesheet"]');
    // eslint-disable-next-line @lwc/lwc/no-document-query
    const calendarStyleSheet = document.querySelector('link[href*="calendar/calendar"][rel="stylesheet"]');
    if (schedulerStyleSheet) {
      schedulerStyleSheet.disabled = false;
    }
    if (calendarStyleSheet) {
      calendarStyleSheet.disabled = true;
    }
    // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
    setTimeout(() => {
      if (this.businessCalendarScheduler) {
        this.businessCalendarScheduler.style.display = display;
        this.businessCalendarScheduler.handleFirstRender();
      }
    }, 100)
  }
}