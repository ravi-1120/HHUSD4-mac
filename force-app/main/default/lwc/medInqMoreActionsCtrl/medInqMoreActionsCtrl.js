import template from "./medInqMoreActionsCtrl.html";

export default class medInqMoreActionsCtrl {
    moreActions = [];
    alignment;
    constructor(moreActions, medicalInquiryController) {
        this.moreActions = moreActions;
        if (medicalInquiryController.action === "View") {
            this.alignment = "right";
        }
    }
    get template() {
        return template;
    }
}