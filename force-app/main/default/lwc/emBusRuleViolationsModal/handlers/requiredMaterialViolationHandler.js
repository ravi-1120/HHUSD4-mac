import { BusRuleConstant } from 'c/emBusRuleUtils';

import EVENT_MATERIAL from '@salesforce/schema/EM_Event_Material_vod__c';
import MATERIAL_NAME from '@salesforce/schema/EM_Event_Material_vod__c.Name_vod__c';

import BaseViolationHandler from './baseViolationHandler';

export default class RequiredMaterialViolationHandler extends BaseViolationHandler {
  get objectApiName() {
    return EVENT_MATERIAL.objectApiName;
  }

  get nameField() {
    return MATERIAL_NAME.fieldApiName;
  }

  get header() {
    return this.isHardWarningScreen
      ? this.messages.EM_RULE_REQUIRED_EVENT_MATERIAL_HARD_WARNING_TITLE
      : this.messages.EM_RULE_REQUIRED_EVENT_MATERIAL_SOFT_WARNING_TITLE;
  }

  get subheader() {
    return this.isHardWarningScreen
      ? this.messages.EM_RULE_REQUIRED_EVENT_MATERIAL_HARD_WARNING_SUBTITLE
      : this.messages.EM_RULE_REQUIRED_EVENT_MATERIAL_SOFT_WARNING_SUBTITLE;
  }

  processEventOverrides(overrides) {
    const overridesWithComments = overrides.filter(override => override.Comment_Box_vod__c !== BusRuleConstant.COMMENT_TYPE.HIDDEN);
    return super.processEventOverrides(overridesWithComments);
  }
}