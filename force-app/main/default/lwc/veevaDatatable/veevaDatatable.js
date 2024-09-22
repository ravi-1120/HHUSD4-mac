import LightningDatatable from 'lightning/datatable';
import { api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import veevaDatatableChannel from '@salesforce/messageChannel/Veeva_Datatable_Channel__c';
import nameLinkCell from './nameLinkCell.html';
import textCell from './textCell.html';
import numberCell from './numberCell.html';
import lookupCell from './lookupCell.html';
import richText from './richText.html';

export default class VeevaDatatable extends LightningDatatable {
  @wire(MessageContext)
  messageContext;

  editPanelOpen = false;

  static customTypes = {
    nameLink: {
      template: nameLinkCell,
      typeAttributes: ['id', 'veevaIcon'],
    },
    picklist: {
      /*
       * Generally, editTemplate is the recommended way to have inline edit functionality
       * However, multi-selecting rows with pick lists and lookups does not work OOTB as of Winter 23
       * Thus, custom edit functionality is in veevaDatatableEditPanel
       */
      template: textCell,
      standardCellLayout: false,
      typeAttributes: ['editable', 'displayReadOnlyIcon', 'iconName', 'iconVariant', 'helptext', 'helptextVariant'],
    },
    lookup: {
      template: lookupCell,
      standardCellLayout: false,
      typeAttributes: ['editable', 'displayReadOnlyIcon', 'useClickEvent'],
    },
    veevaCurrency: {
      /*
       * Standard Currency data type does not support multi-currency formatting, i.e. 'USD 100 (EUR 97)'
       * Native standard is to render text in template and number field when editing
       */
      template: textCell,
      standardCellLayout: false,
      typeAttributes: ['editable', 'displayReadOnlyIcon'],
    },
    richText: {
      template: richText,
      standardCellLayout: true,
    },
    veevaNumber: {
      /*
       * Standard Percent data type scales percent fields up by 100
       * Custom number field can be used with formatter of 'percent-fixed' to avoid scaling issue
       */
      template: numberCell,
      standardCellLayout: false,
      typeAttributes: ['editable', 'displayReadOnlyIcon', 'formatter', 'scale'],
    },
    veevaTextArea: {
      /*
       * Lightning Datatable does not support editing Text Area Fields out of the box
       * Use veevaDatatableTextAreaEdit component instead
       */
      template: textCell,
      standardCellLayout: false,
      typeAttributes: ['editable', 'displayReadOnlyIcon'],
    },
  };

  @api toggleEditPanel() {
    this.editPanelOpen = !this.editPanelOpen;
  }

  handleHorizontalScroll(event) {
    super.handleHorizontalScroll(event);
    this.publishScrollEvent();
  }

  handleVerticalScroll(event) {
    super.handleVerticalScroll(event);
    this.publishScrollEvent();
  }

  publishScrollEvent() {
    if (this.editPanelOpen) {
      // Due to this known issue: https://github.com/salesforce/lwc/issues/1666
      // We cannot dispatch events from elements extending LightningDatatable without enabling Lightning Web Security
      // We are using the message service as a workaround
      publish(this.messageContext, veevaDatatableChannel, { action: 'scroll' });
    }
  }
}

const setFormulaLinkFields = (objectInfoFields, columns) => {
  columns.forEach(column => {
    if (objectInfoFields?.[column.fieldName]?.htmlFormatted) {
      column.type = 'richText';
    }
  });
};

export { setFormulaLinkFields };