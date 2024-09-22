import DefaultListViewColumn from "./defaultListViewColumn";

export default class TimeListViewColumn extends DefaultListViewColumn {
    type = 'time';

    get _filterable() {
        return false;
    }
}