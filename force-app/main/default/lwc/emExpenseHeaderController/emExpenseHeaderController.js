import EmBusRuleWarningsModal from 'c/emBusRuleWarningsModal';
import EmController from 'c/emController';
import EmEventConstant from 'c/emEventConstant';
import EmExpenseLineSectionController from 'c/emExpenseLineSectionController';
import EmInlineFileSectionController from 'c/emInlineFileSectionController';
import EmInlineFilesRelatedListController from 'c/emInlineFilesRelatedListController';
import EmSplitExpenseLineSectionController from 'c/emSplitExpenseLineSectionController';
import EmParticipantsSectionController from 'c/emParticipantsSectionController';
import VeevaConstant from 'c/veevaConstant';
import VeevaToastEvent from 'c/veevaToastEvent';
import VeevaUtils from 'c/veevaUtils';
import { BusRuleConstant } from 'c/emBusRuleUtils';
import { isStatusSendingOrSubmitted } from 'c/emSubmitToConcurErrorHandling';
import EmConcurService from 'c/emConcurService';
import EmExpenseConstant from 'c/emExpenseConstant';
import INCURRED_EXPENSE from '@salesforce/schema/Expense_Header_vod__c.Incurred_Expense_vod__c';
import PAYEE from '@salesforce/schema/Expense_Header_vod__c.Payee_vod__c';
import EVENT from '@salesforce/schema/Expense_Header_vod__c.Event_vod__c';
import SPLIT_LINES from '@salesforce/schema/Expense_Header_vod__c.Split_Lines_vod__c';
import EXPENSE_LINE from '@salesforce/schema/Expense_Line_vod__c';
import ACTUAL from '@salesforce/schema/Expense_Line_vod__c.Actual_vod__c';
import EXPENSE_ATTRIBUTION from '@salesforce/schema/Expense_Attribution_vod__c';
import INCURRED_EXPENSE_TYPE from '@salesforce/schema/Expense_Attribution_vod__c.Incurred_Expense_Type_vod__c';
import getExpenseLines from '@salesforce/apex/EmExpensesController.getExpenseLines';
import getExpenseLineRecordTypeId from '@salesforce/apex/EmExpensesController.getExpenseLineRecordTypeId';
import isSystemAdmin from '@salesforce/apex/EmExpensesController.isSystemAdmin';
import USER_ID from '@salesforce/user/Id';
import { createMessageContext, publish } from 'lightning/messageService';
import LightningConfirm from 'lightning/confirm';
import LightningAlert from 'lightning/alert';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';
import { incurredExpenseReferenceFields, incurredExpenseFieldToType, payeeReferenceFields } from './expenseHeaderBundledFields';
import ExpenseLineDataSvc from './expenseLineDataSvc';
import ExpenseHeaderMultiLookupController from './expenseHeaderMultiLookupController';
import ExpenseRecord from './expenseRecord';
import ConcurSubmissionStatusController from './concurSubmissionStatusController';
import SplitExpenseHandler from './handlers/splitExpenseHandler';
import PaymentHandler from './handlers/paymentHandler';

export default class EmExpenseHeaderController extends EmController {
  #handler;

  constructor(dataSvc, userInterface, messageSvc, metaStore, emPageLayoutEngineSvc) {
    super(dataSvc, userInterface, messageSvc, metaStore, emPageLayoutEngineSvc);
    this.expenseLineDataSvc = new ExpenseLineDataSvc(this.dataSvc);
    this.concurSvc = new EmConcurService(this.dataSvc, this.uiApi);
  }

  get headerCurrency() {
    return this.record?.rawValue(VeevaConstant.FLD_CURRENCY_ISO_CODE);
  }

  get isSplitExpense() {
    return this.#handler instanceof SplitExpenseHandler;
  }

  toVeevaRecord(value) {
    return value instanceof ExpenseRecord ? value : new ExpenseRecord(value);
  }

  getRelatedListsToDisplay(relatedLists) {
    const rlsToDisplay = super.getRelatedListsToDisplay(relatedLists);
    return rlsToDisplay.filter(rl => rl.objectApiName !== EXPENSE_LINE.objectApiName);
  }

  async processLayout(layout) {
    const processedLayout = await super.processLayout(layout);
    if (processedLayout.sections) {
      await Promise.all([this.loadRelatedObjectInfos(), this.loadPluralLabels()]);
      if (this.expenseLineInfo) {
        const recordType = this.expenseLineRecordType ?? this.expenseLineInfo.defaultRecordTypeId;
        this.expenseLineCreateDefaults = this.uiApi.getCreateDefaults(EXPENSE_LINE.objectApiName, recordType);
        await this.getExpenseLines();
      }
      if (this.record.rawValue(SPLIT_LINES.fieldApiName) === 'Yes_vod' && this.expenseLines?.length <= 1) {
        this.#handler = new SplitExpenseHandler(this);
      } else {
        this.#handler = new PaymentHandler(this);
      }
      await this.#handler.processLayout(processedLayout);
      if (this.action !== 'View') {
        if (this.isFieldOnLayout(INCURRED_EXPENSE.fieldApiName)) {
          const incurredExpenseLookupMeta = this.createMultiObjectLookupMeta(incurredExpenseReferenceFields);
          this.incurredExpenseObjectList = incurredExpenseLookupMeta.objectList;
          this.incurredExpenseInitialValue = incurredExpenseLookupMeta.initialValue;
        }
        if (this.isFieldOnLayout(PAYEE.fieldApiName)) {
          const payeeLookupMeta = this.createMultiObjectLookupMeta(payeeReferenceFields);
          this.payeeObjectList = payeeLookupMeta.objectList;
          this.payeeInitialValue = payeeLookupMeta.initialValue;
        }
        if (processedLayout.relatedLists?.some(rl => EmEventConstant.NOTES_ATTACHMENTS_FILES_RELATIONSHIP_NAMES.includes(rl.relationship))) {
          const fileMessage = await this.getMessageWithDefault('FILES', 'Lightning', 'Files');
          processedLayout.sections.push({
            heading: fileMessage,
            rawHeading: fileMessage,
            fileSection: true,
            key: `${processedLayout.sections.length}`,
            layoutRows: [],
          });
        }
      }
    }
    return processedLayout;
  }

  async loadMetadata() {
    [this.isUserSystemAdmin] = await Promise.all([isSystemAdmin(), this.populateConcurMessageMap(), super.loadMetadata()]);
  }

  isItemToHide(item) {
    return incurredExpenseReferenceFields.includes(item.field) || payeeReferenceFields.includes(item.field) || super.isItemToHide(item);
  }

  shouldKeepDefaultField(fieldApiName) {
    return (
      fieldApiName === EmExpenseConstant.CONCUR_STATUS || fieldApiName === SPLIT_LINES.fieldApiName || super.shouldKeepDefaultField(fieldApiName)
    );
  }

  async populateConcurMessageMap() {
    this.concurMessageMap = await this.messageSvc
      .createMessageRequest()
      .addRequest('RESUBMIT_TO_CONCUR', 'Concur', EmExpenseConstant.RESUBMIT_BUTTON_DEFAULT, 'resubmitToConcurMessage')
      .addRequest('CONCUR_SUBMIT_CONFIRM', 'Concur', EmExpenseConstant.CONCUR_SUBMIT_CONFIRM_DEFAULT, 'concurSubmitConfirm')
      .addRequest('CONCUR_ADMIN_POST', 'Concur', EmExpenseConstant.CONCUR_ADMIN_POST_DEFAULT, 'concurAdminPost')
      .addRequest('CONCUR_USER_POST_ERROR', 'Concur', EmExpenseConstant.CONCUR_USER_POST_ERROR_DEFAULT, 'concurUserPostError')
      .addRequest(
        'CONCUR_TRANSACTION_DATE_REQUIRED',
        'Concur',
        EmExpenseConstant.CONCUR_TRANSACTION_DATE_ERROR_DEFAULT,
        'concurTransactionDateRequired'
      )
      .addRequest('CONCUR_ALREADY_SENT_VIEW', 'Concur', EmExpenseConstant.CONCUR_ALREADY_SENT_DEFAULT, 'concurAlreadySent')
      .addRequest('CONCUR_SUBMIT_ACTUAL_REQUIRED', 'Concur', EmExpenseConstant.CONCUR_SUBMIT_ACTUAL_DEFAULT, 'concurSubmitActualRequired')
      .sendRequest();

    Object.entries(this.concurMessageMap).forEach(([key, message]) => {
      this[key] = message;
    });
  }

  getSectionController(meta) {
    if (meta.expenseLineSection) {
      return new EmExpenseLineSectionController(meta, this).initTemplate();
    }
    if (meta.fileSection) {
      return new EmInlineFileSectionController(meta, this).initTemplate();
    }
    if (meta.splitExpenseLineSection) {
      return new EmSplitExpenseLineSectionController(meta, this).initTemplate();
    }
    if (meta.participantsSection) {
      return new EmParticipantsSectionController(meta, this).initTemplate();
    }
    return super.getSectionController(meta, this);
  }

  getRelatedListController(meta, pageCtrl) {
    if ((this.page.action === 'New' || this.page.action === 'Edit') && meta.relationship === 'CombinedAttachments') {
      return new EmInlineFilesRelatedListController(meta, pageCtrl);
    }
    return super.getRelatedListController(meta, pageCtrl);
  }

  initItemController(meta, record) {
    const { field } = meta;
    if (field) {
      const fieldDescribe = this.objectInfo.getFieldInfo(field);
      if (this.action !== 'View' && (field === INCURRED_EXPENSE.fieldApiName || field === PAYEE.fieldApiName)) {
        const objectList = field === PAYEE.fieldApiName ? this.payeeObjectList : this.incurredExpenseObjectList;
        const multiObjectLookupMeta = { ...meta, objectList: this.setDefaultObjectListOption(objectList) };
        return new ExpenseHeaderMultiLookupController(multiObjectLookupMeta, this, fieldDescribe, record);
      }
      if (field === EmExpenseConstant.CONCUR_STATUS) {
        const itemController = new ConcurSubmissionStatusController(meta, this, fieldDescribe, record);
        itemController.editable = meta.editable && this.isUserSystemAdmin;
        return itemController;
      }
    }
    return super.initItemController(meta, record);
  }

  initTemplate(ctrl) {
    if (ctrl.fieldApiName === SPLIT_LINES.fieldApiName || (this.isSplitExpense && ctrl.fieldApiName === INCURRED_EXPENSE.fieldApiName)) {
      ctrl.editable = false;
    }
    if (this.page.action !== 'View' && ctrl.fieldApiName === VeevaConstant.FLD_CURRENCY_ISO_CODE) {
      ctrl.required = true;
    }
    return super.initTemplate(ctrl);
  }

  setFieldValue(field, value, reference, record, source) {
    if (field.apiName === INCURRED_EXPENSE.fieldApiName || field.apiName === PAYEE.fieldApiName) {
      this.updateMultiObjectLookup(field, value, reference, record, source);
    } else if (field.apiName === VeevaConstant.FLD_CURRENCY_ISO_CODE) {
      super.setFieldValue(field, value, reference, record, source);
      if (this.isSplitExpense) {
        this.updateExpenseLineCurrency();
      }
      this.publishCurrencyChangedMessage(value);
    } else {
      super.setFieldValue(field, value, reference, record, source);
    }
  }

  async save(value) {
    let response;
    if (await this.isExpenseSubmittedToConcur()) {
      this.isPopupAlreadyShown = true;
      const confirm = await this.showConcurAlreadySentConfirmPopup();
      if (confirm) {
        return {};
      }
      throw new Error();
    }
    if (value?.submit) {
      response = await this.submitToConcurEdit(value);
    } else {
      response = await super.save(value);
    }
    this.refreshParent();
    return response;
  }

  async doSave(data) {
    if (data.Deleted) {
      return super.doSave(data);
    }

    data.checkExpenseRules = true;
    data.checkSpeakerRules = true;
    data.platform = 'Online';
    let response = await super.doSave(data);
    if (response?.data && !response.data.Id) {
      // business rule potential warnings
      // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
      const modalResult = await EmBusRuleWarningsModal.open({
        warnings: response.data,
        type: BusRuleConstant.RULE_TYPE.EXPENSE_LIMIT,
        label: await this.getMessageWithDefault(
          'EM_RULE_POTENTIAL_EXPENSE_WARNING_TITLE',
          'EVENT_MANAGEMENT',
          'The Following Expense(s) have Potential Rule Violations'
        ),
        size: 'medium',
      });
      if (!modalResult?.success) {
        // cancel expense header save process
        throw new Error();
      }
      // attempt save again without business rules
      data.checkExpenseRules = false;
      data.checkSpeakerRules = false;
      response = await this.dataSvc.save(data);
    }
    return response;
  }

  /**
   * Refreshes Parent records
   */
  refreshParent() {
    if (this.record.rawValue(EVENT.fieldApiName)) {
      this.refreshParentRecordUi(true, this.record.rawValue(EVENT.fieldApiName), EmEventConstant.FIELDS_EXPENSE_LINES_UPDATE_ASYNC);
    }
  }

  getChanges() {
    const changes = super.getChanges();
    const splitLines = this.record.rawValue(SPLIT_LINES.fieldApiName) === 'Yes_vod';
    const hasAttr = !!this.expenseAttrInfo;
    if (this.expenseLines) {
      changes.Expense_Lines_vod__r = this.expenseLines.map(line => {
        const lineChanges = line.record.getChanges(line.pageCtrl.objectInfo);
        if (hasAttr) {
          const attributions = this.getAttributionsForLine(line, this.record, splitLines);
          if (attributions.length) {
            lineChanges.Expense_Attributions_vod__r = attributions;
            lineChanges.type = EXPENSE_LINE.objectApiName;
            if (VeevaUtils.validSfdcId(line.id)) {
              lineChanges.Id = line.id;
            }
          }
        }
        return lineChanges;
      });
      const sendLinesToCrm = changes.Expense_Lines_vod__r.some(line => Object.keys(line).length > 0);
      if (sendLinesToCrm) {
        changes.type = this.objectApiName;
        if (VeevaUtils.validSfdcId(this.id)) {
          changes.Id = this.id;
        }
      }
    }
    return changes;
  }

  getAttributionsForLine(line, headerRecord, splitLines) {
    const attributions = splitLines ? line.attributions : this.getAttributionsForNonSplitLine(line, headerRecord);
    return this.processAttributionsForSave(attributions);
  }

  getAttributionsForNonSplitLine(line, headerRecord) {
    const attr = line.attributions[0] ?? {};
    const populatedField = incurredExpenseReferenceFields.find(field => headerRecord.rawValue(field));
    let saveAttr = true;
    if (populatedField) {
      const copyFields = [...incurredExpenseReferenceFields, INCURRED_EXPENSE.fieldApiName];
      copyFields.forEach(field => {
        attr[field] = headerRecord.rawValue(field) ?? null;
      });
      attr[INCURRED_EXPENSE_TYPE.fieldApiName] = incurredExpenseFieldToType[populatedField];
    } else if (attr.Id) {
      attr.Deleted = true;
    } else {
      saveAttr = false;
    }

    const attributions = [];
    if (saveAttr) {
      attributions.push(attr);
    }
    return attributions;
  }

  processAttributionsForSave(attributions) {
    const incurredExpenseFields = [...incurredExpenseReferenceFields, INCURRED_EXPENSE.fieldApiName, INCURRED_EXPENSE_TYPE.fieldApiName];
    const allowedFields = ['Id', 'Deleted', ...incurredExpenseFields.filter(field => this.expenseAttrInfo.fields[field]?.updateable)];
    return attributions.map(attribution => {
      const processedAttribution = Object.fromEntries(Object.entries(attribution).filter(([key]) => allowedFields.includes(key)));
      processedAttribution.type = EXPENSE_ATTRIBUTION.objectApiName;
      if (!VeevaUtils.validSfdcId(processedAttribution.Id)) {
        delete processedAttribution.Id;
      }
      return processedAttribution;
    });
  }

  processError(data) {
    super.processError(data);
    this.#handler.processError(data);
  }

  clearErrors() {
    super.clearErrors();
    if (this.expenseLines) {
      this.expenseLines.forEach(line => {
        // eslint-disable-next-line no-param-reassign
        line.rowError = null;
        line.pageCtrl?.clearErrors();
      });
    }
  }

  async processForLDSCache(data) {
    super.processForLDSCache(data);

    if (data.Expense_Lines_vod__r?.length) {
      const expenseLineRecordIds = [];
      data.Expense_Lines_vod__r.forEach(line => {
        if (line.Id) {
          expenseLineRecordIds.push({ recordId: line.Id });
        }
      });
      if (expenseLineRecordIds.length) {
        this.notifyLDSCache(expenseLineRecordIds);
      }
    }
  }

  async getExpenseLines() {
    if (!this.expenseLines) {
      if (this.page.action !== 'New') {
        this.expenseLines = await this.getExistingExpenseLines();
      } else {
        this.expenseLines = [];
      }
    }
    return this.expenseLines;
  }

  async getExistingExpenseLines() {
    const expenseLineRecords = [];
    const expenseLines = await getExpenseLines({ expenseHeaderId: this.recordId });
    expenseLines.forEach(line => {
      const record = new ExpenseRecord({
        apiName: EXPENSE_LINE.objectApiName,
        fields: this.convertToVeevaRecordFieldsFormat(line),
        id: line.Id,
        recordTypeId: line.RecordTypeId,
      });
      expenseLineRecords.push({
        id: record.id,
        record,
        attributions: this.addMetadataToAttributions(line.Expense_Attributions_vod__r ?? []),
      });
    });
    return expenseLineRecords;
  }

  convertToVeevaRecordFieldsFormat(line) {
    const fields = {};
    Object.entries(this.expenseLineInfo.fields).forEach(([fieldName, fieldInfo]) => {
      fields[fieldName] = {
        displayValue: line[`toFormat_${fieldName}`] || line[`toLabel_${fieldName}`] || null,
        value: line[fieldName] !== undefined ? line[fieldName] : null,
      };
      const { relationshipName } = fieldInfo;
      if (relationshipName && line[relationshipName]) {
        fields[relationshipName] = {
          displayValue: line[relationshipName].Name || null,
          value: { fields: Object.fromEntries(Object.entries(line[relationshipName]).map(([field, value]) => [field, { value }])) },
        };
      }
    });
    return fields;
  }

  addMetadataToAttributions(attributions) {
    return attributions.map(attribution => ({
      ...attribution,
      ...this.getAttributionMetadata(attribution),
    }));
  }

  getAttributionMetadata(attribution) {
    const metadata = {};
    switch (attribution.Incurred_Expense_Type_vod__c) {
      case 'Attendee_vod': {
        if (attribution.Incurred_Expense_Attendee_vod__r?.Contact_vod__c) {
          metadata.icon = 'standard:contact';
        } else if (attribution.Incurred_Expense_Attendee_vod__r?.User_vod__c) {
          metadata.icon = 'standard:user';
        } else if (attribution.Incurred_Expense_Attendee_vod__r?.Account_vod__r?.IsPersonAccount === false) {
          metadata.icon = 'standard:account';
        } else {
          metadata.icon = 'standard:person_account';
        }
        metadata.mealOptIn = attribution.Incurred_Expense_Attendee_vod__r?.Meal_Opt_In_vod__c;
        metadata.status = attribution.Incurred_Expense_Attendee_vod__r?.toLabel_Incurred_Expense_Attendee_vod__r_Status_vod__c;
        metadata.participantId = attribution.Incurred_Expense_Attendee_vod__c;
        break;
      }
      case 'Event_Speaker_vod':
        metadata.icon = 'custom:custom84';
        metadata.mealOptIn = attribution.Incurred_Expense_Speaker_vod__r?.Meal_Opt_In_vod__c;
        metadata.status = attribution.Incurred_Expense_Speaker_vod__r?.toLabel_Incurred_Expense_Speaker_vod__r_Status_vod__c;
        metadata.participantId = attribution.Incurred_Expense_Speaker_vod__c;
        break;
      case 'Event_Team_Member_vod':
        metadata.icon = 'standard:user';
        metadata.participantId = attribution.Incurred_Expense_Team_Member_vod__c;
        break;
      case 'Vendor_vod':
        metadata.icon = 'custom:custom16';
        metadata.participantId = attribution.Incurred_Expense_Vendor_vod__c;
        break;
      case 'Venue_vod':
        metadata.icon = 'custom:custom16';
        metadata.participantId = attribution.Incurred_Expense_Venue_vod__c;
        break;
      default:
        metadata.icon = 'standard:default';
    }
    return metadata;
  }

  async createNewExpenseLine() {
    let { record: defaultRecord } = await this.expenseLineCreateDefaults;
    if (!defaultRecord) {
      defaultRecord = {
        apiName: EXPENSE_LINE.objectApiName,
        fields: {},
        recordTypeId: this.expenseLineInfo.defaultRecordTypeId,
      };
    }
    const record = new ExpenseRecord(JSON.parse(JSON.stringify(defaultRecord)));
    const currencyToSet = this.headerCurrency;
    if (currencyToSet) {
      record.setFieldValue(VeevaConstant.FLD_CURRENCY_ISO_CODE, currencyToSet);
    }
    record.assignRandomId();
    const expenseLine = {
      id: record.id,
      record,
      attributions: [],
    };
    this.expenseLines.push(expenseLine);
    return expenseLine;
  }

  async deleteExpenseLine(id) {
    let toast;
    const expenseLine = this.expenseLines.find(x => x.id === id);
    if (!expenseLine) {
      return { success: false };
    }
    if (!expenseLine.record.isNew) {
      try {
        if (await isStatusSendingOrSubmitted(this.concurSvc, id, EXPENSE_LINE.objectApiName)) {
          throw new Error(this.concurAlreadySent);
        }
        const response = await this.expenseLineDataSvc.delete(id);
        if (response.status === 0) {
          toast = await VeevaToastEvent.recordDeleted(this.expenseLineInfo.label, expenseLine.record.name);
          if (this.action === 'View') {
            this.notifyLDSCache([{ recordId: this.id }]);
          }
        } else {
          throw new Error(response);
        }
      } catch (error) {
        toast = VeevaToastEvent.error(error);
        return { success: false, toast };
      }
    }
    this.expenseLines = this.expenseLines.filter(x => x.id !== id);
    return { success: true, toast };
  }

  publishCurrencyChangedMessage(value) {
    const payload = {
      key: EmEventConstant.EXPENSE_HEADER_CURRENCY_CHANGED,
      recordId: this.recordId,
      value,
    };
    publish(createMessageContext(), eventsManagementChannel, payload);
  }

  hasCurrencyDiscrepancy() {
    const targetCurrency = this.headerCurrency;
    return this.expenseLines?.some(line => line.record.rawValue(VeevaConstant.FLD_CURRENCY_ISO_CODE) !== targetCurrency);
  }

  updateExpenseLineCurrency() {
    const currencyToSet = this.headerCurrency;
    this.expenseLines?.forEach(line => {
      line.record.setFieldValue(VeevaConstant.FLD_CURRENCY_ISO_CODE, currencyToSet);
    });
  }

  createMultiObjectLookupMeta(referenceFields) {
    const meta = { objectList: [], initialValue: {} };
    referenceFields.forEach(refField => {
      const refFieldDescribe = this.objectInfo.getFieldInfo(refField);
      const refTo = refFieldDescribe?.referenceToInfos?.[0]?.apiName;
      if (refTo) {
        meta.objectList.push({
          field: refFieldDescribe.apiName,
          value: refTo,
          label: this.pluralLabels?.[refTo] || refFieldDescribe.label,
        });
      }
      if (this.record.rawValue(refField)) {
        meta.initialValue = { apiName: refField, rawValue: this.record.rawValue(refField) };
      }
    });
    return meta;
  }

  setDefaultObjectListOption(objectList) {
    const defaultedObjectList = [...objectList];
    defaultedObjectList.forEach(object => {
      // eslint-disable-next-line no-param-reassign
      object.defaultValue = !!this.record.rawValue(object.field);
    });
    return defaultedObjectList;
  }

  updateMultiObjectLookup(multiObjectLookupField, value, reference, record, source) {
    const objectList = multiObjectLookupField.apiName === PAYEE.fieldApiName ? this.payeeObjectList : this.incurredExpenseObjectList;
    // clear all reference fields
    objectList.forEach(field => {
      const fieldInfo = this.objectInfo.getFieldInfo(field.field);
      super.setFieldValue(fieldInfo, null, null, record, source);
    });

    let valueToSet = value;
    if (source === 'UndoClick') {
      const initialValue = multiObjectLookupField.apiName === PAYEE.fieldApiName ? this.payeeInitialValue : this.incurredExpenseInitialValue;
      if (initialValue.apiName) {
        const fieldInfo = this.objectInfo.getFieldInfo(initialValue.apiName);
        super.setFieldValue(fieldInfo, initialValue.rawValue, null, record, source);
      }
    } else if (value && reference) {
      const fieldToSet = objectList.find(field => field.value === reference.apiName);
      if (fieldToSet) {
        const fieldToSetInfo = this.objectInfo.getFieldInfo(fieldToSet.field);
        super.setFieldValue(fieldToSetInfo, value, reference, record, source);
      }
      valueToSet = reference.name;
    }
    super.setFieldValue(multiObjectLookupField, valueToSet, reference, record, source);
  }

  async loadRelatedObjectInfos() {
    const [objectInfos, expenseLineRT] = await Promise.all([
      this.uiApi.objectInfos([EXPENSE_LINE.objectApiName, EXPENSE_ATTRIBUTION.objectApiName]),
      getExpenseLineRecordTypeId({ expenseHeaderRecordType: this.record.rawValue('RecordType')?.fields?.DeveloperName?.value }),
    ]);
    this.expenseLineInfo = objectInfos[EXPENSE_LINE.objectApiName];
    this.expenseAttrInfo = objectInfos[EXPENSE_ATTRIBUTION.objectApiName];
    this.expenseLineRecordType = expenseLineRT;
  }

  async loadPluralLabels() {
    const pluralLabelsMsg = await this.getMessageWithDefault(
      'EXPENSE_OBJECT_LABELS',
      'EVENT_MANAGEMENT',
      'Accounts;;Event Speakers;;Attendees;;Venues;;Vendors;;Event Team Members'
    );
    const pluralLabelsSplit = pluralLabelsMsg.split(';;');
    if (pluralLabelsSplit.length === 6) {
      this.pluralLabels = {
        Account: pluralLabelsSplit[0],
        EM_Event_Speaker_vod__c: pluralLabelsSplit[1],
        EM_Attendee_vod__c: pluralLabelsSplit[2],
        EM_Venue_vod__c: pluralLabelsSplit[3],
        EM_Vendor_vod__c: pluralLabelsSplit[4],
        EM_Event_Team_Member_vod__c: pluralLabelsSplit[5],
      };
    }
  }

  async validateConcurSubmission() {
    const errors = [];
    if (!this.hasTransactionDate()) {
      errors.push(this.concurTransactionDateRequired);
    }
    if (await this.hasBlankExpenseLineActual()) {
      errors.push(this.concurSubmitActualRequired);
    }
    if (!this.userCanPostToConcur) {
      errors.push(this.concurUserPostError);
    }
    return errors;
  }

  async submitToConcurEdit(value) {
    let response;
    let confirm = false;
    const errors = await this.validateConcurSubmission();
    if (errors.length > 0) {
      errors.forEach(error => this.addRecordError(error));
    } else {
      confirm = await this.getSubmitToConcurConfirmPopup();
    }
    if (confirm) {
      response = await super.save(value);
      const recordId = this.record.isNew ? response.Id : this.recordId;
      await this.concurSvc.submitToConcur(recordId);
    } else {
      throw new Error();
    }
    return response;
  }

  get userCanPostToConcur() {
    return this.isUserExpenseOwner() || this.isUserSystemAdmin;
  }

  getHeaderButtons() {
    let buttons = this.page.layout.buttons || [];
    if (EmExpenseConstant.HIDE_BUTTONS_CONCUR_STATUSES.includes(this.getConcurStatus())) {
      buttons = [];
      return buttons;
    }
    const concurButtonIndex = this.getSubmitToConcurOnPageLayoutIndex();
    if (concurButtonIndex && concurButtonIndex > -1) {
      if (this.isConcurStatusCanceled()) {
        buttons.splice(concurButtonIndex, 1);
      } else if (this.showResubmitToConcur()) {
        buttons[concurButtonIndex].label = this.resubmitToConcurMessage;
      }
    }
    return buttons;
  }

  setSubmit(data) {
    if (data && !data.Deleted) {
      if (VeevaUtils.isEmptyObject(data) && !this.record.isNew) {
        data.Id = this.record.id;
        data.type = this.record.apiName;
      }
    }
  }

  isUserExpenseOwner() {
    return USER_ID === this.record?.fields[EmExpenseConstant.OWNER_ID]?.value;
  }

  showStandardConcurConfirmationPopup(adminConfirmPopupShown) {
    return this.recordErrors.length < 1 && !adminConfirmPopupShown;
  }

  async getModalButtons() {
    let modalButtons;
    if (this.action === 'Edit') {
      modalButtons = await Promise.all([this.createCancelButton(), this.createSaveButton()]);
    } else {
      modalButtons = await super.getModalButtons();
    }
    const concurButtonIndex = this.getSubmitToConcurOnPageLayoutIndex();
    if (concurButtonIndex && concurButtonIndex > -1) {
      if (this.showSubmitToConcur()) {
        modalButtons.push(await this.createConcurModalButton('SUBMIT_TO_CONCUR', 'Submit to Concur'));
      } else if (this.showResubmitToConcur()) {
        modalButtons.push(await this.createConcurModalButton('RESUBMIT_TO_CONCUR', 'Resubmit to Concur'));
        modalButtons = modalButtons.filter(button => button.name !== 'submitAndNew');
      }
    }
    return modalButtons;
  }

  getSubmitToConcurOnPageLayoutIndex() {
    return this?.page?.layout?.buttons?.findIndex(button => button.name === EmExpenseConstant.CONCUR_BUTTON);
  }

  async getSubmitToConcurConfirmPopup() {
    let message = this.concurSubmitConfirm;
    if (!this.isUserExpenseOwner() && this.isUserSystemAdmin) {
      message = `${this.concurAdminPost} ${this.concurSubmitConfirm}`;
      const ownerName = this.record?.fields?.[EmExpenseConstant.OWNER]?.displayValue;
      if (message.includes('{0}') && ownerName) {
        message = message.replace('{0}', ownerName);
      }
    }
    // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
    return LightningConfirm.open({
      message,
      variant: 'headerless',
    });
  }

  async isExpenseSubmittedToConcur() {
    return this.getSubmitToConcurOnPageLayoutIndex() > -1 && isStatusSendingOrSubmitted(this.concurSvc, this.record.id);
  }

  async showConcurAlreadySentConfirmPopup() {
    // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
    return LightningConfirm.open({
      message: this.concurAlreadySent,
      variant: 'headerless',
    });
  }

  async showConcurAlreadySentAlertPopup() {
    // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
    return LightningAlert.open({
      message: this.concurAlreadySent,
      variant: 'headerless',
    });
  }

  hasTransactionDate() {
    return this.record?.fields?.[EmExpenseConstant.TRANSACTION_DATE]?.value;
  }

  async hasBlankExpenseLineActual() {
    const expenseLines = await this.getExpenseLines();
    return (
      expenseLines.length === 0 ||
      expenseLines.filter(line => this.isExpenseLineActualNotPopulated(line.record.fields[EmExpenseConstant.ACTUAL].value)).length !== 0
    );
  }

  isExpenseLineActualNotPopulated(actualValue) {
    return actualValue === null || actualValue === '';
  }

  getConcurStatus() {
    return this.record?.fields?.[EmExpenseConstant.CONCUR_STATUS]?.value;
  }

  isConcurStatusCanceled() {
    return this.getConcurStatus() === EmExpenseConstant.CONCUR_CANCELED_STATUS;
  }

  showSubmitToConcur() {
    return this.getConcurStatus() === 'Unsubmitted_vod';
  }

  showResubmitToConcur() {
    return EmExpenseConstant.RESUBMIT_CONCUR_STATUSES.includes(this.getConcurStatus());
  }

  async createConcurModalButton(key, def) {
    return this.createModalButton('submit', key, 'Concur', def);
  }

  createSaveAndNewButton() {
    const concurButtonIndex = this.getSubmitToConcurOnPageLayoutIndex();
    if (concurButtonIndex && concurButtonIndex > -1 && this.getConcurStatus()) {
      return this.createModalButton('submitAndNew', 'SUBMIT_TO_CONCUR_AND_NEW', 'Concur', 'Submit to Concur & New');
    }
    return super.createSaveAndNewButton();
  }

  async getRedirectPageRef() {
    if (this.page.action === 'Edit' && ((await this.alreadySubmittedToConcur()) || !this.canEdit)) {
      return {
        type: 'standard__recordPage',
        attributes: {
          recordId: this.id,
          objectApiName: this.objectApiName,
          actionName: 'view',
        },
      };
    }

    return null;
  }

  async alreadySubmittedToConcur() {
    if (EmExpenseConstant.HIDE_BUTTONS_CONCUR_STATUSES.includes(this.getConcurStatus())) {
      if (!this.isPopupAlreadyShown) {
        this.isPopupAlreadyShown = true;
        await this.showConcurAlreadySentAlertPopup();
      }
      return true;
    }
    return false;
  }

  async delete() {
    if (await isStatusSendingOrSubmitted(this.concurSvc, this.record.id)) {
      await this.showConcurAlreadySentAlertPopup();
      return {};
    }
    return super.delete();
  }

  addDefaultFieldValues(state) {
    if (state?.defaultFieldValues) {
      const values = JSON.parse(state.defaultFieldValues);
      Object.entries(values)
        .filter(([key]) => key !== 'RecordTypeId')
        .forEach(([key, value]) => {
          if (this.record.fields[key] || this.objectInfo.getFieldInfo(key)) {
            this.record.setFieldValue(key, value);
          }
        });
    }
    super.addDefaultFieldValues(state);
  }

  getSplitExpenseLine() {
    return this.expenseLines?.[0];
  }

  getSplitAmountPerPerson() {
    const splitExpenseLine = this.getSplitExpenseLine();
    if (!splitExpenseLine) {
      return null;
    }
    const actual = splitExpenseLine.record.rawValue(ACTUAL.fieldApiName) ?? 0;
    const participantsCount = splitExpenseLine.attributions.filter(attribution => !attribution.Deleted).length;
    return participantsCount ? actual / participantsCount : 0;
  }
}