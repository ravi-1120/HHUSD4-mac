import { getService } from 'c/veevaServiceFactory';
import ColumnUtils from './columnUtils';

// Changing this file without touching the parent `FeedbackAccountsDatatable` JS or HTML could result in build failure.

export default class ProductMetricColumnArray {
  constructor(accountRecordFieldTranslator, accountsTableDetailsRecord, messages) {
    this.translator = accountRecordFieldTranslator;
    this.accountsTableDetailsRecord = accountsTableDetailsRecord;
    this.messages = messages;
    this.columns = this.buildColumns();
  }

  static async createColumns(accountRecordFieldTranslator, accountsTableDetailsRecord) {
    const messages = await this.getVeevaMessages();

    return new ProductMetricColumnArray(accountRecordFieldTranslator, accountsTableDetailsRecord, messages).columns;
  }

  static async getVeevaMessages() {
    const messageSvc = getService('messageSvc');

    return messageSvc
      .createMessageRequest()
      .addRequest('PRODUCT_METRIC', 'Common', 'Product Metric', 'productMetric')
      .sendRequest();
  }

  buildColumns() {
    const columns = [];

    this.accountsTableDetailsRecord.productMetricMetadata.forEach((productMetric, productMetricIndex) => {
      const parentColumn = {
        text: `${this.messages.productMetric}: ${productMetric.productMetricLabel.label}`,
        align: 'center',
      };
      ColumnUtils.addParentColumnToArray(parentColumn, columns);

      const hasOneProduct = (productMetric?.productLabels?.length === 1);

      productMetric.productLabels.forEach((productLabel, productLabelIndex) => {
        ColumnUtils.addChildColumnToParent(parentColumn, {
          text: productLabel,
          width: hasOneProduct ? 250 : 125,
          renderer: ({ record }) =>
            this.translator.localizeField(
              productMetric.productMetricLabel.type,
              record.productMetricDetails?.[productMetricIndex]?.productValues?.[productLabelIndex]
            ),

          ...ColumnUtils.getFilterableColumnProperties(productMetric.productMetricLabel.type, this.translator, ({ record, value, operator }) =>
            ColumnUtils.filter(
              productMetric.productMetricLabel.type,
              record.productMetricDetails?.[productMetricIndex]?.productValues?.[productLabelIndex],
              value,
              operator
            )
          ),

          sortable: (record1, record2) =>
            ColumnUtils.sort(
              productMetric.productMetricLabel.type,
              this.translator.localizeField(
                productMetric.productMetricLabel.type,
                record1.productMetricDetails?.[productMetricIndex]?.productValues?.[productLabelIndex]
              ),
              this.translator.localizeField(
                productMetric.productMetricLabel.type,
                record2.productMetricDetails?.[productMetricIndex]?.productValues?.[productLabelIndex]
              )
            ),
        });
      });
    });

    return columns;
  }
}