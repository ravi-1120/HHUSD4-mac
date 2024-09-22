export default class VeevaLayoutAdapter{

    layout;
    pageController;
    
    constructor(layout, pageController) {
        this.init(layout, pageController);
    }
 
    init(layout, pageController) {
        this.layout = layout;
        this.pageController = pageController;
    }

    processLayout() {
        (this.layout.sections || []).forEach(section => {
            this.processSection(section);
            (section.layoutRows || []).forEach(row => {
                (row.layoutItems || []).forEach(item => {
                    this.processItem(item, row);
                });
            });
        });
        this.removeLayoutComponents();
    }

    removeLayoutComponents() {
        const layoutSections = this.layout.sections || [];
        for (let i = layoutSections.length - 1; i >= 0; i--) {
            const section = layoutSections[i];
            if (this.removeSection(section)) {
                layoutSections.splice(i, 1);
            } else {
                const sectionRows = section.layoutRows || [];
                for (let j = sectionRows.length - 1; j >= 0; j--) {
                    const row = section.layoutRows[j];
                    const rowItems = row.layoutItems || [];
                    let emptyItemsCount = 0;
                    for (let k = rowItems.length - 1; k >= 0; k--) {
                        const item = rowItems[k];
                        if (this.removeItem(item)) {
                            rowItems.splice(k, 1);
                        } else if(this._isEmptyItem(item)) {
                            emptyItemsCount += 1;
                        }
                    }
                    if (row.layoutItems.length === 0 || emptyItemsCount === row.layoutItems.length) {
                        sectionRows.splice(j, 1);
                    }
                }
                if (sectionRows.length === 0) {
                    layoutSections.splice(i, 1);
                }
            }
        }
    }

    processSection(section) {
        // override in sub-classes
    }

    processItem(item, row) {
        // implement in sub-classes
    }

    removeSection(section) {
        return false;
    }

    removeItem(item) {
        return false;
    }

    getLayout() {
        return this.layout;
    }

    _isEmptyItem(item){
        return item.layoutComponents && item.layoutComponents[0].componentType === 'EmptySpace';
    }
}