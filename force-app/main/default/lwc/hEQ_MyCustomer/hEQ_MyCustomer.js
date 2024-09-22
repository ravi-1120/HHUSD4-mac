import { LightningElement, track, wire } from 'lwc';

// Custom Label
import HEQ_NoRecordFound from '@salesforce/label/c.HEQ_NoRecordFound';

// Apex Method
//import getCustomerList from '@salesforce/apex/HEQ_MyCustomerController.getCustomerList';

export default class HEQ_MyCustomer extends LightningElement {

    @track mycustomerlist = [];
    @track filteredCustomers = [];
    @track searchKey = '';
    @track norecord = false;
    @track norecordfound = HEQ_NoRecordFound;

    // ConnectedCallback
    connectedCallback(){
        this.getCustomerList();
    }

    // Get Customer List
    getCustomerList(){
        getCustomerList()
        .then(result => {
            console.log('result>>',result);
            this.mycustomerlist = result;
            this.filteredCustomers = result;
            if(this.filteredCustomers.length > 0){
                this.norecord = false;   
            } else {
                this.norecord = true;
            }
        })
        .catch(error => {
            console.log('error>>',error);
        })
    }

    // Handle Key change
    handleKeyChange(event) {
        this.searchKey = event.target.value.toLowerCase();
        console.log('searchKey>>', this.searchKey);
        this.filterCustomers();
    }

    // Filter customers based on search key
    filterCustomers() {
        if (this.searchKey) {
            this.filteredCustomers = this.mycustomerlist.filter(customer =>
                customer.Name.toLowerCase().includes(this.searchKey)
            );
        } else {
            this.filteredCustomers = this.mycustomerlist;
        }
        if(this.filteredCustomers.length > 0){
            this.norecord = false;   
        } else {
            this.norecord = true;
        }
        console.log('filteredCustomers>>', this.filteredCustomers);
    }
}