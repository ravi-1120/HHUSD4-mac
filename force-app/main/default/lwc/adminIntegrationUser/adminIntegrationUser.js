import { LightningElement, track, api } from 'lwc';
import VeevaToastEvent from 'c/veevaToastEvent';
import { VeevaMessageRequest } from "c/veevaMessageService";
import { getService } from 'c/veevaServiceFactory';
import AdminDataService from "c/adminDataService";

export default class AdminIntegrationUser extends LightningElement {
    @api systemType;
    @api customDataSvc;
    @track userData = {};
    @track messageMap = {};

    userDataSvc;
    orgId;
    showUserModal = false;
    modalTitle;
    showInitLoadingSpinner = true;

    async connectedCallback() {
         this.userDataSvc = this.customDataSvc ? this.customDataSvc : new AdminDataService(getService('sessionSvc'), getService('messageSvc'));
        [this.messageMap, this.orgId] = await Promise.all([this.loadVeevaMessages(), this.userDataSvc.retrieveOrgId()]);
        await this.getUserCredential();
        this.showInitLoadingSpinner = false;
    }

    async loadVeevaMessages() {
        const {messageSvc} = this.userDataSvc;
        const msgRequest = new VeevaMessageRequest();
        msgRequest.addRequest( 'INT_USER', 'EVENT_MANAGEMENT', 'Integration User', 'userCardTitle');
        msgRequest.addRequest('NO_INT_USER', 'EVENT_MANAGEMENT', 'An Integration User does not exist. Click the new button to create one.', 'userCardHelpMsg');
        msgRequest.addRequest( 'NEW', 'Common', 'New', 'newButtonLabel');
        msgRequest.addRequest( 'USERNAME', 'EVENT_MANAGEMENT', 'Username', 'userNameFieldLabel');
        msgRequest.addRequest( 'APPROVED_EMAIL_ADMIN_PAGE_SFDC_SB_TITLE', 'ApprovedEmail', 'Is this a sandbox?', 'sandboxFieldLabel');
        msgRequest.addRequest( 'EM_QR_LAST_MODIFIED', 'EVENT_MANAGEMENT', 'Last Modified', 'lastModFieldLabel');
        msgRequest.addRequest( 'VALIDATE_CREDENTIALS', 'EVENT_MANAGEMENT', 'Validate Credentials', 'validateButtonLabel');
        msgRequest.addRequest( 'Edit', 'Common', 'Edit', 'editButtonLabel');
        msgRequest.addRequest( 'INT_USER_VALID_CRED', 'EVENT_MANAGEMENT', 'Integration User credentials are valid', 'successToast');
        msgRequest.addRequest( 'INT_USER_INVALID_CRED', 'EVENT_MANAGEMENT', 'Integration User credentials are invalid', 'errorToast');
        msgRequest.addRequest( 'NEW_INT_USER', 'EVENT_MANAGEMENT', 'New Integration User', 'newUserModalTitle');
        msgRequest.addRequest( 'EDIT_INT_USER', 'EVENT_MANAGEMENT', 'Edit Integration User', 'editUserModalTitle');
        msgRequest.addRequest( 'CANCEL', 'Common', 'Cancel', 'cancelButtonLabel');
        msgRequest.addRequest( 'SAVE', 'Common', 'Save', 'saveButtonLabel');
        msgRequest.addRequest( 'PASSWORD', 'CLM', 'Password', 'passwordFieldLabel');
        msgRequest.addRequest('GEN_SAVE_ERROR', 'EVENT_MANAGEMENT', 'We were unable to save the record', 'genericPopoverErrorLabel');
        msgRequest.addRequest('ENTER_A_VALUE', 'EVENT_MANAGEMENT', 'Enter a value', 'requiredFieldErrorLabel');
        return messageSvc.getMessageMap(msgRequest);
    }

    displayNewUserModal() {
        this.modalTitle = this.messageMap.newUserModalTitle;
        this.showUserModal = true;
    }

    displayEditUserModal() {
        this.modalTitle = this.messageMap.editUserModalTitle;
        this.showUserModal = true;
    }

    closeUserModal() {
        this.showUserModal = false;
    }

    async saveUserModal() {
        this.showUserModal = false;
        await this.getUserCredential();
    }

    async getUserCredential() {
       this.userData = await this.userDataSvc.readVerifyCredential('read', this.systemType, this.orgId);
    }

    async validateUserCredential() {
        const validateResponse = await this.userDataSvc.readVerifyCredential('validate', this.systemType, this.orgId);
        if(validateResponse === '') {
            this.dispatchEvent(VeevaToastEvent.successMessage(this.messageMap.successToast));
        } else {
            const obj = {message: this.messageMap.errorToast};
            this.dispatchEvent(VeevaToastEvent.error(obj));
        }
    }

    get hasCredential() {
        return Object.keys(this.userData).length !== 0;
    }
}