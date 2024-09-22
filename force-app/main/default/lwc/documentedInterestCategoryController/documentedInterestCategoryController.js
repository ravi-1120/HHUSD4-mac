import PicklistController from 'c/picklistController';

export default class DocumenteInterestCategoryController extends PicklistController {
    initTemplate() {
        this.multiPicklist = true;
        if(!this.pageCtrl.isNew) {
            this.editable = false;
        } else {
            this.controllingValue = 'Scientific_Interest_vod__c';
        }
        return this;
    }

    get readonly() {
        return false;
    }

    get picklists() {
        if (!this._picklists || this._picklists.length === 0) {
          return this.options().then(options => {
            this._picklists = this.getDependentOptions(options, this.controllingValue);
            return this._picklists;
          });
        }
        return this._picklists;
    }

    set picklists(value) {
        this._picklists = value;
    }

    track(element, funcName) {
        this.pageCtrl.track('Scientific_Interest_vod__c', element, funcName);
    }

    get controllerLabel() {
        return '';
    }

    async options() {
        if (!this._picklists || this._picklists.values.length === 0) {
          const picklists = await this.pageCtrl.getPicklistValues(this.meta.field, this.recordTypeId);
          this._metaOptions = picklists;
        }
        return this._metaOptions;
      }
}