import { UniqueFieldName } from 'c/myAccountsDataService';

export default class MyAccountsColumn {
  static FIELD_TYPE_TO_BRYNTUM_TYPE = new Map([
    ['double', 'number'],
    ['long', 'number'],
    ['integer', 'number'],
    ['percent', 'number'],
    ['currency', 'number'],
  ]);

  constructor(column, labels) {
    const fieldName = this._getFieldName(column);
    this.originalFieldName = column.name;
    this.objectName = column.objectName;
    this.sfDisplayType = column.fieldType;
    this.field = fieldName;
    this.prefix = this._getPrefix(column, labels);
    this.text = column.label;
    this.headerRenderer = this._getHeaderRenderer(column, labels);
    this.type = this._getBryntumType();
    this.editor = null;
    this.sortable = true;
    this.filterable = this._getBryntumFilterable();
    this.flex = 1;
    this.format = this._getBryntumFormat(column);
    this.draggable = false;
    this.isRichText = this.sfDisplayType?.toLowerCase() === 'textarea' && column.isHtmlFormatted;
    this.htmlEncode = this.isRichText || !column.isHtmlFormatted;
  }

  getFieldDefinition() {
    return { name: this.field, type: this.type };
  }

  _getBryntumFilterable() {
    return true;
  }

  _getBryntumFormat() {
    // A child class may need to define a specific type of formatting
    return undefined;
  }

  _getBryntumType() {
    return MyAccountsColumn.FIELD_TYPE_TO_BRYNTUM_TYPE.get(this.sfDisplayType?.toLowerCase());
  }

  _getFieldName(column) {
    return UniqueFieldName.create(column);
  }

  _getHeaderRenderer(columnDefinition, labels) {
    if (
      !columnDefinition.accountRelationship ||
      (columnDefinition.accountRelationship === 'Parent_Account_vod__r' && !labels?.parentLabel) ||
      (columnDefinition.accountRelationship === 'Child_Account_vod__r' && !labels?.childLabel)
    ) {
      return undefined;
    }
    return () => `<i>${this.prefix}</i>${columnDefinition.label}`;
  }

  _getPrefix(columnDefinition, labels) {
    let columnPrefix = '';
    if (labels?.parentLabel && columnDefinition.accountRelationship === 'Parent_Account_vod__r') {
      columnPrefix = labels?.parentLabel;
    } else if (labels?.childLabel && columnDefinition.accountRelationship === 'Child_Account_vod__r') {
      columnPrefix = labels?.childLabel;
    }
    return columnPrefix;
  }
}