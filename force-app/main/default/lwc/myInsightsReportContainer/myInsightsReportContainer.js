import { api, LightningElement } from 'lwc';
import ResizeCycleTracker from './resizeCycleTracker';

export default class MyInsightsReportContainer extends LightningElement {
    @api url;
    @api htmlReportId;
    @api htmlReportUuid;
    @api maxHeight;

    defaultHeight = 150;

    dynamicResizingSupport = false;
    recentIFrameDimensionUpdate = false;
    hasAdditionalIFrameDimension = false;

    IFRAME_PING_INTERVAL = 75;
    IFRAME_PING_TERMINATE = 5000;
    SHOULD_TRACK_RESIZE_CYCLES = true;
    sendHTMLReportIdToIFrameIntervalId;

    cycleTracker = this.SHOULD_TRACK_RESIZE_CYCLES ? new ResizeCycleTracker() : null;

    get iframe() {
        return this.template.querySelector("iframe");
    }

    connectedCallback() {
        window.addEventListener("message", this.handleMessage.bind(this));
        this.repeatedlySendReportPropsToIFrame();
    }

    repeatedlySendReportPropsToIFrame() {
        // the My Insights Library js file sometimes starts execution before the onload() callback of the My Insights iframe 
        // this is due to large static assets in the iframe, thus we start pinging the library with our report Id & UUID asap
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.sendHTMLReportIdToIFrameIntervalId = setInterval(() => { this.sendHTMLReportIdToIFrame(); }, this.IFRAME_PING_INTERVAL);
    }

    disconnectedCallback() {
        window.removeEventListener("message", this.handleMessage.bind(this));
    }

    @api
    refresh() {
        // eslint-disable-next-line no-self-assign
        this.iframe.src = this.iframe.src;
        this.repeatedlySendReportPropsToIFrame();
    }

    iframeContentLoaded() {
        this.retrieveIFrameDimensions();
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            if (!this.dynamicResizingSupport) {
                const oldLibraryHeight = this.maxHeight ?? this.defaultHeight;
                this.setReportUsingOldLibraryDimensions(oldLibraryHeight);
            }
        }, 500);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            if (this.sendHTMLReportIdToIFrameIntervalId) {
                clearInterval(this.sendHTMLReportIdToIFrameIntervalId);
                this.sendHTMLReportIdToIFrameIntervalId = null;
            }
        }, this.IFRAME_PING_TERMINATE);
    }

    handleMessage(event) {
        const data = this.parseData(event);
        const commandName = data ? data.command : null;
        if (data && data.htmlReportId === this.htmlReportId && data.htmlReportUUID === this.htmlReportUuid) {
            if (this.sendHTMLReportIdToIFrameIntervalId) {
                clearInterval(this.sendHTMLReportIdToIFrameIntervalId);
                this.sendHTMLReportIdToIFrameIntervalId = null;
            }
            switch (commandName) {
                case "iframeDimensions":
                    this.updateIFrameDimensions(data);
                    break;
                default:
                    break;
            }
        }
    }

    updateIFrameDimensions(data) {
        const newIFrameWindowDimensions = data.iframeDimensions;

        // We will only set the iframe dimensions if we haven't recently updated
        // the iframe dimensions
        if (!this.recentIFrameDimensionUpdate) {
            this.recentIFrameDimensionUpdate = true;

            if (this.cycleTracker) {
                newIFrameWindowDimensions.height = this.cycleTracker.checkAndRetrieveHeight(newIFrameWindowDimensions.height);
            }
            
            if (newIFrameWindowDimensions.height != null) {
                this.setIFrameDimensionsUsingIFrameDimensions(newIFrameWindowDimensions);
            }

            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                // We will only consider updates additional updates after this timeout
                // The timeout will match the transition time that we have in CSS for the iframe
                // Note: this time should be long enough that we do not end up in a cycle for resizing
                this.recentIFrameDimensionUpdate = false;
                // If more dimension came in prior to the timeout we will make another request
                // to retrieve the iframe dimensions.
                if (this.hasAdditionalIFrameDimension) {
                    this.retrieveIFrameDimensions();
                    this.hasAdditionalIFrameDimension = false;
                }
            }, (this.cycleTracker?.IFRAME_DIMENSIONS_DEBOUNCE ?? 300));
        } else {
            this.hasAdditionalIFrameDimension = true;
        }
    }

    setIFrameDimensionsUsingIFrameDimensions(newIFrameWindowDimensions) {
        const { height } = newIFrameWindowDimensions;
        const newIFrameHeight = this.maxHeight ? Math.min(this.maxHeight, height) : height;
        this.iframe.style.height = `${newIFrameHeight}px`;
        // We will set that our height was updated.
        // This means the HTML Report is using a version of MyInsights that supports dynamic resizing
        this.dynamicResizingSupport = true;
    }

    setReportUsingOldLibraryDimensions(oldLibraryHeight) {
        this.iframe.style.height = `${oldLibraryHeight}px`;
    }

    sendHTMLReportIdToIFrame() {
        this.sendMessageToIFrame({
            command: "setHTMLReportIdAndUUID"
        });
    }

    retrieveIFrameDimensions() {
        this.sendMessageToIFrame({
            command: "iframeDimensions"
        });
    }

    sendMessageToIFrame(message) {
        // We will always send the HTML Report Id and our UUID to the iframe
        message.htmlReportId = this.htmlReportId;
        message.htmlReportUUID = this.htmlReportUuid;
        this.iframe?.contentWindow?.postMessage(JSON.stringify(message), "*");
    }

    parseData(event) {
        if (typeof event.data === "string") {
            try {
                return JSON.parse(event.data);
            } catch {
                return event.data;
            }
        }
        return event.data;
    }
}