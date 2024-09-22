import { BusRuleConstant, BusRuleMessageService } from 'c/emBusRuleUtils';
import AttendeeWarningHandler from './handlers/attendeeWarningHandler';
import ExpenseWarningHandler from './handlers/expenseWarningHandler';
import SpeakerWarningHandler from './handlers/speakerWarningHandler';

const RULE_TYPE_TO_HANDLER = {
  [BusRuleConstant.RULE_TYPE.EXPENSE_LIMIT]: ExpenseWarningHandler,
  [BusRuleConstant.RULE_TYPE.PER_ATTENDEE]: AttendeeWarningHandler,
  [BusRuleConstant.RULE_TYPE.PER_SPEAKER]: SpeakerWarningHandler,
};

export default class WarningsModalController {
  constructor(warnings, type) {
    this.warnings = warnings;
    this.type = type;
  }

  async getPage() {
    const messageSvc = new BusRuleMessageService();
    const messages = await messageSvc.getBusRulesMessages('');
    const handler = new RULE_TYPE_TO_HANDLER[this.type](this.warnings, messages);
    const page = {
      header: handler.header,
      messages,
      rows: handler.showCheckbox ? handler.getCheckboxRows() : handler.getCommentRows(),
      ruleType: this.type,
      showCheckbox: handler.showCheckbox,
      subheader: handler.subheader,
    };
    return page;
  }
}