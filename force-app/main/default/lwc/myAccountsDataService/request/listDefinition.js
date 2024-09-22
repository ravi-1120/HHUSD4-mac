import ViewBaseDefinition from './viewBaseDefinition';

export default class ListDefinition extends ViewBaseDefinition {
  constructor(listDefinitionFromApex) {
    super(listDefinitionFromApex);
    this.accounts = this.getAccounts(listDefinitionFromApex.accounts ?? []);
  }

  getAccounts(accounts) {
    return accounts.map(account => account.accountId);
  }
}