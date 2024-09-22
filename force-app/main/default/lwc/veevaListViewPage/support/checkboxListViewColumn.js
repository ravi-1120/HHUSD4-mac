import DefaultListViewColumn from "./defaultListViewColumn";

export default class CheckboxListViewColumn extends DefaultListViewColumn {
    
    align = 'center';

    _renderer({ value }) {
        return {
            tag: 'i',
            className: {
                'b-fa': true,
                'b-fa-check': Boolean(value?.value),
            },
        }
    }
}