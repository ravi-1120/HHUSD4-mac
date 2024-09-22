import CheckboxListViewColumn from './checkboxListViewColumn';
import DateTimeListViewColumn from './dateTimeListViewColumn';
import DefaultListViewColumn from './defaultListViewColumn';
import EmailListViewColumn from './emailListViewColumn';
import NameListViewColumn from './nameListViewColumn';
import NumberListViewColumn from './numberListViewColumn';
import ReferenceListViewColumn from './referenceListViewColumn';
import StandardReferenceListViewColumn from './standardReferenceListViewColumn';
import TimeListViewColumn from './timeListViewColumn';
import UrlListViewColumn from './urlListViewColumn';

const createColumn = (field, label, objectInfo) => {
    const fieldType = objectInfo.fields[field]?.dataType?.toLowerCase();
    let column;
    if (field === 'Name') {
        column = new NameListViewColumn(field, label); 
    } else if (field !== 'RecordType.Name' && field.endsWith('Name')) {
        column = new ReferenceListViewColumn(field, label); 
    } else if (field.includes('.')) { // standard relation fields like RecordType.Name or Owner.Alias that don't need to be links
        column = new StandardReferenceListViewColumn(field, label);
    } else if (fieldType === 'email') {
        column = new EmailListViewColumn(field, label);
    } else if (fieldType === 'url') {
        column = new UrlListViewColumn(field, label);
    } else if (fieldType === 'boolean') {
        column = new CheckboxListViewColumn(field, label);
    } else if (fieldType === 'time') {
        column = new TimeListViewColumn(field, label);
    } else if (['date', 'datetime'].includes(fieldType)) {
        column = new DateTimeListViewColumn(field, label, fieldType);
    } else if (['double', 'long', 'percent', 'integer', 'currency'].includes(fieldType)) {
        column = new NumberListViewColumn(field, label);
    } else {
        column = new DefaultListViewColumn(field, label);
    }
    return column;
}

const formatData = (record, fields) => {
    const row = {};
    [{ field: 'Id' }, ...fields].filter(f => f.field).forEach(({ field }) => {
        if (field.includes('.')) {
            const [ reference, fieldOnReference ] = field.split('.');
            if ('Name' === fieldOnReference) {
                row[field] = { 
                    displayValue: record[reference].displayValue
                };
            } else { // Other standard field relations e.g. Owner.Alias
                row[field] = { 
                    displayValue: record[reference].value?.fields?.[fieldOnReference]?.value 
                };
            }
            row[field].value = record[reference].value?.fields?.Id?.value;
        } else {
            row[field] = record[field];
            if (!row[field]?.displayValue) {
                row[field].displayValue = row[field].value;
            }
        }
    });
    return row;
}

export { createColumn, formatData };