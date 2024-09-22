import MyInsightsMetricsService from 'c/myInsightsMetricsService';
import { SERVICES, getService } from 'c/veevaServiceFactory';

export default class ResizeCycleTracker {    
    IFRAME_DIMENSIONS_DEBOUNCE = 300;
    IFRAME_CYCLE_MAX_DURATION = 100;
    MAX_CYCLES_PERMITTED = 10;

    ignoreNextIteration = false;
    myInsightsMetricService = new MyInsightsMetricsService(getService(SERVICES.METRIC_SENDER), getService(SERVICES.SESSION));
    cycleQueue = [];
    cycleHeights = [];

    /**
     * Determines if a cycle is present or not
     * @return {number|null} the maximum of the two cycle heights if a cycle is present
     */
    _getCycleHeight() {
        const duration = this.cycleQueue.length > 0 ? Date.now() - this.cycleQueue[this.cycleQueue.length - 1].time - this.IFRAME_DIMENSIONS_DEBOUNCE : null;
        const inCycleFrame = duration != null && duration < this.IFRAME_CYCLE_MAX_DURATION && duration >= 0;

        // Confirming previous step was within acceptable time frame and queue is full
        if (inCycleFrame && this.cycleQueue.length === this.MAX_CYCLES_PERMITTED) {
            // We know evenHeight !== oddHeight and cycle alternates because of checks in _addToCycleQueue()
            const evenHeight = this.cycleQueue[0].height;
            const oddHeight = this.cycleQueue[1].height;
            this.cycleHeights.push(evenHeight);
            this.cycleHeights.push(oddHeight);

            this.cycleQueue = [];
            
            const newHeight = Math.max(evenHeight, oddHeight);
            this.myInsightsMetricService.captureCycle(newHeight);
            
            return newHeight;            
        }
        // We can remove all but the most recent iteration if not within acceptable frame
        // Last entry can be beginning of new cycle
        if (!inCycleFrame) {
            this.cycleQueue = this.cycleQueue.slice(-1);
            this.cycleHeights = [];
            this.ignoreNextIteration = false;
        }
        return null;
    }

    /**
     * Adds a cycle iteration to the queue
     * Resets queue if we can already tell we're not in a cycle
     * Prevents queue from exceeding MAX_CYCLES_PERMITTED
     * @param {number} height - The height of the iframe that was just set
    */
    _addToCycleQueue(height) {
        // If current cycle height is equivalent to previous height, we're not entering a cycle
        // Clear the queue of previous entries to prevent unnecessary iteration and proceed 
        if (this.cycleQueue.length > 0 && height === this.cycleQueue[this.cycleQueue.length - 1].height) {
            this.cycleQueue = [];
        } else if (this.cycleQueue.length > 1 && height !== this.cycleQueue[this.cycleQueue.length - 2].height) {
            // Clear the queue if we can already tell it isn't alternating
            this.cycleQueue = [];
        } else if (this.cycleQueue.length === this.MAX_CYCLES_PERMITTED) {
            // Prevent queue from exceeding size restriction
            this.cycleQueue.shift();
        }

        this.cycleQueue.push({
            height,
            time: Date.now()
        });
    }

    /**
     * Determines if an ignore is present and valid
     * @param {number} height - The requested height of the iframe in the most recent message
     * @returns {boolean} true if ignore is present and new height is a cycle height. If new height is not a cycle height or ignore is not present, return false
     */
    _shouldIgnore(height) {
        if (!this.ignoreNextIteration) {
            return false;
        }

        const isCycleHeight = this.cycleHeights.length === 2 && this.cycleHeights.includes(height);
    
        // Resetting variables to allow future requests to proceed normally
        this.cycleHeights = [];
        this.ignoreNextIteration = false;
        
        return isCycleHeight;
    }

    /**
     * Perform logic for checking cycle and ignore status so that myInsightsReportContainer doesn't have to
     * @param {number} height - Current request to change iframe height to
     * @returns {number|null} cycleHeight if the iframe is in a resizing cycle, null if the current iteration should be ignored, and height otherwise
     */
    checkAndRetrieveHeight(height) {
        const cycleHeight = this._getCycleHeight();               
        const shouldIgnore = this._shouldIgnore(height);

        // Prevent next cycle iteration from taking effect, if necessary
        if (shouldIgnore) {
            return null;
        }

        if (cycleHeight != null) {
            // Ignore the next request if it is a part of a cycle (if it is not, the ignore functionality is disabled in _shouldIgnore() or the else if of _getCycleHeight())
            // Allows us to use the maximum cycle height, not just the most recent one in the cycle
            this.ignoreNextIteration = true;
        }

        const retrievedHeight = cycleHeight ?? height
        this._addToCycleQueue(retrievedHeight);
        return retrievedHeight;
    }
}