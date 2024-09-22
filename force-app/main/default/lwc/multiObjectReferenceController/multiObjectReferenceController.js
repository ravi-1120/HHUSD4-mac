import ReferenceController from "c/referenceController";

export default class MultiObjectReferenceController extends ReferenceController {

    #objectInfoCache = [];
    selectedObject = {};

    constructor(objectType, meta, pageCtrl, field, record) {
        super(meta, pageCtrl, field, record);
        this.objectType = objectType;
    }

    get targetSObject() {
        return this.selectedObject.value;
    }

    // override function in ReferenceController as targetSObject can change
    async getTargetObjectInfo() {
        if (!this.#objectInfoCache[this.targetSObject]) {
            this.#objectInfoCache[this.targetSObject] = await this.pageCtrl.uiApi.objectInfo(this.targetSObject);
        }
        return this.#objectInfoCache[this.targetSObject];
    }
}