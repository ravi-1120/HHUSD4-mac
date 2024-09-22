import {getService} from 'c/veevaServiceFactory';
import AdminDataService from "c/adminDataService";

export default class AdminHistoryTableBaseController {
    dataSvc;

    constructor() {
        this.dataSvc = new AdminDataService(getService('sessionSvc'), getService('messageSvc'));
    }

    sortByTimeStamp(tableData) {
        tableData.sort((a, b) => {
            if (a[this.timestamp] === undefined && b[this.timestamp] === undefined) {
                return 0;
            }
            if (a[this.timestamp] === undefined) {
                return -1;
            }
            if (b[this.timestamp] === undefined) {
                return 1;
            }
            return Date.parse(b[this.timestamp]) - Date.parse(a[this.timestamp]);
        });
    }

    getDefaultTableColumns(messageMap) {
        const columns = [
            {
                label: messageMap.timeStampLabel,
                fieldName: 'timeStamp',
                type: 'date',
                hideDefaultActions: true,
                cellAttributes: { alignment: 'left' },
                typeAttributes:{
                    month: "2-digit",
                    day: "2-digit",
                    year: "numeric",
                    hour: "2-digit",
                    minute: "2-digit",
                    second: "2-digit",
                },
            },
            {
                label: messageMap.processLabel,
                fieldName: 'process',
                type: 'text',
                hideDefaultActions: true,
                cellAttributes: { alignment: 'left' },
            },
            {
                label: messageMap.addsLabel,
                fieldName: 'adds',
                type: 'text',
                hideDefaultActions: true,
                cellAttributes: { alignment: 'left' },
            },
            {
                label: messageMap.updatesLabel,
                fieldName: 'updates',
                type: 'text',
                hideDefaultActions: true,
                cellAttributes: { alignment: 'left' },
            },
            {
                label: messageMap.errorsLabel,
                fieldName: 'errors',
                type: 'text',
                hideDefaultActions: true,
                cellAttributes: { alignment: 'left' },
            },
            {
                label: messageMap.actionsLabel,
                fieldName: 'actions',
                type: 'action',
                hideDefaultActions: true,
                cellAttributes: { alignment: 'left' },
                typeAttributes: { rowActions: [{ label: messageMap.downloadLogLabel, name: 'downloadLog' }] },
                fixedWidth: 80,
            },
        ];
        return columns;
    }

    async getCsvFile(event) {
        const file = await this.dataSvc.getMcJobCsvFile(event.detail.row.id, 'em-integration');
        return file;
    }
}