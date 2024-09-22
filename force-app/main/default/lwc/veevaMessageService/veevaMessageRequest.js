export default class VeevaMessageRequest {
  #messageRequestArr;

  constructor(messageService) {
    this.messageService = messageService;
    this.#messageRequestArr = [];
  }

  addRequest(key, category, defaultMessage, label) {
    this.#messageRequestArr.push({ key, category, defaultMessage, label });
    return this;
  }

  async sendRequest() {
    return this.messageService.getMessageMap(this);
  }

  getMessageRequests() {
    return this.#messageRequestArr;
  }
}