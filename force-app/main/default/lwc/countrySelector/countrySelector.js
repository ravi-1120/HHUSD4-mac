import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import { VeevaMessageRequest } from 'c/veevaMessageService';
import getEventCountryConfigs from '@salesforce/apex/EmEventController.getEventCountryConfigs';
import getUserPreferenceCountryConfig from '@salesforce/apex/EmEventController.getUserPreferenceCountryConfig';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class CountrySelector extends LightningElement {
  // Input properties from flow
  @api recordTypeDeveloperName;

  // Output properties to flow
  @api eventConfigId;
  @api exitEarly;
  @api selectedCountryCode;
  @api selectedCountryId;

  // Messages and Prompts
  labelCancel;
  labelNext;
  noEventConfigFoundMessage;
  labelCountryPrompt;
  labelCountry;
  selectLabel;

  // Component's internal Properties
  @track options = [];
  noEventConfigCountriesFound;
  eventConfigQueryComplete = false;
  currentPicklistValue;
  newObjectTemplate;

  messageService;

  get titleNewObject() {
    return this.newObjectTemplate ? this.newObjectTemplate.replace('{0}', this.labelObject) : '';
  }

  get renderCountrySelector() {
    return Boolean(!this.noEventConfigCountriesFound && this.eventConfigQueryComplete);
  }

  @wire(getObjectInfo, { objectApiName: 'EM_Event_vod__c' })
  wiredObjectInfo({ data }) {
    if (data) {
      this.labelObject = data.label;
      if (data.fields.Country_vod__c && data.fields.Country_vod__c.label) {
        this.labelCountry = data.fields.Country_vod__c.label;
      } else {
        this.labelCountry = 'Country';
      }
    }
  }

  async connectedCallback() {
    this.getMessages();
    const  [ userPref = '', countryConfigs ] = await Promise.all([
      getUserPreferenceCountryConfig(),
      getEventCountryConfigs({
        recordTypeDeveloperNames: [this.recordTypeDeveloperName],
      }),
    ]);

    // User Pref Ex. 'US;1'
    const [defaultCountry, onlyDefaultCountry] = userPref.split(';');

    // Check whether User preference is 0
    if (onlyDefaultCountry === '0') {
      const defaultCountryConfig = countryConfigs.find(config => config.Country_vod__r.Alpha_2_Code_vod__c === defaultCountry);
      if (defaultCountryConfig) {
        // Do not render modal, skip to next screen
        this.selectedCountryCode = defaultCountryConfig.Country_vod__r.Alpha_2_Code_vod__c;
        this.selectedCountryId = defaultCountryConfig.Country_vod__c;
        this.eventConfigId = defaultCountryConfig.Event_Configuration_vod__c;
        this.goToNext();
      } else {
        // Display error modal in case no default country config found
        this.noEventConfigCountriesFound = true;
      }
      return;
    }

    this.populatePicklist(defaultCountry, countryConfigs);
  }

  populatePicklist(defaultCountry, countryConfigs) {
    this.options = this.convertCountryConfigsToOptions(countryConfigs, defaultCountry);
    this.options.sort((a, b) => a.label.localeCompare(b.label));

    if (this.options.length === 0) {
      this.noEventConfigCountriesFound = true;
    }

    this.eventConfigQueryComplete = true;
  }

  convertCountryConfigsToOptions(countryConfigs, defaultCountry) {
    const options = [];
    countryConfigs.forEach(config => {
      options.push({
        value: config.Country_vod__r.Alpha_2_Code_vod__c,
        label: config.Country_vod__r.LabelAlias,
        countryId: config.Country_vod__c,
        eventConfigId: config.Event_Configuration_vod__c,
      });
      if (config.Country_vod__r.Alpha_2_Code_vod__c === defaultCountry) {
        this.currentPicklistValue = config.Country_vod__r.Alpha_2_Code_vod__c;
        this.selectedCountryCode = config.Country_vod__r.Alpha_2_Code_vod__c;
        this.selectedCountryId = config.Country_vod__c;
        this.eventConfigId = config.Event_Configuration_vod__c;
      }
    });
    return options;
  }

  handleChange(event) {
    this.currentPicklistValue = event.detail.value;
    this.selectedCountryCode = this.currentPicklistValue;
    // Assumes no duplicate countries may exist for each event config
    const matchingOption = this.options.find(el => el.value === event.detail.value);
    [this.eventConfigId, this.selectedCountryId] = [matchingOption.eventConfigId, matchingOption.countryId];
  }

  goToNext() {
    if (this.validate()) {
      this.dispatchEvent(new FlowNavigationNextEvent());
    }
  }

  finishFlow() {
    this.exitEarly = true;
    this.dispatchEvent(new FlowNavigationNextEvent());
  }

  validate() {
    const element = this.template.querySelector('lightning-combobox');
    if (!element) {
      return true;
    }
    if (element.checkValidity()) {
      return true;
    }
    element.reportValidity();
    return false;
  }

  async getMessages() {
    const messageService = getService(SERVICES.MESSAGE);
    const messageRequest = new VeevaMessageRequest();

    messageRequest.addRequest('CANCEL', 'Common', 'Cancel', 'labelCancel');
    messageRequest.addRequest('NEXT_STEP', 'CallReport', 'Next', 'labelNext');
    messageRequest.addRequest('NO_EVENT_CONFIG', 'EVENT_MANAGEMENT', 'You are not allowed to schedule this type of event during this time frame. Please contact your administrator.', 'noEventConfigFoundMessage');
    messageRequest.addRequest('EVENT_COUNTRY_SELECTOR', 'EVENT_MANAGEMENT', 'What country will this event be hosted in?', 'labelCountryPrompt');
    messageRequest.addRequest('SELECT_FIELD', 'Common', 'Select {0}', 'selectLabel');
    messageRequest.addRequest('NEW_OBJECT', 'TABLET', 'New {0}', 'newObjectTemplate');

    const map = await messageService.getMessageMap(messageRequest);

    map.selectLabel = map.selectLabel.replace('{0}', this.labelCountry);

    Object.entries(map).forEach(([key, message]) => {
      this[key] = message;
    });
  }
}