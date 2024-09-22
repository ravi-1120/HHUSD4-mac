import DefaultListViewColumn from "./defaultListViewColumn";

export default class StandardReferenceListViewColumn extends DefaultListViewColumn {

    htmlEncode = false;
    
    _renderer({ column: { field }, record }) { 
        return record[field]?.displayValue;
    }
}