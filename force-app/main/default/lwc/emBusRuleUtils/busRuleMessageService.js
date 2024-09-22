import { getService, SERVICES } from 'c/veevaServiceFactory';

export default class BusRuleMessageService {
  #messageSvc = getService(SERVICES.MESSAGE);
  #uiApi = getService(SERVICES.UI_API);

  async getBusRulesMessages(eventName) {
    const [veevaMessages, fieldLabels] = await Promise.all([this._getVeevaMessages(eventName), this._getFieldLabels()]);
    return { ...veevaMessages, ...fieldLabels };
  }
  async _getVeevaMessages(eventName) {
    const messages = await this.#messageSvc
      .createMessageRequest()

      // required material headers
      .addRequest(
        'EM_RULE_REQUIRED_EVENT_MATERIAL_HARD_WARNING_TITLE',
        'EVENT_MANAGEMENT',
        'The Following Event Material(s) have Hard Violations',
        'EM_RULE_REQUIRED_EVENT_MATERIAL_HARD_WARNING_TITLE'
      )
      .addRequest(
        'EM_RULE_REQUIRED_EVENT_MATERIAL_HARD_WARNING_SUBTITLE',
        'EVENT_MANAGEMENT',
        'Return to the event and upload missing files and attachments.',
        'EM_RULE_REQUIRED_EVENT_MATERIAL_HARD_WARNING_SUBTITLE'
      )
      .addRequest(
        'EM_RULE_REQUIRED_EVENT_MATERIAL_SOFT_WARNING_TITLE',
        'EVENT_MANAGEMENT',
        'The Following Event Material(s) have Soft Violations',
        'EM_RULE_REQUIRED_EVENT_MATERIAL_SOFT_WARNING_TITLE'
      )
      .addRequest(
        'EM_RULE_REQUIRED_EVENT_MATERIAL_SOFT_WARNING_SUBTITLE',
        'EVENT_MANAGEMENT',
        'If required, add a comment for the following. Click continue to proceed.',
        'EM_RULE_REQUIRED_EVENT_MATERIAL_SOFT_WARNING_SUBTITLE'
      )

      // per attendee violation headers
      .addRequest(
        'EM_RULE_PER_ATTENDEE_ATTENDANCE_HARD_WARNING_TITLE',
        'EVENT_MANAGEMENT',
        'The Following Attendee(s) have Hard Violations',
        'PER_ATTENDEE_HARD_WARNING_TITLE'
      )
      .addRequest(
        'EM_RULE_PER_ATTENDEE_ATTENDANCE_HARD_WARNING_SUBTITLE',
        'EVENT_MANAGEMENT',
        'The following attendee(s) will be removed from the event {0}. Click continue to proceed. Note: This action cannot be undone.',
        'PER_ATTENDEE_HARD_WARNING_SUBTITLE'
      )
      .addRequest(
        'EM_RULE_PER_ATTENDEE_ATTENDANCE_SOFT_WARNING_TITLE',
        'EVENT_MANAGEMENT',
        'The Following Attendee(s) have Soft Violations',
        'PER_ATTENDEE_SOFT_WARNING_TITLE'
      )
      .addRequest(
        'EM_RULE_PER_ATTENDEE_ATTENDANCE_SOFT_WARNING_SUBTITLE',
        'EVENT_MANAGEMENT',
        'Select attendee(s) you wish to remove from the event {0}. Click continue to proceed. Note: This action cannot be undone.',
        'PER_ATTENDEE_SOFT_WARNING_SUBTITLE'
      )
      .addRequest(
        'EM_RULE_PER_ATTENDEE_ATTENDANCE_SOFT_WARNING_SUBTITLE2',
        'EVENT_MANAGEMENT',
        'Add a comment for the following attendee(s) to proceed.',
        'PER_ATTENDEE_SOFT_WARNING_SUBTITLE2'
      )

      // per speaker violation headers
      .addRequest(
        'EM_RULE_PER_SPEAKER_ATTENDANCE_HARD_WARNING_TITLE',
        'EVENT_MANAGEMENT',
        'The Following Speaker(s) have Hard Violations',
        'PER_SPEAKER_ATTENDANCE_HARD_WARNING_TITLE'
      )
      .addRequest(
        'EM_RULE_PER_SPEAKER_ATTENDANCE_HARD_WARNING_SUBTITLE',
        'EVENT_MANAGEMENT',
        'The following speaker(s) will be removed from the event {0}. Click continue to proceed. This action cannot be undone.',
        'PER_SPEAKER_ATTENDANCE_HARD_WARNING_SUBTITLE'
      )
      .addRequest(
        'EM_RULE_PER_SPEAKER_ATTENDANCE_SOFT_WARNING_TITLE',
        'EVENT_MANAGEMENT',
        'The Following Speaker(s) have Soft Violations',
        'PER_SPEAKER_ATTENDANCE_SOFT_WARNING_TITLE'
      )
      .addRequest(
        'EM_RULE_PER_SPEAKER_ATTENDANCE_SOFT_WARNING_SUBTITLE',
        'EVENT_MANAGEMENT',
        'Select speaker(s) you wish to remove from the event {0}. Click continue to proceed. This action cannot be undone.',
        'PER_SPEAKER_ATTENDANCE_SOFT_WARNING_SUBTITLE'
      )
      .addRequest(
        'EM_RULE_PER_SPEAKER_ATTENDANCE_SOFT_WARNING_SUBTITLE2',
        'EVENT_MANAGEMENT',
        'If required, add a comment for the following. Click continue to proceed.',
        'PER_SPEAKER_ATTENDANCE_SOFT_WARNING_SUBTITLE2'
      )

      // per event violation headers
      .addRequest(
        'EM_RULE_PER_EVENT_ATTENDANCE_HARD_WARNING_TITLE',
        'EVENT_MANAGEMENT',
        'Event Does Not Meet Attendance Limits',
        'PER_EVENT_HARD_WARNING_TITLE'
      )
      .addRequest(
        'EM_RULE_PER_EVENT_ATTENDANCE_HARD_WARNING_SUBTITLE',
        'EVENT_MANAGEMENT',
        'This event does not meet attendance limits. Return to the event and adjust attendee count.',
        'PER_EVENT_HARD_WARNING_SUBTITLE'
      )
      .addRequest(
        'EM_RULE_PER_EVENT_ATTENDANCE_SOFT_WARNING_TITLE',
        'EVENT_MANAGEMENT',
        'Event Does Not Meet Attendance Limits',
        'PER_EVENT_SOFT_WARNING_TITLE'
      )
      .addRequest(
        'EM_RULE_PER_EVENT_ATTENDANCE_SOFT_WARNING_SUBTITLE',
        'EVENT_MANAGEMENT',
        'Add a comment for the following violations. Click continue to proceed',
        'PER_EVENT_SOFT_WARNING_SUBTITLE'
      )

      // expense limit violation headers
      .addRequest(
        'EM_RULE_PER_EXPENSE_LIMIT_HARD_WARNING_TITLE',
        'EVENT_MANAGEMENT',
        'The following expense limit(s) have been violated',
        'PER_EXPENSE_HARD_WARNING_TITLE'
      )
      .addRequest(
        'EM_RULE_PER_EXPENSE_LIMIT_HARD_WARNING_SUBTITLE',
        'EVENT_MANAGEMENT',
        'Return to the event and adjust expense inputs',
        'PER_EXPENSE_HARD_WARNING_SUBTITLE'
      )
      .addRequest(
        'EM_RULE_PER_EXPENSE_LIMIT_SOFT_WARNING_TITLE',
        'EVENT_MANAGEMENT',
        'The following expense limit(s) have been violated',
        'PER_EXPENSE_SOFT_WARNING_TITLE'
      )
      .addRequest(
        'EM_RULE_PER_EXPENSE_LIMIT_SOFT_WARNING_SUBTITLE',
        'EVENT_MANAGEMENT',
        'If required, add a comment for the following violations. Click continue to proceed.',
        'PER_EXPENSE_SOFT_WARNING_SUBTITLE'
      )

      // attendee potential warning headers
      .addRequest(
        'EM_RULE_POTENTIAL_ATTENDANCE_WARNING_TITLE',
        'EVENT_MANAGEMENT',
        'The Following Attendee(s) have Potential Rule Violations',
        'POTENTIAL_ATTENDANCE_WARNING_TITLE'
      )
      .addRequest(
        'EM_RULE_POTENTIAL_ATTENDANCE_WARNING_SUBTITLE',
        'EVENT_MANAGEMENT',
        'Select attendee(s) you wish to remove from the event. Click continue to proceed.',
        'POTENTIAL_ATTENDANCE_WARNING_SUBTITLE'
      )

      // speaker potential warning headers
      .addRequest(
        'EM_RULE_POTENTIAL_SPEAKER_WARNING_SUBTITLE',
        'EVENT_MANAGEMENT',
        'Select the speaker(s) you wish to remove from the event. Click continue to proceed.',
        'POTENTIAL_SPEAKER_WARNING_SUBTITLE'
      )
      .addRequest(
        'EM_RULE_POTENTIAL_SPEAKER_WARNING_TITLE',
        'EVENT_MANAGEMENT',
        'The Following Speaker(s) have Potential Rule Violations',
        'POTENTIAL_SPEAKER_WARNING_TITLE'
      )

      // expense potential warning headers
      .addRequest(
        'EM_RULE_POTENTIAL_EXPENSE_WARNING_TITLE',
        'EVENT_MANAGEMENT',
        'The Following Expense(s) have Potential Rule Violations',
        'POTENTIAL_EXPENSE_WARNING_TITLE'
      )
      .addRequest(
        'EM_RULE_POTENTIAL_EXPENSE_WARNING_SUBTITLE',
        'EVENT_MANAGEMENT',
        'Return to the event to adjust expense inputs, or click continue to proceed.',
        'POTENTIAL_EXPENSE_WARNING_SUBTITLE'
      )

      // attendee reconciliation violation headers
      .addRequest(
        'EM_RULE_PER_ATTENDEE_ATTENDANCE_RECONCILIATION_HARD_WARNING_SUBTITLE',
        'EVENT_MANAGEMENT',
        'The following registrant cannot be reconciled to the Account for the event {0}. Select reject to complete the reconciliation. An email will be sent automatically to notify the registrant.',
        'EM_RULE_PER_ATTENDEE_ATTENDANCE_RECONCILIATION_HARD_WARNING_SUBTITLE'
      )
      .addRequest(
        'EM_RULE_PER_ATTENDEE_ATTENDANCE_RECONCILIATION_SOFT_WARNING_SUBTITLE',
        'EVENT_MANAGEMENT',
        'Select confirm to proceed with reconciling the attendee.',
        'EM_RULE_PER_ATTENDEE_ATTENDANCE_RECONCILIATION_SOFT_WARNING_SUBTITLE'
      )
      .addRequest(
        'EM_RULE_PER_ATTENDEE_ATTENDANCE_RECONCILIATION_SOFT_WARNING_SUBTITLE2',
        'EVENT_MANAGEMENT',
        'If required, add a comment for the following attendee. Select confirm to proceed with reconciling the attendee.',
        'EM_RULE_PER_ATTENDEE_ATTENDANCE_RECONCILIATION_SOFT_WARNING_SUBTITLE2'
      )

      // button labels
      .addRequest('CONTINUE', 'Common', 'Continue', 'CONTINUE')
      .addRequest('CLOSE', 'Common', 'Close', 'CLOSE')
      .addRequest('EM_RULE_SAVE_COMMENTS', 'EVENT_MANAGEMENT', 'Save Comments and Return To Event', 'SAVE_COMMENTS')
      .addRequest('REMOVE_ALL_ATTENDEES', 'EVENT_MANAGEMENT', 'Remove All', 'REMOVE_ALL')
      .addRequest('REMOVE_ATTENDEES_CONTINUE', 'EVENT_MANAGEMENT', 'Remove and Continue', 'REMOVE_AND_CONTINUE')
      .addRequest('REJECT_REGISTRANT', 'EVENT_MANAGEMENT', 'Reject Registrant', 'REJECT_REGISTRANT')
      .addRequest('CONFIRM_MATCH', 'EVENT_MANAGEMENT', 'Confirm Match', 'CONFIRM_MATCH')

      // error messages
      .addRequest('ERROR_EVENT_BUSINESS_RULE_VALIDATION', 'EVENT_MANAGEMENT', 'Event Business Rule Error', 'ERROR_EVENT_BUSINESS_RULE_VALIDATION')
      .addRequest(
        'ERROR_EVENT_BUSINESS_RULE_VALIDATION_DESCRIPTION',
        'EVENT_MANAGEMENT',
        'Unable to run the defined Event Business Rules for this event. Please contact your administrator.',
        'ERROR_EVENT_BUSINESS_RULE_VALIDATION_DESCRIPTION'
      )
      .addRequest('ERROR_EVENT_BUSINESS_RULE_SYSTEM', 'EVENT_MANAGEMENT', 'Cannot Complete Event Action', 'ERROR_EVENT_BUSINESS_RULE_SYSTEM')
      .addRequest(
        'ERROR_EVENT_BUSINESS_RULE_SYSTEM_DESCRIPTION',
        'EVENT_MANAGEMENT',
        'The requested action cannot be completed. Please try again or contact your administrator.',
        'ERROR_EVENT_BUSINESS_RULE_SYSTEM_DESCRIPTION'
      )
      .addRequest(
        'ERROR_EVENT_BUSINESS_RULE_PERMISSIONS_DESCRIPTION',
        'EVENT_MANAGEMENT',
        "You do not have access rights to resolve one or more of this event's business rule violations. Please contact an event team member or an administrator.",
        'ERROR_EVENT_BUSINESS_RULE_PERMISSIONS_DESCRIPTION'
      )
      .sendRequest();
    [
      'PER_ATTENDEE_SOFT_WARNING_SUBTITLE',
      'PER_ATTENDEE_HARD_WARNING_SUBTITLE',
      'PER_SPEAKER_ATTENDANCE_SOFT_WARNING_SUBTITLE',
      'PER_SPEAKER_ATTENDANCE_HARD_WARNING_SUBTITLE',
      'EM_RULE_PER_ATTENDEE_ATTENDANCE_RECONCILIATION_HARD_WARNING_SUBTITLE'
    ].forEach(key => {
      messages[key] = messages[key].replace('{0}', eventName);
    });
    return messages;
  }

  async _getFieldLabels() {
    const eventOverrideDescribe = await this.#uiApi.objectInfo('EM_Event_Override_vod__c');
    return {
      COMMENT: eventOverrideDescribe.fields?.Comment_vod__c?.label ?? 'Comment',
    };
  }
}