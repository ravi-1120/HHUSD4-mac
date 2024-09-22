import { api, wire, LightningElement } from 'lwc';
import CALL2_OBJECT from '@salesforce/schema/Call2_vod__c'
import CALL2_LOCATION_NAME_FIELD from '@salesforce/schema/Call2_vod__c.Location_Name_vod__c'
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getChildLocations from '@salesforce/apex/S4LChildAccountService.getChildLocations';

export default class S4lLocationSelector extends LightningElement {

    @api account;
    @api labels;

    locationNameLabel = '';

    loading = true;
    showSelector = false;

    locations = {};
    selected = null;

    @api checkValidity() {
        if(this.showSelector) {
            const dropdown = this.template.querySelector('lightning-combobox');
            if(!this.selected) {
                dropdown.setCustomValidity(this.labels.thisFieldIsRequired);
            } else {
                dropdown.setCustomValidity('');
            }
            return dropdown.reportValidity();
        } else {
            return true;
        }
    }

    @wire(getObjectInfo, { objectApiName: CALL2_OBJECT })
    async wiredObjectInfo({ error, data }) {
        if (data && data.fields && data.fields[CALL2_LOCATION_NAME_FIELD.fieldApiName]) {
            this.locationNameLabel = data.fields[CALL2_LOCATION_NAME_FIELD.fieldApiName].label;
        }
    }

    async connectedCallback() {
        let locations = await getChildLocations({accountId: this.account});
        if(locations && locations.length) {
            // initialize locations map (parent account id -> source child account record)
            locations.map(loc => loc.parent)
                .forEach(parent => this.locations[parent.Parent_Account_vod__c] = parent);
            this.loadPicklist(locations);
        } else {
            this.handleNoLocationFound();
        }
    }

    loadPicklist (locations) {
        let options = [];
        for(let location of locations) {
            let parent = location.parent;
            let id = parent.Parent_Account_vod__c;
            if(location.isDefault) {
                this.selected = id;
            }
            options.push({
                label: parent.Parent_Name_vod__c,
                value: id
            });
        }
        if(options.length > 1) {
            this.showSelector = true;
        }
        // if there's a default, dispatch the selection (user can change selection later)
        if(this.selected != null) {
            this.dispatchSelection();
        }
        this.options = options;
        this.loading = false;
    }

    handleChange = function(e) {
        this.selected = e.detail.value;
        this.dispatchSelection();
        this.checkValidity();
    }

    dispatchSelection() {
        this.loading = false;
        this.dispatchEvent(new CustomEvent('select', {
            detail: {
                selected: this.locations[this.selected]
            }
        }))
    }

    handleNoLocationFound = function() {
        this.loading = false;
        this.dispatchEvent(new CustomEvent('nolocation'));
    }

}