import { LightningElement, api } from 'lwc';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

const USER_VOD = 'User_vod';
const GROUP_VOD = 'Group_vod';
const WRITE_IN_VOD = 'Write_In_vod';

export default class DynamicTeamMemberTypeField extends VeevaErrorHandlerMixin(LightningElement) {
  @api ctrl;
  @api recordUpdateFlag;
  @api showUndo;

  selectedOption;

  currentElementSelector = `c-dynamic-team-member-type-field`;
  validityElementsSelector = '[data-validity]';

  get isUser() {
    return this.selectedOption === USER_VOD;
  }

  get isGroup() {
    return this.selectedOption === GROUP_VOD;
  }

  get isWriteIn() {
    return this.selectedOption === WRITE_IN_VOD;
  }

  get teamMemberFieldKey() {
    return this.ctrl.teamMemberMeta.field;
  }

  get groupNameFieldKey() {
    return this.ctrl.groupNameMeta.field;
  }

  get firstNameFieldKey() {
    return this.ctrl.firstNameMeta.field;
  }

  get lastNameFieldKey() {
    return this.ctrl.lastNameMeta.field;
  }

  get virtualRoleFieldKey() {
    return this.ctrl.virtualRoleMeta?.field;
  }

  connectedCallback() {
    this.selectedOption = this.ctrl?.selected;
    this.ctrl?.pageCtrl.track(this.ctrl.fieldApiName, this, 'updateSelected');
  }

  updateSelected(value) {
    this.ctrl?.clearFields();
    this.selectedOption = value;
  }

  handleFieldChange() {
    const fieldChangeEvent = new CustomEvent('fieldchange');
    this.dispatchEvent(fieldChangeEvent);
  }

  handleUndoClick() {
    const undoClickEvent = new CustomEvent('undoclick');
    this.dispatchEvent(undoClickEvent);
  }
}