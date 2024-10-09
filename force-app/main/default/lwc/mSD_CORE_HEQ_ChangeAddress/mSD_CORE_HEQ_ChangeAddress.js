import { LightningElement, track, api } from 'lwc';

// Apex class
import getAddressesForAccounts from '@salesforce/apex/MSD_CORE_HEQ_CustomerController.getAddressesForAccounts';
import setDefaultAddress from '@salesforce/apex/MSD_CORE_HEQ_CustomerController.setDefaultAddress';
import updateCartAddress from '@salesforce/apex/MSD_CORE_HEQ_CustomerController.updateCartAddress';
import createOrUpdateAddress from '@salesforce/apex/MSD_CORE_HEQ_CustomerController.createOrUpdateAddress';
import deactivateAddress from '@salesforce/apex/MSD_CORE_HEQ_CustomerController.deactivateAddress';

export default class MSD_CORE_HEQ_ChangeAddress extends LightningElement {

    @api accountid;
    @api selfPrintAddress;
    @api customerId;

    @track otherAddresses = [];
    @track showSpinner = false;
    @track selectedAddressId;
    @track showOtherAddress = true;
    @track showEditAddressPopup = false;
    @track showNewAddressPopup = false;
    @track address1;
    @track address2;
    @track city;
    @track stateVal;
    @track zipVal;
    @track isEditDefault = false;
    @track inputError = false;
    @track validInputs = false;


    @track add1Obj = {label: "Address 1", minlength: 1, maxlength: 255, required: false, error: "Please enter valid Address 1"};
    @track add2Obj = {label: "Address 2 (Optional)", minlength: 1, maxlength: 255, required: false, error: "Please enter valid Address 2"};
    @track cityObj = {label: "City", minlength: 1, maxlength: 255, required: false, error: "Please enter valid City"};
    @track stateObj = {label: "State", minlength: 1, maxlength: 255, required: false, error: "Please enter valid State"};
    @track zipObj = {label: "Zip", minlength: 5, maxlength: 10, required: false, error: "Please enter valid Zip"};

    connectedCallback() {
        this.showSpinner = true;
        this.getCustomerAddress();
    }

    getCustomerAddress() {
        this.showSpinner = true;
        console.log('Account ID>>' + this.accountid);
        getAddressesForAccounts({ accountId: this.accountid, isSelfPrint: this.selfPrintAddress })
            .then(result => {
                this.otherAddresses = result;
                this.otherAddresses = result.map(account => {
                    return {
                        ...account,
                        addressList: account.addressList.map(address => {
                            return {
                                ...address,
                                class: address.isDefault ? 'address-section primary-address' : 'address-section additional-address',
                                isSelected: false
                            };
                        })
                    };
                });
                this.showSpinner = false;
                console.log('getAddressesForAccounts ----->', JSON.stringify(result));
            })
            .catch(error => {
                this.showSpinner = false;
                console.error('Error fetching getAddressesForAccounts list:', error.message);
            });
    }

    closeModal() {
        let closeModel = new CustomEvent('closemodel', { detail: true });
        this.dispatchEvent(closeModel);
    }

    submitOtherAddress() {
        let handleSubmitAddress = new CustomEvent('submitaddress', { detail: true });
        this.dispatchEvent(handleSubmitAddress);
    }

    handleDefaultAddress(event) {
        const { addid } = event.currentTarget.dataset;

        this.showSpinner = true;
        setDefaultAddress({ addressId: addid, isSelfPrint: this.selfPrintAddress })
            .then(result => {
                this.showSpinner = false;
                console.log('setDefaultAddress ----->', JSON.stringify(result));
                if (result == 'Success') this.closeModal();
            })
            .catch(error => {
                this.showSpinner = false;
                console.error('Error fetching setDefaultAddress list:', error.message);
            });
    }

    handleAddressChange(event){
        const accountId = event.currentTarget.dataset.accountId;
        const selectedAddressId = event.currentTarget.dataset.addressId;
        this.selectedAddressId = selectedAddressId;

        this.otherAddresses = this.otherAddresses.map(account => {
            if (account.id === accountId) {
                return {
                    ...account,
                    addressList: account.addressList.map(address => {
                        return {
                            ...address,
                            isSelected: address.id === selectedAddressId
                        };
                    })
                };
            }
            return account;
        });

        console.log('Accoun Id>>>' + accountId +'>>>>'+ selectedAddressId); 
    }

    handleAddressSubmit() {
        this.showSpinner = true;
        updateCartAddress({ cartAddressId: this.selectedAddressId, customerId: this.customerId, isSelfPrint: this.selfPrintAddress })
            .then(result => {
                this.showSpinner = false;
                console.log('updateCartAddress ----->', JSON.stringify(result));
                if (result == 'Success') this.submitOtherAddress();
            })
            .catch(error => {
                this.showSpinner = false;
                console.error('Error fetching updateCartAddress list:', error.message);
            });
    }

    handleEditAddress(event){
        const selectedAddressId = event.currentTarget.dataset.addressId;
        this.selectedAddressId = selectedAddressId;
        console.log('handleEdit>>>' + selectedAddressId);

        this.otherAddresses.forEach(record => {
            record.addressList.forEach(address => {
                if (address.id === selectedAddressId) {
                    console.log('handleEdit Inside>>>' + address.id);
                    this.address1 = address.street;
                    this.address2 = '';
                    this.city = address.city;
                    this.stateVal = address.state;
                    this.zipVal = address.zip;
                    this.isEditDefault = address.isDefault;
                }
            });
        });
        this.showOtherAddress = false;
        this.showEditAddressPopup = true;
    }

    handleNewAddress(event){
        this.selectedAddressId = event.currentTarget.dataset.addressId;
        this.address1 = '';
        this.address2 = '';
        this.city = '';
        this.stateVal = '';
        this.zipVal = '';
        this.isEditDefault = false;
        this.showOtherAddress = false;
        this.showNewAddressPopup = true;
    }

    closeEditPopup(){
        this.showSpinner = true;
        this.getCustomerAddress();
        this.showOtherAddress = true;
        this.inputError = false;
        this.validInputs = false;
        this.showEditAddressPopup = false;
    }

    closeNewPopup(){
        this.showSpinner = true;
        this.getCustomerAddress();
        this.showOtherAddress = true;
        this.inputError = false;
        this.validInputs = false;
        this.showNewAddressPopup = false;
    }

    handleNewCheck(event){
        this.isEditDefault = event.target.checked;
    }

    handleEditCheck(event){
        this.isEditDefault = event.target.checked;
    }

    handleSaveAddress(event) {
        this.showSpinner = true;
        console.log('Zip code>>>' + this.zipVal);
        console.log('Add Id>>>' + this.city);
        console.log('Add stateVal>>>' + this.stateVal);
        console.log('Add accountId>>>' + this.accountid);

        if (
            String(this.address1).trim() &&
            String(this.city).trim() &&
            String(this.stateVal).trim() &&
            String(this.zipVal).trim()
        ) {
            this.inputError = false;
            this.validInputs = true;
            console.log('All inputs are valid');
        } else {
            this.inputError = true;
            this.validInputs = false;
            console.log('Invalid input found');
        }

        setTimeout(() => {
            if (this.validInputs == true) {
                createOrUpdateAddress({ address1: this.address1, address2: this.address2, city: this.city, state: this.stateVal, zip: this.zipVal, isSelfPrint: this.selfPrintAddress, userOrAccountId: this.accountid, isDefault: this.isEditDefault, addressId: this.selectedAddressId })
                    .then(result => {
                        this.showSpinner = false;
                        console.log('createOrUpdateAddress ----->', JSON.stringify(result));
                        if (result == 'Success') {
                            this.getCustomerAddress();
                            this.showOtherAddress = true;
                            this.showNewAddressPopup = false;
                            this.showEditAddressPopup = false;
                        }
                    })
                    .catch(error => {
                        this.showSpinner = false;
                        console.error('Error fetching createOrUpdateAddress list:', error.message);
                    });
            } else {
                this.showSpinner = false;
            }
        }, 0);
    }

    handleInputAddress(event){
        const { label, value } = event.target;
        let trimValue = value.trim();

        if(label == this.add1Obj.label){
            this.address1 = trimValue;
        }else if(label == this.add2Obj.label){
            this.address2 = trimValue;
        }else if(label == this.cityObj.label){
            this.city = trimValue;
        }else if(label == this.stateObj.label){
            this.stateVal = trimValue;
        }else if(label == this.zipObj.label){
            this.zipVal = trimValue;
        }

        // if (
        //     String(this.address1).trim() &&
        //     String(this.city).trim() &&
        //     String(this.stateVal).trim() &&
        //     String(this.zipVal).trim()
        // ) {
        //     this.inputError = false;
        //     this.validInputs = true;
        //     console.log('All inputs are valid');
        // } else {
        //     this.inputError = true;
        //     this.validInputs = false;
        //     console.log('Invalid input found');
        // }
        
    }

    handleDeleteAddress(event){
        const selectedAddressId = event.currentTarget.dataset.addressId;
        this.selectedAddressId = selectedAddressId;
        this.showSpinner = true;

        deactivateAddress({ addressId: this.selectedAddressId })
            .then(result => {
                this.showSpinner = false;
                console.log('createOrUpdateAddress ----->', JSON.stringify(result));
                if (result == 'Success'){
                    this.getCustomerAddress();
                    this.showSpinner = false;
                }
            })
            .catch(error => {
                this.showSpinner = false;
                console.error('Error deactivateAddress: ', error.message);
            });
    }
}