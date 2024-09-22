export default class VeevaLayoutParser {

    layout;

    constructor(layout) {
        this.layout = layout;
    }

    parseLayout() {
        this.layout.layoutFields = {};
        this.layout.sectionSignals = {};
        (this.layout.sections || []).forEach(section => {
            this.extractFromSection(section);
            (section.layoutRows || []).forEach(row => {
                (row.layoutItems || []).forEach(item => {
                    this.layout.layoutFields[item.field] = true;
                    this.extractFromItem(item, row, section);
                });
            });
        });
    }

    extractFromSection(section) {
        // override in sub-classes
    }

    extractFromItem(item, row, section) {
        // implement in sub-classes
    }
}