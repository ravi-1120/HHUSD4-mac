export default class DefaultListViewColumn {

    flex = 1;
    cellCls = 'hide-column-dividers';
    htmlEncode = true;

    constructor(field, label) {
        this.id = field;
        this.text = label;
        this.field = field;
        this.editor = null;
        this.draggable = false;
        this.sortable = this._sortable;
        this.filterable = this._filterable;
        this.renderer = this._renderer;
    }

    _renderer({ value }) {
        return value?.displayValue ?? value?.value;
    }

    _filterable({ value, record, property}) {
        return record[property]?.displayValue && record[property]?.displayValue.toLowerCase().includes(value.toLowerCase());
    }

    _sortable() {
        return 0;
    }
}