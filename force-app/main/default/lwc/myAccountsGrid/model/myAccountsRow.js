export default class MyAccountsRow {
  constructor(originalRow) {
    Object.assign(this, originalRow);
    if (this['Address_vod__c-Id']) {
      this.id = `${this['Account-Id']}--${this['Address_vod__c-Id']}`;
    } else {
      this.id = this['Account-Id'];
    }
  }
}