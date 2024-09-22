import getIdentifierString from "@salesforce/apex/VeevaMyScheduleController.getIdentifierString";

export default class VeevaMedicalIdentifierHelper {
    static identifierString = null;

    static getIdentifierApiName() {
        getIdentifierString()
            .then(result => {this.identifierString = result;})
            .catch(() => {this.identifierString = 'Account_Identifier_vod__c';})
        return this.identifierString;
    }
}