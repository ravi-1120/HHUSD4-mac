import { CHALLENGE_STATUSES, CHALLENGE_TYPES, ACCOUNT_CHANGE } from 'c/territoryFeedbackConstants';

export const COLUMN_PREFIXES = {
  GOAL: 'goal',
  DETAIL: 'detail',
  METRIC: 'metric',
  SEGMENT: 'segment',
};

export default class AccountRecord {
  constructor(account, isInTerritory) {
    this.accountId = account.id;
    this.location = account.location ?? null;
    this.id = this.constructAccountRecordId(account.id, account.location);
    this.name = account.formattedName ?? account.name;
    this.firstName = account.firstName;
    this.lastName = account.lastName;
    this.person = account.person;
    this.target = account.target;
    this.challengeType = account.challengeType;
    this.challengeStatus = account.challengeStatus;
    this.challengeReasons = account.challengeReasons ?? [];
    this.targetChallengeType = account.targetChallengeType;
    this.targetChallengeStatus = account.targetChallengeStatus;
    this.targetChallengeReasons = account.targetChallengeReasons ?? [];
    this.accountDetails = account.accountDetails ?? [];
    this.productMetricDetails = account.productMetricDetails ?? [];
    this.goalDetails = account.goalDetails ?? [];
    this.segmentDetails = account.segmentDetails ?? [];
    this.planTargetId = account.planTargetId;
    this.addresses = account.addresses ?? [];
    this.specialtyPrimary = account.specialtyPrimary;
    this.change = account.change;
    this.isInTerritory = isInTerritory;
    this.isRemoved = false;
  }

  get hasPendingChallenge() {
    return this.hasPendingAccountChallenge || this.hasPendingTargetChallenge;
  }

  get hasPendingAccountChallenge() {
    return this.hasAccountChallenge && this.challengeStatus === CHALLENGE_STATUSES.CHALLENGED;
  }

  get hasPendingTargetChallenge() {
    return this.hasTargetChallenge && this.targetChallengeStatus === CHALLENGE_STATUSES.CHALLENGED;
  }

  get hasApprovedChallenge() {
    return this.hasApprovedAccountChallenge || this.hasApprovedTargetChallenge;
  }

  get hasApprovedAccountChallenge() {
    return this.hasAccountChallenge && this.challengeStatus === CHALLENGE_STATUSES.APPROVED;
  }

  get hasApprovedTargetChallenge() {
    return this.hasTargetChallenge && this.targetChallengeStatus === CHALLENGE_STATUSES.APPROVED;
  }

  get hasRejectedChallenge() {
    return this.hasRejectedAccountChallenge || this.hasRejectedTargetChallenge;
  }

  get hasRejectedAccountChallenge() {
    return this.hasAccountChallenge && this.challengeStatus === CHALLENGE_STATUSES.REJECTED;
  }

  get hasRejectedTargetChallenge() {
    return this.hasTargetChallenge && this.targetChallengeStatus === CHALLENGE_STATUSES.REJECTED;
  }

  get hasChallenge() {
    return this.hasAccountChallenge || this.hasTargetChallenge;
  }

  get hasAccountChallenge() {
    return this.challengeType != null;
  }

  get hasTargetChallenge() {
    return this.targetChallengeType != null;
  }

  get shouldAllowApprove() {
    return (
      (this.hasAccountChallenge && this.challengeStatus !== CHALLENGE_STATUSES.APPROVED) ||
      (this.hasTargetChallenge && this.targetChallengeStatus !== CHALLENGE_STATUSES.APPROVED)
    );
  }

  get shouldAllowReject() {
    return (
      (this.hasAccountChallenge && this.challengeStatus !== CHALLENGE_STATUSES.REJECTED) ||
      (this.hasTargetChallenge && this.targetChallengeStatus !== CHALLENGE_STATUSES.REJECTED)
    );
  }

  get shouldAllowApproveAddAccountOnly() {
    return (
      this.challengeType === CHALLENGE_TYPES.ADD_ACCOUNT &&
      this.targetChallengeType === CHALLENGE_TYPES.ADD_TARGET &&
      !(this.challengeStatus === CHALLENGE_STATUSES.APPROVED && this.targetChallengeStatus === CHALLENGE_STATUSES.REJECTED)
    );
  }

  get shouldAllowApproveKeepAccountOnly() {
    return (
      this.challengeType === CHALLENGE_TYPES.KEEP_ACCOUNT &&
      this.targetChallengeType === CHALLENGE_TYPES.ADD_TARGET &&
      !(this.challengeStatus === CHALLENGE_STATUSES.APPROVED && this.targetChallengeStatus === CHALLENGE_STATUSES.REJECTED)
    );
  }

  get shouldAllowApproveRemoveTargetOnly() {
    return (
      this.challengeType === CHALLENGE_TYPES.REMOVE_ACCOUNT &&
      this.targetChallengeType === CHALLENGE_TYPES.REMOVE_TARGET &&
      !(this.challengeStatus === CHALLENGE_STATUSES.REJECTED && this.targetChallengeStatus === CHALLENGE_STATUSES.APPROVED)
    );
  }

  get shouldAllowAddTarget() {
    return !this.target && this.targetChallengeType !== CHALLENGE_TYPES.ADD_TARGET;
  }

  get shouldAllowKeepAccount() {
    return !this.isAssignedToTerritory && this.challengeType !== CHALLENGE_TYPES.KEEP_ACCOUNT;
  }

  get shouldAllowRemoveTarget() {
    return this.target && this.targetChallengeType !== CHALLENGE_TYPES.REMOVE_TARGET;
  }

  get shouldAllowRemoveAccount() {
    return !this.isDropped && this.challengeType !== CHALLENGE_TYPES.REMOVE_ACCOUNT;
  }

  get shouldAllowEditGoals() {
    return this.target;
  }

  get isAdded() {
    return this.isPendingAddAccount || (this.change === ACCOUNT_CHANGE.ADDED && !this.isPendingDrop && !this.isRejectedAddAccount);
  }

  get isDropped() {
    return (this.change === ACCOUNT_CHANGE.DROPPED && !this.isPendingAssignment) || this.isRejectedKeepAccount || (this.isPendingDrop && this.change === ACCOUNT_CHANGE.NO_CHANGE);
  }

  get isAssignedToTerritory() {
    return !this.isDropped && !this.isPendingDrop;
  }

  // Represents an account that is currently a Drop in this feedback cycle, but is pending reintroduction at the end of the cycle
  get isPendingAssignment() {
    return this.challengeType === CHALLENGE_TYPES.KEEP_ACCOUNT && this.challengeStatus !== CHALLENGE_STATUSES.REJECTED;
  }

  // Represents an account that is not currently a Drop in this feedback cycle, but is pending removal at the end of the cycle
  get isPendingDrop() {
    return this.challengeType === CHALLENGE_TYPES.REMOVE_ACCOUNT && this.challengeStatus !== CHALLENGE_STATUSES.REJECTED;
  }

  get isPendingAddTarget() {
    return this.targetChallengeType === CHALLENGE_TYPES.ADD_TARGET && this.targetChallengeStatus !== CHALLENGE_STATUSES.REJECTED;
  }

  get isPendingRemoveTarget() {
    return this.targetChallengeType === CHALLENGE_TYPES.REMOVE_TARGET && this.targetChallengeStatus !== CHALLENGE_STATUSES.REJECTED;
  }

  get isPendingAddAccount() {
    return this.challengeType === CHALLENGE_TYPES.ADD_ACCOUNT && this.challengeStatus !== CHALLENGE_STATUSES.REJECTED;
  }

  get isRejectedAddAccount() {
    return this.challengeType === CHALLENGE_TYPES.ADD_ACCOUNT && this.challengeStatus === CHALLENGE_STATUSES.REJECTED;
  }

  get isRejectedKeepAccount() {
    return this.challengeType === CHALLENGE_TYPES.KEEP_ACCOUNT && this.challengeStatus === CHALLENGE_STATUSES.REJECTED;
  }

  get isRejectedAddTarget() {
    return this.targetChallengeType === CHALLENGE_TYPES.ADD_TARGET && this.targetChallengeStatus === CHALLENGE_STATUSES.REJECTED;
  }

  get isRejectedRemoveTarget() {
    return this.targetChallengeType === CHALLENGE_TYPES.REMOVE_TARGET && this.targetChallengeStatus === CHALLENGE_STATUSES.REJECTED;
  }

  get isRejectedEditGoals() {
    return this.targetChallengeType === CHALLENGE_TYPES.GOAL_EDIT && this.targetChallengeStatus === CHALLENGE_STATUSES.REJECTED;
  }

  get isBusiness() {
    return !this.person;
  }

  get addDropStatus() {
    if (this.isAdded) {
      return ACCOUNT_CHANGE.ADDED;
    }
    
    if (this.isDropped) {
      return ACCOUNT_CHANGE.DROPPED;
    }

    return ACCOUNT_CHANGE.NO_CHANGE;
  }

  get shouldUseFeedbackGoalIfAvailable() {
    return !this.isRejectedEditGoals;
  }

  constructAccountRecordId(accountId, location) {
    let recordId = accountId;

    if (location?.id) {
      recordId += `_${location.id}`;
    }

    return recordId;
  }
}