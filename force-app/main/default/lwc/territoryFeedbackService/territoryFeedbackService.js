import FieldPlanRecord from 'c/fieldPlanRecord';
import { TimeoutError, AlignError, NoFieldPlansError } from 'c/territoryFeedbackErrors';
import uuidV4 from 'c/uuidV4';
import FeedbackChannelGoalRequest from 'c/feedbackChannelGoalRequest';

export default class TerritoryFeedbackService {
  static FEEDBACK_PATH = '/align/feedback';
  static REQUEST_TIMEOUT_MS = 20000;
  static POST_REQUEST_TIMEOUT_MS = 60000;

  constructor(alignServer, alignVersion) {
    this._alignServer = convertToRedesignedFeedbackURL(alignServer);
    this._alignVersion = alignVersion;
    this._sourceGlobalTag = uuidV4();
  }

  async login(crmUserId, crmLanguage, sfSession, sfEndpoint) {
    return this.getRequest('/login', { crmUserId, crmLanguage }, { 'SF-Session': sfSession, 'SF-Endpoint': sfEndpoint });
  }

  async getFieldPlans() {
    const json = await this.getRequest(`/manager/field-plans`);
    json.fieldPlans = json.fieldPlans.map(fieldPlan => new FieldPlanRecord(fieldPlan));
    return json;
  }

  async getFieldPlanInfo(fieldPlanId) {
    const json = await this.getRequest(`/manager/field-plans/${fieldPlanId}`);
    return new FieldPlanRecord(json);
  }

  async bulkApproveOrRejectPendingChallenges(territoryModelId, shouldApprove) {
    return this.postRequest(`/manager/territory-model/${territoryModelId}/hierarchy/challenges`, { isApprove: shouldApprove });
  }

  async moveToLifecycleState(territoryModelId, targetLifecycleState, runAsynchronously) {
    return this.postRequest(`/manager/territory-model/${territoryModelId}/hierarchy/lifecycle-state/${runAsynchronously ? 'async' : 'sync'}`, {
      lifecycleStateAction: targetLifecycleState,
    });
  }

  async getAsynchronousProcessFlag() {
    const json = await this.getRequest(`/manager/async-processing-flag`);
    return json.asynchronousProcessRunning;
  }

  async getTerritoryModelDetails(territoryModelId, filter) {
    const url = `/territory/${territoryModelId}`;
    return filter ? this.getRequest(url, { filter }) : this.getRequest(url);
  }

  async approveOrRejectChallenges(territoryModelId, accountIds, shouldApprove, filter) {
    const requestData = {
      approve: shouldApprove,
      accountIds,
    };
    if (filter && shouldApprove && accountIds.length === 1) {
      requestData.filter = filter;
    }

    return this.postRequest(`/manager/territory-model/${territoryModelId}/challenges`, null, requestData);
  }

  async makeEditGoalsChallenge(territoryModelId, feedbackGoalEditorRecord) {
    const editGoalsRequest = {
      channelGoalRequest: instantiateChannelGoalRequests(feedbackGoalEditorRecord, true),
      planTargetId: feedbackGoalEditorRecord.planTargetId,
      ...initializeGenericAccountChallengeRequest(feedbackGoalEditorRecord.accountId),
    };

    return this.postRequest(
      `/territory/${territoryModelId}/challenge/editGoals`,
      null,
      initializeBulkAccountChallengeRequest('feedbackEditGoalsRequests', editGoalsRequest)
    );
  }

  async makeAddTargetsChallenge(territoryModelId, feedbackGoalEditorRecord, shouldRevertChallengesFirst) {
    const addTargetsRequest = {
      channelGoalRequest: instantiateChannelGoalRequests(feedbackGoalEditorRecord, false),
      ...initializeGenericAccountChallengeRequest(feedbackGoalEditorRecord.accountId),
    };

    if (feedbackGoalEditorRecord.planTargetId) {
      addTargetsRequest.planTargetId = feedbackGoalEditorRecord.planTargetId;
    }

    if (feedbackGoalEditorRecord.locationId) {
      addTargetsRequest.locationId = feedbackGoalEditorRecord.locationId;
    }

    return this.postRequest(
      `/territory/${territoryModelId}/challenge/addTargets`,
      { revertChallengesFirst: shouldRevertChallengesFirst },
      initializeBulkAccountChallengeRequest('feedbackAddTargetRequests', addTargetsRequest)
    );
  }

  async revertChallenges(territoryModelId, accountId, planTargetId, revertAccountOnly, revertTargetOnly) {
    const revertChallengesRequest = {
      revertAccountOnly,
      revertTargetOnly,
      ...initializeGenericAccountChallengeRequest(accountId),
    };

    if (planTargetId) {
      revertChallengesRequest.planTargetId = planTargetId;
    }

    return this.postRequest(
      `/territory/${territoryModelId}/challenge/revertChallenges`,
      null,
      initializeBulkAccountChallengeRequest('feedbackRevertChallengesRequests', revertChallengesRequest)
    );
  }

  async makeKeepAccountsChallenge(territoryModelId, accountId) {
    const keepAccountsRequest = initializeGenericAccountChallengeRequest(accountId);

    return this.postRequest(
      `/territory/${territoryModelId}/challenge/keepAccounts`,
      null,
      initializeBulkAccountChallengeRequest('feedbackKeepAccountRequests', keepAccountsRequest)
    );
  }

  async makeRemoveTargetsChallenge(territoryModelId, accountId, planTargetId, revertChallenges) {
    const removeTargetsRequest = {
      planTargetId,
      ...initializeGenericAccountChallengeRequest(accountId),
    };

    return this.postRequest(
      `/territory/${territoryModelId}/challenge/removeTargets`,
      null,
      initializeBulkAccountChallengeRequest('feedbackRemoveTargetsRequests', removeTargetsRequest, revertChallenges)
    );
  }

  async makeRemoveAccountsChallenge(territoryModelId, accountId, shouldRevertChallengesFirst) {
    const removeAccountsRequest = initializeGenericAccountChallengeRequest(accountId);

    return this.postRequest(
      `/territory/${territoryModelId}/challenge/removeAccounts`,
      { revertChallengesFirst: shouldRevertChallengesFirst },
      initializeBulkAccountChallengeRequest('feedbackRemoveAccountRequests', removeAccountsRequest)
    );
  }

  async makeAddAccountsChallenge(territoryModelId, accountId) {
    const addAccountsRequest = initializeGenericAccountChallengeRequest(accountId);

    return this.postRequest(
      `/territory/${territoryModelId}/challenge/addAccounts`,
      null,
      initializeBulkAccountChallengeRequest('feedbackAddAccountRequests', addAccountsRequest)
    );
  }

  async makeAddAccountsAddTargetsChallenge(territoryModelId, feedbackGoalEditorRecord) {
    const addAddTargetsRequest = {
      channelGoalRequest: instantiateChannelGoalRequests(feedbackGoalEditorRecord, false),
      ...initializeGenericAccountChallengeRequest(feedbackGoalEditorRecord.accountId),
    };

    if (feedbackGoalEditorRecord.locationId) {
      addAddTargetsRequest.locationId = feedbackGoalEditorRecord.locationId;
    }

    return this.postRequest(
      `/territory/${territoryModelId}/challenge/addAddTargets`,
      null,
      initializeBulkAccountChallengeRequest('feedbackAddAddTargetRequests', addAddTargetsRequest)
    );
  }

  async makeKeepAccountsAddTargetsChallenge(territoryModelId, feedbackGoalEditorRecord) {
    const keepAddTargetsRequest = {
      channelGoalRequest: instantiateChannelGoalRequests(feedbackGoalEditorRecord, false),
      ...initializeGenericAccountChallengeRequest(feedbackGoalEditorRecord.accountId),
    };

    if (feedbackGoalEditorRecord.locationId) {
      keepAddTargetsRequest.locationId = feedbackGoalEditorRecord.locationId;
    }

    return this.postRequest(
      `/territory/${territoryModelId}/challenge/keepAddTargets`,
      null,
      initializeBulkAccountChallengeRequest('feedbackKeepAddTargetRequests', keepAddTargetsRequest)
    );
  }

  async search(territoryModelId, searchQuery) {
    return this.postRequest(`/territory/${territoryModelId}/search`, null, { query: searchQuery });
  }

  get feedbackApiPathString() {
    return `https://${this._alignServer}${TerritoryFeedbackService.FEEDBACK_PATH}`;
  }

  async postRequest(urlPath, queryParams, requestData) {
    const url = new URL(`${this.feedbackApiPathString}${urlPath}`);

    url.search = new URLSearchParams(queryParams ?? {});

    const requestInit = {
      method: 'POST',
      credentials: 'include',
    };
    if (requestData) {
      requestInit.headers = {
        'Content-Type': 'application/json',
        'X-Source-Global-Tag': this._sourceGlobalTag,
        'X-Source-Tag': uuidV4()
      };
      requestInit.body = JSON.stringify(requestData);
    }

    const response = await timeoutPromise(TerritoryFeedbackService.POST_REQUEST_TIMEOUT_MS, fetch(url, requestInit));

    if (!response.ok) {
      const isUnauthorizedError = response.status === 401;
      throw new AlignError(response.statusText, isUnauthorizedError);
    }

    return response.json();
  }

  async getRequest(urlPath, queryParams = {}, additionalHeaders = {}) {
    const url = new URL(`${this.feedbackApiPathString}${urlPath}`);
    url.search = new URLSearchParams(queryParams);

    const headers = {
      'X-Source-Global-Tag': this._sourceGlobalTag,
      'X-Source-Tag': uuidV4(),
      ...additionalHeaders
    };

    const response = await timeoutPromise(TerritoryFeedbackService.POST_REQUEST_TIMEOUT_MS, fetch(url, { credentials: 'include', headers }));

    if (!response.ok) {
      if (response.status === 400) {
        const errorBody = await response.json();
        throw new NoFieldPlansError(errorBody.message);
      } else {
        const isUnauthorizedError = response.status === 401;
        throw new AlignError(response.statusText, isUnauthorizedError);
      }
    }

    return response.json();
  }
}

function timeoutPromise(ms, promise) {
  return new Promise((resolve, reject) => {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    const timeoutId = setTimeout(() => {
      reject(new TimeoutError('Request to Align timed out'));
    }, ms);

    promise.then(
      res => {
        clearTimeout(timeoutId);
        resolve(res);
      },
      err => {
        clearTimeout(timeoutId);
        reject(err);
      }
    );
  });
}

function convertToRedesignedFeedbackURL(alignServer) {
  return alignServer.replace('-app.', '-feedback.');
}

function initializeGenericAccountChallengeRequest(accountId) {
  return {
    requestId: uuidV4(),
    accountId,
  };
}

function initializeBulkAccountChallengeRequest(challengeRequestName, challengeRequest) {
  const bulkRequest = {
    globalRequestId: uuidV4(),
    // Managers cannot give reasons for challenges yet, but Align expects an array to be present
    challengeReasons: [],
  };
  bulkRequest[challengeRequestName] = [challengeRequest];

  return bulkRequest;
}

function instantiateChannelGoalRequests(feedbackGoalEditorRecord, isEditGoalsRequest) {
  const filteredChannelGoals = feedbackGoalEditorRecord.editedChannels.filter(channel => !channel.isNotLocationSpecificChannelGoal);
  return filteredChannelGoals.map(channel => new FeedbackChannelGoalRequest(channel, isEditGoalsRequest));
}