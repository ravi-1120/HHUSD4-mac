import { LightningElement, api } from 'lwc';
import { getService } from 'c/veevaServiceFactory';
import LOCALE from '@salesforce/i18n/locale';
import { COMMANDS } from 'c/accountsPageCommandFactory';
import AccountRecord from 'c/accountRecord';

export default class FeedbackOutsideTerritorySearchModal extends LightningElement {
  static MAX_NUM_RESULTS = 100;

  @api territoryFeedbackService;
  @api territoryModelId;
  @api inTerritoryAccountsById;
  @api locationBasedTargeting;
  @api cyclePresent;

  messageService;
  searchMessage;
  tooManyResultsMessage;
  inTerritoryMessage;
  nameMessage;
  addressMessage;
  specialtyMessage;
  addAccountMessage;
  addTargetMessage;

  isLoading = false;
  searchQuery;
  hasTooManyResults = false;
  accounts = [];
  columns;

  get tableContainerClass() {
    return `table-container slds-p-around_x-small ${this.accounts.length ? 'slds-show' : 'slds-hide'}`;
  }

  async connectedCallback() {
    await this.initMessages();
    this.initColumns();
  }

  async initMessages() {
    this.messageService = getService('messageSvc');
    [
      this.searchMessage,
      this.tooManyResultsMessage,
      this.inTerritoryMessage,
      this.nameMessage,
      this.locationMessage,
      this.addressMessage,
      this.specialtyMessage,
      this.addAccountMessage,
      this.addTargetMessage,
    ] = await Promise.all([
      this.messageService.getMessageWithDefault('SEARCH', 'Common', 'Search'),
      this.messageService.getMessageWithDefault('TOO_MANY_RESULTS', 'Common', 'More than {0} results match search criteria. Please refine search.'),
      this.messageService.getMessageWithDefault('IN_TERRITORY', 'Feedback', 'In Territory?'),
      this.messageService.getMessageWithDefault('NAME', 'Common', 'Name'),
      this.messageService.getMessageWithDefault('LOCATION', 'Common', 'Location'),
      this.messageService.getMessageWithDefault('ADDRESS', 'Feedback', 'Address'),
      this.messageService.getMessageWithDefault('SPECIALTY', 'Common', 'Specialty'),
      this.messageService.getMessageWithDefault('ADD_ACCOUNT', 'Feedback', 'Add Account'),
      this.messageService.getMessageWithDefault('ADD_TARGET', 'Feedback', 'Add as Target'),
    ]);

    this.tooManyResultsMessage = this.tooManyResultsMessage.replace(
      '{0}',
      new Intl.NumberFormat(LOCALE).format(FeedbackOutsideTerritorySearchModal.MAX_NUM_RESULTS)
    );
  }

  initColumns() {
    this.columns = [
      {
        type: 'action',
        typeAttributes: { rowActions: { fieldName: 'availableActions' }, menuAlignment: 'auto' },
        hideDefaultActions: true,
        cellAttributes: { class: { fieldName: 'moreActionsMenuClass' } },
      },
      {
        type: 'boolean',
        label: this.inTerritoryMessage,
        fieldName: 'isInTerritory',
        hideDefaultActions: true,
        initialWidth: 110,
        cellAttributes: { alignment: 'center' },
      },
      { type: 'styled-text', label: this.nameMessage, fieldName: 'name', hideDefaultActions: true },
      {
        type: 'styled-text',
        label: this.addressMessage,
        fieldName: 'addressDisplay',
        hideDefaultActions: true,
        typeAttributes: { classes: 'multiline-cell' },
      },
      { type: 'styled-text', label: this.specialtyMessage, fieldName: 'specialtyPrimary', hideDefaultActions: true },
    ];

    if (this.locationBasedTargeting) {
      this.columns.splice(3, 0, { type: 'styled-text', label: this.locationMessage, fieldName: 'locationName', hideDefaultActions: true, initialWidth: 175 });
    }
  }

  async handleSearch() {
    this.resetModal();
    this.searchQuery = this.template.querySelector('lightning-input.search-input')?.value;

    // Don't execute empty searches
    if (!this.searchQuery) {
      return;
    }

    this.isLoading = true;

    try {
      const searchResponse = await this.territoryFeedbackService.search(this.territoryModelId, this.searchQuery);
      this.hasTooManyResults = searchResponse.moreThanFeedbackSearchLimit;
      this.accounts = searchResponse.feedbackAccounts.map(account => {
        const isAccountInTerritory = this.inTerritoryAccountsById.has(account.id);
        const outsideTerritorySearchResult = new AccountRecord(account, isAccountInTerritory);
        outsideTerritorySearchResult.availableActions = this.getActionsForAccount(outsideTerritorySearchResult);
        outsideTerritorySearchResult.moreActionsMenuClass = this.getMoreActionsMenuClassForAccount(outsideTerritorySearchResult);
        outsideTerritorySearchResult.addressDisplay = this.getAddressDisplayForAccount(outsideTerritorySearchResult);
        outsideTerritorySearchResult.locationName = this.getLocationDisplayForAccount(outsideTerritorySearchResult);

        return outsideTerritorySearchResult;
      });
    } catch (error) {
      this.emitError(error);
    }

    this.isLoading = false;
  }

  resetModal() {
    this.accounts = [];
    this.hasTooManyResults = false;
  }

  handleRowAction(event) {
    const { action, row } = event.detail;
    
    let associatedRows;
    if (this.locationBasedTargeting) {
      associatedRows = this.accounts.filter(account => account.id !== row.id && account.accountId === row.accountId);
    }

    this.dispatchEvent(
      new CustomEvent('rowaction', { detail: { action, row, associatedRows } })
    );
  }

  getActionsForAccount(account) {
    const actions = [];

    if (!account.isInTerritory) {
      actions.push({
        name: COMMANDS.ADD_ACCOUNT,
        label: this.addAccountMessage,
      });

      if (this.cyclePresent) {
        actions.push(        {
          name: COMMANDS.ADD_TARGET,
          label: this.addTargetMessage,
        });
      }
    }

    return actions;
  }

  // eslint-disable-next-line class-methods-use-this
  getMoreActionsMenuClassForAccount(account) {
    return !account.availableActions.length ? 'hide-more-actions' : '';
  }

  // eslint-disable-next-line class-methods-use-this
  getAddressDisplayForAccount(account) {
    return account.addresses.join('\n');
  }

  // eslint-disable-next-line class-methods-use-this
  getLocationDisplayForAccount(account) {
    return account.location?.name;
  }

  emitError(error) {
    this.dispatchEvent(
      new CustomEvent('error', {
        detail: {
          error,
        },
      })
    );
  }

  handleClose() {
    this.dispatchEvent(new CustomEvent('close'));
  }
}