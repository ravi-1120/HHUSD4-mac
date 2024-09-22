import { BusRuleConstant, BusRuleDataService } from 'c/emBusRuleUtils';
import VeevaUtils from 'c/veevaUtils';

const SHOW_COMMENT_BOX = [BusRuleConstant.COMMENT_TYPE.OPTIONAL, BusRuleConstant.COMMENT_TYPE.REQUIRED];

export default class BaseViolationHandler {
  busRuleDataSvc = new BusRuleDataService();

  constructor(eventId, violations, messages, page = 1) {
    this.eventId = eventId;
    this.violations = violations;
    this.messages = messages;
    this.page = page;
  }

  get showCheckbox() {
    return false;
  }

  get objectApiName() {
    return null;
  }

  get nameField() {
    return null;
  }

  get hasComments() {
    return (
      !this.isHardWarningScreen &&
      this.recordsToDisplay.some(record => record.EM_Event_Override_vod__c.Comment_Box_vod__c !== BusRuleConstant.COMMENT_TYPE.HIDDEN)
    );
  }

  get buttons() {
    const buttons = [];
    if (this.isHardWarningScreen) {
      buttons.push({ name: BusRuleConstant.ACTION_NAME.EXIT, label: this.messages.CLOSE, variant: 'brand' });
    } else {
      if (this.hasComments) {
        buttons.push({ name: BusRuleConstant.ACTION_NAME.SAVE_OVERRIDES_EXIT, label: this.messages.SAVE_COMMENTS });
      }
      buttons.push({ name: BusRuleConstant.ACTION_NAME.SAVE_OVERRIDES_CONTINUE, label: this.messages.CONTINUE, variant: 'brand' });
    }
    return buttons;
  }

  get isHardWarningScreen() {
    return this.violations.some(rule => rule.EM_Business_Rule_vod__c.Warning_Type_vod__c === BusRuleConstant.WARNING_TYPE.HARD);
  }

  get recordsToDisplay() {
    const warningType = this.isHardWarningScreen ? BusRuleConstant.WARNING_TYPE.HARD : BusRuleConstant.WARNING_TYPE.SOFT;
    return this.violations.filter(rule => rule.EM_Business_Rule_vod__c.Warning_Type_vod__c === warningType);
  }

  get buttonHandlers() {
    return {
      [BusRuleConstant.ACTION_NAME.SAVE_OVERRIDES_CONTINUE]: this.saveEventOverrides,
      [BusRuleConstant.ACTION_NAME.SAVE_OVERRIDES_EXIT]: this.saveEventOverrides,
    };
  }

  getCheckboxRows() {
    const checkboxRows = this.recordsToDisplay.map(record => this.generateCheckboxRow(record));
    return this.removeDuplicateNames(checkboxRows);
  }

  getCommentRows() {
    const commentRows = this.recordsToDisplay.map(record => this.generateCommentRow(record));
    return this.removeDuplicateNames(commentRows);
  }

  generateCheckboxRow(record) {
    return {
      checked: false,
      id: this.objectApiName ? record[this.objectApiName].Id : null,
      key: record.EM_Event_Override_vod__c.Id,
      name: this.objectApiName ? record[this.objectApiName][this.nameField] : '',
      warning: record.EM_Event_Override_vod__c.Warning_Text_vod__c,
    };
  }

  generateCommentRow(record) {
    return {
      commentBox: SHOW_COMMENT_BOX.includes(record.EM_Event_Override_vod__c.Comment_Box_vod__c),
      commentRequired: record.EM_Event_Override_vod__c.Comment_Box_vod__c === BusRuleConstant.COMMENT_TYPE.REQUIRED,
      id: this.objectApiName ? record[this.objectApiName].Id : null,
      name: this.objectApiName ? record[this.objectApiName][this.nameField] : '',
      override: JSON.parse(JSON.stringify(record.EM_Event_Override_vod__c)),
    };
  }

  removeDuplicateNames(rows) {
    let prevRowId;
    rows.forEach(row => {
      if (prevRowId === row.id) {
        row.name = '';
      } else {
        prevRowId = row.id;
      }
    });
    return rows;
  }

  async handleButton(buttonName, overrides, checkedRows) {
    if (this.buttonHandlers[buttonName]) {
      return this.buttonHandlers[buttonName].bind(this)(buttonName, overrides, checkedRows);
    }
    return {
      nextStep: BusRuleConstant.NEXT_STEP.EXIT,
    };
  }

  // eslint-disable-next-line no-unused-vars
  async saveEventOverrides(buttonName, overrides, checkedRows) {
    const overridesToSave = this.processEventOverrides(overrides);
    if (overridesToSave.length) {
      await this.busRuleDataSvc.saveEventOverrides(overridesToSave);
    }
    return {
      nextStep:
        buttonName === BusRuleConstant.ACTION_NAME.SAVE_OVERRIDES_CONTINUE ? BusRuleConstant.NEXT_STEP.CONTINUE : BusRuleConstant.NEXT_STEP.EXIT,
      remainingRecords: [],
    };
  }

  processEventOverrides(overrides) {
    return overrides.map(override => {
      const newOverride = {};
      if (VeevaUtils.validSfdcId(override.Id)) {
        newOverride.Id = override.Id;
      } else {
        newOverride.Event_vod__c = override.Event_vod__c;
        newOverride.Event_Action_vod__c = override.Event_Action_vod__c;
        newOverride.RecordTypeId = override.RecordTypeId;
        newOverride.Veeva_ID_vod__c = override.Veeva_ID_vod__c;
        newOverride.EM_Attendee_vod__c = override.EM_Attendee_vod__c || null;
        newOverride.EM_Event_Material_vod__c = override.EM_Event_Material_vod__c || null;
        newOverride.EM_Speaker_vod__c = override.EM_Speaker_vod__c || null;
        newOverride.Status_vod__c = 'Active';
      }
      newOverride.Comment_Box_vod__c = override.Comment_Box_vod__c;
      if (override.Comment_vod__c?.trim().length) {
        newOverride.Comment_vod__c = override.Comment_vod__c;
      } else {
        newOverride.Comment_vod__c = null;
      }
      if (override.Warning_Text_vod__c?.trim().length) {
        newOverride.Warning_Text_vod__c = override.Warning_Text_vod__c;
      } else {
        newOverride.Warning_Text_vod__c = null;
      }
      return newOverride;
    });
  }
}