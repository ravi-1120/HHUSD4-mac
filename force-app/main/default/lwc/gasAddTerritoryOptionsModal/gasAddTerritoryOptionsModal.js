import { LightningElement,api } from 'lwc';
import { getPageController } from "c/veevaPageControllerFactory";

export default class GasAddTerritoryOptionsModal extends LightningElement {
    @api userTerritories;
    selectedTerritories = [];

    // Labels using Veeva Messages
    addToTerritoryLabel = 'Add to Territory';
    cancelButtonLabel = 'Cancel';
    okayButtonLabel = 'OK';
    selectTerritoryLabel = 'Select Territories';

    async connectedCallback() {
        const veevaMessageService = getPageController('messageSvc');
        await Promise.all([
            this.loadLabels(veevaMessageService)
        ]);
    }

    get canNotPressOkay() {
        return this.selectedTerritories.length === 0;
    }

    async loadLabels(veevaMessageService) {
        await veevaMessageService.loadVeevaMessageCategories(['Common', 'Global Account Search']);

        [this.addToTerritoryLabel, this.cancelButtonLabel, this.okayButtonLabel, this.selectTerritoryLabel] = await Promise.all([
            veevaMessageService.getMessageWithDefault('GAS_ADD_TO_TERRITORY', 'Global Account Search', this.addToTerritoryLabel),
            veevaMessageService.getMessageWithDefault('CANCEL', 'Common', this.cancelButtonLabel),
            veevaMessageService.getMessageWithDefault('OK', 'Common', this.okayButtonLabel),
            veevaMessageService.getMessageWithDefault('GAS_SELECT_TERRITORIES', 'Global Account Search', this.selectTerritoryLabel),
        ]);
    }

    closeAddTerritoryOptionsModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    updateSelectedTerritories(event) {
        this.selectedTerritories = event.detail.value;
    }

    handleAddTerritories(){
        this.dispatchEvent(new CustomEvent("addterritories", {
            detail: {
              selectedTerritories: this.selectedTerritories,
            },
            bubbles: true, composed: true
          })
      );
    }
}