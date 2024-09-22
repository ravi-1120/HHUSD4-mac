import EmController from 'c/emController';
import EmEventConstant from 'c/emEventConstant';
import EmInlineFileSectionController from 'c/emInlineFileSectionController';
import EmInlineFilesRelatedListController from 'c/emInlineFilesRelatedListController';
import EmEventMaterialNotesAttachmentsRelatedListController from 'c/emEventMaterialNotesAttachmentsRelatedListController';
import EmEventMaterialFilesRelatedListController from 'c/emEventMaterialFilesRelatedListController';
import MaterialLookupController from 'c/materialLookupController';
import MATERIAL from '@salesforce/schema/EM_Event_Material_vod__c.Material_vod__c';
import CLM_PRESENTATION from '@salesforce/schema/EM_Event_Material_vod__c.Clm_Presentation_vod__c';
import EMAIL_TEMPLATE from '@salesforce/schema/EM_Event_Material_vod__c.Email_Template_vod__c';

const OBJECT_INFO_MAPPING = {
  [MATERIAL.fieldApiName]: 'EM_Catalog_vod__c',
  [CLM_PRESENTATION.fieldApiName]: 'Clm_Presentation_vod__c',
  [EMAIL_TEMPLATE.fieldApiName]: 'Approved_Document_vod__c',
};
const FIELD_MAP = {
  Clm_Presentation_vod__c: {
    Name: 'Name_vod__c',
  },
  Approved_Document_vod__c: {
    Name: 'Name_vod__c',
    Document_Description_vod__c: 'Description_vod__c',
    Events_Management_Subtype_vod__c: 'Subtype_vod__c',
  },
};
export default class EmEventMaterialController extends EmController {
  stampedFields = [];
  objectInfosPromise = this.uiApi.objectInfos(['EM_Catalog_vod__c', 'Clm_Presentation_vod__c', 'Approved_Document_vod__c']);

  async processLayout(layout) {
    const processedLayout = super.processLayout(layout);
    if (
      (this.action === 'New' || this.action === 'Edit') &&
      processedLayout.relatedLists?.some(rl => EmEventConstant.NOTES_ATTACHMENTS_FILES_RELATIONSHIP_NAMES.includes(rl.relationship))
    ) {
      const fileMessage = await this.getMessageWithDefault('FILES', 'Lightning', 'Files');
      processedLayout.sections.push({
        heading: fileMessage,
        rawHeading: fileMessage,
        fileSection: true,
        key: `${processedLayout.sections.length}`,
        layoutRows: [],
      });
    }
    return processedLayout;
  }

  getSectionController(meta) {
    if (meta.fileSection) {
      return new EmInlineFileSectionController(meta, this).initTemplate();
    }
    return super.getSectionController(meta, this);
  }

  getRelatedListController(meta, pageCtrl) {
    if ((this.page.action === 'New' || this.page.action === 'Edit') && meta.relationship === 'CombinedAttachments') {
      return new EmInlineFilesRelatedListController(meta, pageCtrl);
    }
    if (this.page.action === 'View' && meta.relationship === 'CombinedAttachments') {
      return new EmEventMaterialNotesAttachmentsRelatedListController(meta, pageCtrl);
    }
    if (this.page.action === 'View' && meta.relationship === 'AttachedContentDocuments') {
      return new EmEventMaterialFilesRelatedListController(meta, pageCtrl);
    }
    return super.getRelatedListController(meta, pageCtrl);
  }

  initItemController(meta, record) {
    const { field } = meta;
    if (field === MATERIAL.fieldApiName) {
      return new MaterialLookupController(meta, this, this.objectInfo.getFieldInfo(field), record);
    }
    if (this.stampedFields.includes(field)) {
      // eslint-disable-next-line no-param-reassign
      meta = { ...meta };
      meta.disabled = true;
    }
    return super.initItemController(meta, record);
  }

  getQueryFields() {
    const queryFields = super.getQueryFields();
    queryFields.push(`${this.objectApiName}.RecordType.DeveloperName`);
    return queryFields;
  }

  async initData() {
    await super.initData();
    this.processMaterialFields();
  }

  processMaterialFields() {
    if (this.action === 'Edit') {
      Object.keys(OBJECT_INFO_MAPPING).forEach(field => {
        if (this.record.rawValue(field)) {
          this.setDependentMaterialFields(this.record.rawValue(field), field);
        }
      });
    }
  }

  setFieldValue(field, value, reference, record, source) {
    super.setFieldValue(field, value, reference, record, source);
    if (Object.keys(OBJECT_INFO_MAPPING).includes(field.apiName)) {
      this.setDependentMaterialFields(value, field.apiName);
    }
  }

  async setDependentMaterialFields(materialId, controllingField) {
    this.stampedFields.forEach(field => {
      this.record.setFieldValue(field, null);
    });
    this.stampedFields = [];

    if (materialId) {
      const objectInfos = await this.objectInfosPromise;
      const controllingObjectInfo = objectInfos[OBJECT_INFO_MAPPING[controllingField]];
      const queryFields = Object.entries(controllingObjectInfo.fields)
        .filter(([fieldName, fieldInfo]) => (fieldInfo.custom && fieldName !== 'External_ID_vod__c') || fieldName === 'CurrencyIsoCode')
        .map(([fieldName]) => `${controllingObjectInfo.apiName}.${fieldName}`);
      if (controllingObjectInfo.apiName === 'Clm_Presentation_vod__c' || controllingObjectInfo.apiName === 'Approved_Document_vod__c') {
        queryFields.push(`${controllingObjectInfo.apiName}.Name`);
      }
      const record = await this.uiApi.getRecord(materialId, queryFields);
      const fieldMap = FIELD_MAP[record.apiName];
      if (fieldMap) {
        for (const [key, value] of Object.entries(fieldMap)) {
          record.fields[value] = record.fields[key];
          delete record.fields[key];
        }
      }
      if (!record.fields.Name_vod__c?.value) {
        record.fields.Name_vod__c = { value: '' };
      }
      if (!record.fields.Description_vod__c?.value) {
        record.fields.Description_vod__c = { value: '' };
      }
      Object.entries(record.fields).forEach(([field, value]) => {
        if (this.isFieldOnLayout(field) && value.value !== null) {
          this.stampedFields.push(field);
          this.record.setFieldValue(field, value.value);
        }
      });
    }

    this.page.recordUpdateFlag = !this.page.recordUpdateFlag;
  }
}