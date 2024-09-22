import LightningDatatable from 'lightning/datatable';
import { api } from 'lwc';
import nameDetailsTemplate from './nameDetails.html';
import customCheckboxTemplate from './customCheckbox.html';
import lookupName from './lookupName.html';
import richText from './richText.html';
import customButtonIcon from './customButtonIcon.html';

export default class EmSelectionPageDatatable extends LightningDatatable {
  @api scrollListener;
  initialRender = true;

  static customTypes = {
    nameDetails: {
      template: nameDetailsTemplate,
      standardCellLayout: true,
      typeAttributes: ['id', 'icon'],
    },
    customCheckbox: {
      template: customCheckboxTemplate,
      standardCellLayout: true,
      typeAttributes: ['disabled', 'id'],
    },
    lookup: {
      template: lookupName,
      standardCellLayout: true,
      typeAttributes: ['lookupRecord'],
    },
    richText: {
      template: richText,
      standardCellLayout: true,
    },
    customButtonIcon: {
      template: customButtonIcon,
      standardCellLayout: true,
      typeAttributes: ['id'],
    },
  };

  renderedCallback() {
    if (super.renderedCallback) {
      super.renderedCallback();
    }
    if (this.initialRender) {
      this.initialRender = false;
      const scrollTable = this.template.querySelector('.slds-scrollable_y');
      if (scrollTable) {
        scrollTable.addEventListener('scroll', this.scrollListener);
      }
    }
  }
}