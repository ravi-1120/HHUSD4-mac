import VeevaPageController from 'c/veevaPageController';
import isNextYearAnnualCapSettingEnabled from '@salesforce/apex/VeevaEmSpeakerCapUtil.isNextYearAnnualCapSettingEnabled';
import hasProductCapsWithFutureEndDate from '@salesforce/apex/VeevaEmSpeakerCapUtil.hasProductCapsWithFutureEndDate';

const SPEAKER_CAP_RECORD_CHANGES_HEADER_DEFAULT = 'Speaker Cap Changes';
const SPEAKER_CAP_RECORD_CHANGES_DEFAULT = 'By making this change, Speaker Cap records may be updated. Are you sure you want to continue?';

export default class EmSpeakerController extends VeevaPageController {
  initialResetMonth;
  initialResetDay;

  async initData() {
    await Promise.all([super.initData(), this.getSpeakerMessageMap()]);
    if (!this.record.isNew) {
      this.initialResetMonth = this.record.rawValue('Year_To_Date_Reset_Month_vod__c') ?? '';
      this.initialResetDay = this.record.rawValue('Year_To_Date_Reset_Day_vod__c') ?? '';
    }
  }

  async getSpeakerMessageMap() {
    const messageMap = await this.messageSvc
      .createMessageRequest()
      .addRequest('SPEAKER_CAP_RECORD_CHANGES_HEADER', 'EVENT_MANAGEMENT', SPEAKER_CAP_RECORD_CHANGES_HEADER_DEFAULT, 'productCapsImpactedHeader')
      .addRequest('SPEAKER_CAP_RECORD_CHANGES', 'EVENT_MANAGEMENT', SPEAKER_CAP_RECORD_CHANGES_DEFAULT, 'productCapsImpactedMessage')
      .sendRequest();
    this.populateMessageMap(messageMap);
  }

  populateMessageMap(messageMap) {
    this.productCapsImpactedHeader = messageMap.productCapsImpactedHeader;
    this.productCapsImpactedMessage = messageMap.productCapsImpactedMessage;
  }

  async performPreSaveConfirmationLogic() {
    let result = {
      showConfirmationModal: false,
      content: null,
    };
    const changes = super.getChanges();
    if (
      !this.record.isNew &&
      ((changes.Year_To_Date_Reset_Month_vod__c != null && changes.Year_To_Date_Reset_Month_vod__c !== this.initialResetMonth) ||
        (changes.Year_To_Date_Reset_Day_vod__c != null && changes.Year_To_Date_Reset_Day_vod__c !== this.initialResetDay))
    ) {
      const isNextYearAnnualCapEnabled = await isNextYearAnnualCapSettingEnabled();
      if (isNextYearAnnualCapEnabled) {
        const hasCapsWithFutureEndDate = await hasProductCapsWithFutureEndDate({ speakerId: this.record.fields?.Id?.value });
        if (hasCapsWithFutureEndDate) {
          result = {
            showConfirmationModal: true,
            content: {
              title: this.productCapsImpactedHeader,
              messages: [this.productCapsImpactedMessage],
              buttonHorizontalAlign: 'center',
              messageHorizontalAlign: 'left',
              size: 'small',
            },
          };
          return result;
        }
      }
    }

    return result;
  }
}