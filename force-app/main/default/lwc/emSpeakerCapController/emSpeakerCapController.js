import VeevaPageController from 'c/veevaPageController';
import isNextYearAnnualCapSettingEnabled from '@salesforce/apex/VeevaEmSpeakerCapUtil.isNextYearAnnualCapSettingEnabled';

const PRODUCT_CAP_EXCEEDED_HEADER_DEFAULT = 'Reallocation Warning';
const PRODUCT_CAP_EXCEEDED_REALLOCATION_DEFAULT =
  "The speaker's predicted spend for this product cap is greater than the annual cap. Are you sure you want to continue?";
const PRODUCT_CAP_RECORD_TYPE_DEVELOPER_NAME = 'Product_Cap_vod';

export default class EmSpeakerCapController extends VeevaPageController {
  async initData() {
    await Promise.all([super.initData(), this.getSpeakerCapMessageMap()]);
  }

  getQueryFields() {
    const queryFields = super.getQueryFields();
    queryFields.push(`${this.objectApiName}.RecordType.DeveloperName`);
    return queryFields;
  }

  async getSpeakerCapMessageMap() {
    const messageMap = await this.messageSvc
      .createMessageRequest()
      .addRequest('PRODUCT_CAP_EXCEEDED_HEADER', 'EVENT_MANAGEMENT', PRODUCT_CAP_EXCEEDED_HEADER_DEFAULT, 'productCapExceededHeader')
      .addRequest('PRODUCT_CAP_EXCEEDED_REALLOCATION', 'EVENT_MANAGEMENT', PRODUCT_CAP_EXCEEDED_REALLOCATION_DEFAULT, 'productCapExceededMessage')
      .sendRequest();
    this.populateMessageMap(messageMap);
  }

  populateMessageMap(messageMap) {
    this.productCapExceededHeader = messageMap.productCapExceededHeader;
    this.productCapExceededMessage = messageMap.productCapExceededMessage;
  }

  async performPreSaveConfirmationLogic() {
    let result = {
      showConfirmationModal: false,
      content: null,
    };
    if (!this.record.isNew && PRODUCT_CAP_RECORD_TYPE_DEVELOPER_NAME === this.record.fields?.RecordType?.value?.fields?.DeveloperName?.value) {
      const doesPredictedSpendExceedAnnualCap = this.record.fields?.Predicted_Spend_vod__c?.value > this.record.fields?.Annual_Cap_vod__c?.value;
      if (doesPredictedSpendExceedAnnualCap && (await isNextYearAnnualCapSettingEnabled())) {
        result = {
          showConfirmationModal: true,
          content: {
            title: this.productCapExceededHeader,
            messages: [this.productCapExceededMessage],
            buttonHorizontalAlign: 'center',
            messageHorizontalAlign: 'left',
            size: 'small',
          },
        };
      }
    }

    return result;
  }
}