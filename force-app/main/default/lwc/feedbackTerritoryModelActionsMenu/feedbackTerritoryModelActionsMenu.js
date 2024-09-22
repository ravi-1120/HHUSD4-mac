import { api, LightningElement } from 'lwc';

export default class FeedbackTerritoryModelActionsMenu extends LightningElement {
  @api territoryModelActions = [];

  handleTerritoryModelAction(event) {
    const command = event.detail.value;
    const label = this.getLabelForAction(command);

    this.dispatchEvent(
      new CustomEvent('territorymodelaction', {
        detail: {
          command,
          label,
        },
      })
    );
  }

  getLabelForAction(commandName) {
    return this.territoryModelActions.find(action => action.name === commandName).label;
  }
}