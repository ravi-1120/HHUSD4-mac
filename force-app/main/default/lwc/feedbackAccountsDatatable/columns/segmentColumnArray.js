import { getService } from 'c/veevaServiceFactory';
import { ALIGN_TYPES, NULL_DISPLAY_STRING } from 'c/territoryFeedbackConstants';
import ColumnUtils from './columnUtils';

// Changing this file without touching the parent `FeedbackAccountsDatatable` JS or HTML could result in build failure.

export default class SegmentColumnArray {
  constructor(accountRecordFieldTranslator, accountsTableDetailsRecord, messages) {
    this.translator = accountRecordFieldTranslator;
    this.accountsTableDetailsRecord = accountsTableDetailsRecord;
    this.messages = messages;
    this.columns = this.buildColumns();
  }

  static async createColumns(accountRecordFieldTranslator, accountsTableDetailsRecord) {
    const messages = await this.getVeevaMessages();

    return new SegmentColumnArray(accountRecordFieldTranslator, accountsTableDetailsRecord, messages).columns;
  }

  static async getVeevaMessages() {
    const messageSvc = getService('messageSvc');

    return messageSvc
      .createMessageRequest()
      .addRequest('SEGMENT', 'Feedback', 'Segment: {0}', 'segment')
      .sendRequest();
  }

  buildColumns() {
    const columns = [];

    this.accountsTableDetailsRecord.segmentMetadata.forEach((channelMetadata, channelIndex) => {
      const parentColumn = {
        text: this.messages.segment.replace('{0}', channelMetadata.channelLabel),
        align: 'center',
      };
      ColumnUtils.addParentColumnToArray(parentColumn, columns);

      ColumnUtils.addChildColumnToParent(parentColumn, {
        text: channelMetadata.channelLabel,
        renderer: ({ record }) => this.getSegmentDisplay(record.target, record.location, record.segmentDetails?.[channelIndex]?.channelSegmentation, channelMetadata.channelObject),

        ...ColumnUtils.getFilterableColumnProperties(ALIGN_TYPES.STRING, this.translator, ({ record, value, operator }) =>
          ColumnUtils.filter(
            ALIGN_TYPES.STRING,
            this.getSegmentDisplay(record.target, record.location, record.segmentDetails?.[channelIndex]?.channelSegmentation, channelMetadata.channelObject),
            value,
            operator
          )
        ),

        sortable: (record1, record2) =>
          ColumnUtils.sort(
            ALIGN_TYPES.STRING,
            this.getSegmentDisplay(record1.target, record1.location, record1.segmentDetails?.[channelIndex]?.channelSegmentation, channelMetadata.channelObject),
            this.getSegmentDisplay(record2.target, record2.location, record2.segmentDetails?.[channelIndex]?.channelSegmentation, channelMetadata.channelObject)
          ),
      });

      channelMetadata.products.forEach((product, productIndex) => {
        ColumnUtils.addChildColumnToParent(parentColumn, {
          text: product.productLabel,
          cls: 'product-segment-column',
          cellCls: 'product-segment',
          renderer: ({ record }) =>
            this.getSegmentDisplay(record.target, record.location, record.segmentDetails?.[channelIndex]?.productSegmentations?.[productIndex], channelMetadata.channelObject),

          ...ColumnUtils.getFilterableColumnProperties(ALIGN_TYPES.STRING, this.translator, ({ record, value, operator }) =>
            ColumnUtils.filter(
              ALIGN_TYPES.STRING,
              this.getSegmentDisplay(record.target, record.location, record.segmentDetails?.[channelIndex]?.productSegmentations?.[productIndex], channelMetadata.channelObject),
              value,
              operator
            )
          ),

          sortable: (record1, record2) =>
            ColumnUtils.sort(
              ALIGN_TYPES.STRING,
              this.getSegmentDisplay(record1.target, record1.location, record1.segmentDetails?.[channelIndex]?.productSegmentations?.[productIndex], channelMetadata.channelObject),
              this.getSegmentDisplay(record2.target, record2.location, record2.segmentDetails?.[channelIndex]?.productSegmentations?.[productIndex], channelMetadata.channelObject)
            ),
        });
      });
    });

    return columns;
  }

  getSegmentDisplay(target, location, segment, channelObject) {
    const shouldDisplayNullSegmentValue = !target || (location && channelObject !== 'Call2_vod__c');
    return shouldDisplayNullSegmentValue ? NULL_DISPLAY_STRING : this.translator.localizeField(ALIGN_TYPES.STRING, segment);
  }
}