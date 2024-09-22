import { BusRuleConstant, BusRuleDataService, BusRuleMessageService } from 'c/emBusRuleUtils';
import VeevaUtils from 'c/veevaUtils';

import EmEventConstant from 'c/emEventConstant';
import ExpenseLimitViolationHandler from './handlers/expenseLimitViolationHandler';
import PerAttendeeViolationHandler from './handlers/perAttendeeViolationHandler';
import PerSpeakerViolationHandler from './handlers/perSpeakerViolationHandler';
import PerEventViolationHandler from './handlers/perEventViolationHandler';
import RequiredMaterialViolationHandler from './handlers/requiredMaterialViolationHandler';
import PerAttendeeReconciliationViolationHandler from './handlers/perAttendeeReconciliationViolationHandler';

const RULE_DISPLAY_ORDER = [
  BusRuleConstant.RULE_TYPE.REQUIRED_MATERIAL,
  BusRuleConstant.RULE_TYPE.PER_ATTENDEE,
  BusRuleConstant.RULE_TYPE.PER_SPEAKER,
  BusRuleConstant.RULE_TYPE.PER_EVENT,
  BusRuleConstant.RULE_TYPE.EXPENSE_LIMIT,
];

const RULE_TYPE_TO_HANDLER = {
  [BusRuleConstant.RULE_TYPE.EXPENSE_LIMIT]: ExpenseLimitViolationHandler,
  [BusRuleConstant.RULE_TYPE.PER_ATTENDEE]: PerAttendeeViolationHandler,
  [BusRuleConstant.RULE_TYPE.PER_ATTENDEE + EmEventConstant.ATTENDEE_RECONCILIATION]: PerAttendeeReconciliationViolationHandler,
  [BusRuleConstant.RULE_TYPE.PER_EVENT]: PerEventViolationHandler,
  [BusRuleConstant.RULE_TYPE.PER_SPEAKER]: PerSpeakerViolationHandler,
  [BusRuleConstant.RULE_TYPE.REQUIRED_MATERIAL]: RequiredMaterialViolationHandler,
};

export default class ViolationsModalController {
  dataSvc = new BusRuleDataService();

  ruleTypeToViolations = {
    [BusRuleConstant.RULE_TYPE.EXPENSE_LIMIT]: [],
    [BusRuleConstant.RULE_TYPE.PER_ATTENDEE]: [],
    [BusRuleConstant.RULE_TYPE.PER_EVENT]: [],
    [BusRuleConstant.RULE_TYPE.PER_SPEAKER]: [],
    [BusRuleConstant.RULE_TYPE.REQUIRED_MATERIAL]: [],
  };

  constructor(buttonName, eventId, eventName, violations, entryPoint) {
    this.buttonName = buttonName;
    this.eventId = eventId;
    this.eventName = eventName;
    this.violations = violations;
    this.entryPoint = entryPoint ?? '';
    this.initRules();
  }

  initRules() {
    const rules = JSON.parse(JSON.stringify(this.violations));
    rules.forEach(rule => {
      const ruleType = BusRuleConstant.RECORD_TYPE_TO_RULE_TYPE[rule.EM_Business_Rule_vod__c.RecordTypeId];

      rule.EM_Event_Override_vod__c.Id = rule.EM_Event_Override_vod__c.Id ?? VeevaUtils.getRandomId();

      if (ruleType) {
        this.ruleTypeToViolations[ruleType]?.push(rule);
      }
    });
  }

  async getMessages() {
    if (!this.messages) {
      const messageSvc = new BusRuleMessageService();
      this.messages = await messageSvc.getBusRulesMessages(this.eventName);
    }
    return this.messages;
  }

  getNextRule() {
    let nextRule = null;
    for (const rule of RULE_DISPLAY_ORDER) {
      if (this.ruleTypeToViolations[rule].length) {
        nextRule = rule;
        break;
      }
    }
    return nextRule;
  }

  async getNextPage() {
    this.currentRule = this.getNextRule();
    if (!this.currentRule) {
      return {
        close: 'success',
      };
    }
    return this.getPage();
  }

  async getPage(page = 1) {
    this.handler = new RULE_TYPE_TO_HANDLER[this.currentRule + this.entryPoint](
      this.eventId,
      this.ruleTypeToViolations[this.currentRule],
      await this.getMessages(),
      page
    );
    const nextPage = {
      buttons: this.handler.buttons,
      header: this.handler.header,
      messages: this.messages,
      rows: this.handler.showCheckbox ? this.handler.getCheckboxRows() : this.handler.getCommentRows(),
      ruleType: this.currentRule,
      showCheckbox: this.handler.showCheckbox,
      subheader: this.handler.subheader,
    };
    return nextPage;
  }

  async refreshPerEventRules() {
    const newPerEventRules = await this.dataSvc.reloadPerEventViolations(this.eventId, this.buttonName);
    newPerEventRules.forEach(rule => {
      rule.EM_Event_Override_vod__c.Id = rule.EM_Event_Override_vod__c.Id ?? VeevaUtils.getRandomId();
    });
    this.ruleTypeToViolations[BusRuleConstant.RULE_TYPE.PER_EVENT] = newPerEventRules;
  }

  async handleButton(buttonName, overrides, checkedRows) {
    const { nextStep, refreshPerEvent, remainingRecords } = await this.handler.handleButton(buttonName, overrides, checkedRows);
    this.ruleTypeToViolations[this.currentRule] = remainingRecords;
    if (refreshPerEvent) {
      await this.refreshPerEventRules();
    }
    let nextPage;
    if (nextStep === BusRuleConstant.NEXT_STEP.CONTINUE) {
      nextPage = this.getNextPage();
    } else if (nextStep === BusRuleConstant.NEXT_STEP.PAGE_TWO) {
      nextPage = this.getPage(2);
    } else {
      nextPage = {
        close: 'exitEarly',
      };
    }
    return nextPage;
  }
}