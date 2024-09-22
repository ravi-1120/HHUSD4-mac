import getRelatedRecords from '@salesforce/apex/VeevaRelatedObjectController.getRelatedRecords';
import ASSIGNED_HOST from '@salesforce/schema/EM_Event_vod__c.Assigned_Host_vod__c';
import ENGAGE_WEBINAR from '@salesforce/schema/EM_Event_vod__c.Engage_Webinar_vod__c';
import WEBINAR_STATUS from '@salesforce/schema/EM_Event_vod__c.Webinar_Status_vod__c';
import USER_ID from '@salesforce/user/Id';

export default class EmEventEngageService {
  constructor(uiApi, dataSvc) {
    this.uiApi = uiApi;
    this.dataSvc = dataSvc;
  }

  async checkIncludeEngageButtons(eventId, objectInfo, record) {
    let includeStartWebinarButton;
    let includeScheduleEngageButton;

    if (
      'On_vod' === record.rawValue(WEBINAR_STATUS.fieldApiName) &&
      this.engageAvailable(objectInfo, record) &&
      (await this.checkEngageHost(USER_ID, eventId, record))
    ) {
      const meetingType = this.getRemoteMeetingRecordType(objectInfo, record);
      if ('Event_vod' === meetingType) {
        const hostUserInfo = await this.getMeetingUserInfo(USER_ID);
        includeStartWebinarButton =
          hostUserInfo?.fields?.Remote_Meeting_Host_Id_vod__c?.value && hostUserInfo?.fields?.Remote_Meeting_Host_Token_vod__c?.value;
      } else if ('Webinar_vod' === meetingType) {
        const hostUserInfo = await this.getMeetingUserInfo(record.rawValue(ASSIGNED_HOST.fieldApiName));
        includeStartWebinarButton = hostUserInfo?.fields?.Webinar_Host_Id_vod__c?.value && hostUserInfo?.fields?.Webinar_Host_Token_vod__c?.value;
      }
    }

    if (
      this.checkWebinarStatus(objectInfo, record) &&
      !record.rawValue(ENGAGE_WEBINAR.fieldApiName) &&
      !record.rawValue(ASSIGNED_HOST.fieldApiName)
    ) {
      const hostUserInfo = await this.getMeetingUserInfo(USER_ID);
      includeScheduleEngageButton =
        hostUserInfo?.fields?.Remote_Meeting_Host_Id_vod__c?.value && hostUserInfo?.fields?.Remote_Meeting_Host_Token_vod__c?.value;
    }
    return { includeStartWebinarButton, includeScheduleEngageButton };
  }

  checkWebinarStatus(objectInfo, record) {
    return (
      objectInfo.getFieldInfo(WEBINAR_STATUS.fieldApiName)?.updateable &&
      ('Off_vod' === record.rawValue(WEBINAR_STATUS.fieldApiName) ||
        'Failed_vod' === record.rawValue(WEBINAR_STATUS.fieldApiName) ||
        !record.rawValue(WEBINAR_STATUS.fieldApiName))
    );
  }

  engageAvailable(objectInfo, record) {
    const engageWebinarFieldInfo = objectInfo.getFieldInfo(ENGAGE_WEBINAR.fieldApiName);
    return (
      engageWebinarFieldInfo &&
      record.rawValue(engageWebinarFieldInfo.relationshipName)?.fields?.Meeting_Id_vod__c?.value &&
      record.rawValue(engageWebinarFieldInfo.relationshipName)?.fields?.Scheduled_vod__c?.value
    );
  }

  async checkEngageHost(userId, eventId, record) {
    if (userId === record.rawValue(ASSIGNED_HOST.fieldApiName)) {
      return true;
    }
    const hostIds = await this.getHostAndAlternativeHostIds(eventId);
    return hostIds.includes(userId);
  }

  getRemoteMeetingRecordType(objectInfo, record) {
    const engageWebinarFieldInfo = objectInfo.getFieldInfo(ENGAGE_WEBINAR.fieldApiName);
    return (
      engageWebinarFieldInfo && record.rawValue(engageWebinarFieldInfo.relationshipName)?.fields?.RecordType?.value?.fields?.DeveloperName?.value
    );
  }

  async getMeetingUserInfo(userId) {
    const result = await this.uiApi.getRecord(
      userId,
      [
        'User.Remote_Meeting_Host_Id_vod__c',
        'User.Remote_Meeting_Host_Token_vod__c',
        'User.Webinar_Host_Id_vod__c',
        'User.Webinar_Host_Token_vod__c',
      ],
      true
    );
    return result;
  }

  async getHostAndAlternativeHostIds(eventId) {
    const hostIds = [];
    const teamMembers = await getRelatedRecords({
      fields: 'Team_Member_vod__c,Virtual_Role_vod__c',
      objectApiName: 'EM_Event_Team_Member_vod__c',
      relationField: 'Event_vod__c',
      id: eventId,
      duplicateRawFields: true,
    });
    teamMembers.forEach(teamMember => {
      if ('Host_vod' === teamMember.Virtual_Role_vod__c || 'Alternative_Host_vod' === teamMember.Virtual_Role_vod__c) {
        hostIds.push(teamMember.Team_Member_vod__c);
      }
    });
    return hostIds;
  }

  async deleteWebinar(eventId) {
    const path = `/api/v1/layout3/EM_Event_vod__c/meeting/${eventId}`;
    return this.dataSvc.sendRequest('DELETE', path, null, null, 'deleteWebinar');
  }

  async scheduleEngage(data) {
    const queryParams = { 'data-format': 'raw' };
    return this.dataSvc.sendRequest('POST', '/api/v1/layout3/EM_Event_vod__c/meeting', queryParams, data, 'scheduleEngageMeeting');
  }
}