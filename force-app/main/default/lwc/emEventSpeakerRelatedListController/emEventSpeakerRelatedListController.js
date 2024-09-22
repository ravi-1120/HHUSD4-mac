import EmRelatedListController from 'c/emRelatedListController';
import EmEventConstant from 'c/emEventConstant';
import { createMessageContext, publish } from 'lightning/messageService';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';
import getFilters from '@salesforce/apex/VeevaRelatedListFilterController.getFilters';

const SELECTION_PAGE_FLOW = 'EmSelectionPageFlow';
const FILTER_FIELDS = ['Status_vod__c', 'Meal_Opt_In_vod__c'];

export default class EmEventSpeakerRelatedListController extends EmRelatedListController {
  constructor(meta, pageCtrl) {
    super(meta, pageCtrl);
    this.messageContext = createMessageContext();
  }

  async getButtons() {
    const buttons = await super.getButtons();
    if (buttons.length > 0) {
      const newSpeakerButton = buttons.find(button => button.name === 'new');
      newSpeakerButton.name = EmEventConstant.SPEAKER_SELECTION;
    }
    return buttons;
  }

  handleButton(buttonName) {
    if (buttonName === EmEventConstant.SPEAKER_SELECTION) {
      const payload = {
        flowName: SELECTION_PAGE_FLOW,
        flowVariables: this.getSelectionPageFlowVariables(),
      };
      publish(this.messageContext, eventsManagementChannel, payload);
    }
  }

  getSelectionPageFlowVariables() {
    const flowVariables = [
      {
        name: 'objectApiName',
        value: this.objectDescribe.apiName,
        type: 'String',
      },
      {
        name: 'relatedListRelationship',
        value: this.meta.relationship,
        type: 'String',
      },
      {
        name: 'parentRecord',
        value: JSON.stringify(this.pageCtrl.record),
        type: 'String',
      },
    ];
    if (this.objectDescribe?.recordTypeInfos) {
      const availableRecordTypes = Object.values(this.objectDescribe.recordTypeInfos).filter(rt => rt.available && !rt.master);
      if (availableRecordTypes.length < 2) {
        flowVariables.push({
          name: 'skipRecordTypeSelector',
          value: true,
          type: 'Boolean',
        });

        if (availableRecordTypes.length === 1) {
          flowVariables.push({
            name: 'selectedRecordTypeId',
            value: availableRecordTypes[0].recordTypeId,
            type: 'String',
          });
        }
      }
    }
    return flowVariables;
  }

  async getFilters(params) {
    const filters = await getFilters({ ...params, filterFields: FILTER_FIELDS });
    await this.processFilters(filters);
    return filters;
  }

  async processFilters(filters) {
    const messageMap = await this.pageCtrl.messageSvc
      .createMessageRequest()
      .addRequest('MEAL_OPT_IN', 'EVENT_MANAGEMENT', 'Opt In', 'mealOptInLabel')
      .addRequest('MEAL_OPT_OUT', 'EVENT_MANAGEMENT', 'Opt Out', 'mealOptOutLabel')
      .sendRequest();

    const fieldLabelMap = {
      Meal_Opt_In_vod__c: {
        true: messageMap.mealOptInLabel,
        false: messageMap.mealOptOutLabel,
      },
    };

    this.processFilterLabels(filters, fieldLabelMap);
  }

  showFilter() {
    return true;
  }
}