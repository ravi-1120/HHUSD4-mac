export default class VeevaSalesforcePerformanceMetrics {
  static captureMetrics(pageMetricsService, metricArray) {
    const pageViewStart = this.getViewStart();
    const timeoutTime = 5000;

    const getMetrics = () => {
      const timestamp = +new Date();
      // EPT
      let EPTCalc = this.getEPT(pageViewStart);
      if (EPTCalc) {
        EPTCalc = EPTCalc.duration;
        const ept = pageMetricsService.createMetricObject('EPT', 'timer', timestamp, EPTCalc);
        metricArray.push(ept);
        pageMetricsService.send(metricArray);
      } else {
        this.captureMetrics(pageMetricsService, metricArray);
      }
    };

    if ('requestIdleCallback' in window) {
      requestIdleCallback(getMetrics, { timeout: timeoutTime });
    } else {
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      setTimeout(getMetrics, timeoutTime);
    }
  }

  static getViewStart() {
    let eptMarkEntries;
    if (window.performance.getEntriesByName) {
      eptMarkEntries = window.performance.getEntriesByName('ltng:pageView', 'mark');
      if (eptMarkEntries && eptMarkEntries.length > 0) {
        return eptMarkEntries[eptMarkEntries.length - 1].startTime;
      }
    }
    return 0;
  }

  static getEPT(startTime) {
    if (window.performance.getEntriesByName) {
      return window.performance.getEntriesByName('PageView EPT', 'measure').find(entry => entry.startTime >= startTime);
    }
    return undefined;
  }
}