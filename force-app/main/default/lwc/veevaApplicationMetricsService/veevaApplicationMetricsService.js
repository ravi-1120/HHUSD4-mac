import VeevaMetricsService from 'c/veevaMetricsService';
import VeevaPageMetricsService from 'c/veevaPageMetricsService';

export default class VeevaApplicationMetricsService extends VeevaMetricsService {
  performanceNavigationTiming;
  appMetrics = [];

  captureMetrics() {
    const timestamp = +new Date();
    if (window.performance.getEntriesByType) {
      [this.performanceNavigationTiming] = window.performance.getEntriesByType('navigation');

      if (this.performanceNavigationTiming) {
        // TTFB
        const timeToFirstByteCalc = this.performanceNavigationTiming.responseEnd - this.performanceNavigationTiming.requestStart;
        const ttfb = this.createMetricObject('timeToFirstByte', 'timer', timestamp, timeToFirstByteCalc);
        this.appMetrics.push(ttfb);
        // PageLoadTime
        const pageLoadTimeCalc = this.performanceNavigationTiming.loadEventEnd - this.performanceNavigationTiming.fetchStart;
        const plt = this.createMetricObject('pageLoadTime', 'timer', timestamp, pageLoadTimeCalc);
        this.appMetrics.push(plt);
        // DomLoad
        const domLoadCalc = this.performanceNavigationTiming.domComplete - this.performanceNavigationTiming.fetchStart;
        const dl = this.createMetricObject('domLoad', 'timer', timestamp, domLoadCalc);
        this.appMetrics.push(dl);
        // DNS Lookup
        const dnsLookupCalc = this.performanceNavigationTiming.domainLookupEnd - this.performanceNavigationTiming.domainLookupStart;
        const dnsLookupMetric = this.createMetricObject('dnsLookup', 'timer', timestamp, dnsLookupCalc);
        this.appMetrics.push(dnsLookupMetric);
        
        this.send(this.appMetrics);
      }
    }
  }

  createPageMetricsService() {
    return new VeevaPageMetricsService(this);
  }
}