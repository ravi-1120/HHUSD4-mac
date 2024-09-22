export default class TerritoryModelDetails {
  constructor(accountsTableDetailsRecord) {
    this.canChallenge = accountsTableDetailsRecord.canChallenge;
    this.canReview = accountsTableDetailsRecord.canReview;
    this.manager = accountsTableDetailsRecord.manager;
    this.territoryDescription = accountsTableDetailsRecord.description;
    this.workingDays = accountsTableDetailsRecord.workingDays;
    this.territoryName = accountsTableDetailsRecord.name;
    this.territoryId = accountsTableDetailsRecord.id;
    this.teamSellingEnabled = accountsTableDetailsRecord.teamSelling;
    this.status = accountsTableDetailsRecord.lifecycleState;
    this.readOnly = accountsTableDetailsRecord.readOnlyMode;
    this.modelDescription = accountsTableDetailsRecord.fieldPlanName;
    this.targetingEnabled = accountsTableDetailsRecord.cyclePresent;
    this.dueDate = accountsTableDetailsRecord.dueDate;
    this.startDate = accountsTableDetailsRecord.startDate;
    this.endDate = accountsTableDetailsRecord.endDate;
    this.instructions = accountsTableDetailsRecord.instructions;
    this.crmUserId = accountsTableDetailsRecord.crmUserId;
    this.daysOffCycle = accountsTableDetailsRecord.daysOffCycle;
    this.territoryCapacity = accountsTableDetailsRecord.territoryCapacity;
    this.cycleCapacity = accountsTableDetailsRecord.cycleCapacity;
    this.upperUtilizationThreshold = accountsTableDetailsRecord.upperUtilizationThreshold;
    this.lowerUtilizationThreshold = accountsTableDetailsRecord.lowerUtilizationThreshold;
    this.overReachedThreshold = accountsTableDetailsRecord.overReachedThreshold;
    this.underReachedThreshold = accountsTableDetailsRecord.underReachedThreshold;
    this._setGoalMetadata(accountsTableDetailsRecord);
    this._setAccountMetrics(accountsTableDetailsRecord);
    this._setGeoMetrics(accountsTableDetailsRecord);
    this._setProductMetricMetadata(accountsTableDetailsRecord);
    this._setAccountData(accountsTableDetailsRecord);
    this._setAccountDetailMetadata(accountsTableDetailsRecord);
  }

  _setAccountDetailMetadata(accountsTableDetailsRecord) {
    const { accountDetailMetadata, accountProfileDetailMetadata } = accountsTableDetailsRecord;
    const mergedAccountDetails = [];
    const seenFields = new Set();

    // Add all base account detail field metadata
    accountDetailMetadata.forEach(fieldMetadata => {
      mergedAccountDetails.push(fieldMetadata);
      seenFields.add(fieldMetadata.name);
    });

    // Merge account card field metadata with existing field metadata
    accountProfileDetailMetadata.forEach(fieldMetadata => {
      if (!seenFields.has(fieldMetadata.name)) {
        mergedAccountDetails.push(fieldMetadata);
        seenFields.add(fieldMetadata.name);
      }
    });

    this.accountDetailMetadata = mergedAccountDetails;
  }

  _setAccountMetrics(accountsTableDetailsRecord) {
    this._initializeAccountMetrics(accountsTableDetailsRecord);

    // Collections for partitioning accounts based on existence of target/account-level challenges
    const targetChallengedAccounts = [];
    const accountChallengedAccounts = [];

    // Adds, drops, and person accounts are only counted at the account level
    // so we can maintain a history of account IDs we've already seen/counted.
    const previouslyCountedAdds = new Set();
    const previouslyCountedDrops = new Set();
    const previouslyCountedPersonAccounts = new Set();
    accountsTableDetailsRecord.accounts.forEach(accountRecord => {
      // Partition account rows between those with target-level and account-level challenges
      if (accountRecord.hasTargetChallenge) {
        targetChallengedAccounts.push(accountRecord);
      } else if (accountRecord.hasAccountChallenge) {
        accountChallengedAccounts.push(accountRecord);
      }

      this.addedAccounts += this._shouldCountAddedAccount(accountRecord, previouslyCountedAdds) ? 1 : 0;
      this.droppedAccounts += this._shouldCountDroppedAccount(accountRecord, previouslyCountedDrops) ? 1 : 0;
      this.personAccounts += this._shouldCountPersonAccount(accountRecord, previouslyCountedPersonAccounts) ? 1 : 0;
      this.targetAccounts += this._shouldCountTargetAccount(accountRecord) ? 1 : 0;
      this.businessAccounts += this._shouldCountBusinessAccount(accountRecord) ? 1 : 0;
      this._countGoalMetricsForAccount(accountRecord);
    });

    const previouslyCountedAccounts = new Set();
    const previouslyCountedApprovals = new Set();
    const previouslyCountedRejections = new Set();
    const previouslyCountedPendings = new Set();

    targetChallengedAccounts.forEach(accountRecord => {
      // Rows with target-level type/status information are always counted
      this.totalChallengeAccounts += 1;

      // Maintain history of already-seen accounts if target-level information exists
      // for the row
      if (!previouslyCountedAccounts.has(accountRecord.accountId)) {
        previouslyCountedAccounts.add(accountRecord.accountId);
      }

      // Count the approval/rejection/pending status for the target-level challenge
      if (accountRecord.hasApprovedTargetChallenge) {
        this.approvedChallengeAccounts += 1;
        if (!previouslyCountedApprovals.has(accountRecord.accountId)) {
          previouslyCountedApprovals.add(accountRecord.accountId);
        }
      } else if (accountRecord.hasPendingTargetChallenge) {
        this.pendingChallengeAccounts += 1;
        if (!previouslyCountedPendings.has(accountRecord.accountId)) {
          previouslyCountedPendings.add(accountRecord.accountId);
        }
      } else if (accountRecord.hasRejectedTargetChallenge) {
        this.rejectedChallengeAccounts += 1;
        if (!previouslyCountedRejections.has(accountRecord.accountId)) {
          previouslyCountedRejections.add(accountRecord.accountId);
        }
      }

      if (accountRecord.hasApprovedAccountChallenge && !previouslyCountedApprovals.has(accountRecord.accountId)) {
        this.approvedChallengeAccounts += 1;
        previouslyCountedApprovals.add(accountRecord.accountId);
      } else if (accountRecord.hasPendingAccountChallenge && !previouslyCountedPendings.has(accountRecord.accountId)) {
        this.pendingChallengeAccounts += 1;
        previouslyCountedPendings.add(accountRecord.accountId);
      } else if (accountRecord.hasRejectedAccountChallenge && !previouslyCountedRejections.has(accountRecord.accountId)) {
        this.rejectedChallengeAccounts += 1;
        previouslyCountedRejections.add(accountRecord.accountId);
      }
    });

    accountChallengedAccounts.forEach(accountRecord => {
      // Account-level type/status information is only counted as a unit if it does
      // not contain any target-level information
      if (!previouslyCountedAccounts.has(accountRecord.accountId)) {
        this.totalChallengeAccounts += 1;
        previouslyCountedAccounts.add(accountRecord.accountId);
      }

      if (accountRecord.hasApprovedAccountChallenge && !previouslyCountedApprovals.has(accountRecord.accountId)) {
        this.approvedChallengeAccounts += 1;
        previouslyCountedApprovals.add(accountRecord.accountId);
      } else if (accountRecord.hasPendingAccountChallenge && !previouslyCountedPendings.has(accountRecord.accountId)) {
        this.pendingChallengeAccounts += 1;
        previouslyCountedPendings.add(accountRecord.accountId);
      } else if (accountRecord.hasRejectedAccountChallenge && !previouslyCountedRejections.has(accountRecord.accountId)) {
        this.rejectedChallengeAccounts += 1;
        previouslyCountedRejections.add(accountRecord.accountId);
      }
    });
  }

  _shouldCountAddedAccount(accountRecord, previouslyCountedAdds) {
    let shouldCount = false;

    if (accountRecord.isAdded && !previouslyCountedAdds.has(accountRecord.accountId)) {
      shouldCount = true;
      previouslyCountedAdds.add(accountRecord.accountId);
    }

    return shouldCount;
  }

  _shouldCountDroppedAccount(accountRecord, previouslyCountedDrops) {
    let shouldCount = false;

    if (accountRecord.isDropped && !previouslyCountedDrops.has(accountRecord.accountId)) {
      shouldCount = true;
      previouslyCountedDrops.add(accountRecord.accountId);
    }

    return shouldCount;
  }

  _shouldCountPersonAccount(accountRecord, previouslyCountedPersonAccounts) {
    let shouldCount = false;

    if (accountRecord.person && accountRecord.isAssignedToTerritory && !accountRecord.isRejectedAddAccount && !previouslyCountedPersonAccounts.has(accountRecord.accountId)) {
      shouldCount = true;
      previouslyCountedPersonAccounts.add(accountRecord.accountId);
    }

    return shouldCount;
  }

  _shouldCountTargetAccount(accountRecord) {
    return (accountRecord.target || accountRecord.isPendingAddTarget) && !accountRecord.isPendingRemoveTarget;
  }

  _shouldCountBusinessAccount(accountRecord) {
    return accountRecord.isBusiness && accountRecord.isAssignedToTerritory && !accountRecord.isRejectedAddAccount;
  }

  _countGoalMetricsForAccount(accountRecord) {
    if (!this._shouldCountTargetAccount(accountRecord)) {
      return;
    }

    accountRecord.goalDetails.forEach((channelGoalDetail, channelIndex) => {
      const totalGoalChannel = this.totalGoals[channelIndex];
      const channelGoalValue = accountRecord.shouldUseFeedbackGoalIfAvailable
        ? channelGoalDetail.feedbackChannelGoal ?? channelGoalDetail.channelGoal
        : channelGoalDetail.channelGoal;
      totalGoalChannel.totalGoal = addTotalGoal(totalGoalChannel.totalGoal, channelGoalValue);

      channelGoalDetail.productGoals.forEach((productGoalDetail, productIndex) => {
        const totalGoalProduct = totalGoalChannel.products[productIndex];
        const productGoalValue = accountRecord.shouldUseFeedbackGoalIfAvailable
          ? productGoalDetail.feedbackProductGoal ?? productGoalDetail.productGoal
          : productGoalDetail.productGoal;
        totalGoalProduct.totalGoal = addTotalGoal(totalGoalProduct.totalGoal, productGoalValue);
      });
    });
  }

  _initializeAccountMetrics(accountsTableDetailsRecord) {
    this.totalChallengeAccounts = 0;
    this.pendingChallengeAccounts = 0;
    this.approvedChallengeAccounts = 0;
    this.rejectedChallengeAccounts = 0;
    this.targetAccounts = 0;
    this.personAccounts = 0;
    this.businessAccounts = 0;
    this.addedAccounts = 0;
    this.droppedAccounts = 0;
    this._initializeGoalMetrics(accountsTableDetailsRecord);
  }

  _initializeGoalMetrics(accountsTableDetailsRecord) {
    this.totalGoals = accountsTableDetailsRecord.goalMetadata.map(channelMetadata => ({
      channelOrProductId: channelMetadata.channelId,
      label: channelMetadata.channelLabel,
      totalGoal: 0,
      products: channelMetadata.products.map(productMetadata => ({
        channelOrProductId: productMetadata.productId,
        label: productMetadata.productLabel,
        totalGoal: 0,
      })),
    }));
  }

  _setGeoMetrics(accountsTableDetailsRecord) {
    this._initializeGeoMetrics();
    this.addedZipcodes = accountsTableDetailsRecord.zipsAdded;
    this.droppedZipcodes = accountsTableDetailsRecord.zipsDropped;
    this.addedBrickCodes = accountsTableDetailsRecord.bricksAdded;
    this.droppedBrickCodes = accountsTableDetailsRecord.bricksDropped;
  }

  _initializeGeoMetrics() {
    this.addedZipcodes = [];
    this.droppedZipcodes = [];
    this.addedBrickCodes = [];
    this.droppedBrickCodes = [];
  }

  _setGoalMetadata(accountsTableDetailsRecord) {
    this.goalMetadata = accountsTableDetailsRecord.goalMetadata.map(channel => ({
      dailyActivityGoal: channel.dailyActivityGoal,
      defaultGoal: channel.defaultGoal,
      defaultMaxGoal: channel.defaultMaxGoal,
      id: channel.channelId,
      channelOrProductName: channel.channelLabel,
      products: channel.products.map(product => ({
        dailyActivityGoal: product.dailyActivityGoal,
        defaultGoal: product.defaultGoal,
        defaultMaxGoal: product.defaultMaxGoal,
        id: product.productId,
        channelOrProductName: product.productLabel,
        products: [],
      })),
    }));
  }

  _setProductMetricMetadata(accountsTableDetailsRecord) {
    const metrics = [];
    const products = [];

    accountsTableDetailsRecord.productMetricMetadata.forEach(metricMetadata => {
      metrics.push({
        apiName: metricMetadata.productMetricLabel.name,
        label: metricMetadata.productMetricLabel.label,
        type: metricMetadata.productMetricLabel.type,
      });
      products.push(...metricMetadata.productLabels);
    });

    // Need to dedupe product labels
    this.productMetricMetadata = {
      metrics,
      products: [...new Set(products)],
    };
  }

  _setAccountData(accountsTableDetailsRecord) {
    this.accountData = [];
    for (const accountRecord of accountsTableDetailsRecord.accounts) {
      const accountDetails = accountsTableDetailsRecord.accountDetailMetadata.reduce((accountDetail, accountDetailMetadata, accountDetailIndex) => {
        accountDetail[accountDetailMetadata.name] = accountRecord.accountDetails[accountDetailIndex];
        return accountDetail;
      }, {});

      const { accountProfileDetailMetadata, territoryProfileData } = accountsTableDetailsRecord;
      const accountProfileDetailsData = territoryProfileData[accountRecord.accountId]?.accountDetails;
      if (accountProfileDetailsData?.length) {
        accountProfileDetailMetadata.forEach((metadatum, index) => {
          if (!accountDetails[metadatum.name]) {
            accountDetails[metadatum.name] = accountProfileDetailsData[index];
          }
        });
      }

      const goalDetails = accountRecord.goalDetails.map((channelGoal, channelIndex) =>
        getChannelGoalDetail(accountRecord, channelGoal, channelIndex, accountsTableDetailsRecord.goalMetadata[channelIndex])
      );
      
      const productMetricDetails = accountRecord.productMetricDetails.map((metric, metricIndex) =>
        getProductMetricDetail(accountsTableDetailsRecord.productMetricMetadata[metricIndex], metric)
      );
      
      this.accountData.push({
        accountChallengeReasons: accountRecord.challengeReasons,
        accountChallengeStatus: accountRecord.challengeStatus,
        accountChallengeType: accountRecord.challengeType,
        formattedName: accountRecord.name,
        addresses: accountRecord.addresses,
        firstName: accountRecord.firstName,
        id: accountRecord.accountId,
        lastName: accountRecord.lastName,
        person: accountRecord.person,
        target: accountRecord.target,
        targetChallengeReasons: accountRecord.targetChallengeReasons,
        targetChallengeStatus: accountRecord.targetChallengeStatus,
        targetChallengeType: accountRecord.targetChallengeType,
        locationId: accountRecord.location?.id ?? '',
        locationName: accountRecord.location?.name ?? '',
        isAddedAccount: accountRecord.isAdded,
        isDroppedAccount: accountRecord.isDropped,
        accountDetails,
        goalDetails,
        productMetricDetails
      });
    }
  }
}

function addTotalGoal(totalGoal, goalToAdd) {
  return (totalGoal ?? 0) + (goalToAdd ?? 0)
}

function getChannelGoalDetail(accountRecord, channelGoal, channelIndex, channelMetadata) {
  return {
    channelOrProductId: channelMetadata.channelId,
    feedbackGoal: channelGoal.feedbackChannelGoal,
    goal: channelGoal.channelGoal,
    maxGoal: channelGoal.maxChannelGoal,
    segment: accountRecord.segmentDetails[channelIndex]?.channelSegmentation,
    teamGoal: channelGoal.channelTeamGoal,
    productGoals: channelGoal.productGoals.map((productGoal, productIndex) =>
      getProductGoalDetail(accountRecord, channelIndex, productGoal, productIndex, channelMetadata.products[productIndex])
    ),
  };
}

function getProductGoalDetail(accountRecord, channelIndex, productGoal, productIndex, productMetadata) {
  return {
    channelOrProductId: productMetadata.productId,
    feedbackGoal: productGoal.feedbackProductGoal,
    goal: productGoal.productGoal,
    maxGoal: productGoal.maxProductGoal,
    segment: accountRecord.segmentDetails[channelIndex]?.productSegmentations[productIndex],
    teamGoal: productGoal.productTeamGoal,
    productGoals: [],
  };
}

function getProductMetricDetail(metricMetadata, metric) {
  return {
    metric: metricMetadata?.productMetricLabel.name,
    productMetricValues: metricMetadata?.productLabels.reduce((productMetricValues, productLabel, productIndex) => {
      if (metric.productValues[productIndex] != null && metric.productValues[productIndex] !== '') {
        productMetricValues[productLabel] = metric.productValues[productIndex];
      }
      return productMetricValues;
    }, {}),
  };
}