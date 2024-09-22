import { LightningElement, api } from 'lwc';
import MyAccountsButtonControllerFactory from 'c/myAccountsButtonControllerFactory';

export default class MyAccountsActionControls extends LightningElement {
  @api objectInfos;
  @api messageMap;

  _selectedAccounts;
  _view;

  menuItems = [];
  buttons = [];

  @api
  get hasMenuItems() {
    return this.menuItems.length > 0;
  }

  @api
  get selectedAccounts() {
    return this._selectedAccounts;
  }

  set selectedAccounts(value) {
    this._selectedAccounts = value;
    this._updateSelectedAccountsForActions(value);
  }

  @api
  get settings() {
    const settingsMap = new Map();
    for (const setting of this._settings) {
      if (settingsMap.has(setting[0])) {
        settingsMap.set(setting[0], Object.assign(settingsMap.get(setting[0]), setting[1]));
      } else {
        settingsMap.set(setting[0], JSON.parse(JSON.stringify(setting[1])));
      }
    }
    return settingsMap;
  }

  set settings(settings) {
    this._settings = settings;
  }

  @api
  get navItems() {
    return new Map(this._navItems?.data?.navItems?.map(navItem => [navItem.developerName, navItem]));
  }

  set navItems(navItems) {
    this._navItems = navItems;
  }

  @api
  get view() {
    return this._view;
  }

  set view(value) {
    if (this._view !== value) {
      this._view = value;
      this._createNewActions();
    }
  }

  connectedCallback() {
    this._createNewActions();
  }

  _createNewActions() {
    // clear buttons and menu items
    this.buttons = [];
    this.menuItems = [];

    // populate buttons and menu items based on factory response
    const actionControls = MyAccountsButtonControllerFactory.createAccountActionControls(
      this.view ?? {},
      this.objectInfos,
      this.messageMap,
      this.settings,
      this.navItems
    );
    actionControls
      .filter(control => control.visible)
      .forEach((control, index) => {
        if (index < 3) {
          this.buttons.push(control);
        } else {
          this.menuItems.push(control);
        }
      });

    if (this.selectedAccounts && this.selectedAccounts.length > 0) {
      this._updateSelectedAccountsForActions(this.selectedAccounts);
    }
  }

  _updateSelectedAccountsForActions(selectedAccounts) {
    this.menuItems.forEach(menuItem => {
      menuItem.setSelectedAccounts(selectedAccounts);
    });
    this.buttons.forEach(buttons => buttons.setSelectedAccounts(selectedAccounts));
    this._updateActions();
  }

  _updateActions() {
    // We must recreate the actions array with all of the same elements since only "simple" JSON objects are tracked in LWCs
    this.buttons = [...this.buttons];
    this.menuItems = [...this.menuItems];
  }

  async handleButtonSelection(event) {
    const index = event.currentTarget.value;
    const events = await this.buttons[index].createActionEvents();
    events.forEach(customEvent => this.dispatchEvent(customEvent));
  }

  async handleMenuItemSelection(event) {
    const { value } = event.detail;
    const events = await value.createActionEvents();
    events.forEach(customEvent => this.dispatchEvent(customEvent));
  }
}