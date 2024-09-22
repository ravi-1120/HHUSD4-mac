import VeevaBaseController from "c/veevaBaseController";

const EXTRA_LARGE_MODAL_SIZE = 'veeva-extra-large';
const SIDE_BAR_MODAL_RATIO = ' slds-size_1-of-4';
const DETAIL_PAGE_MODAL_RATIO = ' slds-size_3-of-4';

export default class VeevaSideBarController extends VeevaBaseController {

    template;

    constructor(meta, pageCtrl) {
        super(meta, pageCtrl, pageCtrl.record);
    }

    set hasContent(value) {
        this._hasContent = value;
    }

    get hasContent() {
        return this._hasContent;
    }

    initTemplate() {
        return this;
    }

    getSideBarModalSize() {
        return EXTRA_LARGE_MODAL_SIZE;
    }

    getSideBarRatio() {
        return SIDE_BAR_MODAL_RATIO;
    }

    getDetailPageRatio() {
        return DETAIL_PAGE_MODAL_RATIO;
    }

}