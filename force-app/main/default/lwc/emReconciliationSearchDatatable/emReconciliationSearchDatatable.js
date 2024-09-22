import LightningDatatable from 'lightning/datatable';
import reconciliationSearch from './reconciliationSearch.html';

export default class EmReconciliationSearchDatatable extends LightningDatatable {

    static customTypes = {
        reconciliation: {
            template: reconciliationSearch,
            standardCellLayout: false,
            typeAttributes: ['terms', 'type']
        }
    }
    
}