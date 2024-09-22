/* eslint-disable class-methods-use-this */
import ATTENDEE from '@salesforce/schema/EM_Attendee_vod__c';
import ACCOUNT_LOOKUP from '@salesforce/schema/EM_Attendee_vod__c.Account_vod__c';
import USER_LOOKUP from '@salesforce/schema/EM_Attendee_vod__c.User_vod__c';
import CONTACT_LOOKUP from '@salesforce/schema/EM_Attendee_vod__c.Contact_vod__c';
import CHILD_ACCOUNT_LOOKUP from '@salesforce/schema/EM_Attendee_vod__c.Child_Account_vod__c';
import CHILD_ACCOUNT_ID from '@salesforce/schema/EM_Attendee_vod__c.Child_Account_Id_vod__c';
import ENTITY_REFERENCE_ID from '@salesforce/schema/EM_Attendee_vod__c.Entity_Reference_Id_vod__c';
import getViews from '@salesforce/apex/EmAttendeeSelection.getViews';
import getChildAccountViews from '@salesforce/apex/VeevaChildAccountAttendeeSelection.getViews';
import getAttendeeFields from '@salesforce/apex/EmAttendeeSelection.getAttendeeFields';
import getExistingAttendees from '@salesforce/apex/EmAttendeeSelection.getExistingAttendees';
import getAttendees from '@salesforce/apex/EmAttendeeSelection.getAttendees';
import getLastTopicDate from '@salesforce/apex/EmAttendeeSelection.getLastTopicDate';
import getRecentEvents from '@salesforce/apex/EmAttendeeSelection.getRecentEvents';
import getOutsideExistingAttendees from '@salesforce/apex/EmOutsideTerritorySearch.getOutsideExistingAttendees';
import getOutsideExistingAttendeesWithChildAccounts from '@salesforce/apex/EmOutsideTerritorySearch.getOutsideExistingAttendeesWithChildAccounts';
import getOutsideAttendees from '@salesforce/apex/EmOutsideTerritorySearch.getAttendees';
import getOutsideChildAccounts from '@salesforce/apex/EmOutsideTerritorySearch.getChildAccounts';
import getOutsideTerritoryRule from '@salesforce/apex/EmAttendeeSelection.getOutsideTerritoryRule';
import getViewDefinition from '@salesforce/apex/VeevaMyAccountsController.getViewDefinition';
import getChildAccounts from '@salesforce/apex/VeevaChildAccountAttendeeSelection.getChildAccounts';
import getUserTerritories from '@salesforce/apex/VeevaMyAccountsController.getUserTerritories';
import getAttendeeQueryCount from '@salesforce/apex/EmAttendeeSelection.getQueryCount';
import getOutsideAttendeeQueryCount from '@salesforce/apex/EmOutsideTerritorySearch.getQueryCount';
import { UniqueFieldName } from 'c/myAccountsDataService';

export default class AttendeeSelectionService {
  veevaDataService;

  constructor(veevaDataService, pleService, myAccountsDataService) {
    this.veevaDataService = veevaDataService;
    this.pleService = pleService;
    this.myAccountsDataService = myAccountsDataService;
  }

  async getViews() {
    return getViews();
  }

  async getAttendeeFields(eventId) {
    let attendeeFields;
    try {
      attendeeFields = getAttendeeFields({ eventId });
    } catch (ex) {
      attendeeFields = [];
    }
    return attendeeFields;
  }

  async getOutsideTerritoryConfig(eventId, eventConfig, eventCountry) {
    let oot;
    try {
      oot = await getOutsideTerritoryRule({ eventId, eventConfig, eventCountry });
    } catch (ex) {
      oot = {
        enabled: false,
      };
    }
    return oot;
  }

  async getAccountsForView(viewId) {
    let accountIds = [];
    try {
      let userTerritories = [];
      const viewDefinition = (await getViewDefinition({ viewId })) || {};
      if (viewDefinition.requiresTerritory) {
        userTerritories = await getUserTerritories();
      }
      const defaultTerritory = userTerritories.length > 0 ? { id: userTerritories[0].id, name: userTerritories[0].name } : null;
      const idField = {
        fieldType: 'id',
        name: 'Id',
        objectName: 'Account',
      };
      if (viewDefinition.source === 'LOCATION') {
        idField.objectName = 'Child_Account_vod__c';
      }
      viewDefinition.columns = [idField];
      const field = UniqueFieldName.create(idField);
      const response = await this.myAccountsDataService.getViewData(viewDefinition, userTerritories, [], null, defaultTerritory);
      if (response?.length > 0) {
        accountIds = response.map(account => account[field]);
      }
    } catch (error) {
      accountIds = [];
    }
    return accountIds;
  }

  async getExistingAttendees(eventId) {
    let currentAttendees = [];
    try {
      currentAttendees = await getExistingAttendees({ eventId });
    } catch (ex) {
      currentAttendees = [];
    }
    return currentAttendees;
  }

  async getOutsideExistingAttendees(eventId) {
    let currentAttendees = [];
    try {
      const response = await getOutsideExistingAttendees({ eventId });
      currentAttendees = response.map(({ fields, outside }) => ({ ...fields, outside }));
    } catch (ex) {
      currentAttendees = [];
    }
    return currentAttendees;
  }

  async getAttendees(args) {
    let results;
    try {
      const response = await getAttendees(args);
      results = response.map(({ record }) => ({ ...record }));
    } catch (ex) {
      results = [];
    }
    return results;
  }

  async getOutsideAttendees(args) {
    let results;
    try {
      const response = await getOutsideAttendees(args);
      results = response.map(({ fields, outside }) => ({ ...fields, outside }));
    } catch (ex) {
      results = [];
    }
    return results;
  }

  getAttendeeSoqlCount(args) {
    return getAttendeeQueryCount(args);
  }

  getOutsidetAttendeeSoqlCount(args) {
    return getOutsideAttendeeQueryCount(args);
  }

  async createAttendees(attendees) {
    const path = `/api/v1/base/data/${ATTENDEE.objectApiName}s`;
    const body = {};
    body[ATTENDEE.objectApiName] = attendees;
    const saveResult = {};
    try {
      const response = await this.veevaDataService.sendRequest('PUT', path, { sendToEngage: true }, body, 'createAttendees');
      if (response.recordCount > -1) {
        if (response.insertCount > 0) {
          saveResult.insertCount = response.insertCount;
        }
        if (response.failedCount > 0) {
          saveResult.failedInsertCount = response.failedCount;
          const { failedRecords } = response;
          if (failedRecords?.length > 0) {
            saveResult.failedInsertRecords = failedRecords.map(record => {
              let attendeeRelatedRecord = ACCOUNT_LOOKUP.fieldApiName;
              const recordFields = record[ATTENDEE.objectApiName];
              if (recordFields[CHILD_ACCOUNT_LOOKUP.fieldApiName]) {
                attendeeRelatedRecord = CHILD_ACCOUNT_LOOKUP.fieldApiName;
              } else if (recordFields[USER_LOOKUP.fieldApiName]) {
                attendeeRelatedRecord = USER_LOOKUP.fieldApiName;
              } else if (recordFields[CONTACT_LOOKUP.fieldApiName]) {
                attendeeRelatedRecord = CONTACT_LOOKUP.fieldApiName;
              } else if (recordFields[CHILD_ACCOUNT_ID.fieldApiName]) {
                attendeeRelatedRecord = CHILD_ACCOUNT_ID.fieldApiName;
              } else if (recordFields[ENTITY_REFERENCE_ID.fieldApiName]) {
                attendeeRelatedRecord = ENTITY_REFERENCE_ID.fieldApiName;
              }
              return {
                id: record[ATTENDEE.objectApiName][attendeeRelatedRecord],
                messages: record.insertErrors.map(error => error.message),
              };
            });
          }
        }
      }
    } catch (ex) {
      if (ex.status === -1) {
        saveResult.failedInsertCount = attendees.length;
        saveResult.failedInsertMessage = ex.message;
      }
    }
    return saveResult;
  }

  async deleteAttendees(attendeesIds) {
    const path = `/api/v1/layout3/data/${ATTENDEE.objectApiName}/Bulk`;
    const body = {
      Ids: attendeesIds,
    };
    const saveResult = {};
    try {
      const response = await this.veevaDataService.sendRequest('DELETE', path, {}, body, 'deleteAttendees');
      if (response.status === 0) {
        saveResult.deleteCount = attendeesIds.length;
      }
    } catch (ex) {
      if (ex.status === -1) {
        saveResult.failedDeleteCount = attendeesIds.length;
        saveResult.failedDeleteMessage = ex.message;
      }
    }
    return saveResult;
  }

  async hasDeleteButton(eventId, object, recordTypeIds, eventStatus, countryAlpha2Code, eventConfigId) {
    let hasDelete = false;
    try {
      const response = await this.pleService.getBatchEventLayoutButtons(
        eventId,
        object,
        recordTypeIds,
        eventStatus,
        countryAlpha2Code,
        eventConfigId
      );
      if (response?.data?.length > 0) {
        hasDelete = {};
        response.data.forEach(({ recordTypeId, buttons }) => {
          hasDelete[recordTypeId] = buttons.some(button => button.name.toLowerCase() === 'delete');
        });
      }
    } catch (e) {
      hasDelete = {};
    }
    return hasDelete;
  }

  async getLastTopicDate(objectName, recordId, eventId, eventTopic) {
    let lastTopicDate = '';
    try {
      lastTopicDate = getLastTopicDate({ objectName, recordId, eventId, eventTopic });
    } catch (e) {
      lastTopicDate = '';
    }
    return lastTopicDate;
  }

  async getAccountAddresses(accountId) {
    const query = `Account_vod__c;=;${accountId},AND,Inactive_vod__c;=;false`;
    const path = `/api/v1/base/data/Address_vod__c/search`;
    const params = {
      q: query,
      limit: 10,
      sort: 'Primary_vod__c',
      descend: true,
    };

    let addressRecords = [];
    try {
      const response = await this.veevaDataService.sendRequest('GET', path, params, null, 'getAccountAddress');
      addressRecords = response.data;
    } catch (e) {
      addressRecords = [];
    }
    return addressRecords;
  }

  async getRecentEvents(object, recordId, eventId) {
    let recentEvents = [];
    try {
      recentEvents = await getRecentEvents({ objectName: object, recordId, eventId });
    } catch (e) {
      recentEvents = [];
    }
    return recentEvents;
  }

  async getMCCP(accountId, eventStartDate) {
    const path = `/api/v1/attendee.hub/MCCP/${accountId}`;
    const params = { eventStartDate };

    let mccp = {};
    try {
      const response = await this.veevaDataService.sendRequest('GET', path, params, null, 'getMCCP');
      if (response?.data) {
        mccp = response.data;
      }
    } catch (e) {
      mccp = {};
    }
    return mccp;
  }

  async getOwners(ids) {
    const path = `/api/v1/base/data/User`;
    const params = {
      fields: 'Id,Name',
      ids,
    };
    let owners = [];
    try {
      const response = await this.veevaDataService.sendRequest('GET', path, params, null, 'getOwners');
      owners.push(...response.data);
    } catch (e) {
      owners = [];
    }
    return owners;
  }

  async getOutsideTerritoryRecordDetails(recordId, eventId) {
    const path = `/api/v1/attendee.hub/outside/${recordId}`;
    const params = {
      eventId,
      formatTime: true,
    };
    let outsideInfo = {};
    try {
      const response = await this.veevaDataService.sendRequest('GET', path, params, null, 'getOutsideTerritoryRecordDetails');
      if (response?.data?.length > 0) {
        [outsideInfo] = response.data[0].result;
      }
    } catch (e) {
      outsideInfo = {};
    }
    return outsideInfo;
  }

  async getAttendeeRuleWarnings(attendees, eventId) {
    const path = '/api/v1/attendee.hub/attendee-rule-warnings';
    const params = {
      platform: 'Online',
    };
    const data = {
      EM_Attendee_vod__c: attendees,
      Event_vod__c: eventId,
    };
    const response = await this.veevaDataService.sendRequest('PUT', path, params, data, 'getAttendeeRuleWarnings');
    if (response.status !== 0) {
      throw response;
    }
    return response.data;
  }

  async getOutsideExistingAttendeesWithChildAccounts(eventId) {
    let currentAttendees = [];
    try {
      const response = await getOutsideExistingAttendeesWithChildAccounts({ eventId });
      currentAttendees = response.map(({ fields, outside }) => ({ ...fields, outside }));
    } catch (ex) {
      currentAttendees = [];
    }
    return currentAttendees;
  }

  async getChildAccounts(parameters) {
    let childAccounts = [];
    try {
      const records = await getChildAccounts(parameters);
      childAccounts = records.map(record => ({ ...record.fields, Id: record.childAccountId, childId: record.childId, parentId: record.parentId }));
    } catch (e) {
      childAccounts = [];
    }
    return childAccounts;
  }

  async getOutsideChildAccounts(args) {
    let results;
    try {
      const response = await getOutsideChildAccounts(args);
      results = response.map(({ childAccountId, childId, parentId, fields, outside }) => ({
        ...fields,
        outside,
        Id: childAccountId,
        childId,
        parentId,
      }));
    } catch (ex) {
      results = [];
    }
    return results;
  }

  async getChildAccountViews() {
    return getChildAccountViews();
  }
}