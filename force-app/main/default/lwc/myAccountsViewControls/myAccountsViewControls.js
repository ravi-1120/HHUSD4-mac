import { api, LightningElement } from 'lwc';

import MyAccountsButtonControllerFactory from 'c/myAccountsButtonControllerFactory';

export default class MyAccountsViewControls extends LightningElement {
  @api objectInfos;
  @api messageMap;

  _hasLists;
  _selectedAccounts;
  _view;

  controls = [];

  @api
  get hasLists() {
    return this._hasLists;
  }

  set hasLists(value) {
    this._hasLists = value;
    this._updateHasListsForControls();
  }

  @api
  get selectedAccounts() {
    return this._selectedAccounts;
  }

  set selectedAccounts(value) {
    this._selectedAccounts = value;
    this._updateSelectedAccountsForControls(value);
  }

  @api
  get view() {
    return this._view;
  }

  set view(value) {
    if (this._view !== value) {
      this._view = value;
      this.isViewOwner = value.isViewOwner;
      this._createNewControls();
    }
  }

  connectedCallback() {
    this._createNewControls();
  }

  _createNewControls() {
    this.controls = MyAccountsButtonControllerFactory.createAccountViewControls(this.view ?? {}, this.objectInfos, this.messageMap);
    this._updateHasListsForControls();
    this._updateIsViewOwnerForControls();
    if (this.selectedAccounts && this.selectedAccounts.length > 0) {
      this._updateSelectedAccountsForControls(this.selectedAccounts);
    }
  }

  _updateHasListsForControls() {
    this.controls.forEach(control => {
      if ('hasLists' in control) {
        control.hasLists = this.hasLists;
      }
    });
    this._updateControls();
  }

  _updateIsViewOwnerForControls() {
    this.controls.forEach(control => {
      if ('isViewOwner' in control) {
        control.isViewOwner = this.isViewOwner;
      }
    });
    this._updateControls();
  }

  _updateSelectedAccountsForControls(selectedAccounts) {
    this.controls.forEach(control => {
      control.setSelectedAccounts(selectedAccounts);
    });
    this._updateControls();
  }

  _updateControls() {
    // We must recreate the controls array with all of the same elements since only "simple" JSON objects are tracked in LWCs
    this.controls = [...this.controls];
  }

  handleSelection(event) {
    const { value } = event.detail;
    const events = value.createEvents();
    events.forEach(customEvent => this.dispatchEvent(customEvent));
  }
}