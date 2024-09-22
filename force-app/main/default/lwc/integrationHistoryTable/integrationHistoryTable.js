import { LightningElement, api, track, wire } from 'lwc';
import integrationAdminChannel from '@salesforce/messageChannel/Integration_Admin_Channel_vod__c';
import { publish, MessageContext, subscribe, unsubscribe } from 'lightning/messageService';

export default class IntegrationHistoryTable extends LightningElement {
    @api ctrl;
    @api numberOfRows;
    @api enableInfiniteLoading;

    @track messageMap = {};
    @track showLoadingSpinner = false;

    @wire(MessageContext)
    messageContext;

    loadMore = false;
    showSyncButton = false;
    columns = [];
    tableData = [];
    displayedTableData = [];
    
    

    async connectedCallback() {
        this.subscribeToChannel();
        this.showSyncButton = this.ctrl?.showSyncButton;
        await this.loadVeevaMessages();
        await Promise.all([this.getTableColumns(), this.getTableData()]);
    }

    disconnectedCallback() {
        this.unsubscribeToChannel();
    }
    
    async loadVeevaMessages() {
        const {messageSvc} = this.ctrl.dataSvc;
        this.messageMap =  await messageSvc
            .createMessageRequest()
            .addRequest('INTEGRATION_HISTORY', 'EVENT_MANAGEMENT', 'Integration History', 'tableTitle')
            .addRequest('SYNC', 'TABLET', 'Sync', 'syncButtonLabel')
            .addRequest('APPROVED_EMAIL_ADMIN_PAGE_TIMESTAMP', 'ApprovedEmail', 'Timestamp', 'timeStampLabel')
            .addRequest('APPROVED_EMAIL_ADMIN_PAGE_VURL', 'ApprovedEmail', 'Vault URL', 'vaultUrlLabel')
            .addRequest('PROCESS', 'EVENT_MANAGEMENT', 'Process', 'processLabel')
            .addRequest('ADDS', 'NETWORK', 'Adds', 'addsLabel')
            .addRequest('UPDATES', 'EVENT_MANAGEMENT', 'Updates', 'updatesLabel')
            .addRequest('ERRORS', 'TABLET', 'Errors', 'errorsLabel')
            .addRequest('ACTIONS', 'TABLET', 'Actions', 'actionsLabel')
            .addRequest('EM_QR_DOWNLOAD_LOG', 'EVENT_MANAGEMENT', 'Download Log', 'downloadLogLabel')
            .addRequest('APPROVED_EMAIL_ADMIN_PAGE_FULLRFRSH_BTN', 'ApprovedEmail', 'Force Full Refresh', 'fullSyncButtonLabel')
            .sendRequest();
    }

    async getTableColumns() {
        this.columns = await this.ctrl.getTableColumns(this.messageMap);
    }

    async getTableData() {
        this.loadMore = true;
        this.showLoadingSpinner = true;
        this.tableData = await this.ctrl.getTableData();
        if (this.tableData) {
            this.ctrl.sortByTimeStamp(this.tableData);
            this.displayedTableData = this.displayData();
        }
        this.showLoadingSpinner = false;
    }

    get infiniteLoading() {
        return this.loadMore && this.enableInfiniteLoading === 'true';
    }

    async sync() {
        this.startSync(false);
    }

    async fullSync() {
        this.startSync(true);
    }

    async startSync(isFullSync) {
        this.showLoadingSpinner = true;
        await this.ctrl.sync(isFullSync);
        const payload = {
            type: 'sync',
        };
        publish(this.messageContext, integrationAdminChannel, payload);
        this.getTableData();
    }

    async handleRowAction(event) {
        if (!event.detail.row.disabled && event.detail.action.name === "downloadLog") {
            const file =  await this.ctrl.getCsvFile(event);
            const fileName = this.ctrl.getFileName(event.detail.row);
            if(file && fileName) {
                this.saveBlob(file, fileName);
            }
        }
    }

    saveBlob(blob, filename) {
        const a = document.createElement('a');
        a.href = window.URL.createObjectURL(blob);
        a.download = filename;
        a.dispatchEvent(new MouseEvent('click'));
    }

    displayData() {
        return this.numberOfRows > this.tableData.length ? this.tableData : this.tableData.slice(0, this.numberOfRows);
    }

    async loadMoreData() {
        this.loadMore = false;
        const nextArraySize = this.displayedTableData.length + Number(this.numberOfRows);
        if (nextArraySize < this.tableData.length) {
            this.loadMore = true;
            this.displayedTableData = this.tableData.slice(0, nextArraySize);
        } else {
            this.displayedTableData = this.tableData;
        }
    }

    subscribeToChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(this.messageContext, integrationAdminChannel, message => this.handleMessage(message));
        }
    }

    unsubscribeToChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleMessage(msg) {
        if (msg.type === 'deleteConnection') {
            this.getTableData();
        }
    }
}