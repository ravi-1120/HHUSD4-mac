import DefaultListViewColumn from "./defaultListViewColumn";

export default class NameListViewColumn extends DefaultListViewColumn {

    flex = 1.5;
    htmlEncode = false;
    
    _renderer({ record, value }) {
        return `<a href="/lightning/r/${record.Id.value}/view" title="${value.value}">${value.value}</a>`;
    }
}