import VeevaMetricsService from 'c/veevaMetricsService';

export default class VeevaComponentMetricsService extends VeevaMetricsService {
  pageMetricsService;
  name;
  componentName;
  pageName;

  constructor(pageMetricsService, measurementName, componentName, pageName) {
    super(pageMetricsService?.getMetricsSender(), pageMetricsService?.getSessionService(), pageMetricsService?.getSessionId());
    this.pageMetricsService = pageMetricsService;
    this.name = measurementName;
    this.componentName = componentName;
    this.pageName = pageName;
  }

  // Override call to not capture metrics here
  captureMetrics() {}

  // override send function to allow component to use page tags
  send(data) {
    for (const metric of data) {
      metric.tags = { ...this.pageMetricsService.tags, ...metric.tags };
    }

    this.metricsSender?.send(this.configureData(data));
  }
}