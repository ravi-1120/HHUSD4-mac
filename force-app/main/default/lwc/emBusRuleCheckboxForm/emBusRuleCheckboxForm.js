import { LightningElement, api, track } from 'lwc';

export default class EmBusRulesCheckboxForm extends LightningElement {
  @api get page() {
    return this._page;
  }
  set page(value) {
    this._page = value;
    if (value) {
      this.rows = JSON.parse(JSON.stringify(value.rows));
    }
  }

  @track rows = [];

  handleSelectAll() {
    this.rows.forEach(row => {
      if (row.name) {
        row.checked = true;
      }
    });
    this.dispatchCheckedRowsChangeEvent();
  }

  handleCheckboxChange(event) {
    if (event.target.name != null) {
      this.rows[event.target.name].checked = event.target.checked;
      this.dispatchCheckedRowsChangeEvent();
    }
  }

  dispatchCheckedRowsChangeEvent() {
    const checkedRows = this.rows.reduce((rows, curRow) => {
      if (curRow.checked) {
        rows.push(curRow.id);
      }
      return rows;
    }, []);
    this.dispatchEvent(
      new CustomEvent('selectionchange', {
        detail: { checkedRows },
      })
    );
  }
}