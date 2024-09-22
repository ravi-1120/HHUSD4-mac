import { LightningElement, api } from 'lwc';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import SPLIT_LINES_FIELD from '@salesforce/schema/Expense_Header_vod__c.Split_Lines_vod__c';

export default class EmSplitExpensesSelector extends LightningElement {
  // Input properties from flow
  @api recordTypeId;

  // Output properties to flow
  @api exitEarly;
  @api defaultFieldValues;

  // Messages
  labelCancel;
  labelNext;
  splitExpenseSelectorHeader;
  splitExpenseDescriptionNo;
  splitExpenseDescriptionYes;

  selectedOption;
  options = [];
  showSelector = false;

  msgMap = {
    splitExpenseSelectorHeader: 'Split Expense?',
    splitExpenseDescriptionNo: 'Create expenses and optionally associate to a single participant',
    splitExpenseDescriptionYes: 'Create a single expense and split to multiple participants',
  };

  async connectedCallback() {
    await this.loadVeevaMessages();
    const uiApi = getService(SERVICES.UI_API);
    const [objectInfo, picklistValues] = await Promise.all([
      uiApi.objectInfo(SPLIT_LINES_FIELD.objectApiName),
      uiApi.getPicklistValues(this.recordTypeId, SPLIT_LINES_FIELD.objectApiName, SPLIT_LINES_FIELD.fieldApiName),
    ]);
    const availableValues = picklistValues?.values || [];
    const yesOption = availableValues.find(option => option.value === 'Yes_vod');
    const noOption = availableValues.find(option => option.value === 'No_vod');
    const canEdit = objectInfo?.fields?.[SPLIT_LINES_FIELD.fieldApiName]?.updateable;
    if ((!yesOption && !noOption) || !canEdit) {
      this.goToNext();
    } else if (!yesOption || !noOption) {
      this.selectedOption = yesOption ? yesOption.value : noOption.value;
      this.goToNext();
    } else {
      this.options = [
        {
          label: yesOption.label,
          value: yesOption.value,
          description: this.splitExpenseDescriptionYes,
        },
        {
          label: noOption.label,
          value: noOption.value,
          description: this.splitExpenseDescriptionNo,
        },
      ];
      this.showSelector = true;
    }
  }

  async loadVeevaMessages() {
    this.msgMap = await getService(SERVICES.MESSAGE)
      .createMessageRequest()
      .addRequest('CANCEL', 'Common', 'Cancel', 'labelCancel')
      .addRequest('NEXT_STEP', 'CallReport', 'Next', 'labelNext')
      .addRequest('SPLIT_EXPENSE_SELECTOR_HEADER', 'EVENT_MANAGEMENT', this.msgMap.splitExpenseSelectorHeader, 'splitExpenseSelectorHeader')
      .addRequest('SPLIT_EXPENSE_DESCRIPTION_NO', 'EVENT_MANAGEMENT', this.msgMap.splitExpenseDescriptionNo, 'splitExpenseDescriptionNo')
      .addRequest('SPLIT_EXPENSE_DESCRIPTION_YES', 'EVENT_MANAGEMENT', this.msgMap.splitExpenseDescriptionYes, 'splitExpenseDescriptionYes')
      .sendRequest();

    Object.entries(this.msgMap).forEach(([key, message]) => {
      this[key] = message;
    });
  }

  handleOptionChange(event) {
    const selected = event.target.value;
    this.selectedOption = selected;
    this.options.forEach(option => {
      option.checked = option.value === selected;
    });
  }

  goToNext() {
    this.defaultFieldValues = JSON.stringify({ Split_Lines_vod__c: this.selectedOption });
    this.dispatchEvent(new FlowNavigationNextEvent());
  }

  finishFlow() {
    this.exitEarly = true;
    this.dispatchEvent(new FlowNavigationNextEvent());
  }

  get disableNext() {
    return !this.selectedOption;
  }
}