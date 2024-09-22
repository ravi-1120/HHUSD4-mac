export default class TerritoryModelCommand {
  constructor(territoryFeedbackBasePage, targetTerritoryModel, label) {
    this.territoryFeedbackPage = territoryFeedbackBasePage;
    this.targetTerritoryModel = targetTerritoryModel;
    this.commandLabel = label;
  }

  get messageService() {
    return this.territoryFeedbackPage.messageService;
  }

  modalTitle() {
    return this.commandLabel;
  }

  modalBody() {
    return [];
  }

  modalType() {
    return null;
  }

  async showModal(onConfirmCallback) {
    this.territoryFeedbackPage.showModal(
      {
        type: this.modalType(),
        title: this.modalTitle(),
        body: await this.modalBody(),
      },
      onConfirmCallback
    );
  }

  async execute() {
    // To be implemented by subclasses
  }
}