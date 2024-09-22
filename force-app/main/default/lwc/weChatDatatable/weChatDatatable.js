import LightningDatatable from 'lightning/datatable';
import textWithActionCell from './textWithActionCell.html';

export default class WeChatDatatable extends LightningDatatable {
    static customTypes = {
        textWithAction: {
            template: textWithActionCell,
            standardCellLayout: true,
            typeAttributes: ['actionLabel', 'action']
        }
    };
}