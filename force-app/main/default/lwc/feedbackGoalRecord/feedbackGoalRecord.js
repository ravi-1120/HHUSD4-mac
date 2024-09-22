export default class FeedbackGoalRecord {
    constructor(goalDetails, goalMetadata, useDefaultGoals, parentChannelId, accountHasLocation, channelObject) {
        this.id = goalMetadata?.channelId ?? goalMetadata?.productId;
        this.templateId = parentChannelId ? `${parentChannelId}_${this.id}` : this.id; // Needed as a key for LWC HTML template iteration
        // planChannelId/planProductId might not exist yet, particularly in the case where the user is about to make an Add Target request
        this.planId = goalDetails?.planChannelId ?? goalDetails?.planProductId ?? goalDetails?.planId;
        this.goal = goalDetails?.channelGoal ?? goalDetails?.productGoal ?? 0;

        if (useDefaultGoals) {
            this.feedbackGoal = goalMetadata?.defaultGoal ?? 0;
            this.previousFeedbackGoal = 0;
            this.maxGoal = goalMetadata?.defaultMaxGoal;
        } else {
            this.feedbackGoal = goalDetails?.feedbackChannelGoal ?? goalDetails?.feedbackProductGoal ?? this.goal;
            this.previousFeedbackGoal = this?.feedbackGoal;
            this.maxGoal = goalDetails?.maxChannelGoal ?? goalDetails?.maxProductGoal;
        }

        this.channelObject = channelObject ?? goalMetadata?.channelObject ?? '';
        this.accountHasLocation = accountHasLocation ?? false;

        this.label = goalMetadata?.channelLabel ?? goalMetadata?.productLabel;
        this.productGoals = this._instantiateProductGoals(goalDetails?.productGoals, goalMetadata?.products, this.maxGoal, useDefaultGoals);
    }

    get shouldDisableMinControls() {
        return this.isNotLocationSpecificChannelGoal || this.isFeedbackGoalAtMinValue;
    }

    get shouldDisableMaxControls() {
        return this.isNotLocationSpecificChannelGoal || this.isFeedbackGoalAtMaxValue;
    }

    get isFeedbackGoalAtMaxValue() {
        return this.maxGoal !== null && this.maxGoal !== undefined && this.feedbackGoal === this.maxGoal;
    }

    get isFeedbackGoalAtMinValue() {
        return this.feedbackGoal === 0;
    }

    get isLocationSpecificChannel() {
        return this.channelObject === 'Call2_vod__c';
    }

    get isNotLocationSpecificChannelGoal() {
        return this.accountHasLocation && !this.isLocationSpecificChannel;
    }

    get counterDatatype() {
        return this.isNotLocationSpecificChannelGoal ? 'text' : 'number';
    }

    get channelContainerClass() {
        const baseContainerClass = 'channel-container';
        return this.isNotLocationSpecificChannelGoal ? `${baseContainerClass} channel-disabled` : baseContainerClass;
    }

    get hasProductGoals() {
        return this.productGoals.length !== 0;
    }

    get editedProductGoals() {
        return this.productGoals.filter(productGoal => productGoal.previousFeedbackGoal !== productGoal.feedbackGoal);
    }

    get hasBeenEdited() {
        return this.hasChannelGoalBeenEdited || this.haveProductGoalsBeenEdited;
    }

    get hasChannelGoalBeenEdited() {
        return this.previousFeedbackGoal !== this.feedbackGoal; 
    }

    get haveProductGoalsBeenEdited() {
        return this.editedProductGoals.length > 0;
    }

    get hasGoalDifference() {
        return this.hasChannelGoalDifference || this.hasProductGoalDifference;
    }

    get hasChannelGoalDifference() {
        return this.feedbackGoal !== this.goal ?? 0;
    }

    get hasProductGoalDifference() {
        return this.productGoals.find(productGoal => productGoal.feedbackGoal !== productGoal.goal ?? 0);
    }

    getProductGoal(productId) {
        return this.productGoals.find(productGoal => productGoal.id === productId);
    }

    _instantiateProductGoals(productGoals, productsMetadata, maxChannelGoal, useDefaultGoals) {
        return productsMetadata?.map((productMetadata, productIndex) => {
                // It's possible that 1+ products exist, but do not yet have goals (e.g. when making an "Add as Target" challenge)
                const productGoalDetails = productGoals ? productGoals[productIndex] : null;

                const productGoalRecord = new FeedbackGoalRecord(productGoalDetails, productMetadata, useDefaultGoals, this.id, this.accountHasLocation, this.channelObject);
                // It's up to CRM to ensure that any maxProductGoal is less than or equal to the parent channel's maxChannelGoal
                if (maxChannelGoal !== null && productGoalRecord.maxGoal !== null) {
                    productGoalRecord.maxGoal = Math.min(maxChannelGoal, productGoalRecord.maxGoal);
                }
    
                return productGoalRecord;
            })
            ?? [];
    }
}