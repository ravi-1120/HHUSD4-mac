import PicklistController from 'c/picklistController';
import getRelatedRecords from '@salesforce/apex/VeevaRelatedObjectController.getRelatedRecords';
import EVENT_VOD from '@salesforce/schema/EM_Event_Team_Member_vod__c.Event_vod__c';
import VIRTUAL_ROLE from '@salesforce/schema/EM_Event_Team_Member_vod__c.Virtual_Role_vod__c';

export default class VirtualRoleFieldController extends PicklistController {
  async options() {
    const [picklistValues, hasHost] = await Promise.all([
      super.options(),
      this.hasHostTeamMember(this.pageCtrl),
    ]);
    if (hasHost) {
      picklistValues.values = picklistValues.values.filter(picklistValue => 'Host_vod' !== picklistValue.value);
    }
    return picklistValues;
  
  }

  async hasHostTeamMember(pageCtrl) {
    const queryFields = [VIRTUAL_ROLE.fieldApiName];
    const teamMembers = await getRelatedRecords({
      fields: queryFields.join(','),
      objectApiName: pageCtrl.objectApiName,
      relationField: EVENT_VOD.fieldApiName,
      id: pageCtrl.eventId,
      formatFields: false,
    });
    return teamMembers.some(t => 'Host_vod' === t.Virtual_Role_vod__c);
  }
}