import EmRelatedListController from 'c/emRelatedListController';
import { createMessageContext, publish } from 'lightning/messageService';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';
import getAttendeeRecordType from '@salesforce/apex/EmAttendeeSelection.getAttendeeRecordType';
import getFilters from '@salesforce/apex/VeevaRelatedListFilterController.getFilters';
import ACCOUNT_LABEL from '@salesforce/label/c.ACCOUNT_vod';
import CHILD_ACCOUNT_LABEL from '@salesforce/label/c.CHILD_ACCOUNT_vod';
import CONTACT_LABEL from '@salesforce/label/c.CONTACT_vod';
import USER_LABEL from '@salesforce/label/c.USER_vod';
import WALK_IN_LABEL from '@salesforce/label/c.WALK_IN_vod';
import isChildAccountEnabled from '@salesforce/apex/EmAttendeeSelection.isChildAccountEnabled';
import CHILD_ACCOUNT from '@salesforce/schema/Child_Account_vod__c';

const SELECTION_PAGE_FLOW = 'EmSelectionPageFlow';
const ATTENDEE_SELECTION = 'attendeeSelection';
const FILTER_FIELDS = ['Status_vod__c', 'Attendee_Type_vod__c', 'Meal_Opt_In_vod__c', 'Walk_In_Status_vod__c'];
const NON_GROUPABLE_FIELD_VALUES = {
  Attendee_Type_vod__c: [ACCOUNT_LABEL, CHILD_ACCOUNT_LABEL, CONTACT_LABEL, USER_LABEL, WALK_IN_LABEL],
};
export default class EmAttendeeRelatedListController extends EmRelatedListController {
  constructor(meta, pageCtrl) {
    super(meta, pageCtrl);
    this.messageContext = createMessageContext();
  }

  async getButtons() {
    const buttons = await super.getButtons();
    if (buttons.length > 0) {
      const newAttendeeButton = buttons.find(button => button.name === 'new');
      if (newAttendeeButton) {
        newAttendeeButton.name = ATTENDEE_SELECTION;
      }
    }
    return buttons;
  }

  handleButton(buttonName) {
    if (buttonName === ATTENDEE_SELECTION) {
      this.getMessagePayload().then(payload => publish(this.messageContext, eventsManagementChannel, payload));
    }
  }

  async getFilters(params) {
    const filters = await getFilters({ ...params, filterFields: FILTER_FIELDS, nonGroupableFieldValues: NON_GROUPABLE_FIELD_VALUES });
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

  async getMessagePayload() {
    const flowVariables = [
      {
        name: 'objectApiName',
        value: this.objectDescribe.apiName,
        type: 'String',
      },
      {
        name: 'parentRecord',
        value: JSON.stringify(this.pageCtrl.record),
        type: 'String',
      },
      {
        name: 'skipRecordTypeSelector',
        value: true,
        type: 'Boolean',
      },
    ];
    const childAccountEnabled = await isChildAccountEnabled();
    const relatedListRelationship = {
      name: 'relatedListRelationship',
      value: this.meta.relationship + (childAccountEnabled ? `.${CHILD_ACCOUNT.objectApiName}` : ''),
      type: 'String',
    };
    flowVariables.push(relatedListRelationship);
    const attendeeRecordType = await getAttendeeRecordType({ eventRecordTypeId: this.pageCtrl?.record?.recordTypeId });
    if (attendeeRecordType) {
      flowVariables.push({
        name: 'selectedRecordTypeId',
        value: attendeeRecordType,
        type: 'String',
      });
    }
    return {
      flowName: SELECTION_PAGE_FLOW,
      flowVariables,
    };
  }

  showFilter() {
    return true;
  }
}