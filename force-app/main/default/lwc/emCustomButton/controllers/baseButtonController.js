export default class BaseButtonController {
  navigationHandlers = {};
  clickHandlers = {};

  constructor(meta, pageCtrl) {
    this.meta = meta;
    this.pageCtrl = pageCtrl;
  }

  get recordId() {
    return this.pageCtrl.recordId;
  }

  isNavigationAction() {
    return Object.keys(this.navigationHandlers).includes(this.meta.name);
  }

  getNavigationUrl() {
    return this.navigationHandlers[this.meta.name].bind(this)();;
  }

  async handleClick() {
    let handler = this.clickHandlers[this.meta.name];
    if (!handler) {
      handler = this.clickHandlers.default;
    }
    if (handler) {
      return handler.bind(this)();
    }
    return null;
  }

  static constructVfpPageRef(pageName, queryParams = {}) {
    const queryParamString = new URLSearchParams(queryParams).toString();
    let url = `/apex/${pageName}`;
    if (queryParamString) {
      url += `?${queryParamString}`;
    }
    return {
      type: 'standard__webPage',
      attributes: { url },
    };
  }
}