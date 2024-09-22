import AccountRecord from 'c/accountRecord';
import { GEO_TYPES } from 'c/territoryFeedbackConstants';

export default class AccountsTableDetailsRecord {
    constructor(accountsTableDetails) {
        this.id = accountsTableDetails.id;
        this.name = accountsTableDetails.name;
        this.rosterMembers = accountsTableDetails.rosterMembers ?? [];
        this.fieldPlanName = accountsTableDetails.fieldPlanName;
        this.dueDate = accountsTableDetails.dueDate;
        this.startDate = accountsTableDetails.startDate;
        this.endDate = accountsTableDetails.endDate;
        this.instructions = accountsTableDetails.instructions;
        this.cyclePresent = accountsTableDetails.cyclePresent;
        this.accountDetailMetadata = accountsTableDetails.territoryMetadata?.territoryTableMetadata?.accountDetailMetadata ?? [];
        this.productMetricMetadata = accountsTableDetails.territoryMetadata?.territoryTableMetadata?.productMetricMetadata?.productMetrics ?? [];
        this.accountProfileDetailMetadata = accountsTableDetails.territoryMetadata?.territoryProfileMetadata?.accountDetailMetadata ?? [];
        this.territoryProfileData = accountsTableDetails.territoryData?.territoryProfileData ?? {};
        this.goalMetadata = accountsTableDetails.territoryMetadata?.territoryTableMetadata?.goalMetadata?.channels ?? [];
        this.segmentMetadata = accountsTableDetails.territoryMetadata?.territoryTableMetadata?.segmentMetadata?.channels ?? [];
        this.accounts = accountsTableDetails.territoryData?.territoryTableData?.map(account => new AccountRecord(account, true)) ?? [];
        this.canReview = accountsTableDetails.canReview;
        this.canChallenge = accountsTableDetails.canChallenge;
        this.htmlReportExternalId = accountsTableDetails.myInsightsReport?.split(':')[0];
        this.htmlReportHeight = accountsTableDetails.myInsightsReport?.split(':')[1];
        this.manager = accountsTableDetails.manager;
        this.description = accountsTableDetails.description;
        this.workingDays = accountsTableDetails.workingDays;
        this.teamSelling = accountsTableDetails.teamSelling;
        this.readOnlyMode = accountsTableDetails.territoryMetadata?.readOnlyMode ?? false;
        this.lifecycleState = accountsTableDetails.lifecycleState;
        this.locationBasedTargeting = accountsTableDetails.locationBasedTargeting ?? false;
        this.availableLifecycleActions = accountsTableDetails.availableLifecycleActions;
        this.crmUserId = accountsTableDetails.crmUserId ?? [];
        this.daysOffCycle = accountsTableDetails.daysOffCycle;
        this.territoryCapacity = accountsTableDetails.territoryCapacity;
        this.cycleCapacity = accountsTableDetails.cycleCapacity;
        this.upperUtilizationThreshold = accountsTableDetails.upperUtilizationThreshold;
        this.lowerUtilizationThreshold = accountsTableDetails.lowerUtilizationThreshold;
        this.overReachedThreshold = accountsTableDetails.overReachedThreshold;
        this.underReachedThreshold = accountsTableDetails.underReachedThreshold;
        this._calculateGeos(accountsTableDetails);
    }

    get geoAdded() {
        return this._geoAdded.map(geoMapper);
    }

    get geoDropped() {
        return this._geoDropped.map(geoMapper);
    }

    get zipsAdded() {
        return this._geoAdded.filter(geo => geo.type === GEO_TYPES.POSTAL_CODE).map(geoMapper);
    }

    get zipsDropped() {
        return this._geoDropped.filter(geo => geo.type === GEO_TYPES.POSTAL_CODE).map(geoMapper);
    }

    get bricksAdded() {
        return this._geoAdded.filter(geo => geo.type === GEO_TYPES.BRICK).map(geoMapper);
    }

    get bricksDropped() {
        return this._geoDropped.filter(geo => geo.type === GEO_TYPES.BRICK).map(geoMapper);
    }

    _calculateGeos(accountsTableDetails) {
        if (!this._geoAdded || !this._geoDropped) {
            this._geoAdded = [];
            this._geoDropped = [];

            accountsTableDetails.territoryData?.territoryGeographyData?.forEach(geoData => {
                if (geoData.change === 'ADDED') {
                    this._geoAdded.push(geoData);
                } else if (geoData.change === 'DROPPED') {
                    this._geoDropped.push(geoData);
                }
            });
        }
    }
}

function geoMapper(geo) {
    return geo.geography;
}