import EmBusRuleWarningsModal from 'c/emBusRuleWarningsModal';
import { BusRuleConstant } from 'c/emBusRuleUtils';
import { isStatusSendingOrSubmitted } from 'c/emSubmitToConcurErrorHandling';

import BaseButtonController from './baseButtonController';

export default class ExpenseHeaderButtonController extends BaseButtonController {
  clickHandlers = {
    Submit_to_Concur_vod: this.submitToConcurView,
  };

  async submitToConcurView() {
    if (await isStatusSendingOrSubmitted(this.pageCtrl.concurSvc, this.recordId)) {
      await this.pageCtrl.showConcurAlreadySentAlertPopup();
      return;
    }

    const errors = await this.pageCtrl.validateConcurSubmission();
    if (errors.length > 0) {
      throw new Error(errors[0]); // only throw first error
    }

    const confirm = await this.pageCtrl.getSubmitToConcurConfirmPopup();
    if (!confirm) {
      return;
    }

    const response = await this.pageCtrl.concurSvc.submitToConcur(this.recordId, true);
    if (response?.data) {
      // business rule potential warnings
      // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
      const modalResult = await EmBusRuleWarningsModal.open({
        warnings: response.data,
        type: BusRuleConstant.RULE_TYPE.EXPENSE_LIMIT,
        label: await this.pageCtrl.getMessageWithDefault(
          'EM_RULE_POTENTIAL_EXPENSE_WARNING_TITLE',
          'EVENT_MANAGEMENT',
          'The Following Expense(s) have Potential Rule Violations'
        ),
        size: 'medium',
      });
      if (modalResult?.success) {
        // submit again without business rules
        await this.pageCtrl.concurSvc.submitToConcur(this.recordId, false);
      }
    }
  }
}