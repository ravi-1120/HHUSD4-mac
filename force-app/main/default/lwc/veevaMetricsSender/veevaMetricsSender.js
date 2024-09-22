import getMetricUrl from '@salesforce/apex/VeevaMetricsController.getMetricUrl';

export default class VeevaMetricsSender {
  sessionService;
  sendingStarted = false;
  queue = [];
  horusEndpointPromise;
  timeoutTime = 5000;

  constructor(sessionSvc) {
    this.sessionService = sessionSvc;
    this.horusEndpointPromise = getMetricUrl();
  }

  send(data) {
    this.queue.push(data);

    if (!this.sendingStarted) {
      this.sendingStarted = true;
      this.callWhenIdle(() => this.startMetricsQueue(), this.timeoutTime);
    }
  }

  callWhenIdle(callback, timeout) {
    if ('requestIdleCallback' in window) {
      requestIdleCallback(callback, { timeout });
    } else {
      /* eslint-disable-next-line @lwc/lwc/no-async-operation */
      setTimeout(callback, timeout);
    }
  }

  startMetricsQueue() {
    const sendMetrics = () => {
      while (this.queue.length > 0) {
        const metric = this.queue.shift();
        this.sendMetricToHorus(metric);
      }
    };

    /* eslint-disable-next-line @lwc/lwc/no-async-operation */
    setInterval(sendMetrics, this.timeoutTime);

    // before closing, send any metrics still in queue
    window.addEventListener('beforeunload', () => sendMetrics());
  }

  async sendMetricToHorus(metric) {
    try {
      const resource = await this.horusEndpointPromise;
      const options = await this.setRequestOptions(metric);
      if (resource) {
        await fetch(resource, options);
      }
    } catch (e) {
      // do nothing
    }
  }

  async setRequestOptions(metric) {
    const options = {};
    const vodInfo = await this.sessionService.getVodInfo();
    options.headers = { sfSession: vodInfo.sfSession, sfEndpoint: vodInfo.sfEndpoint, 'Content-Type': 'application/json' };
    options.method = 'POST';
    options.body = JSON.stringify(metric);
    return options;
  }
}