import { LightningElement, api } from 'lwc';

const NAME = 'name';
const ADDRESS = 'addresses';
const EMAIL = 'emails';
const PHONE = 'phoneNumbers';
export default class EmReconciliationHighlightedText extends LightningElement {

    @api terms;
    @api type;
    @api set value(value) {
        if (Array.isArray(value)) {
            this._value = value;
        } else if (value) {
            this._value = [ value ];
        } else {
            this._value = [];
        }
    }
    get value() {
        return this._value;
    }
    lines = [];

    connectedCallback() {
        let fn;
        switch(this.type) {
            case NAME:
                fn = this.buildName;
                break;
            case ADDRESS:
                fn = this.buildAddress;
                break;
            case EMAIL:
                fn = this.buildEmail;
                break;
            case PHONE:
                fn = this.buildPhone;
                break;
            default:
                fn = this.buildCustomField;
        }
        this.lines = this.value.map((obj, idx) => ({
            id: idx,
            text: fn.call(this, obj)
        }));
    }

    buildName(obj) {
        const { firstName, lastName, parentName } = obj;
        const { firstName: firstNameSearch, lastName: lastNameSearch } = this.terms;

        let name = this.highlight(lastName, lastNameSearch);
        if (firstName) {
            name += `, ${this.highlight(firstName, firstNameSearch)}`;
        }
        if(parentName) {
            name += ` @ ${parentName}`;
        }
        return name;
    }

    buildAddress(obj) {
        const { addressLine1, addressLine2, city, state, country, zip } = obj;
        const { city: citySearch, zip: zipSearch } = this.terms;
        const fullAddress = [addressLine1, addressLine2, this.highlight(city, citySearch), state, this.highlight(zip, zipSearch), country];
        return fullAddress.filter(addressPart => addressPart).join(' ');
    }

    buildEmail(obj) {
        const email = obj;
        const { email: emailSearch } = this.terms;
        return this.highlight(email, emailSearch);
    }

    buildPhone(obj) {
        const { phone: phoneSearch} = this.terms;
        let phone = obj;
        if (phone && phoneSearch) {
            const regex = /[\s()-]/g;
            const rawResult = phone.replace(regex, '');
            const rawTerm = phoneSearch.replace(regex, '');
            phone = this.highlight(rawResult, rawTerm, phone);
        }
        return phone;
    }

    buildCustomField(obj) {
        let field = obj;
        const term = this.terms[this.type];
        if (field && term) {
            field = this.highlight(field, term);
        }
        return field;
    }

    // eslint-disable-next-line class-methods-use-this
    highlight(a, b, toHighlight) {
        let text = toHighlight ?? a; // if toHighlight is provided use for display value, otherwise first arg
        if (a && b && a.toLowerCase().trim() === b.toLowerCase().trim()) {
            text = `<span style="color: var(--veeva-highlight-text-color)">${text}</span>`;
        }
        return text;
    };


    
}