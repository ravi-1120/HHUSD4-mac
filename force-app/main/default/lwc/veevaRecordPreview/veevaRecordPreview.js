import { LightningElement, api, track } from 'lwc';
import VeevaUtils from 'c/veevaUtils';

export default class VeevaRecordPreview extends LightningElement {
    @track selected = {};
    @track showAvatar = false;
    avatarUrl;
    avatarStyle;

    get name() {
        if (this.selected.name) {
            return this.selected.name;
        }
        return this.ctrl.selected.name;
    }
    @api
    get ctrl() {
        return this._ctrl;
    }
    set ctrl(value) {
        this._ctrl = value;
        this.assignDependentProperties(value);
    }
    get url() {
        let recordUrl = '';
        if (this._isValidRecord()) {
            recordUrl = `/${this.ctrl.selected.id}`;
        }
        return recordUrl;
    }

    get extra() {
        let extraText = '';
        if (this._isValidRecord()) {
            extraText = this.ctrl.extra;
        }
        return extraText;
    }

    get isRecordType() {
        return this.ctrl.relationshipName === 'RecordType';
    }

    async assignDependentProperties(value) {
        await this.getMissingName(value);
        this.getAvatar();
    }

    isNotValidName() {
        if (this.ctrl.selected.id) {
            return (!this.ctrl.selected.name) || (this.ctrl.selected.id === this.ctrl.selected.name);
        }
        return false;
    }

    _isValidRecord() {
        return this.name && VeevaUtils.validSfdcId(this.ctrl.selected.id);
    }
    async getMissingName(currCtrl) {
        if (this.isNotValidName()) {
            const selObj = currCtrl.selected;
            await populateMissingName(selObj, currCtrl.nameField, currCtrl.pageCtrl.uiApi, currCtrl)
            this.selected = selObj;
        }
        else {
            this.selected = currCtrl.selected;
        }
        async function populateMissingName(selectedObj, nameField, uiApi, referenceController) {
            let objectApiName = selectedObj.apiName ;
            if (!objectApiName) {
                objectApiName = await referenceController.getReferencedObjectApiName();
            }

            if (objectApiName) {
                const data = await VeevaUtils.to(uiApi.getRecord(selectedObj.id, [`${objectApiName}.${nameField}`], true));
                const value = data?.[1]?.fields?.[nameField]?.displayValue || data?.[1]?.fields?.[nameField]?.value;
                if (value) {
                    selectedObj.name = value;
                }
            }
        }
    }

    getAvatar() {
        const { id } = this.selected;

        if(VeevaUtils.isUser(id)) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                this.ctrl.pageCtrl.uiApi.getRecord(id, ['User.SmallPhotoUrl'], true).then(userRecord => {
                    if (userRecord?.fields?.SmallPhotoUrl?.value) {
                        this.avatarUrl = userRecord.fields.SmallPhotoUrl.value;
                        this.avatarStyle = 'slds-m-right_x-small';
                        this.showAvatar = true;
                    }
            })}, 100);            
        }
    }
}