export default class TerritoryFeedbackConstants {
  static FIELD_PLANS = 'fieldPlans';
  static TERRITORIES = 'territories';
  static ACCOUNTS = 'accounts';

  // Filters for the Accounts screen
  static TARGETS = 'TARGETS';
  static ALL_CHALLENGES = 'ALL_CHALLENGES';
  static PENDING_CHALLENGES = 'PENDING_CHALLENGES';
  static PERSON_ACCOUNTS = 'PERSON_ACCOUNTS';
  static BUSINESS_ACCOUNTS = 'BUSINESS_ACCOUNTS';
}

export const CHALLENGE_STATUSES = {
  APPROVED: 'Approved',
  REJECTED: 'Rejected',
  CHALLENGED: 'Challenged',
};

export const CHALLENGE_TYPES = {
  ADD_ACCOUNT: 'AddAccount',
  ADD_TARGET: 'AddTarget',
  REMOVE_ACCOUNT: 'RemoveAccount',
  REMOVE_TARGET: 'RemoveTarget',
  EDIT_GOAL: 'EditGoal',
  KEEP_ACCOUNT: 'KeepAccount',
  GOAL_EDIT: 'GoalEdit',
};

export const ACCOUNT_CHANGE = {
  ADDED: 'ADDED',
  DROPPED: 'DROPPED',
  NO_CHANGE: 'NO_CHANGE',
};

export const ALIGN_TYPES = {
  STRING: 'STRING',
  BOOLEAN: 'BOOLEAN',
  DATE: 'DATE',
  DATETIME: 'DATETIME',
  NUMBER: 'NUMBER',
};

export const NULL_DISPLAY_STRING = '-';

export const GEO_TYPES = {
  POSTAL_CODE: 'POSTAL_CODE',
  BRICK: 'BRICK',
};