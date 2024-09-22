import VeevaMetricsService from 'c/veevaMetricsService';

export default class MyInsightsMetricsService extends VeevaMetricsService {

  async captureCycle(height) {
    const timestamp = +new Date();
    await this.readyToSendMetrics; // inherited from VeevaMetricsService, indicates context tags have finished fetching

    // Log height used to break out of cycle
    const newHeightMetric = this.createMetricObjectForPage(
      'iframe_resize_cycle_new_height', 
      'counter',
      timestamp,
      height,
      'MyInsights',
      null,
      this.UNITS.UNITS
    );

    this.send([newHeightMetric]);
  }
}