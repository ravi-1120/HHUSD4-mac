import ReferenceController from 'c/referenceController';
import VeevaUtils from 'c/veevaUtils';
import ACCOUNT_RECORD_TYPE_ICONS from '@salesforce/resourceUrl/account_record_type_icons';
import VeevaMessageService, { VeevaMessageRequest } from "c/veevaMessageService";
import getAccountRecordTypeInfos from '@salesforce/apex/VeevaGlobalAccountSearchController.getAccountRecordTypeInfos';

export default class GasRecordTypeLookupController extends ReferenceController {
  _columns = null;
  msgMap;
  msgSvc;
  recordTypeToIconMap;
  getCustomRecordTypeMappingsPromise;
  accountRecordTypeInfos;
  accountRecordTypeInfosPromise;

  constructor(meta, pageCtrl, field, record) {
    super(meta, pageCtrl, field, record);
    this.getCustomRecordTypeMappingsPromise = this.getCustomRecordTypeMappings();
    this.accountRecordTypeInfosPromise = getAccountRecordTypeInfos();
  }

  static STANDARD_RECTYPE_ICON_MAP = new Map([
    ["Business_Professional_vod", "business_professional"], ["Professional_vod", "professional"], ["MCOPlan_vod", "mco"],
    ["MCO_vod", "mco"], ["Practice_vod", "private_practice"], ["Hospital_vod", "hospital"], ["Pharmacy_vod", "pharmacy"],
    ["HospitalDepartment_vod", "hospital_department"], ["Laboratory_vod", "laboratory"], ["Organization_vod", "board"],
    ["Board_vod", "board"], ["Employer_vod", "employer"], ["ExtendedCare_vod", "ambulatory"], ["Institution_vod", "institution"],
    ["Publication_vod", "publication"], ["KOL_vod", "kol"], ["Wholesaler_vod", "wholesaler"], ["Government_Agency_vod", "government"],
    ["Distributor_vod", "distributor"], ["Distributor_Branch_vod", "distributor"], ["PersonAccount", "person"]
  ]);

  get recordTypes() {
    return Object.values(this.pageCtrl.objectInfo.recordTypeInfos)
      .filter(recordType => !recordType.master)
      .map(recordType => ({
        name: recordType.name,
        apiName: 'RecordType',
        id: recordType.recordTypeId,
        icon: VeevaUtils.getIconHardcoded('RecordType'),
        veevaIcon: this.getRecordTypeIconUrl(recordType.recordTypeId)
      }))
      .sort((first, second) => first.name.localeCompare(second.name));
  }

  getRecordTypeIconUrl(recordTypeId) {
    const developerName = this.accountRecordTypeInfos[recordTypeId].DeveloperName;
    let iconName = this.recordTypeToIconMap.get(developerName);
    if (!iconName) {
      if (this.accountRecordTypeInfos[recordTypeId].IsPersonType) {
        iconName = 'person';
      } else {
        iconName = 'business';
      }
    }
    return `${ACCOUNT_RECORD_TYPE_ICONS}/icons/${iconName}.svg`;
  }
  
  _addCustomRecordTypesToMap() {
    if (!this.msgMap.recordTypeIconMapString || this.msgMap.recordTypeIconMapString.length < 1) {
        return;
    }
    const newRecordTypesToCurrentTypesMap = VeevaMessageService.convertMessageStringToMap(this.msgMap.recordTypeIconMapString);
    Object.entries(newRecordTypesToCurrentTypesMap).forEach(([desiredRecordType, recordTypeList]) => {
        recordTypeList.forEach(rt => {
          this.recordTypeToIconMap.set(rt, this.recordTypeToIconMap.get(desiredRecordType))
        });
    });
  }

  async getCustomRecordTypeMappings() {
    this.msgSvc = this.pageCtrl.messageSvc;
    this.recordTypeToIconMap = GasRecordTypeLookupController.STANDARD_RECTYPE_ICON_MAP;
    // load veeva messages if necessary
    if (!this.msgMap || Object.keys(this.msgMap).length < 1) {
      const msgRequest = new VeevaMessageRequest();
      msgRequest.addRequest('ACCOUNT_RECORD_TYPE_ICON_MAP', 'Common', '', 'recordTypeIconMapString');
      this.msgMap = await this.msgSvc.getMessageMap(msgRequest);
      this._addCustomRecordTypesToMap();
    }
  }

  async search(term) {
    let matchingRecordTypes;
    this.accountRecordTypeInfos = await this.accountRecordTypeInfosPromise;
    await this.getCustomRecordTypeMappingsPromise;
    if (!term) {
      matchingRecordTypes = this.recordTypes;
    } else {
      matchingRecordTypes = this.recordTypes.filter(recordType => recordType.name.toLowerCase().indexOf(term.toLowerCase()) !== -1);
    }
    return Promise.resolve({
      records: matchingRecordTypes,
    });
  }

  async getColumns() {
    if (!this._columns) {
      const recordTypeObjectInfo = await this.getTargetObjectInfo();
      this._columns = [
        {
          fieldName: 'Name',
          label: recordTypeObjectInfo.fields.Name.label,
          queryFld: 'RecordType.Name',
          type: 'nameLink',
          typeAttributes: { id: { fieldName: 'id' } },
        },
        {
          fieldName: 'DeveloperName',
          label: recordTypeObjectInfo.fields.DeveloperName.label,
          queryFld: 'RecordType.DeveloperName',
          type: 'text',
        },
      ];
    }
    return this._columns;
  }
}