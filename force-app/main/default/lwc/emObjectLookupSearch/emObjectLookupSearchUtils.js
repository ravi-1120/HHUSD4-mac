import EmEventConstant from 'c/emEventConstant';
import EVENT from '@salesforce/schema/EM_Event_vod__c';
import ACCOUNT from '@salesforce/schema/EM_Event_vod__c.Account_vod__c';
import ADDRESS from '@salesforce/schema/Address_vod__c';
import EVENT_BUDGET from '@salesforce/schema/EM_Event_Budget_vod__c';
import EXPENSE_LINE from '@salesforce/schema/Expense_Line_vod__c';
import EXPENSE_HEADER from '@salesforce/schema/Expense_Header_vod__c';
import EXPENSE_ESTIMATE from '@salesforce/schema/EM_Expense_Estimate_vod__c';
import EVENT_ACTION from '@salesforce/schema/EM_Event_Action_vod__c';
import EVENT_LAYOUT from '@salesforce/schema/EM_Event_Layout_vod__c';
import EVENT_RULE from '@salesforce/schema/EM_Event_Rule_vod__c';
import SPEAKER_QUALIFICATION from '@salesforce/schema/EM_Speaker_Qualification_vod__c';
import EVENT_SESSION_ATTENDEE from '@salesforce/schema/EM_Event_Session_Attendee_vod__c';
import EVENT_SESSION from '@salesforce/schema/EM_Event_Session_Attendee_vod__c.Event_Session_vod__c';
import EM_ATTENDEE from '@salesforce/schema/EM_Attendee_vod__c';
import CHILD_ACCOUNT from '@salesforce/schema/EM_Attendee_vod__c.Child_Account_vod__c';

const getLookupRequiredId = (referenceFrom, fieldName) => {
  let requiredId = 'Id';
  switch (referenceFrom) {
    case EVENT.objectApiName:
      requiredId = fieldName === ADDRESS.fieldApiName ? ACCOUNT.fieldApiName : 'Id';
      break;
    case EVENT_BUDGET.objectApiName:
    case EXPENSE_LINE.objectApiName:
    case EXPENSE_HEADER.objectApiName:
    case EXPENSE_ESTIMATE.objectApiName:
      requiredId = EmEventConstant.EVENT;
      break;
    case EVENT_ACTION.objectApiName:
    case EVENT_LAYOUT.objectApiName:
    case EVENT_RULE.objectApiName:
      requiredId = EmEventConstant.EVENT_CONFIG;
      break;
    case SPEAKER_QUALIFICATION.objectApiName:
      requiredId = 'RecordTypeId';
      break;
    case EVENT_SESSION_ATTENDEE.objectApiName:
      requiredId = EVENT_SESSION.fieldApiName;
      break;
    case EM_ATTENDEE.objectApiName:
      requiredId = fieldName === CHILD_ACCOUNT.fieldApiName ? ACCOUNT.fieldApiName : 'Id';
      break;
    default:
      break;
  }
  return requiredId;
};

export default getLookupRequiredId;