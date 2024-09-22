import VeevaSignatureController from 'c/veevaSignatureController';
import MedicalInquirySignatureController from 'c/medicalInquirySignatureController';
import Container from 'c/container';
import { getService, SERVICES } from 'c/veevaServiceFactory';

const sessionService = getService(SERVICES.SESSION);
const vDataService = getService(SERVICES.DATA);
const CONTROLLER_PARAMS = [vDataService, sessionService];

const _container = Container.SIGNATURE_CONTROLLERS;
_container.register('signatureController', VeevaSignatureController, CONTROLLER_PARAMS);
_container.register('Medical_Inquiry_vod__c', MedicalInquirySignatureController, CONTROLLER_PARAMS);

export const getSignatureController = name => {
    let signatureController;
    if (name) {
        signatureController = _container.get(name);
    }
    if (!signatureController) {
        signatureController = _container.get('signatureController');
    }
    return signatureController;
};

export default { getSignatureController };