import customRecordTypeIcons from '@salesforce/resourceUrl/account_record_type_icons';
import VeevaMessageService from "c/veevaMessageService";

export default class AccountRecTypeIconService {
    
    ACCOUNT_REC_TYPE_ICON_MAP = {
        "Business_Professional_vod" : "business_professional",
        "Professional_vod" : "professional",
        "Professional" : "professional",
        "MCOPlan_vod" : "mco",
        "MCO_vod" : "mco",
        "Practice_vod" : "private_practice",
        "Hospital_vod" : "hospital",
        "Pharmacy_vod" : "pharmacy",
        "HospitalDepartment_vod" : "hospital_department",
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
    };
    recordTypeToIconMap = {};
    
    constructor(customRecordTypes) {
        this._setUpDefaultRecTypeIconMap();
        this._addCustomRecordTypesToMap(customRecordTypes);
    }

    _setUpDefaultRecTypeIconMap(){
        Object.entries(this.ACCOUNT_REC_TYPE_ICON_MAP).forEach(([key, value]) => {
            this.recordTypeToIconMap[key] = `${customRecordTypeIcons}/icons/${value}.svg`;
        });

    }

    _addCustomRecordTypesToMap(recordTypeIconMapString) {
        if (!recordTypeIconMapString || recordTypeIconMapString.length < 1) {
            return;
        }
        const newRecordTypesToCurrentTypesMap = VeevaMessageService.convertMessageStringToMap(recordTypeIconMapString);
        Object.entries(newRecordTypesToCurrentTypesMap).forEach(([desiredRecordType, recordTypeList]) => {
            const value = this.recordTypeToIconMap[desiredRecordType];
            recordTypeList.forEach(rt => {         
                this.recordTypeToIconMap[rt] = value;
            });
        });
    }

    getRecTypeIconMap(){
        return this.recordTypeToIconMap;
    }
}