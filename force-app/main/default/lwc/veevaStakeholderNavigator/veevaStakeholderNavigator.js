import { api } from 'lwc';
import StakeholderNavigatorResourceURL from '@salesforce/resourceUrl/stakeholder_navigator';
import { NavigationMixin } from 'lightning/navigation';
import VeevaMainPage from 'c/veevaMainPage';
import StakeholderNavigatorMetricsService from 'c/stakeholderNavigatorMetricsService';
import { getPageController } from 'c/veevaPageControllerFactory';
import { VeevaAccountSearchController } from 'c/veevaAccountSearch';
import { VeevaMessageRequest } from 'c/veevaMessageService';
import initializeGraph from '@salesforce/apex/StakeholderNavigatorController.initializeGraph';
import loadInitialHierarchy from '@salesforce/apex/StakeholderNavigatorController.loadInitialHierarchy';
import loadAccountBatch from '@salesforce/apex/StakeholderNavigatorController.loadAccountBatch'; 
import loadHierarchy from '@salesforce/apex/StakeholderNavigatorController.loadHierarchy';
import loadParentHierarchy from '@salesforce/apex/StakeholderNavigatorController.loadParentHierarchy';
import loadAccountRelatedObjectFields from '@salesforce/apex/StakeholderNavigatorController.loadAccountRelatedObjectFields';
import loadOOHAccounts from '@salesforce/apex/StakeholderNavigatorController.loadOOHAccounts';
import getRootAccountDataWithRelatedAffiliationIds from '@salesforce/apex/StakeholderNavigatorController.getRootAccountDataWithRelatedAffiliationIds';
import getRootAccountsAffiliationData from '@salesforce/apex/StakeholderNavigatorController.getRootAccountsAffiliationData';
import queryAccountDataWithRelatedAffiliationData from '@salesforce/apex/StakeholderNavigatorController.queryAccountDataWithRelatedAffiliationData';
import addToTerritory from '@salesforce/apex/StakeholderNavigatorController.addToTerritory';
import { deleteRecord, createRecord, updateRecord } from 'lightning/uiRecordApi';

export default class VeevaStakeholderNavigator extends NavigationMixin(VeevaMainPage) {

  @api recordId;
  @api includeHeader = false;
  @api height = 600;
  @api launchedFromAuraParent = false; // set to true by the original aura entry point, not accessible via the page builder

  staticResourceURL = `${StakeholderNavigatorResourceURL}/index.html`;
  ctrl;
  pageCtrl = getPageController('pageCtrl');
  // eslint-disable-next-line no-restricted-globals
  uuid = self.crypto.randomUUID();
  shouldShowAccountCount = true;
  numberOfAccountsLoaded = 0;
  messageMap = {};

  showAccountSearch = false;
  fromAccountId;
  toAccountFieldsToQuery;
  showAccountSelectionErrorModal = false;

  stakeholderNavigatorMetricsService = new StakeholderNavigatorMetricsService();
  isInitialLoadCount = true;

  // we know we need to query for this before Stakeholder Navigator asks us to
  // so we get a headstart in the connected callback
  metadataPromise;

  get iframe() {
    return this.template.querySelector("iframe");
  }

  get iframeClass() {
    return this.launchedFromAuraParent ? 'iframe-full-width iframe-full-height' : 'iframe-full-width';
  }

  get iframeStyle() {
    return this.launchedFromAuraParent ? '' : `height: ${this.height}px`;
  }

  async connectedCallback() {
    this.metadataPromise = this.queryObjectMetadata();
    window.addEventListener('message', event => this.handleMessage(event));
    this.stakeholderNavigatorMetricsService.start();

    const msgRequest = new VeevaMessageRequest();
    msgRequest.addRequest('SELF_AFFILIATED_ACCOUNT', 'TriggerError', 'From Account and To Account cannot be the same.', 'selfAffiliationAccount');
    msgRequest.addRequest('STAKEHOLDER_NAVIGATOR_PAGE_NAME', 'stakeholder_navigator', 'Stakeholder Navigator', 'pageName');
    this.messageMap = await this.pageCtrl.getMessageMap(msgRequest);

    this.ctrl = new VeevaAccountSearchController(this.pageCtrl);
  }

  sendMessage(message) {
    this.iframe?.contentWindow?.postMessage(message, "*");
  }

  handleMessage(event) {
    const message = this.parseMessage(event);
    const { command } = message;

    if (command === 'ping') {
      this.sendMessage({ command: 'ping',  uuid: this.uuid });
      return;
    }

    if (this.uuid !== message.uuid) {
      return;
    }
    
    switch (command) {
      case 'initGraph':
        initializeGraph({ rootId: this.recordId })
          .then(res => {
            this.sendMessage({ command: 'initGraph', data: res });
          })
        break;
      case 'objectMetadata':
        this.metadataPromise
          .then(res => {
            this.sendMessage({ command: 'objectMetadata', data: res });
          })
        break;
      case 'loadInitialHierarchy':
        loadInitialHierarchy({ rootId: message.rootId })
          .then(res => {
            this.sendMessage({ command: 'loadInitialHierarchy', data: res })
          })
        break;
      case 'loadAccountBatch':
        loadAccountBatch({ batchId: message.batchId, accountIds: message.accountIds, accountFields: message.accountFields, affiliationFields: message.affiliationFields })
          .then(res => {
            this.sendMessage({ command: 'loadAccountBatch', data: res })
          })
        break;
      case 'loadHierarchy':
        loadHierarchy({ ids: message.ids, parentId: message.parentId })
          .then(res => {
            res.parentId = message.parentId;
            this.sendMessage({ command: 'loadHierarchy', data: res })
          })
        break;
      case 'loadParentHierarchy':
        loadParentHierarchy({ childId: message.childId })
          .then(res => {
            this.sendMessage({ command: 'loadParentHierarchy', data: res })
          })
        break;
      case 'loadAccountRelatedObjectFields':
        loadAccountRelatedObjectFields({relatedObjectRequest: { accountId: message.accountId, relatedObjectFields: message.relatedObjectFields }})
          .then(res => {
            this.sendMessage({ command: 'loadAccountRelatedObjectFields', data: res })
          })
        break;
      case 'loadOutOfHierarchyAccounts':
        loadOOHAccounts({outOfHierarchyAccountRequest: { originAccountId: message.originAccountId, accountIds: message.accountIds, accountFields: message.accountFields }})
          .then(res => {
            this.sendMessage({ command: 'loadOutOfHierarchyAccounts', data: res })
          })
        break;
      case 'loadAffiliationViewData':
        this.loadAffiliationViewData({ rootAccountId: message.rootAccountId, accountFields: message.accountFields, affiliationFields: message.affiliationFields })
          .then(res => {
            this.sendMessage({ command: 'loadAffiliationViewData', data: res })
          })
        break;
      case 'addAccountToTerritories':
        addToTerritory({ accountId: message.accountId, terrsToAdd: message.terrsToAdd })
          .then(res => {
            this.sendMessage({ command: 'addAccountToTerritories', data: {
              ...res, 
              accountId: message.accountId,
              terrsToAdd: message.terrsToAdd
            }})
          })
        break;
      case 'updateNumberAccounts':
        this.numberOfAccountsLoaded = message.numberAccounts;
        if (this.isInitialLoadCount) {
          this.stakeholderNavigatorMetricsService.finishInitialLoad(message.numberAccounts);
          this.isInitialLoadCount = false;
        }
        break;
      case 'shouldShowAccountCount':
        this.shouldShowAccountCount = message.shouldShowAccountCount;
        break;
      case 'createRecord':
        this.createObjectRecord(message);
        break;
      case 'updateRecord':
        this.updateObjectRecord(message);
        break;
      case 'deleteRecord':
        this.deleteObjectRecord(message);
        break;
      case 'performAccountSearch':
        this.showAccountSearch = true;
        this.fromAccountId = message.fromAccountId;
        this.toAccountFieldsToQuery = message.accountFields;
        break;
      case "redirect":
        switch (message.type) {
          case 'timeline':
            this.redirectToTimeline(message.location);
            break;
          case 'detail':
            this.redirectToAccountDetail(message.location);
            break;
          case 'external':
            window.open(this.formatUrl(message.location), '_blank');
            break;
          default:
            break;
        }
        break;
      default:
        // eslint-disable-next-line no-console
        console.log(`Unexpected command (${command}) recieved from Stakeholder Navigator, with content ${message}`);
        break;
    }
  }

  parseMessage(event) {
    if (typeof event.data === "string") {
        try {
            return JSON.parse(event.data);
        } catch {
            return event.data;
        }
    }
    return event.data;
  }

  async queryObjectMetadata() {

    const restApiResult = await Promise.allSettled(
      [
        this.getObjectInfoFromRestAPI('Account'),
        this.getObjectInfoFromRestAPI('Address_vod__c'),
        this.getObjectInfoFromRestAPI('Affiliation_vod__c'),
      ]
    );

    const result = {
      Account: { objectInfo : restApiResult[0]?.value },
      Address_vod__c: { objectInfo : restApiResult[1]?.value },
      Affiliation_vod__c: { objectInfo : restApiResult[2]?.value },
    }

    return result;
  }

  async getObjectInfoFromRestAPI(objectName) {
    const objectNameEncoded = encodeURIComponent(objectName);
    const url = `/sobjects/${objectNameEncoded}/describe`;
    let objectMetadata;
    try {
      const response = await this.pageCtrl.uiApi.performRequest(`sobject-describe-${objectName}`, url);
      if (response.success) {
        objectMetadata = {
          apiName: objectName,
          ...response.data
        };
        objectMetadata.fields = this.formatFields(objectMetadata.fields);
        objectMetadata.recordTypeInfos = this.formatRecordTypes(objectMetadata.recordTypeInfos);
      } else {
        // eslint-disable-next-line no-console 
        console.warn(`Could not retrieve object info for ${objectName}`, response.error);
        objectMetadata = null;
      }
    } catch (e) {
      objectMetadata = null;
    }
    return objectMetadata;
  }

  formatFields(fields) {
    const fieldMap = {};
    if (fields) {
      fields.forEach(field => {
        fieldMap[field.name] = {
          apiName: field.name,
          dataType: field.type,
          ...field
        }
      });
    }
    return fieldMap;
  }

  formatRecordTypes(recordTypeInfos) {
    const recordTypeInfosMap = {};
    if (recordTypeInfos) {
      recordTypeInfos.forEach(recordTypeInfo => {
        recordTypeInfosMap[recordTypeInfo.recordTypeId] = {
          ...recordTypeInfo
        }
      });
    }
    return recordTypeInfosMap;
  }

  async loadAffiliationViewData({rootAccountId, accountFields, affiliationFields}) {

    // in order to circumvent apex row query limits we split this up into multiple apex transactions
    const {rootAccountData, rootsAffiliationIds} = await getRootAccountDataWithRelatedAffiliationIds({rootAccountId, accountFields});

    const batchSize = this.chooseBatchSizeForTotalRequestSize(rootsAffiliationIds.length);
    const affiliationIdChunks = [];
    for (let i = 0; i < rootsAffiliationIds.length; i += batchSize) {
      affiliationIdChunks.push(rootsAffiliationIds.slice(i, i + batchSize));
    }

    const chunkPromises = affiliationIdChunks.map(affiliationIdChunk => getRootAccountsAffiliationData({affiliationIdChunk, accountFields, affiliationFields}))
    const chunkResults = await Promise.all(chunkPromises);
    
    const res = {
      account: {
        ...rootAccountData,
        affiliations: chunkResults.flat()
      }
    }

    return res;
  }

  chooseBatchSizeForTotalRequestSize(requestSize) {

    if (requestSize >= 0 && requestSize < 2500) {
      return 500;
    }
    
    if (requestSize >= 2500 && requestSize < 5000) {
      return 1000;
    }
    
    if (requestSize >= 5000  && requestSize < 10000) {
      return 2000;
    }

    if (requestSize >= 10000 && requestSize < 15000) {
      return 3000;
    }

    return 4000; // past a batch size of 4000, we risk hitting row request limits on individual requests
  }

  deleteObjectRecord(message) {
    if (message.object === "Affiliation_vod__c") {
      this.deleteAffiliation(message);
      return;
    }
    const { id } = message;
    const response = {
      command: message.command,
      object: message.object,
      response: true,
      result: { success: false, id, errors: [] }
    };
    deleteRecord(id)
      .then(() => {
        response.result.success = true;
        this.sendMessage(response);
      })
      .catch(error => {
        response.result.errors.push(error);
        this.sendMessage(response);
      });
  }

  deleteAffiliation(message) {
    // special logic speficially for Affiliation_vod__c, as the proper way to delete it is 
    // to set the Destroy_vod__c field to true
    const affFieldData = {
      Id: message.id,
      destroy_vod__c: true
    };
    const newMessage = {
      object: message.object,
      fieldData: affFieldData,
      command: message.command
    };
    this.updateObjectRecord(newMessage)
  }

  createObjectRecord(message) {
    switch(message.object) {
      case 'Affiliation_vod__c':
        this.createAffiliationRecord(message);
        break;
      default:
        break;
    }
  }

  createAffiliationRecord(message) {
    const recordInput = {
      apiName: message.object,
      fields: message.fieldData
    };
    const response = {
      command: message.command,
      object: message.object,
      fieldData: message.fieldData,
      response: true,
      result: { success: false, id: "", errors: [] }
    };
    createRecord(recordInput)
      .then((newRecord) => {
        response.result.id = newRecord.id;
        response.result.success = true;
        response.fieldData.Child_affiliation_vod__c = newRecord.fields.Child_affiliation_vod__c?.value;
        this.sendMessage(response);
      })
      .catch(error => {
        response.result.errors.push(error);
        this.sendMessage(response);
      });
  }

  updateObjectRecord(message) {
    const recordInput = {
      fields: message.fieldData
    };
    const response = {
      command: message.command,
      object: message.object,
      fieldData: message.fieldData,
      response: true,
      result: { success: false, id: message.fieldData.Id, errors: [] }
    };
    updateRecord(recordInput)
      .then(() => {
        response.result.success = true;
        this.sendMessage(response);
      })
      .catch(error => {
        if (error.status === 404 && message.object === "Affiliation_vod__c" && message.command === "deleteRecord") {
          // Affilaition_vod__c can be deleted by an update, and thus a 404 will be returned as the now
          // deleted object info cannot be retrieved, this can be ignored
          response.result.success = true;
          this.sendMessage(response);
        } else {
          response.result.errors.push(error);
          this.sendMessage(response);
        }
      });
    }

    redirectToAccountDetail(id) {
      this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: id,
            objectApiName: 'Account',
            actionName: 'view'
        }
      });
    }

    redirectToTimeline(id) {
      const url = `/apex/Account_Overview_vod?id=${id}`;
      this[NavigationMixin.Navigate]({
          type: 'standard__webPage',
          attributes: {
              url
          }
      });
    }

    formatUrl(passedUrl) {
      if (passedUrl.startsWith("http://") || passedUrl.startsWith("https://")) {
        return passedUrl;
      } 
      return `https://${passedUrl}`;
    }

    handleModalCancel() {
      this.showAccountSearch = false;
    }

    handleAccountSelection(event) {
      queryAccountDataWithRelatedAffiliationData({ accountId: event.detail, accountFields: this.toAccountFieldsToQuery })
        .then(res => {
          this.sendMessage({ command: 'performAccountSearch', data: res });
          this.showAccountSearch = false;
        });
    }

    handleInvalidSelection() {
      this.showAccountSelectionErrorModal = true;
    }

    closeAlertDialog() {
      this.showAccountSelectionErrorModal = false;
    }
}