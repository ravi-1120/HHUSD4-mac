export default class EmExpenseConstant {
  static CONCUR_STATUS = 'Concur_Status_vod__c';
  static EXPENSE_HEADER = 'Expense_Header_vod__c';
  static EXPENSE_HEADER_RELATED = 'Expense_Header_vod__r';
  static TRANSACTION_DATE = 'Transaction_Date_vod__c';
  static FAILED_EXPENSE = 'Failed_Expense_vod__c';
  static ACTUAL = 'Actual_vod__c';
  static OWNER = 'Owner';
  static OWNER_ID = 'OwnerId';

  static HIDE_BUTTONS_CONCUR_STATUSES = ['Submitted_vod', 'Sending_vod'];
  static RESUBMIT_CONCUR_STATUSES = ['Failed_Connection_vod', 'Failed_Config_vod', 'Failed_Duplicate_vod'];
  static CONCUR_CANCELED_STATUS = 'Canceled_vod';
  static CONCUR_BUTTON = 'Submit_to_Concur_vod';
  static RESUBMIT_BUTTON_DEFAULT = 'Resubmit to Concur';
  static CONCUR_SUBMIT_CONFIRM_DEFAULT = 'Once the expense is submitted to Concur it will become locked. Any required changes to this expense must be completed in Concur.';
  static CONCUR_ADMIN_POST_DEFAULT = 'Expense will be submitted as {0}';
  static CONCUR_ALREADY_SENT_DEFAULT = 'This record has already been submitted to Concur and cannot be modified.';
  static CONCUR_USER_POST_ERROR_DEFAULT = 'An expense can only be submitted to Concur by the expense owner or a system admin';
  static CONCUR_TRANSACTION_DATE_ERROR_DEFAULT = 'A transaction date is required to submit an expense to Concur.';
  static CONCUR_SUBMIT_ACTUAL_DEFAULT = 'Please fill in all actual expense amounts before submitting your expense to Concur.';
}