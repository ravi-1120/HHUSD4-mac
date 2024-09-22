import DefaultListViewColumn from "./defaultListViewColumn";

export default class EmailListViewColumn extends DefaultListViewColumn {

    htmlEncode = false;
    
    _renderer({ value }) {
        return value?.value ? `<a href="mailto:${value.value}" target="_blank">${value.value}</a>` : null;
    }
}