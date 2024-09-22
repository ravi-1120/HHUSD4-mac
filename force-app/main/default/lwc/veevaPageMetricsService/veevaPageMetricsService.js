import VeevaSalesforcePerformanceMetrics from 'c/veevaSalesforcePerformanceMetrics';
import VeevaComponentMetricsService from 'c/veevaComponentMetricsService';
import VeevaMetricsService from 'c/veevaMetricsService';

export default class VeevaPageMetricsService extends VeevaMetricsService {
  name;
  tags;

  constructor(appMetricsService) {
    super(appMetricsService?.getMetricsSender(), appMetricsService?.getSessionService(), appMetricsService?.getSessionId());
  }

  captureMetrics() {
    const pageMetrics = [];
    VeevaSalesforcePerformanceMetrics.captureMetrics(this, pageMetrics);
    const timestamp = +new Date();
    if (window.performance.getEntriesByName) {
      // FirstContentfulPaint
      let contentfulPaintCalc = window.performance.getEntriesByName('first-contentful-paint', 'paint')[0];
      if (contentfulPaintCalc) {
        contentfulPaintCalc = contentfulPaintCalc.startTime;
        const paint = this.createMetricObject('firstContentfulPaint', 'timer', timestamp, contentfulPaintCalc);
        pageMetrics.push(paint);
      }
      // Total Resource Transfer Size
      const transferSizeCalc = this.getTransferSize();
      const pageTransferSize = this.createMetricObject('totalPageTransferSize', 'counter', timestamp, transferSizeCalc, this.UNITS.BYTES);
      pageMetrics.push(pageTransferSize);
    }
  }

  // override send function to account for salesforce metrics
  send(data) {
    for (const metric of data) {
      metric.tags = { ...this.tags, ...metric.tags };
    }

    this.metricsSender?.send(this.configureData(data));
  }

  createComponentMetricsService(measurementName, componentName, pageName) {
    return new VeevaComponentMetricsService(this, measurementName, componentName, pageName);
  }

  formatPageName(actionName, objectApiName) {
    return `${actionName}${objectApiName}`;
  }

  getTransferSize() {
    let totalTransferSize = 0;

    if (document.readyState === 'complete') {
      const resources = window.performance.getEntriesByType('resource') ?? [];
      totalTransferSize = resources.reduce((accumulatedTransferSize, currentResource) => 
        currentResource.transferSize ? accumulatedTransferSize + currentResource.transferSize : accumulatedTransferSize, 0);
    }

    return totalTransferSize;
  }
}