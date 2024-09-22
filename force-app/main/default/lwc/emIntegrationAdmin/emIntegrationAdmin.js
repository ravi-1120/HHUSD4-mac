import { LightningElement, track } from 'lwc';
import { getService } from 'c/veevaServiceFactory';
import { VeevaMessageRequest } from "c/veevaMessageService";
import EmVaultConnectionController from "c/emVaultConnectionController"



export default class EmIntegrationAdmin extends LightningElement {
    @track messageMap = {};
    connectionCtrl = new EmVaultConnectionController();
    salesforceEm = 'SalesForce_EM';
    vaultEm = 'Vault_EM';

    async connectedCallback() {
        this.messageMap = await this.loadVeevaMessages();
    }

    async loadVeevaMessages() {
        const messageSvc = getService('messageSvc');
        const msgRequest = new VeevaMessageRequest();
        msgRequest.addRequest('INTEGRATION_ADMIN_PAGE_TITLE', 'EVENT_MANAGEMENT', 'Events Management Integration Administration Page', 'pageTitle');
        msgRequest.addRequest('INTEGRATION_ADMIN_PAGE_HELP_TEXT', 'EVENT_MANAGEMENT', 'Setup and manage your Events Management integrations.', 'pageHelpText');
        msgRequest.addRequest('INTEGRATION_ADMIN_PAGE_SPEAKER_PORTAL_TAB_TITLE', 'SPEAKER_PORTAL', 'Speaker Portal', 'speakerPortalTabTitle');
        msgRequest.addRequest('INTEGRATION_ADMIN_PAGE_VAULT_TAB_TITLE', 'EVENT_MANAGEMENT', 'Vault', 'vaultTabTitle');
        return messageSvc.getMessageMap(msgRequest);
    }
}