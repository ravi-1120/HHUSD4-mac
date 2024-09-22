import BaseButtonController from './baseButtonController';

export default class EventSpeakerButtonController extends BaseButtonController {
  navigationHandlers = {
    Link_Contract_vod: this.getLinkContractUrl,
    Manage_Contracts_vod: this.getManageContractsUrl,
  };

  getLinkContractUrl() {
    return EventSpeakerButtonController.constructVfpPageRef('EM_Link_Contract_vod', { id: this.recordId });
  }

  getManageContractsUrl() {
    return EventSpeakerButtonController.constructVfpPageRef('EM_Manage_Contracts_vod', { id: this.recordId });
  }
}