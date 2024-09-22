import { LightningElement, api, track, wire } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import EDIT_REDIRECT_STYLE from '@salesforce/resourceUrl/emEventAttendeeEditRedirect';
import TEAM_MEMBER_EVENT_FIELD from '@salesforce/schema/EM_Event_Team_Member_vod__c.Event_vod__c';
import TEAM_MEMBER_EVENT_NAME_FIELD from '@salesforce/schema/EM_Event_Team_Member_vod__c.Event_vod__r.Name';

export default class EmEventAttendeeEditRedirect extends NavigationMixin(LightningElement) {    
    @api recordId;
    @api objectApiName;

    @track showEdit = true;
    @track showNew = false;
    @track loading = true;

    pageReference;
    justDispatchClose = true;
    eventTeamMemberId;

    SHOW_NEW_DEBOUNCE = 100;

    async connectedCallback() {
        await loadStyle(this, EDIT_REDIRECT_STYLE);
    }

    onLoaded() {
        this.loading = false;
    }

    async onClose(event) {
        const saveAndNew = event.detail?.saveAndNew;
        this.showEdit = false;
        this.showNew = false;
        
        if (saveAndNew) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(async () => {
                this.pageReference = {
                    state: {},
                    attributes: { objectApiName: this.objectApiName }
                };
                if (this.objectApiName === 'EM_Event_Team_Member_vod__c') {
                    this.eventTeamMemberId = event.detail.id;
                } else {
                    this.showNew = true;
                }
            }, this.SHOW_NEW_DEBOUNCE);    
        } else {
            window.history.go(-1);
        }
    }

    @wire(getRecord, { recordId: '$eventTeamMemberId', fields: [TEAM_MEMBER_EVENT_FIELD, TEAM_MEMBER_EVENT_NAME_FIELD] })
    wireGetEventTeamMemberEventInfo({ data, error }) {
        if (data) {
            this.pageReference.state = {
                inContextOfRef: {
                    attributes: {},
                    emDefaultFieldValues: {
                        Event_vod__c: {
                            value: data.fields.Event_vod__c.value,
                            displayValue: data.fields.Event_vod__r.displayValue
                        }
                    }
                }
            };
            this.showNew = true;
        } else if (error) {
            // eslint-disable-next-line no-console
            console.error(error);
            this.showNew = true;
        }
    }
}