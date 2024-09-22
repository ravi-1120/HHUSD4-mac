export default class SchedulerManagerBase {
    translatedLabels;
    calendarObjectInfos;
    settings;
    schedulerGrid;
    schedulerPaneFooter;
    
    emptyText;

    constructor(translatedLabels, calendarObjectInfos, settings){
        this.translatedLabels = translatedLabels;
        this.calendarObjectInfos = calendarObjectInfos;
        this.settings = settings;
        
        this.emptyText = '';
    }

    showSpinner(){
        this.schedulerGrid?.maskBody?.({ text: `
            <div role="status" class="slds-spinner slds-spinner_medium slds-spinner_brand">
                <div class="slds-spinner__dot-a"></div>
                <div class="slds-spinner__dot-b"></div>
            </div>`, icon: '', mode: 'bright'});
    }

    hideSpinner(){
        this.schedulerGrid?.unmaskBody?.();
    }

    shouldUpdateOnViewChange() {
        return false;
    }
    
    getSchedulerTabFooter() {
        return null;
    }

    updateFooter() {
        if (this.schedulerPaneFooter && this.schedulerPaneFooter.items.length < 1) {
            this.schedulerPaneFooter.items = [ this.getSchedulerTabFooter() ];
        }
    }
}