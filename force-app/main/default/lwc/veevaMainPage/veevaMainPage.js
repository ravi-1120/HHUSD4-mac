import { LightningElement } from 'lwc';

export default class VeevaMainPage extends LightningElement {
  timer;
  #isPageReady = false;
  pageName;
  componentName;
  objType = null;
  hasRendered = false;

  // This property is "protected" and will be set by child implementations when the page is considered ready
  get isPageReady() {
    return this.#isPageReady;
  }

  set isPageReady(value) {
    // pageReady should only be set once, this property represents the point in which the page is ready
    // and when we should log page performance
    if (!this.#isPageReady) {
      this.#isPageReady = value;
    }
  }

  connectedCallback() {
    if (this.pageCtrl) {
      const pageMetricsService = this.pageCtrl.getPageMetricsService();
      let compMetricsService;
      if (this.componentName != null || this.pageName != null) {
        compMetricsService = pageMetricsService?.createComponentMetricsService('time_to_initialize_component', this.componentName, this.pageName);
      }
      this.timer = compMetricsService?.createMetricTimer();
      this.timer?.start();
  
      this.pageReadyListener = event => {
        event.stopPropagation();
        this.endPageTimer();
      };
      this.template.addEventListener('pageready', this.pageReadyListener);
    }
  }

  disconnectedCallback() {
    this.template.removeEventListener('pageready', this.pageReadyListener);
  }

  renderedCallback() {
    if (this.isPageReady && !this.hasRendered) {
      this.hasRendered = true;
      this.endPageTimer();
    }
  }

  endPageTimer() {
    this.timer?.end();
  }
}