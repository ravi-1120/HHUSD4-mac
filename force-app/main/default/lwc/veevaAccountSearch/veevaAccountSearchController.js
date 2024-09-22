import VeevaMessageService, { VeevaMessageRequest } from "c/veevaMessageService";
import ReferenceController from "c/referenceController";
import VeevaRecord from "c/veevaRecord";
import getPrimaryAddresses from '@salesforce/apex/VeevaAddress.getPrimaryAddresses';
import accountRecordTypeIcons from '@salesforce/resourceUrl/account_record_type_icons';
import VeevaMedicalIdentifierHelper from "c/veevaMedicalIdentifierHelper";

export default class VeevaAccountSearchController extends ReferenceController {
    static VEEVA_ICON_MAP = {
        "Business_Professional_vod" : "business_professional",
        "Professional_vod" : "professional",
        "Professional" : "professional",
        "MCOPlan_vod" : "mco",
        "MCO_vod" : "mco",
        "Practice_vod" : "private_practice",
        "Hospital_vod" : "hospital",
        "Pharmacy_vod" : "pharmacy",
        "HospitalDepartment_vod" : "hospital",
        "Laboratory_vod" : "laboratory",
        "Organization_vod" : "board",
        "Board_vod" : "board",
        "Employer_vod" : "employer",
        "ExtendedCare_vod" : "ambulatory",
        "Institution_vod" : "institution",
        "Publication_vod" : "publication",
        "KOL_vod" : "kol",
        "Wholesaler_vod" : "wholesaler",
        "Government_Agency_vod" : "government",
        "Distributor_vod" : "distributor",
        "Distributor_Branch_vod" : "distributor",
        "PersonAccount" : "person",
        "defaultPersonAccount" : "person",
        "defaultNonPersonAccount" : "business"
    }
    recordTypeToIconMap;
    msgSvc;
    msgMap;
    accountObjInfo;

    constructor(pageCtrl, objectApiName = "Call2_vod__c") {
        const veevaRecord = new VeevaRecord({ recordTypeId: 'recId', fields: {}, apiName: objectApiName });
        super({}, pageCtrl, {referenceToInfos: [{apiName: 'Account', nameFields: ['Name']}, {apiName: VeevaMedicalIdentifierHelper.getIdentifierApiName()}], apiName: 'Account_vod__c'}, veevaRecord);
        this.msgSvc = pageCtrl.messageSvc;
        this.recordTypeToIconMap = {...VeevaAccountSearchController.VEEVA_ICON_MAP};
    }

    _addCustomRecordTypesToMap() {
        if (!this.msgMap.recordTypeIconMapString || this.msgMap.recordTypeIconMapString.length < 1) {
            return;
        }
        const newRecordTypesToCurrentTypesMap = VeevaMessageService.convertMessageStringToMap(this.msgMap.recordTypeIconMapString);
        Object.entries(newRecordTypesToCurrentTypesMap).forEach(([desiredRecordType, recordTypeList]) => {
            recordTypeList.forEach(rt => {
                this.recordTypeToIconMap[rt] = this.recordTypeToIconMap[desiredRecordType];
            });
        });
    }

    async retrieveAccountSearchInfo() {
        // load veeva messages if necessary
        if (!this.msgMap || Object.keys(this.msgMap).length < 1) {
            const msgRequest = new VeevaMessageRequest();
            msgRequest.addRequest('ADDRESS', 'TABLET', 'Address', 'msgAddress');
            msgRequest.addRequest('ACCOUNT_RECORD_TYPE_ICON_MAP', 'Common', '', 'recordTypeIconMapString');
            this.msgMap = await this.msgSvc.getMessageMap(msgRequest);
            this._addCustomRecordTypesToMap();
        }
        // load account object info if necessary
        if (!this.accountObjInfo || !this.accountObjInfo.fields || this.accountObjInfo.fields.length < 1) {
            this.accountObjInfo = await this.getTargetObjectInfo();
        }
    }

    async getColumns() {
        await this.retrieveAccountSearchInfo();
        const columns = [];
        columns.push(
            {
                label: this.accountObjInfo.fields.Formatted_Name_vod__c.label,
                fieldName: "Formatted_Name_vod__c",
                queryFld: ["Account.Formatted_Name_vod__c", "Account.RecordType.DeveloperName", "Account.IsPersonAccount"],
                type: 'nameLink', 
                typeAttributes: { 
                    id: {fieldName: 'id'},
                    veevaIcon: {fieldName: 'veevaIcon'}
                }
            }
        );
        if (Object.keys(this.accountObjInfo.fields).includes(VeevaMedicalIdentifierHelper.getIdentifierApiName())) { // Account Identifier FLS check
            columns.push({label: this._getIdentifierLabel(), fieldName: VeevaMedicalIdentifierHelper.getIdentifierApiName(), queryFld: `Account.${  VeevaMedicalIdentifierHelper.getIdentifierApiName()}`});
        }
        columns.push({label: this.msgMap.msgAddress, fieldName: "Address"});
        return columns;
    }

    async search(searchTerm, nextPageUrl) {
        const response = await super.search(searchTerm, nextPageUrl);
        response.records = await this.parseForColumns(response.records);
        response.records.forEach(record => {
            const recordType = record?.RecordType?.fields?.DeveloperName?.value;
            let veevaIcon = this.recordTypeToIconMap[recordType];
            if (!veevaIcon) {
                veevaIcon = record.IsPersonAccount ? this.recordTypeToIconMap.defaultPersonAccount : this.recordTypeToIconMap.defaultNonPersonAccount;
            }
            record.veevaIcon = `${ accountRecordTypeIcons  }/icons/${  veevaIcon  }.svg`
            record.name = record.Formatted_Name_vod__c;
        });
        return response;
    }

    async searchWithColumns(term, nextPageUrl) {
        const response = await super.searchWithColumns(term, nextPageUrl);

        const accountIds = response.records.map(record => record.id);

        const addressFields = ['Id', 'Name', 'City_vod__c', 'State_vod__c', 'Zip_vod__c',
        'Primary_vod__c', 'CreatedDate', 'Account_vod__c'];
        const addresses = await getPrimaryAddresses({ 'accountIds': accountIds, 'fieldNames': addressFields, duplicateRawAddressFields: false });

        for(const record of response.records) {
            const address = addresses[record.id];
            if(address) {
                record.Address =
                    `${address.Name 
                    } ${ 
                    address.City_vod__c 
                    }, ${ 
                    address.State_vod__c 
                    } ${ 
                    address.Zip_vod__c}`;
            }
        }

        return response;
    }

    _getIdentifierLabel() {
        if (VeevaMedicalIdentifierHelper.getIdentifierApiName() === "Medical_Identifier_vod__c") {
            return this.accountObjInfo.fields.Medical_Identifier_vod__c.label;
        }
        return this.accountObjInfo.fields.Account_Identifier_vod__c.label;
    }
}