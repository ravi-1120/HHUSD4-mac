export default class VeevaTimer {
  metricsService;

  startTime;
  endTime;
  timestamp;
  duration;

  constructor(metricsService) {
    this.metricsService = metricsService;
  }

  start() {
    this.startTime = new Date();
    this.timestamp = this.startTime.getTime();
  }

  end(extraTags) {
    this.endTime = new Date();
    this.measure();
    const metric = this.metricsService.createMetricObjectForPage(this.metricsService.name, 'timer', this.timestamp, this.duration, this.metricsService.componentName, this.metricsService.pageName, this.metricsService.UNITS.MILLISECONDS, extraTags);
    this.metricsService.send([metric]);
  }

  measure() {
    this.duration = this.endTime - this.startTime;
  }
}