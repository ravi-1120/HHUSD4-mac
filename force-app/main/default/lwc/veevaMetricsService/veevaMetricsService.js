import VeevaTimer from 'c/veevaTimer';

export default class VeevaMetricsService {
  metricsSender;
  sessionService;
  sessionId;

  /**
   * this holds the promise that resolves when the infromation from the context tags has been retrieved
   * if a class extending VeevaMetricsService wants to call {@link VeevaMetricsService.send()} rather than overriding {@link VeevaMetricsService.captureMetrics()}
   * they should first await this promise otherwise there is potential for malformed metrics to be sent
   */
  readyToSendMetrics;

  contextType = 'org';
  contextTags = {};
  platformType = 'LEX';
  platformTags = {};
  payloadType = 'metric';
  payloadTags = {};

  UNITS = Object.freeze({
    MILLISECONDS: 'milliseconds',
    SECONDS: 'seconds',
    BYTES: 'bytes',
    UNITS: 'units',
  });

  constructor(metricsSender, sessionSvc, sessionId) {
    this.metricsSender = metricsSender;
    this.sessionService = sessionSvc;
    if (sessionId) {
      this.sessionId = sessionId;
    } else {
      this.sessionId = this.generateUUID();
    }
    this.readyToSendMetrics = this.setVodInfo().then(() => this.captureMetrics());
  }

  getMetricsSender() {
    return this.metricsSender;
  }

  getSessionService() {
    return this.sessionService;
  }

  getSessionId() {
    return this.sessionId;
  }

  async setVodInfo() {
    const vodInfo = await this.sessionService?.getVodInfo();
    if (vodInfo) {
      this.contextTags.org_id = vodInfo.orgId;
      this.contextTags.user_id = vodInfo.userId;
      this.contextTags.app_name = vodInfo.veevaServer;
      this.contextTags.app_version = vodInfo.veevaVersion;
      this.contextTags.session_id = this.sessionId;
      this.setPlatformTagsFromBrowser();
    }
  }

  // To be overridden by a child class
  // Will be called after vodInfo has been set
  captureMetrics() {}

  send(data) {
    this.metricsSender?.send(this.configureData(data));
  }

  createMetricTimer() {
    return new VeevaTimer(this);
  }

  configureData(data) {
    // Configure data to meet Horus specifications
    const payload = {};

    payload.context_type = this.contextType;
    payload.context_tags = JSON.parse(JSON.stringify(this.contextTags));

    payload.platform_type = 'LEX';
    payload.platform_tags = this.platformTags;

    payload.payload_type = this.payloadType;
    payload.payload_tags = this.payloadTags;

    payload.payload = data;

    return payload;
  }

  _createMetricObject(name, type, timestamp, value, unit = this.UNITS.MILLISECONDS, tags = {}) {
    const obj = {};
    obj.name = name;
    obj.type = type;
    obj.timestamp = timestamp;
    obj.value = Math.round(value);
    obj.unit = unit;
    obj.tags = tags;
    return obj;
  }

  /**
   * @deprecated This method does not automatically add the category and page_name tags,
   * please use {@link VeevaMetricsService.createMetricObjectForPage()}
   */
  createMetricObject(name, type, timestamp, value, unit = this.UNITS.MILLISECONDS, tags = {}) {
    return this._createMetricObject(name, type, timestamp, value, unit, tags);
  }

  createMetricObjectForPage(name, type, timestamp, value, componentName, pageName, unit = this.UNITS.MILLISECONDS, tags = {}) {
    const obj = this._createMetricObject(name, type, timestamp, value, unit, tags);
    if (componentName != null) {
      obj.tags.category = componentName;
    }
    if (pageName != null) {
      obj.tags.page_name = pageName;
    }
    return obj;
  }

  // Referenced from My Insights component in myInsights.js
  // Original reference https://www.w3resource.com/javascript-exercises/javascript-math-exercise-23.php
  generateUUID() {
    let dateTime = new Date().getTime();
    const uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, character => {
      // eslint-disable-next-line no-bitwise
      const randomHexValue = (dateTime + Math.random() * 16) % 16 | 0;
      dateTime = Math.floor(dateTime / 16);
      // eslint-disable-next-line no-bitwise
      return (character === 'x' ? randomHexValue : (randomHexValue & 0x3) | 0x8).toString(16);
    });
    return uuid;
  }

  /*
   * Helps parse browser and OS information from user agent
   * Modified for our use with reference to original here:
   * https://github.com/keithws/browser-report/blob/master/index.js
   */
  setPlatformTagsFromBrowser() {
    const userAgent = window.navigator.userAgent || {};
    this.platformTags.user_agent = userAgent;

    // grab operating system
    this.platformTags.os = '';
    if (userAgent.indexOf('Windows') >= 0) {
      this.platformTags.os = 'Windows';
    }

    if (userAgent.indexOf('OS X') >= 0) {
      this.platformTags.os = 'MacOS';
    }

    // grab os version
    this.platformTags.os_version = '';
    
    let match = null;
    switch (this.platformTags.os) {
      case 'Windows':
        match = userAgent.match(/Win(?:dows)?(?: Phone)?[ _]?(?:(?:NT|9x) )?((?:(\d+\.)*\d+)|XP|ME|CE)\b/);

        if (match && match[1]) {
          switch (match[1]) {
            case '6.4':
              match[1] = '10.0';
              break;
            case '6.3':
              match[1] = '8.1';
              break;
            case '6.2':
              match[1] = '8';
              break;
            case '6.1':
              match[1] = '7';
              break;
            case '6.0':
              match[1] = 'Vista';
              break;
            case '5.2':
              match[1] = 'Server 2003';
              break;
            case '5.1':
              match[1] = 'XP';
              break;
            case '5.01':
              match[1] = '2000 SP1';
              break;
            case '5.0':
              match[1] = '2000';
              break;
            case '4.0':
              match[1] = '4.0';
              break;
            default:
              // nothing
              break;
          }
        }
        break;
      case 'MacOS':
        match = userAgent.match(/OS X ((\d+[._])+\d+)\b/);
        break;
      default:
        this.platformTags.os_version = '';
        break;
    }

    if (match && match[1]) {
      // replace underscores in version number with periods
      match[1] = match[1].replace(/_/g, '.');
      [, this.platformTags.os_version] = match;
    }
    
    // grab browser
    this.platformTags.browser = '';
    
    if (userAgent.indexOf('Trident') >= 0 || userAgent.indexOf('MSIE') >= 0) {
      this.platformTags.browser = 'Internet Explorer';
    }

    if (userAgent.indexOf('Edge') >= 0) {
      this.platformTags.browser = 'Edge';
    }

    if (userAgent.indexOf('Firefox') >= 0) {
      this.platformTags.browser = 'Firefox';
    }

    if (userAgent.indexOf('Safari') >= 0) {
      this.platformTags.browser = 'Safari';
    }

    if (userAgent.indexOf('Chrome') >= 0) {
      this.platformTags.browser = 'Chrome';
    }

    // grab browser version
    this.platformTags.browser_version = '';
    match = null;

    switch (this.platformTags.browser) {
      case 'Chrome':
        match = userAgent.match(/Chrome\/((\d+\.)+\d+)/);
        break;
      case 'Firefox':
        match = userAgent.match(/Firefox\/((\d+\.)+\d+)/);
        break;
      case 'Edge':
      case 'Internet Explorer':
        if (userAgent.indexOf('Edge') >= 0) {
          match = userAgent.match(/Edge\/((\d+\.)+\d+)/);
        } else if (userAgent.indexOf('rv:11') >= 0) {
          match = userAgent.match(/rv:((\d+\.)+\d+)/);
        } else if (userAgent.indexOf('MSIE') >= 0) {
          match = userAgent.match(/MSIE ((\d+\.)+\d+)/);
        }
        break;
      case 'Safari':
        match = userAgent.match(/Version\/((\d+\.)+\d+)/);
        break;
      default:
        match = userAgent.match(/\/((\d+\.)+\d+)$/);
        break;
    }

    if (match && match[1]) {
      [, this.platformTags.browser_version] = match;
    }
  }
}