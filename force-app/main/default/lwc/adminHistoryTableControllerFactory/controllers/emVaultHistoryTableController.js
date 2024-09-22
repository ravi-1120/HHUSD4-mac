import VeevaUtils from 'c/veevaUtils';
import AdminHistoryTableController from "./adminHistoryTableBaseController";

export default class EmVaultHistoryTableController extends AdminHistoryTableController{
    showSyncButton = true;
    
    getTableColumns(messageMap) {
        const columns = this.getDefaultTableColumns(messageMap);
        columns.splice(1, 0, 
            {
                label: messageMap.vaultUrlLabel,
                fieldName: 'vaultUrl',
                type: 'text',
                hideDefaultActions: true,
                cellAttributes: { alignment: 'left' },
            }
        );
        return columns;
    }

    async getTableData() {
        const historyData = await this.dataSvc.getJobStatus('em-integration', '30', 'day');
        const tableData = historyData?.rsrList?.map(result => {
            const tableRow = {};
            tableRow.timeStamp = result.timestamp;
            tableRow.process = result.Process;
            tableRow.adds = result.Adds;
            tableRow.updates = result.Updates;
            tableRow.errors = result.Errors;
            tableRow.id = result.jobId;
            tableRow.vaultUrl = result['Vault URL'];
            return tableRow;
        }) ?? [];
        return tableData;
    }

    async sync(isFullSync) {
        const syncType = isFullSync ? 2 : 1;
        const response = await this.dataSvc.runMcTask('EM_VAULT_INTEGRATION', syncType);
        this.jobId = response?.data?.results?.[0]?.jobId ?? '';
        if(this.jobId) {
            const record = await this.pollingJobStatus(this.jobId);
            this.errorCount = record?.data?.[0]?.Fail ?? '0';
            return this.isJobCompleted(record);
        }
        return false;
    }

    async pollingJobStatus(jobId) {
        const pollingJob = async () => this.dataSvc.getJobStatus('em-integration', '10', 'record', jobId);
        const isDone = record => this.isJobCompleted(record);
        return VeevaUtils.poll(pollingJob, isDone, 3000, 20);
    }

    isJobCompleted(record) {
        const status = record?.status ?? '';
        return status === 'SUCCESS';
    }

    getFileName (row) {
        const {process : processName, vaultUrl} = row;
        let fileName;
        if(vaultUrl) {
            fileName = `${vaultUrl.replace(/(^\w+:|^)\/\//, '')}`;
        }
        if(processName) {
            fileName = fileName? `${fileName}_${processName.replace(/\s/g, '')}` : `${processName.replace(/\s/g, '')}`;
        }
        if(!fileName) {
            fileName = 'VaultIntegrationDownload';
        }

        return `${fileName}.csv`;
    }

}