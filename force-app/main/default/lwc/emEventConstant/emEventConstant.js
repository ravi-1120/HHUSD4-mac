// Used in Parent Record Refresh whenever Expense Header is saved
import EVENT_BUDGET_ESTIMATE from '@salesforce/schema/EM_Event_Budget_vod__c.Estimate_vod__c';
import EVENT_BUDGET_COMMITTED from '@salesforce/schema/EM_Event_Budget_vod__c.Committed_vod__c';
import EVENT_BUDGET_ACTUAL from '@salesforce/schema/EM_Event_Budget_vod__c.Actual_vod__c';
import EVENT_ACTUAL_COST from '@salesforce/schema/EM_Event_vod__c.Actual_Cost_vod__c';
import EVENT_COMMITTED_COST from '@salesforce/schema/EM_Event_vod__c.Committed_Cost_vod__c';
import EXPENSE_ESTIMATE_ACTUAL from '@salesforce/schema/EM_Expense_Estimate_vod__c.Actual_vod__c';
import EXPENSE_ESTIMATE_COMMITTED from '@salesforce/schema/EM_Expense_Estimate_vod__c.Committed_vod__c';

export default class EmEventConstant {
  static ZVOD_EVENT_LAYOUT = 'zvod_Event_Layout_vod__c';
  static ZVOD_START_TIME = 'zvod_Start_Time_vod__c';
  static ZVOD_END_TIME = 'zvod_End_Time_vod__c';
  static ZVOD_ZOOM_JOIN_TOKEN = 'zvod_Zoom_Join_Token_vod__c';
  static START_TIME_LOCAL = 'Start_Time_Local_vod__c';
  static END_TIME_LOCAL = 'End_Time_Local_vod__c';
  static START_DATE = 'Start_Date_vod__c';
  static END_DATE = 'End_Date_vod__c';
  static START_TIME = 'Start_Time_vod__c';
  static END_TIME = 'End_Time_vod__c';
  static TIME_ZONE = 'Time_Zone_vod__c';
  static COUNTRY = 'Country_vod__c';
  static COUNTRY_LOOKUP = 'Country_vod__r';
  static COUNTRY_NAME = 'Country_Name_vod__c';
  static EVENT_CONFIG = 'Event_Configuration_vod__c';
  static WEBINAR_STATUS = 'Webinar_Status_vod__c';
  static DISPLAY_EVENT_ACTION_DIALOG = 'displayEventActionDialog';
  static HANDLE_EVENT_ACTION_DIALOG = 'handleEventActionDialog';
  static POPULATE_RELATED_LIST_TABS = 'populateRelatedListTabs';
  static DISPLAY_PRINT_TEMPLATE_DIALOG = 'displayPrintTemplateDialog';
  static DISPLAY_LOCAL_TIME_FIELDS = 'displayLocalTimeFields';
  static APPROVER_ID = 'approverId';
  static PLE_SUPPORTED_OBJECTS = [
    'EM_Attendee_vod__c',
    'EM_Event_Budget_vod__c',
    'EM_Event_Material_vod__c',
    'EM_Event_Session_Attendee_vod__c',
    'EM_Event_Session_vod__c',
    'EM_Event_Speaker_vod__c',
    'EM_Event_Team_Member_vod__c',
    'EM_Event_vod__c',
    'EM_Expense_Estimate_vod__c',
    'Expense_Header_vod__c',
    'Expense_Line_vod__c',
  ];
  static EVENT = 'Event_vod__c';
  static ATTENDEE_SELCTION_SOQL_LIMIT = 5000;

  static ATTENDEE_RECONCILIATION = 'attendeeReconciliation';
  static SPEAKER_SELECTION = 'speakerSelection';
  static REFRESH_RELATED_LIST = 'refreshRelatedList';
  static REFRESH_RELATED_LISTS = 'refreshRelatedLists';
  static REFRESH_PARENT_RECORD = 'refreshParentRecord';
  static EXPENSE_LINE_SECTION_UPDATE_FLAG = 'expenseLineSectionUpdateFlag';
  static EXPENSE_HEADER_CURRENCY_CHANGED = 'expenseHeaderCurrencyChanged';
  static EXPENSE_SPLIT_AMOUNT_CHANGED = 'expenseSplitAmountChanged';

  // Fields parent records poll to determine async job completion
  static FIELDS_EXPENSE_LINES_UPDATE_ASYNC = [
    EVENT_BUDGET_ACTUAL.fieldApiName,
    EVENT_BUDGET_COMMITTED.fieldApiName,
    EVENT_BUDGET_ESTIMATE.fieldApiName,
    EVENT_ACTUAL_COST.fieldApiName,
    EVENT_COMMITTED_COST.fieldApiName,
    EXPENSE_ESTIMATE_ACTUAL.fieldApiName,
    EXPENSE_ESTIMATE_COMMITTED.fieldApiName,
  ];

  // mapping of fields on EM_Venue_vod__c to EM_Event_vod__c
  static VENUE_FIELD_TO_EVENT_FIELD_MAP = {
    Name: 'Location_vod__c',
    Address_vod__c: 'Location_Address_vod__c',
    Address_Line_2_vod__c: 'Location_Address_Line_2_vod__c',
    City_vod__c: 'City_vod__c',
    State_Province_vod__c: 'State_Province_vod__c',
    Postal_Code_vod__c: 'Postal_Code_vod__c',
  };

  /**
   * Map of Name fields to show for objects with auto-numbered or ambiguous default names
   */
  static OBJECT_TO_NAME_FIELD = {
    EM_Catalog_vod__c: 'Name_vod__c',
    EM_Attendee_vod__c: 'Attendee_Name_vod__c',
    EM_Event_Budget_vod__c: 'Budget_Name_vod__c',
    EM_Event_Speaker_vod__c: 'Speaker_Name_vod__c',
    EM_Expense_Estimate_vod__c: 'Expense_Type_Name_vod__c',
    Country_vod__c: 'Country_Name_vod__c',
  };

  // Relationship names for notes and attachments related list and files related list
  static NOTES_ATTACHMENTS_FILES_RELATIONSHIP_NAMES = ['RelatedNoteList', 'CombinedAttachments', 'RelatedFileList', 'AttachedContentDocuments'];

  static REGISTRATION_FORM_ASSIGNMENT_FIELDS = ['Product_vod__c', 'Location_Type_vod__c', 'Event_Format_vod__c', 'Registration_Form_vod__c'];
}