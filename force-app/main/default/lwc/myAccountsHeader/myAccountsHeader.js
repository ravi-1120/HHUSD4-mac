import { api, LightningElement, wire } from 'lwc';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import { createRecord, deleteRecord, updateRecord } from 'lightning/uiRecordApi';
import { APPLICATION_SCOPE, MessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import { refreshApex } from '@salesforce/apex';

import VeevaToastEvent from 'c/veevaToastEvent';
import VeevaObjectInfo from 'c/veevaObjectInfo';

import MyAccountsAddToListModal from 'c/myAccountsAddToListModal';
import MyAccountsCreateNewListModal from 'c/myAccountsCreateNewListModal';
import MyAccountsEditListModal from 'c/myAccountsEditListModal';

import USER_ID from '@salesforce/user/Id';

import ACCOUNT_LIST_NAME_FLD from '@salesforce/schema/Account_List_vod__c.Name';
import ACCOUNT_LIST_ICON_NAME_FLD from '@salesforce/schema/Account_List_vod__c.Icon_Name_vod__c';

import PREFERENCES_OBJECT from '@salesforce/schema/Preferences_vod__c';
import LAST_TERRITORY_USED_FLD from '@salesforce/schema/Preferences_vod__c.Last_Territory_Used_vod__c';
import LAST_ACCOUNT_VIEW_USED_FLD from '@salesforce/schema/Preferences_vod__c.Last_Account_View_Used_vod__c';
import LAST_VIEW_USED_FLD from '@salesforce/schema/Preferences_vod__c.Last_View_Used_vod__c';
import PREFERENCES_USER_FLD from '@salesforce/schema/Preferences_vod__c.User_vod__c';
import PREFERENCES_TYPE_FLD from '@salesforce/schema/Preferences_vod__c.Type_vod__c';

import LOCALE from "@salesforce/i18n/locale";

import createDefaultView from '@salesforce/apex/VeevaMyAccountsController.createDefaultView';
import getMyAccountsUserPreference from '@salesforce/apex/VeevaMyAccountsController.getMyAccountsUserPreference';
import getUserTerritories from '@salesforce/apex/VeevaMyAccountsController.getUserTerritories';
import getViewDefinition from '@salesforce/apex/VeevaMyAccountsController.getViewDefinition';
import getViews from '@salesforce/apex/VeevaMyAccountsController.getViews';
import removeAccountListItems from '@salesforce/apex/VeevaMyAccountsController.removeAccountListItems';
import getVeevaSettings from '@salesforce/apex/VeevaCustomSettingsService.getVeevaSettings';

import MY_ACCOUNTS_VIEW_CHANNEL from '@salesforce/messageChannel/My_Accounts_View_Channel_vod__c';
import { loadStyle } from 'lightning/platformResourceLoader'

import myAccountsHeaderStyleOverrides from '@salesforce/resourceUrl/myAccountsHeaderStyleOverrides'

const ACCOUNT_LIST_TYPE = 'ACCOUNT_LIST';
const DISABLE_ALL_ACCOUNTS_FLD = 'DISABLE_ALL_ACCOUNTS_vod__c';

export default class MyAccountsHeader extends LightningElement {
  @api subtitle;
  @api labels;
  @api accountNumber = null;
  @api totalAccountNumber = null;
  @api selectedRecords = [];
  @api sortedColumn = '';
  @api sortDirection = '';
  _stylesLoaded = false;

  @wire(MessageContext)
  messageContext;
  myAccountsViewChannelSubscription;

  iconName = 'standard:account';

  _wiredGetMyAccountsUserPreferences = null;
  _wiredGetUserTerritories = null;
  _wiredGetViews = null;
  _preferencesLoaded = false;
  _canUpdatePreferences = false;
  _canUpdateLastTerritoryUsed = false;
  _preferencesObjectInfo;

  _initialViewTerritoryChangeDispatched = false;

  _territoriesLoaded = false;
  _viewsLoaded = false;
  _objectInfoLoaded = false;

  preferencesId;
  selectedTerritoryId;
  selectedTerritoryName;
  selectedView = {};

  views = [];

  veevaSettings = {};

  get preferencesLoaded() {
    return this._preferencesLoaded;
  }

  set preferencesLoaded(value) {
    this._preferencesLoaded = value;
    this.dispatchInitialViewTerritoryChange();
  }

  get territoriesLoaded() {
    return this._territoriesLoaded;
  }

  set territoriesLoaded(value) {
    this._territoriesLoaded = value;
    this.dispatchInitialViewTerritoryChange();
  }

  get viewsLoaded() {
    return this._viewsLoaded;
  }

  set viewsLoaded(value) {
    this._viewsLoaded = value;
    this.dispatchInitialViewTerritoryChange();
  }

  get objectInfoLoaded() {
    return this._objectInfoLoaded;
  }

  set objectInfoLoaded(value) {
    this._objectInfoLoaded = value;
    this.dispatchInitialViewTerritoryChange();
  }

  get lists() {
    return this.views.filter(view => view.type === ACCOUNT_LIST_TYPE);
  }

  get territories() {
    if (!this.territoriesLoaded) {
      return [];
    }

    const viewRequiresTerritorySelection = this.selectedView.requiresTerritory;
    const disableAllAccountsSetting = this.veevaSettings[DISABLE_ALL_ACCOUNTS_FLD];
    const userDoesNotHaveAnyTerritorySelections = this.#originalTerritories.length === 0;
    const shouldShowAllTerritories = !viewRequiresTerritorySelection && (userDoesNotHaveAnyTerritorySelections || !disableAllAccountsSetting);

    let territoriesToShow = this.#originalTerritories.map(territory => ({ label: territory.name, value: territory.id }));
    if (shouldShowAllTerritories) {
      const allLabel = this.selectedView.source === 'LOCATION' ? this.labels.allLocations : this.labels.allAccounts;
      territoriesToShow = [{ label: allLabel, value: 'all' }, ...territoriesToShow];
    }
    return territoriesToShow;
  }

  get headerMessage() {
    if (this.accountNumber == null || this.selectedRecords == null || this.labels.items == null ||
      this.labels.selected == null || (this.sortedColumn != null && this.labels.sortedBy == null)) {
      return '';
    }

    const formattedAccountNumber = new Intl.NumberFormat(LOCALE).format(this.accountNumber);
    const formattedTotalAccountNumber = new Intl.NumberFormat(LOCALE).format(this.totalAccountNumber);
    const formattedSelectedNumber = new Intl.NumberFormat(LOCALE).format(this.selectedRecords.length);

    if (this.sortedColumn == null && this.totalAccountNumber > 200000) {
      return `${this.labels.limitedItems?.replace('{0}', formattedAccountNumber).replace('{1}', formattedTotalAccountNumber)} • ${this.labels.selected?.replace('{0}', formattedSelectedNumber)}`;
    }

    if (this.sortedColumn == null) {
      return `${this.labels.items?.replace('{0}', formattedAccountNumber)} • ${this.labels.selected?.replace('{0}', formattedSelectedNumber)}`;
    }
    
    if (this.totalAccountNumber > 200000) {
      return `${this.labels.limitedItems?.replace('{0}', formattedAccountNumber).replace('{1}', formattedTotalAccountNumber)} • ${this.labels.selected?.replace('{0}', formattedSelectedNumber)} • ${this.labels.sortedBy?.replace('{0}', this.sortedColumn)}`;
    }

    return `${this.labels.items?.replace('{0}', formattedAccountNumber)} • ${this.labels.selected?.replace('{0}', formattedSelectedNumber)} • ${this.labels.sortedBy?.replace('{0}', this.sortedColumn)}`;
  }

  get shouldShowIcon() {
    return this.headerMessage?.length > 0 && this.sortedColumn != null && this.sortDirection;
  }

  #originalTerritories = [];

  @wire(getObjectInfos, { objectApiNames: [PREFERENCES_OBJECT.objectApiName] })
  wiredObjectInfos({ data }) {
    if (data) {
      const objectInfos = data.results;
      this._preferencesObjectInfo = new VeevaObjectInfo(objectInfos[0].result);
      this._canUpdatePreferences = this._preferencesObjectInfo.updateable;
      this._canUpdateLastTerritoryUsed = this._preferencesObjectInfo.updateableField(LAST_TERRITORY_USED_FLD.fieldApiName);
      this._canUpdateLastAccountViewUsed = this._preferencesObjectInfo.updateableField(LAST_ACCOUNT_VIEW_USED_FLD.fieldApiName);
      this._canUpdateLastViewUsed = this._preferencesObjectInfo.updateableField(LAST_VIEW_USED_FLD.fieldApiName);
      this.objectInfoLoaded = true;
    }
  }

  @wire(getViews)
  async wiredViews(wiredGetViews) {
    this._wiredGetViews = wiredGetViews;
    const { data } = this._wiredGetViews;
    if (data) {
      const views = data;
      this.views = views.map(view => ({ label: view.name, value: view.id, type: view.type, color: view.color, source: view.source }));
      if (this.views.length === 0) {
        const defaultView = await createDefaultView();
        if (defaultView) {
          this.selectedView = defaultView;
          this.views = [{ label: defaultView.name, value: defaultView.id, type: defaultView.type, color: defaultView.color }];
        }
      }

      this.dispatchViewCountChange();
      this.viewsLoaded = true;
    }
  }

  @wire(getUserTerritories)
  wiredTerritories(wiredGetUserTerritories) {
    this._wiredGetUserTerritories = wiredGetUserTerritories;
    const { data } = this._wiredGetUserTerritories;
    if (data) {
      this.#originalTerritories = data;
      if (this.preferencesLoaded && !this.selectedTerritoryId && this.territories.length > 0) {
        this._selectFirstAvailableTerritoryId();
      }
      this.territoriesLoaded = true;
    }
  }

  @wire(getMyAccountsUserPreference)
  async wiredUserPreferences(wiredGetMyAccountsUserPreferences) {
    this._wiredGetMyAccountsUserPreferences = wiredGetMyAccountsUserPreferences;
    const { data } = this._wiredGetMyAccountsUserPreferences;
    if (data) {
      const { view, territories } = data;
      this.preferencesId = data.preferencesId;
      if (!this.preferencesId) {
        this.preferencesId = await this._createPreferencesRecord();
      }

      // We will set the territory first since the view may change the territory
      // depending on if the view requires a territory to be selected
      if (territories?.length > 0) {
        const [firstTerritory] = territories;
        this.selectedTerritoryId = firstTerritory.value;
        this.selectedTerritoryName = firstTerritory.label;
      } else if (this.territories.length > 0) {
        this._selectFirstAvailableTerritoryId();
      }

      if (view) {
        this.selectedView = view;
        this.updateTerritorySelectedBasedOnView();
      }

      this.dispatchEvent(new CustomEvent('preferences', { detail: { preferencesId: data.preferencesId } }));

      this.preferencesLoaded = true;
    }
  }

  async connectedCallback() {
    this._subscribeToMyAccountsViewChannel();
    this.veevaSettings = await getVeevaSettings({ settingFieldNames: [DISABLE_ALL_ACCOUNTS_FLD] });
  }

  disconnectedCallback() {
    if (this.myAccountsViewChannelSubscription) {
      unsubscribe(this.myAccountsViewChannelSubscription);
    }
  }

  renderedCallback() {
    if(!this._stylesLoaded){
      loadStyle(this, myAccountsHeaderStyleOverrides);
      this._stylesLoaded = true;
    }
  }

  _subscribeToMyAccountsViewChannel() {
    this.myAccountsViewChannelSubscription = subscribe(
      this.messageContext,
      MY_ACCOUNTS_VIEW_CHANNEL,
      message => this._handleMyAccountsViewChannelMessage(message),
      { scope: APPLICATION_SCOPE }
    );
  }

  @api
  async removeAccountListItems(accountIds) {
    if (this.selectedView.type !== 'ACCOUNT_LIST') {
      return false;
    }
    // We will remove accounts from the currently selected view assuming it is an Account List
    const { accounts } = this.selectedView;
    const accountIdsToRemoveSet = new Set(accountIds);
    const listItemIds = accounts.filter(account => accountIdsToRemoveSet.has(account.accountId)).map(listItem => listItem.id);
    if (listItemIds.length === 0) {
      // If there are no list item ids to remove this means that the account ids received cannot be removed from the currently selected view.
      // This is unlikely in a user flow, but could occur if we are sending the wrong accountIds to this method
      return false;
    }

    // Now that we have the list item ids, we will attempt to delete all of them
    try {
      const itemsDeleted = await removeAccountListItems({ listItemIds });
      if (itemsDeleted > 0) {
        this.dispatchEvent(VeevaToastEvent.successMessage(this.labels.listUpdatedLabel));
      }
      return itemsDeleted > 0;
    } catch (e) {
      this.dispatchEvent(VeevaToastEvent.error(e));
      return false;
    }
  }

  @api
  async deleteCurrentView() {
    const currentViewId = this.selectedView.id;
    const deleteToastMessage = this.selectedView.type === 'ACCOUNT_LIST' ? this.labels.listDeletedLabel : this.labels.viewDeletedLabel;
    if (currentViewId) {
      try {
        await deleteRecord(currentViewId);
        const currentViewIndex = this.views.findIndex(view => view.value === currentViewId);
        this.views.splice(currentViewIndex, 1);
        this.selectedView = {};
        this.dispatchEvent(VeevaToastEvent.successMessage(deleteToastMessage));
        this.dispatchViewCountChange();
        await this._selectFirstAvailableViewAndSave();
        this.dispatchViewTerritoryChange();
        refreshApex(this._wiredGetViews);
      } catch (e) {
        this.dispatchEvent(VeevaToastEvent.error(e));
      }
    }
  }

  @api
  async addToList(accountIds) {
    if (accountIds && accountIds.length > 0) {
      // Note MyAccountsAddToListModal will handle any errors during creation of the Account List Items
      const result = await MyAccountsAddToListModal.open({
        size: 'small',
        options: this.lists,
        labels: this.labels,
        accountIds: [...accountIds],
      });
      if (result?.length > 0) {
        this.dispatchEvent(VeevaToastEvent.successMessage(this.labels.listUpdatedLabel));
      }
    }
  }

  @api
  async createNewList(accountIds) {
    const createNewListResult = await MyAccountsCreateNewListModal.open({
      size: 'small',
      labels: this.labels,
      accountIds: [...accountIds],
    });
    if (!createNewListResult) {
      return;
    }

    const { accountList } = createNewListResult;
    if (accountList) {
      this._addView({
        value: accountList.id,
        label: accountList.fields[ACCOUNT_LIST_NAME_FLD.fieldApiName].value,
        color: accountList.fields[ACCOUNT_LIST_ICON_NAME_FLD.fieldApiName].value,
        type: ACCOUNT_LIST_TYPE,
      });
      this.dispatchEvent(VeevaToastEvent.successMessage(this.labels.listCreatedLabel));
      this.dispatchViewCountChange();
      await this._updateSelectedViewAndUpdatePreferencesAndDispatchChange(accountList.id);
      refreshApex(this._wiredGetViews);
    }
  }

  @api
  async editList() {
    const editListResult = await MyAccountsEditListModal.open({
      size: 'small',
      labels: this.labels,
      accountListId: this.selectedView.id,
      existingName: this.selectedView.name,
    });
    if (!editListResult) {
      return;
    }

    const { accountList } = editListResult;
    if (accountList) {
      const views = this.views.filter(view => view.type !== ACCOUNT_LIST_TYPE);
      const lists = this.views.filter(view => view.type === ACCOUNT_LIST_TYPE);

      const listToUpdate = lists.find(list => list.value === accountList.id);
      const newViewName = accountList.fields[ACCOUNT_LIST_NAME_FLD.fieldApiName].value;
      listToUpdate.label = newViewName;
      // selectedView has read-only properties so we will create a copy with the updated name
      this.selectedView = { ...this.selectedView, name: newViewName };
      lists.sort((a, b) => a.label.localeCompare(b.label));
      this.views = [...views, ...lists];

      this.dispatchEvent(VeevaToastEvent.successMessage(this.labels.listUpdatedLabel));
    }
  }

  _addView(viewToAdd) {
    const views = this.views.filter(view => view.type !== ACCOUNT_LIST_TYPE);
    const lists = this.views.filter(view => view.type === ACCOUNT_LIST_TYPE);
    if (viewToAdd.type === ACCOUNT_LIST_TYPE) {
      lists.push(viewToAdd);
      lists.sort((a, b) => a.label.localeCompare(b.label));
    } else {
      views.push(viewToAdd);
      views.sort((a, b) => a.label.localeCompare(b.label));
    }
    this.views = [...views, ...lists];
  }

  get doesNotHaveTerritories() {
    return this.territories.length === 0;
  }

  get doesNotHaveViews() {
    return this.views.length === 0;
  }

  handleTerritoryChange(event) {
    const selectedTerritoryId = event.detail.value;
    if (selectedTerritoryId !== this.selectedTerritoryId) {
      this.selectedTerritoryId = selectedTerritoryId;
      this.selectedTerritoryName = this.territories.find(territory => territory.value === selectedTerritoryId).label;
      if (this._canUserUpdatePreferences()) {
        this._updatePreferencesToCurrentlySelected();
      }
      this.dispatchViewTerritoryChange();
    }
  }

  async handleViewChange(event) {
    const selectedViewId = event.detail.value;
    if (selectedViewId !== this.selectedView.id) {
      await this._updateSelectedViewAndUpdatePreferencesAndDispatchChange(selectedViewId);
    }
  }

  async _createPreferencesRecord() {
    let preferencesId;
    try {
      const preferences = await createRecord({
        apiName: PREFERENCES_OBJECT.objectApiName,
        fields: {
          [PREFERENCES_USER_FLD.fieldApiName]: USER_ID,
          [PREFERENCES_TYPE_FLD.fieldApiName]: 'User',
        },
      });
      preferencesId = preferences.id;
    } catch (e) {
      // Error creating Preferences record, possible that user is missing create permission
      preferencesId = null;
    }
    return preferencesId;
  }

  async _updateSelectedViewAndUpdatePreferencesAndDispatchChange(selectedViewId) {
    await this.updateSelectedView(selectedViewId);
    if (this._canUserUpdatePreferences()) {
      this._updatePreferencesToCurrentlySelected();
    }
    this.dispatchViewTerritoryChange();
  }

  async _updatePreferencesToCurrentlySelected() {
    const fieldsToUpdate = {};

    if (this.selectedView.id && this._canUpdateLastViewUsed) {
      fieldsToUpdate[LAST_VIEW_USED_FLD.fieldApiName] = this.selectedView.id;
    } else if (this.selectedView.id && this.selectedView.type !== 'ACCOUNT_LIST' && this._canUpdateLastAccountViewUsed) {
      // LAST_ACCOUNT_VIEW_USED_FLD only supports VIEW ids, so we cannot store an Account List Id for this field
      fieldsToUpdate[LAST_ACCOUNT_VIEW_USED_FLD.fieldApiName] = this.selectedView.id;
    }

    if (this.selectedTerritoryId && this._canUpdateLastTerritoryUsed) {
      fieldsToUpdate[LAST_TERRITORY_USED_FLD.fieldApiName] = this.selectedTerritoryId;
    }

    if (Object.keys(fieldsToUpdate).length > 0) {
      try {
        await updateRecord({
          fields: {
            ...fieldsToUpdate,
            Id: this.preferencesId,
          },
        });
        if (this._wiredGetMyAccountsUserPreferences) {
          refreshApex(this._wiredGetMyAccountsUserPreferences);
        }
      } catch (e) {
        this.dispatchEvent(VeevaToastEvent.error(e));
      }
    }
  }

  _canUserUpdatePreferences() {
    return this._canUpdatePreferences && this.preferencesId;
  }

  async _selectFirstAvailableViewAndSave() {
    const [firstView] = this.views;
    await this.updateSelectedView(firstView.value);
    if (this._canUserUpdatePreferences()) {
      this._updatePreferencesToCurrentlySelected();
    }
  }

  _selectFirstAvailableTerritoryId() {
    if (this.territories.length > 0) {
      const [firstTerritory] = this.territories;
      this.selectedTerritoryId = firstTerritory.value;
      this.selectedTerritoryName = firstTerritory.label;
    } else {
      this.selectedTerritoryId = null;
      this.selectedTerritoryName = null;
    }
  }

  _isSelectedTerritoryValid() {
    return (
      this.territories.find(territory => territory.label === this.selectedTerritoryName && territory.value === this.selectedTerritoryId) !== undefined
    );
  }

  async updateSelectedView(selectedViewId) {
    this.selectedView = await getViewDefinition({ viewId: selectedViewId });
    this.updateTerritorySelectedBasedOnView();
  }

  updateTerritorySelectedBasedOnView() {
    if (this.selectedView.id && this.selectedView.requiresTerritory && this.selectedTerritoryId === 'all' && this.territories.length > 0) {
      this.selectedTerritoryId = this.territories[0].value;
      this.selectedTerritoryName = this.territories[0].label;
    }
  }

  async dispatchInitialViewTerritoryChange() {
    // Selects first available view if views were loaded and preferences were loaded but the selectedView was not set
    // We also will wait for objectInfo to be loaded so we can determine whether the user can update the preferences record
    if (this.objectInfoLoaded && this.viewsLoaded && this.preferencesLoaded && Object.keys(this.selectedView).length === 0) {
      if (this.views.length > 0) {
        await this._selectFirstAvailableViewAndSave();
      }
    }
    // The initial viewterritorychange will be dispatched once after user's preferences and territories have loaded
    // Also checks that the selected view has been populated
    if (
      !this._initialViewTerritoryChangeDispatched &&
      this.preferencesLoaded &&
      this.territoriesLoaded &&
      Object.keys(this.selectedView).length > 0
    ) {
      this._initialViewTerritoryChangeDispatched = true;
      if (!this._isSelectedTerritoryValid()) {
        this._selectFirstAvailableTerritoryId();
      }
      this.dispatchViewTerritoryChange();
    }
  }

  dispatchViewTerritoryChange() {
    const selectedTerritory = this._getSelectedTerritory();
    const territories = this._getSelectedTerritoryAndChildren();
    const groupIds = this._getGroupIdsBasedOnSelectedTerritory(territories);
    this.dispatchEvent(
      new CustomEvent('viewterritorychange', {
        detail: {
          defaultTerritory: this._getDefaultTerritory(),
          territories: territories.map(territory => ({ id: territory.id, name: territory.name })),
          selectedTerritory,
          view: this.selectedView,
          groupIds,
        },
      })
    );
  }

  _getSelectedTerritoryAndChildren() {
    if (!this.selectedTerritoryId) {
      return [];
    }
    return this.selectedTerritoryId === 'all' ? this.#originalTerritories : this._getCurrentAndChildTerritories(this.selectedTerritoryId);
  }

  _getSelectedTerritory() {
    return this.selectedTerritoryId && this.selectedTerritoryId !== 'all'
      ? {
          id: this.selectedTerritoryId,
          name: this.selectedTerritoryName,
        }
      : null;
  }

  dispatchViewCountChange() {
    this.dispatchEvent(
      new CustomEvent('viewcountchange', {
        detail: {
          views: this.views.length - this.lists.length,
          lists: this.lists.length ?? 0,
        },
      })
    );
  }

  _getGroupIdsBasedOnSelectedTerritory(territoriesToGetGroupIds) {
    if (territoriesToGetGroupIds.length === 0) {
      return [];
    }
    if (!this.selectedTerritoryId || this.selectedTerritoryId === 'all') {
      return [];
    }
    return this._getGroupIds(territoriesToGetGroupIds);
  }

  _getGroupIds(territories) {
    return territories.map(territory => territory.groupId);
  }

  _getCurrentAndChildTerritories(territoryId) {
    const territoriesByParent = this._getChildTerritoriesByParent();
    const allGroupForTerritoryId = [this.#originalTerritories.find(territory => territory.id === territoryId)];

    const childTerritories = territoriesByParent[territoryId];
    while (childTerritories?.length > 0) {
      const currentTerritory = childTerritories.pop();
      allGroupForTerritoryId.push(currentTerritory);
      const childTerritoriesForCurrentTerritory = territoriesByParent[currentTerritory.id];
      if (childTerritoriesForCurrentTerritory) {
        childTerritories.push(...childTerritoriesForCurrentTerritory);
      }
    }

    return allGroupForTerritoryId;
  }

  _getChildTerritoriesByParent() {
    return this.#originalTerritories.reduce((currentMap, currentTerritory) => {
      const { parentId } = currentTerritory;
      let childTerritories = currentMap[parentId];
      if (!childTerritories) {
        childTerritories = [];
        currentMap[parentId] = childTerritories;
      }
      childTerritories.push(currentTerritory);
      return currentMap;
    }, {});
  }

  _getDefaultTerritory() {
    const originalTerritoryLength = this.#originalTerritories.length;
    const defaultTerritoryIndex = this.selectedView.source === 'LOCATION' ? originalTerritoryLength - 1 : 0;
    return this.selectedTerritoryId === 'all' && originalTerritoryLength > 0
      ? {
          id: this.#originalTerritories[defaultTerritoryIndex].id,
          name: this.#originalTerritories[defaultTerritoryIndex].name,
        }
      : null;
  }

  async _handleMyAccountsViewChannelMessage(message) {
    switch (message.type) {
      case 'refreshViews':
        if (this._wiredGetViews) {
          refreshApex(this._wiredGetViews);
        }
        break;
      case 'refreshPreferences':
        if (this._wiredGetMyAccountsUserPreferences) {
          await refreshApex(this._wiredGetMyAccountsUserPreferences);
          // We will dispatch viewterritorychange after refreshing the preferences
          // If we are refreshing preferences this means:
          //  - the preferences were updated to point at a new view or territory
          //  - the view was updated via View Edit
          this.dispatchViewTerritoryChange();
        }
        break;
      default:
        break;
    }
  }
}