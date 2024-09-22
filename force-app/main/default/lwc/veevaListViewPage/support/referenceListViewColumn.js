import DefaultListViewColumn from "./defaultListViewColumn";

export default class ReferenceListViewColumn extends DefaultListViewColumn {

    htmlEncode = false;
    
    _renderer({ column: { field }, record }) {
        const recordValue = record[field];
        return recordValue?.value && recordValue?.displayValue ? `<a href="/lightning/r/${recordValue.value}/view" title="${recordValue.displayValue}">${recordValue.displayValue}</a>` : null;
    }
}