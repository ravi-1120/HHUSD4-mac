import LOCALE from '@salesforce/i18n/locale';

import MyAccountsColumn from "./myAccountsColumn";

export default class MyAccountsNumberColumn extends MyAccountsColumn {
    constructor(column, labels) {
        super(column, labels);
        this.sortable = this._sort;
        this.scale = column.scale;
    }

    _getBryntumFormat(column) {
        const fraction = column.scale
        if (column.fieldType === 'percent') {
            return {
                fraction,
                format(value) {
                    return Intl.NumberFormat(LOCALE.replace('_', '-'), {
                        maximumFractionDigits: this.fraction,
                        minimumFractionDigits: this.fraction,
                        style: 'percent'
                    }).format(value / 100);
                }
            }
        }
        return {
            fraction,
            format(value) {
                return Intl.NumberFormat(LOCALE.replace('_', '-'), {
                    maximumFractionDigits: this.fraction,
                    minimumFractionDigits: this.fraction,
                }).format(value);
            }
        };
    }

    _sort(left, right) {
        const leftValue = left.get(this.field);
        const rightValue = right.get(this.field);

        const leftNumber = leftValue === 0 || leftValue ? leftValue : Number.MIN_SAFE_INTEGER;
        const rightNumber = rightValue === 0 || rightValue ? rightValue : Number.MIN_SAFE_INTEGER;

        let comparison = 0;
        if(leftNumber > rightNumber) {
            comparison = 1;
        } else if(leftNumber < rightNumber) {
            comparison = -1;
        }
        return comparison;
    }
}