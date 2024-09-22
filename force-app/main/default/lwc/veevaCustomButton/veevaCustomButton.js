import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import VeevaConstant from 'c/veevaConstant';

export default class VeevaCustomButton extends NavigationMixin(LightningElement) {
    @api meta;
    @api variant = 'neutral';
    @api pageCtrl;
    @api disableButton;

    @api
    click(){
        this.handleClick();  
    }

    async handleClick() {
        if (this.meta.pageRef) {
            this[NavigationMixin.Navigate](this.meta.pageRef);
            return;
        }

        if (this.meta.name === VeevaConstant.CLONE_VOD) {
            const state = this.pageCtrl.getDataForClone();
            const recordTypeId = state.RecordTypeId && state.RecordTypeId.value;
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: this.pageCtrl.objectApiName,
                    actionName: 'new'
                },
                state: {
                    defaultFieldValues: JSON.stringify(state),
                    recordTypeId,
                    c__inContextOfRef: JSON.stringify(this.pageCtrl.getPageRefForClose(state.cloneFromId)),
                    c__flowVariables: JSON.stringify([
                        {
                          name: 'objectApiName',
                          value: this.pageCtrl.objectApiName,
                          type: 'String',
                        },
                        {
                            name: 'selectedRecordTypeId',
                            value: recordTypeId,
                            type: 'String',
                        },
                        {
                            name: 'defaultFieldValues',
                            value: JSON.stringify(state),
                            type: 'String',
                        },
                        {
                            name: 'skipRecordTypeSelector',
                            value: true,
                            type: 'Boolean',
                        },
                    ])
                }
            });
            return;
        }

        if (this.ctrl === undefined) {
            this.ctrl = await this.pageCtrl.toButtonCtrl(this.meta);
        }
        if (this.ctrl && this.ctrl.pageRef) {
            this[NavigationMixin.Navigate](this.ctrl.pageRef);
        }
    }

    get isMenu() {
        return this.meta.menu;
    }
}