import INCURRED_EXPENSE_ACCOUNT from '@salesforce/schema/Expense_Header_vod__c.Incurred_Expense_Account_vod__c';
import INCURRED_EXPENSE_ATTENDEE from '@salesforce/schema/Expense_Header_vod__c.Incurred_Expense_Attendee_vod__c';
import INCURRED_EXPENSE_SPEAKER from '@salesforce/schema/Expense_Header_vod__c.Incurred_Expense_Speaker_vod__c';
import INCURRED_EXPENSE_TEAM_MEMBER from '@salesforce/schema/Expense_Header_vod__c.Incurred_Expense_Team_Member_vod__c';
import INCURRED_EXPENSE_VENDOR from '@salesforce/schema/Expense_Header_vod__c.Incurred_Expense_Vendor_vod__c';
import INCURRED_EXPENSE_VENUE from '@salesforce/schema/Expense_Header_vod__c.Incurred_Expense_Venue_vod__c';

import PAYEE_ACCOUNT from '@salesforce/schema/Expense_Header_vod__c.Payee_Account_vod__c';
import PAYEE_ATTENDEE from '@salesforce/schema/Expense_Header_vod__c.Payee_Attendee_vod__c';
import PAYEE_SPEAKER from '@salesforce/schema/Expense_Header_vod__c.Payee_Speaker_vod__c';
import PAYEE_TEAM_MEMBER from '@salesforce/schema/Expense_Header_vod__c.Payee_Team_Member_vod__c';
import PAYEE_VENDOR from '@salesforce/schema/Expense_Header_vod__c.Payee_Vendor_vod__c';
import PAYEE_VENUE from '@salesforce/schema/Expense_Header_vod__c.Payee_Venue_vod__c';

const incurredExpenseReferenceFields = [
  INCURRED_EXPENSE_ACCOUNT.fieldApiName,
  INCURRED_EXPENSE_ATTENDEE.fieldApiName,
  INCURRED_EXPENSE_SPEAKER.fieldApiName,
  INCURRED_EXPENSE_TEAM_MEMBER.fieldApiName,
  INCURRED_EXPENSE_VENDOR.fieldApiName,
  INCURRED_EXPENSE_VENUE.fieldApiName,
];

const incurredExpenseFieldToType = {
  [INCURRED_EXPENSE_ACCOUNT.fieldApiName]: 'Account_vod',
  [INCURRED_EXPENSE_ATTENDEE.fieldApiName]: 'Attendee_vod',
  [INCURRED_EXPENSE_SPEAKER.fieldApiName]: 'Event_Speaker_vod',
  [INCURRED_EXPENSE_TEAM_MEMBER.fieldApiName]: 'Event_Team_Member_vod',
  [INCURRED_EXPENSE_VENDOR.fieldApiName]: 'Vendor_vod',
  [INCURRED_EXPENSE_VENUE.fieldApiName]: 'Venue_vod',
};

const payeeReferenceFields = [
  PAYEE_ACCOUNT.fieldApiName,
  PAYEE_ATTENDEE.fieldApiName,
  PAYEE_SPEAKER.fieldApiName,
  PAYEE_TEAM_MEMBER.fieldApiName,
  PAYEE_VENDOR.fieldApiName,
  PAYEE_VENUE.fieldApiName,
];

export { incurredExpenseReferenceFields, incurredExpenseFieldToType, payeeReferenceFields };