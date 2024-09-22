import { getService } from 'c/veevaServiceFactory';
import ColumnUtils from './columnUtils';

// Changing this file without touching the parent `FeedbackAccountsDatatable` JS or HTML could result in build failure.

export default class AccountDetailsColumnArray {
  constructor(accountRecordFieldTranslator, accountsTableDetailsRecord, messages) {
    this.translator = accountRecordFieldTranslator;
    this.accountsTableDetailsRecord = accountsTableDetailsRecord;
    this.messages = messages;
    this.columns = this.buildColumns();
  }

  static async createColumns(accountRecordFieldTranslator, accountsTableDetailsRecord) {
    const messages = await this.getVeevaMessages();

    return new AccountDetailsColumnArray(accountRecordFieldTranslator, accountsTableDetailsRecord, messages).columns;
  }

  static async getVeevaMessages() {
    const messageSvc = getService('messageSvc');

    return messageSvc
      .createMessageRequest()
      .addRequest('ACCOUNT_DETAILS', 'Feedback', 'Account Details', 'accountDetails')
      .sendRequest();
  }

  buildColumns() {
    const columns = [];

    const parentColumn = {
      text: this.messages.accountDetails,
      align: 'center',
    };
    ColumnUtils.addParentColumnToArray(parentColumn, columns);

    this.accountsTableDetailsRecord.accountDetailMetadata.forEach((accountDetail, detailIndex) => {
      ColumnUtils.addChildColumnToParent(parentColumn, {
        text: accountDetail.label,
        renderer: ({ record }) => this.translator.localizeField(accountDetail.type, record.accountDetails?.[detailIndex]),

        ...ColumnUtils.getFilterableColumnProperties(accountDetail.type, this.translator, ({ record, value, operator }) =>
          ColumnUtils.filter(accountDetail.type, record.accountDetails?.[detailIndex], value, operator)
        ),

        sortable: (record1, record2) =>
          ColumnUtils.sort(
            accountDetail.type,
            this.translator.localizeField(accountDetail.type, record1.accountDetails?.[detailIndex]),
            this.translator.localizeField(accountDetail.type, record2.accountDetails?.[detailIndex])
          ),
      });
    });

    return columns;
  }
}