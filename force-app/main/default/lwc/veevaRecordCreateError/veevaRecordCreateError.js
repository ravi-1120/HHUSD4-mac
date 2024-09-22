export default class VeevaRecordCreateError extends Error {
  constructor(title, messages, redirectRef, ...params) {
    super(...params);

    this.name = 'VeevaRecordCreateError';

    this.title = title;
    this.messages = messages;
    this.redirectRef = redirectRef;
  }
}