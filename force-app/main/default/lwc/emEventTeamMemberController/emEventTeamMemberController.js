import EmController from 'c/emController';
import TeamMemberTypeFieldController from 'c/teamMemberTypeFieldController';
import LookupDataReferenceController from 'c/lookupDataReferenceController';
import GroupNameReferenceController from 'c/groupNameReferenceController';
import VirtualRoleFieldController from 'c/virtualRoleFieldController';
import EmEventTeamMemberRecord from 'c/emEventTeamMemberRecord';
import VeevaUtils from 'c/veevaUtils';
import NAME from '@salesforce/schema/EM_Event_Team_Member_vod__c.Name';
import GROUP from '@salesforce/schema/Group';
import TEAM_MEMBER_TYPE from '@salesforce/schema/EM_Event_Team_Member_vod__c.Team_Member_Type_vod__c';
import TEAM_MEMBER from '@salesforce/schema/EM_Event_Team_Member_vod__c.Team_Member_vod__c';
import GROUP_NAME from '@salesforce/schema/EM_Event_Team_Member_vod__c.Group_Name_vod__c';
import FIRST_NAME from '@salesforce/schema/EM_Event_Team_Member_vod__c.First_Name_vod__c';
import LAST_NAME from '@salesforce/schema/EM_Event_Team_Member_vod__c.Last_Name_vod__c';
import VIRTUAL_ROLE from '@salesforce/schema/EM_Event_Team_Member_vod__c.Virtual_Role_vod__c';

const HIDDEN_FIELDS = [TEAM_MEMBER.fieldApiName, GROUP_NAME.fieldApiName, FIRST_NAME.fieldApiName, LAST_NAME.fieldApiName, VIRTUAL_ROLE.fieldApiName];

export default class EmEventTeamMemberController extends EmController {
  toVeevaRecord(value) {
    return value instanceof EmEventTeamMemberRecord ? value : new EmEventTeamMemberRecord(value);
  }

  initItemController(meta, record) {
    const { field } = meta;
    if (field) {
      const fieldDescribe = this.objectInfo.getFieldInfo(field);
      const isRequired = this.action !== 'View' && this.isFieldOnLayout(TEAM_MEMBER_TYPE.fieldApiName);
      if (field === TEAM_MEMBER_TYPE.fieldApiName) {
        return new TeamMemberTypeFieldController(meta, this, fieldDescribe, record);
      }
      if (field === TEAM_MEMBER.fieldApiName) {
        const teamMemberCtrl = new LookupDataReferenceController(meta, this, fieldDescribe, record);
        teamMemberCtrl.required = isRequired || teamMemberCtrl.required;
        return teamMemberCtrl;
      }
      if (field === GROUP_NAME.fieldApiName && this.action !== 'View') {
        fieldDescribe.referenceToInfos = [{ apiName: GROUP.objectApiName, nameFields: [] }];
        const groupNameCtrl = new GroupNameReferenceController(meta, this, fieldDescribe, record);
        groupNameCtrl.required = isRequired || groupNameCtrl.required;
        return groupNameCtrl;
      }
      if (field === FIRST_NAME.fieldApiName || field === LAST_NAME.fieldApiName) {
        const writeInCtrl = super.initItemController(meta, record);
        writeInCtrl.required = isRequired || writeInCtrl.required;
        return writeInCtrl;
      }
      if (field === VIRTUAL_ROLE.fieldApiName) {
        return new VirtualRoleFieldController(meta, this, fieldDescribe, record);
      }
    }
    return super.initItemController(meta, record);
  }

  /**
   * EM Team Member has special delete logic, requiring different processing than saving with a Deleted flag
   */
  doSave(data) {
    return data.Deleted === 'true' ? this.deleteTeamMember(data) : super.doSave(data);
  }

  async deleteTeamMember(data) {
    let result = {};
    try {
      result = await this.dataSvc.delete(data.type, data.Id);
    } catch (error) {
      const erroredResult = VeevaUtils.getConvertedToSaveErrorFormat(error);
      result = Promise.reject(erroredResult);
    }
    return result;
  }

  processLayout(layout) {
    this.teamMemberTypeOnLayout = this.isTeamMemberTypeOnLayout(layout);
    return super.processLayout(layout);
  }

  isTeamMemberTypeOnLayout(layout) {
    for (const section of layout?.sections ?? []) {
      for (const row of section.layoutRows ?? []) {
        for (const item of row.layoutItems ?? []) {
          if (item.field === TEAM_MEMBER_TYPE.fieldApiName) {
            return true;
          }
        }
      }
    }
    return false;
  }

  isItemToHide(item) {
    return (
      (this.teamMemberTypeOnLayout && ((item.field === NAME.fieldApiName && this.page.action !== 'View') || HIDDEN_FIELDS.includes(item.field))) ||
      super.isItemToHide(item)
    );
  }
}