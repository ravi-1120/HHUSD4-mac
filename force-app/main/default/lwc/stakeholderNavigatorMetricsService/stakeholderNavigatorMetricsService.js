import VeevaMetricsService from 'c/veevaMetricsService';
import { SERVICES, getService } from 'c/veevaServiceFactory';

export default class StakeholderNavigatorMetricsService extends VeevaMetricsService {
  stakeholderLoadStartTime;

  constructor() {
    super(getService(SERVICES.METRIC_SENDER), getService(SERVICES.SESSION));
  }

  start() {
    this.stakeholderLoadStartTime = +new Date();
  }

  async finishInitialLoad(initialLoadCount) {
    const timestamp = +new Date();
    const duration = timestamp - this.stakeholderLoadStartTime;

    await this.readyToSendMetrics; // inherited from VeevaMetricsService, indicates context tags have finished fetching

    const loadDurationMetrics = this.createMetricObject(
      'initial_load_duration', 
      'timer', 
      timestamp, 
      duration, 
      this.UNITS.MILLISECONDS, 
      {
        category: 'StakeholderNavigator'
      }
    );

    const loadSizeMetric = this.createMetricObject(
      'initial_account_load_size',
      'counter',
      timestamp,
      initialLoadCount,
      this.UNITS.UNITS,
      {
        category: 'StakeholderNavigator'
      }
    );

    this.send([loadDurationMetrics, loadSizeMetric]);
  }
}