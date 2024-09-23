import { LightningElement, track, wire, api } from 'lwc';

// Custom Label
import HEQ_NoRecordFound from '@salesforce/label/c.MSD_CORE_HEQ_NoRecordFound';
import isInvitedMsg from '@salesforce/label/c.MSD_CORE_HEQ_IsInvitedMsg';
import recordPerPage from '@salesforce/label/c.MSD_CORE_HEQ_RecordPerPage';
import pageOption from '@salesforce/label/c.MSD_CORE_HEQ_PageOption';
import recordsperpage from '@salesforce/label/c.MSD_CORE_HEQ_AllResourceRecordPerPage';
// Apex class
import getCustomerList from '@salesforce/apex/MSD_CORE_HEQ_CustomerController.getCustomerList';
import sendRegistrationInvite from '@salesforce/apex/MSD_CORE_HEQ_AuthController.sendRegistrationInvite';

export default class MSD_CORE_HEQ_Customer extends LightningElement {

    @api mainHeader;
    @api isFooterbutton;
    @api isRegisterUserOnly;
    @api footerbtnname;
    @api customertype;
    @api feature;
    @api hideAddRecipient;

    // Pagination
    @track isPagination = true;
    @track totalRecords = 0;
    @track totalPages = 1;
    @track currentPage = 1;
    @track recordsPerPage = recordsperpage;
    @track recordsPageOptions = [];
    @track searchCategory = [];
    @track mycustomerlist = [];
    @track newRecipients = [];
    @track searchKey = '';
    @track norecordfound = HEQ_NoRecordFound;
    @track isCustomer = false;
    @track activeTab = 'register';
    @track filterLayout = false;
    @track unfilterLayout = false;


    @track selectedCustomers = [];
    @track registeredCustomers = [];
    @track unregisteredCustomers = [];
    @track paginatedRegisteredCustomers = [];
    @track paginatedUnregisteredCustomers = [];
    @track currentPageRegistered = 1;
    @track totalPagesRegistered = 0;
    @track recordsPerPageRegistered = recordPerPage;
    @track noRegisteredRecords = false;
    @track noUnregisteredRecords = false;
    @track currentPageUnregistered = 1;
    @track totalPagesUnregistered = 0;
    @track recordsPerPageUnregistered = recordPerPage;
    @track isLastPageUnregistered;
    @track isFirstPageUnregistered;
    @track isFirstPageRegistered;
    @track isLastPageRegistered;
    recordsPerPageOptions = [];
    totalRegisteredRecords = 0;
    totalUnregisteredRecords = 0;
    showSpinner = false;


    labels = {
        isInvitedMsg
    };

    // ConnectedCallback
    connectedCallback() {
        this.getCustomerList();
        if (this.customertype == 'registered') {
            this.filterLayout = true;
        } else if (this.customertype == 'allcustomers') {
            this.unfilterLayout = true;
        }

        const optionval = pageOption.split(',');
        this.recordsPerPageOptions = optionval.map(option => {
            return { label: option.trim(), value: option.trim() };
        });
    }

    get isBothFalse() {
    return !this.filterLayout && !this.unfilterLayout;
}

    addRecipient() {
        const newRecipient = {
            FirstName: 'First Name',
            LastName: 'Last Name',
            Email: 'Email@example.com',
            LastLoginDate: null
        };

        this.mycustomerlist = [...this.mycustomerlist, newRecipient];
    }

    getCustomerList() {
        getCustomerList()
            .then(result => {
                console.log('result----->' + JSON.stringify(result));
                if (result.length == 0) {
                    this.isCustomer = false;
                } else {
                    this.isCustomer = true;
                }
                this.mycustomerlist = result;
                console.log('this.mycustomerlist------->' + JSON.stringify(this.mycustomerlist));
                this.filterAndPaginateCustomers();
            })
            .catch(error => {
                console.error('Error fetching customer list:', error);
            });
    }


    filterAndPaginateCustomers() {
        const searchKeyLower = this.searchKey.toLowerCase();

        this.registeredCustomers = this.mycustomerlist
            .filter(customer => customer.IsRegister)
            .filter(customer =>
                (customer.FirstName && customer.FirstName.toLowerCase().includes(searchKeyLower)) ||
                (customer.LastName && customer.LastName.toLowerCase().includes(searchKeyLower)) ||
                (customer.Email && customer.Email.toLowerCase().includes(searchKeyLower))
            );

        this.unregisteredCustomers = this.mycustomerlist
            .filter(customer => !customer.IsRegister)
            .filter(customer =>
                (customer.FirstName && customer.FirstName.toLowerCase().includes(searchKeyLower)) ||
                (customer.LastName && customer.LastName.toLowerCase().includes(searchKeyLower)) ||
                (customer.Email && customer.Email.toLowerCase().includes(searchKeyLower))
            );
        if (this.customertype === 'allcustomers') {
            this.allCustomers = [...this.registeredCustomers, ...this.unregisteredCustomers];
        }
        console.log('this.allCustomers>>>'+JSON.stringify(this.allCustomers));

        this.totalRegisteredRecords = this.registeredCustomers.length;
        this.totalUnregisteredRecords = this.unregisteredCustomers.length;

        this.calculatePagination();
        this.noRegisteredRecords = this.registeredCustomers.length === 0;
        this.noUnregisteredRecords = this.unregisteredCustomers.length === 0;
        this.noRecordsFound = this.noRegisteredRecords && this.noUnregisteredRecords;
    }

    calculatePagination() {
        this.totalPagesRegistered = Math.ceil(this.totalRegisteredRecords / parseInt(this.recordsPerPageRegistered));
        this.updatePaginatedRegisteredCustomers();

        this.totalPagesUnregistered = Math.ceil(this.totalUnregisteredRecords / parseInt(this.recordsPerPageUnregistered));
        this.updatePaginatedUnregisteredCustomers();
        console.log('>>>this.currentPageUnregistered>>>' + this.currentPageUnregistered);
        console.log('>>>this.totalPagesUnregistered>>>' + this.totalPagesUnregistered);
        if (this.currentPageRegistered == 1) {
            this.isFirstPageRegistered = true;
            this.isLastPageRegistered = false;
        } else {
            if (this.currentPageRegistered == this.totalPagesRegistered) {
                this.isLastPageRegistered = true;
                this.isFirstPageRegistered = false;
            } else {
                this.isLastPageRegistered = false;
            }
        }
        if (this.totalPagesRegistered == 1 || this.totalPagesRegistered == 0) {
            this.isLastPageRegistered = true;
        }
        if (this.currentPageUnregistered == 1) {
            this.isFirstPageUnregistered = true;
            this.isLastPageUnregistered = false;
        } else {
            if (this.currentPageUnregistered == this.totalPagesUnregistered) {
                this.isLastPageUnregistered = true;
                this.isFirstPageUnregistered = false;
            } else {
                this.isLastPageUnregistered = false;
            }
        }
        if (this.totalPagesUnregistered == 1 || this.totalPagesUnregistered == 0) {
            this.isLastPageUnregistered = true;
        }
    }

    updatePaginatedRegisteredCustomers() {
        const startIdx = (this.currentPageRegistered - 1) * parseInt(this.recordsPerPageRegistered);
        const endIdx = startIdx + parseInt(this.recordsPerPageRegistered);
        this.paginatedRegisteredCustomers = this.registeredCustomers.slice(startIdx, endIdx);
        this.noRegisteredRecords = this.paginatedRegisteredCustomers.length === 0;
    }

    updatePaginatedUnregisteredCustomers() {
        const startIdx = (this.currentPageUnregistered - 1) * parseInt(this.recordsPerPageUnregistered);
        const endIdx = startIdx + parseInt(this.recordsPerPageUnregistered);
        this.paginatedUnregisteredCustomers = this.unregisteredCustomers.slice(startIdx, endIdx);
        this.noUnregisteredRecords = this.paginatedUnregisteredCustomers.length === 0;
    }

    addRecipient() {
        const newRecipient = {
            FirstName: '',
            LastName: '',
            Email: '',
            LastLoginDate: null,
            IsNew: true
        };

        this.newRecipients = [...this.newRecipients, newRecipient];
    }

    removeRecipient(event) {
        const recipientId = event.currentTarget.dataset.id;
        this.newRecipients = this.newRecipients.filter(recipient => recipient.Id !== recipientId);
    }


    // handleRecipient(event) {
    //     const field = event.target.name;
    //     const recipientId = event.target.dataset.id;
    //     this.newRecipients = this.newRecipients.map(recipient => {
    //         if (recipient.Id === recipientId) {
    //             recipient[field] = event.target.value;
    //         }
    //         return recipient;
    //     });
    // }

    handleRecipient(event) {
    const field = event.target.name;
    const recipientId = event.target.dataset.id;

    this.newRecipients = this.newRecipients.map(recipient => {
        if (recipient.Id === recipientId) {
            // Update the field value
            recipient[field] = event.target.value;

            // Validation Logic
            if (field === 'FirstName') {
                recipient.firstNameError = !recipient.FirstName; 
            } else if (field === 'LastName') {
                recipient.lastNameError = !recipient.LastName; 
            } else if (field === 'Email') {
                 if (recipient.Email) { 
                    const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                    recipient.emailError = !emailPattern.test(recipient.Email); 
                } else {
                    recipient.emailError = false; 
                }
        }
    }
        return recipient;
    });
}



    handleSearchKeyChange(event) {
        this.searchKey = event.target.value;
        this.filterAndPaginateCustomers();
    }

    handlePreviousPageRegistered() {
        if (this.currentPageRegistered > 1) {
            this.currentPageRegistered -= 1;
            this.updatePaginatedRegisteredCustomers();
        }
        if (this.currentPageRegistered == 1) {
            this.isFirstPageRegistered = true;
            this.isLastPageRegistered = false;
        } else {
            this.isFirstPageRegistered = false;
        }
        if (this.currentPageRegistered == this.totalPagesRegistered) {
            this.isLastPageRegistered = true;
            this.isFirstPageRegistered = false;
        } else {
            this.isLastPageRegistered = false;
        }
    }

    handleNextPageRegistered() {
        if (this.currentPageRegistered < this.totalPagesRegistered) {
            this.currentPageRegistered += 1;
            this.updatePaginatedRegisteredCustomers();
        }
        if (this.currentPageRegistered == 1) {
            this.isFirstPageRegistered = true;
            this.isLastPageRegistered = false;
        } else {
            this.isFirstPageRegistered = false;
        }
        if (this.currentPageRegistered == this.totalPagesRegistered) {
            this.isLastPageRegistered = true;
            this.isFirstPageRegistered = false;
        } else {
            this.isLastPageRegistered = false;
        }
    }

    handlePageChangeRegistered(event) {
        const pageNumber = parseInt(event.target.dataset.id, 10);
        this.currentPageRegistered = pageNumber;
        this.updatePaginatedRegisteredCustomers();
    }

    handleRecordsPerPageRegisteredChange(event) {
        this.recordsPerPageRegistered = event.target.value, 10;
        this.currentPageRegistered = 1;
        this.calculatePagination();
    }

    handlePreviousPageUnregistered() {
        if (this.currentPageUnregistered > 1) {
            this.currentPageUnregistered -= 1;
            this.updatePaginatedUnregisteredCustomers();
        }
        if (this.currentPageUnregistered == 1) {
            this.isFirstPageUnregistered = true;
            this.isLastPageUnregistered = false;
        } else {
            this.isFirstPageUnregistered = false;
        }
        if (this.currentPageUnregistered == this.totalPagesUnregistered) {
            this.isLastPageUnregistered = true;
            this.isFirstPageUnregistered = false;
        } else {
            this.isLastPageUnregistered = false;
        }
    }

    handleNextPageUnregistered() {
        if (this.currentPageUnregistered < this.totalPagesUnregistered) {
            this.currentPageUnregistered += 1;
            this.updatePaginatedUnregisteredCustomers();
        }
        if (this.currentPageUnregistered == 1) {
            this.isFirstPageUnregistered = true;
            this.isLastPageUnregistered = false;
        } else {
            this.isFirstPageUnregistered = false;
        }
        if (this.currentPageUnregistered == this.totalPagesUnregistered) {
            this.isLastPageUnregistered = true;
            this.isFirstPageUnregistered = false;
        } else {
            this.isLastPageUnregistered = false;
        }
    }

    handlePageChangeUnregistered(event) {
        const pageNumber = parseInt(event.target.dataset.id, 10);
        this.currentPageUnregistered = pageNumber;
        this.updatePaginatedUnregisteredCustomers();
    }

    handleRecordsPerPageUnregisteredChange(event) {
        this.recordsPerPageUnregistered = event.target.value, 10;
        this.currentPageUnregistered = 1;
        this.calculatePagination();
    }

    handleTabClick(event) {
        this.activeTab = event.target.dataset.tab;
        this.searchKey = '';
        this.filterAndPaginateCustomers();
    }

    get registerTabClass() {
        return `tab-button ${this.activeTab === 'register' ? 'active' : ''}`;
    }

    get unregisterTabClass() {
        return `tab-button ${this.activeTab === 'unregister' ? 'active' : ''}`;
    }

    get isRegisterActive() {
        return this.activeTab === 'register';
    }

    get isUnregisterActive() {
        return this.activeTab === 'unregister';
    }

    sendInvite(event) {
        this.showSpinner = true;
        let accId = event.currentTarget.dataset.id;
        console.log('accountId ' + accId);
        sendRegistrationInvite({ accountId: accId })
            .then(result => {
                if (result == 'Success') {
                    this.template.querySelector('c-custom-toast').showToast('success', this.labels.isInvitedMsg);
                    this.mycustomerlist = this.mycustomerlist.map(record => {
                        if (record.Id === accId && record.isInvited === false) {
                            return { ...record, isInvited: true };
                        }
                        return record;
                    });
                    this.filterAndPaginateCustomers();
                    console.log('Success' + JSON.stringify(this.paginatedUnregisteredCustomers));
                } else {
                    console.error('Error ' + JSON.stringify(result));
                }
                this.showSpinner = false;
            })
            .catch(error => {
                this.showSpinner = false;
                console.error('Error sendRegistrationInvite:', error);
            });
    }

    handleShareClick() {
        const allSelectedCustomers = [...this.selectedCustomers, ...this.newRecipients];
        console.log('allSelectedCustomers>>',allSelectedCustomers);
        console.log('allSelectedCustomers>>>>'+JSON.stringify(allSelectedCustomers));
        console.log('allSelectedCustomers', JSON.stringify(this.allSelectedCustomers));
        let shareclick = new CustomEvent('sharecustomerdata', { detail: {data:allSelectedCustomers, feature: this.feature}});
        this.dispatchEvent(shareclick);
    }

    handleCheckbox(event) {
        // let checkbox = event.target.checked;
        // let { firstname, lastname, email } = event.currentTarget.dataset;
        // if (checkbox == true) {
        //     this.selectedCustomers.push(event.target.value);
        // }

        let checkbox = event.target.checked;
        let { firstname, lastname, email, isregister } = event.currentTarget.dataset;

        if (checkbox) {
            this.selectedCustomers.push({
                id: event.target.value,
                name: firstname+' '+lastname,
                email: email,
                isregister: isregister
            });
        } else {
            this.selectedCustomers = this.selectedCustomers.filter(customer => customer.id !== event.target.value);
        }
    }

    handleCheck(event) {

        let checkbox = event.target.checked;
        let { firstname, lastname, email } = event.currentTarget.dataset;

        if (checkbox) {
            this.selectedCustomers.push({
                name: firstname+' '+lastname,
                email: email
            });
        } else {
            this.selectedCustomers = this.selectedCustomers.filter;
        }
    }

    showCancelModal() {
        let closeModel = new CustomEvent('closemodel', { detail: true });
        this.dispatchEvent(closeModel);
    }
}