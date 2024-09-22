export default class BusRuleConstant {
  static #EXPENSE_LIMIT = 'expenseLimit';
  static #PER_ATTENDEE = 'perAttendee';
  static #PER_EVENT = 'perEvent';
  static #PER_SPEAKER = 'perSpeaker';
  static #REQUIRED_MATERIAL = 'requiredMaterial';

  static ACTION_NAME = {
    EXIT: 'exit',
    REMOVE_ALL_CONTINUE: 'removeAllContinue',
    REMOVE_SELECTED_CONTINUE: 'removeSelectedContinue',
    SAVE_OVERRIDES_CONTINUE: 'saveOverridesContinue',
    SAVE_OVERRIDES_EXIT: 'saveOverridesExit',
    REJECT_REGISTRANT: 'rejectRegistrant',
    CONFIRM_MATCH: 'confirmMatch',
  };

  static COMMENT_TYPE = {
    HIDDEN: 'hidden',
    OPTIONAL: 'optional',
    REQUIRED: 'required',
  };

  static NEXT_STEP = {
    CONTINUE: 'continue',
    EXIT: 'exit',
    PAGE_TWO: 'page2',
  };

  static RECORD_TYPE_TO_RULE_TYPE = {
    EM_Actual_Versus_Estimate_Expense_Threshold_Rule_vod: BusRuleConstant.#EXPENSE_LIMIT,
    EM_Attendee_Expense_Cap_Rule_vod: BusRuleConstant.#EXPENSE_LIMIT,
    EM_Attendee_Product_Restriction_Rule_vod: BusRuleConstant.#PER_ATTENDEE,
    EM_Cross_Event_Attendee_Expense_Cap_Rule_vod: BusRuleConstant.#EXPENSE_LIMIT,
    EM_Cross_Event_Meal_Opt_In_Attendance_Limit_Rule_vod: BusRuleConstant.#PER_ATTENDEE,
    EM_Cross_Event_Per_Attendee_Attendance_Limit_Rule_vod: BusRuleConstant.#PER_ATTENDEE,
    EM_Cross_Event_Per_Speaker_Engagement_Limit_Rule_vod: BusRuleConstant.#PER_SPEAKER,
    EM_Meal_Opt_In_Attendance_Limit_Rule_vod: BusRuleConstant.#PER_ATTENDEE,
    EM_Per_Attendee_Attendance_Limit_Rule_vod: BusRuleConstant.#PER_ATTENDEE,
    EM_Per_Event_Attendance_Limit_Rule_vod: BusRuleConstant.#PER_EVENT,
    EM_Per_Event_Attendee_Expense_Limit_Rule_vod: BusRuleConstant.#EXPENSE_LIMIT,
    EM_Per_Event_Expense_Limit_Rule_vod: BusRuleConstant.#EXPENSE_LIMIT,
    EM_Per_Event_Speaker_Expense_Limit_Rule_vod: BusRuleConstant.#EXPENSE_LIMIT,
    EM_Per_Event_Speaker_Limit_Rule_vod: BusRuleConstant.#PER_EVENT,
    EM_Per_Event_Speaker_Ratio_Rule_vod: BusRuleConstant.#PER_EVENT,
    EM_Per_Speaker_Engagement_Limit_Rule_vod: BusRuleConstant.#PER_SPEAKER,
    EM_Required_Event_Material_Rule_vod: BusRuleConstant.#REQUIRED_MATERIAL,
    EM_Speaker_Attendance_Expense_Cap_Rule_vod: BusRuleConstant.#PER_SPEAKER,
    Speaker_Attendance_Product_Cap_Rule_vod: BusRuleConstant.#PER_SPEAKER,
    EM_Speaker_Attendance_Qualification_Rule_vod: BusRuleConstant.#PER_ATTENDEE,
  };

  static RULE_TYPE = {
    EXPENSE_LIMIT: BusRuleConstant.#EXPENSE_LIMIT,
    PER_ATTENDEE: BusRuleConstant.#PER_ATTENDEE,
    PER_EVENT: BusRuleConstant.#PER_EVENT,
    PER_SPEAKER: BusRuleConstant.#PER_SPEAKER,
    REQUIRED_MATERIAL: BusRuleConstant.#REQUIRED_MATERIAL,
  };

  static WARNING_TYPE = {
    HARD: 'Hard_Warning_vod',
    SOFT: 'Soft_Warning_vod',
  };
}