import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Custom Label
import HEQ_NoRecordFound from '@salesforce/label/c.MSD_CORE_HEQ_NoRecordFound';
import isInvitedMsg from '@salesforce/label/c.MSD_CORE_HEQ_IsInvitedMsg';
import recordPerPage from '@salesforce/label/c.MSD_CORE_HEQ_RecordPerPage';
import pageOption from '@salesforce/label/c.MSD_CORE_HEQ_PageOption';
import recordsperpage from '@salesforce/label/c.MSD_CORE_HEQ_CustomerPerPage';
import recordperpageoption from '@salesforce/label/c.MSD_CORE_HEQ_CustomerPerPageOptions';
import lastlogin from '@salesforce/label/c.MSD_CORE_HEQ_Last_Login';

// Apex class
import getCustomerList from '@salesforce/apex/MSD_CORE_HEQ_CustomerController.getCustomerList';
import sendRegistrationInvite from '@salesforce/apex/MSD_CORE_HEQ_AuthController.sendRegistrationInvite';
import saveRecipients from '@salesforce/apex/MSD_CORE_HEQ_CustomerController.saveRecipients';
import getRecipients from '@salesforce/apex/MSD_CORE_HEQ_CustomerController.getRecipients';
import getUser from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getuser';

export default class MSD_CORE_HEQ_Customer extends NavigationMixin(LightningElement) {

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
    @track allRecords = [];
    @track recordsPerPageOptions = [];

    @track searchCategory = [];
    @track mycustomerlist = [];
    @track newRecipients = [];
    @track searchKey = '';
    @track norecordfound = HEQ_NoRecordFound;
    @track noSearchResults = false;
    @track searchMessage = '';

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
    @track selfPrint = false;
    // recordsPerPageOptions = [];
    totalRegisteredRecords = 0;
    totalUnregisteredRecords = 0;
    showSpinner = false;

    @track isModalOpen = false;
    @track selectedCustomer = {};
    @track nonPrimaryAddresses = [];
    // needScroll = false;


    labels = {
        isInvitedMsg,
        lastlogin
    };

    // renderedCallback() {
    //     if (this.needScroll) {
    //         console.log('Focus being called');
    //         const scrollArea = this.template.querySelector('[data-scroll-area]');
    //         console.log('### scroll height ' + scrollArea.scrollHeight);
    //         scrollArea.scrollTop = scrollArea.scrollHeight + 90;
    //         this.needScroll = false;
    //     }
    // }
    // ConnectedCallback
    connectedCallback() {
        console.log('hideAddRecipient>>>', this.hideAddRecipient);
        this.fetchCustomers();
        this.getCustomerList();
        if (this.customertype == 'registered') {
            this.filterLayout = true;
        } else if (this.customertype == 'allcustomers') {
            this.unfilterLayout = true;
        } else if (this.customertype == 'registered-unregistered') {
            this.unfilterLayout = true;
        }

        const optionval = pageOption.split(',');
        // this.recordsPerPageOptions = optionval.map(option => {
        //     return { label: option.trim(), value: option.trim() };
        // });

        this.recordsPerPageOptions = recordperpageoption.split(',').map(option => parseInt(option.trim()));

        const paramValue = this.getUrlParamValue(window.location.href, 'Id');
        getUser({ userId: paramValue })
            .then(result => {
                this.userVar = result;
                this.AEEmail = this.userVar.Email || '';
                const firstName = this.userVar.FirstName || '';
                const lastName = this.userVar.LastName || '';
                this.fullName = `${firstName} ${lastName}`.trim();
                console.log("getUser AEEmail==>: " + JSON.stringify(this.AEEmail));
            })
            .catch(error => {
                console.log("getUser error==>: " + JSON.stringify(error));
            });
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    fetchCustomers() {
        getRecipients()
            .then(result => {
                // this.newCustomers = result;
                this.newCustomers = result.map(customer => {
                    // Create a new object to avoid mutating the original
                    const transformedCustomer = { ...customer };

                    // If MSD_CORE_HEQ_FirstName__c exists, use it as FirstName
                    if (transformedCustomer.MSD_CORE_HEQ_FirstName__c) {
                        transformedCustomer.FirstName = transformedCustomer.MSD_CORE_HEQ_FirstName__c;
                        transformedCustomer.LastName = transformedCustomer.MSD_CORE_HEQ_LastName__c;
                        transformedCustomer.Email = transformedCustomer.MSD_CORE_HEQ_Email__c;
                    }
                    return transformedCustomer;
                });
                // FirstName = result.MSD_CORE_HEQ_FirstName__c;
                // console.log('FirstName'+FirstName);
                console.log('Fetched Customers:', this.newCustomers);
            })
            .catch(error => {
                console.error('Error fetching customers:', error);
            });
    }

    get isBothFalse() {
        return !this.filterLayout && !this.unfilterLayout;
    }

    handleOtherAddressesClick(event) {
        const customerId = event.currentTarget.dataset.id;
        const selectedCustomer = this.mycustomerlist.find(customer => customer.Id === customerId);

        if (selectedCustomer) {
            this.selectedCustomer = selectedCustomer;
            this.nonPrimaryAddresses = selectedCustomer.Addresses.filter(address => !address.Primary);
            this.isModalOpen = true;
        }
    }

    closeModal() {
        this.isModalOpen = false;
        this.selectedCustomer = {};
        this.nonPrimaryAddresses = [];
    }

    handleSave() {
        this.isModalOpen = false;
    }



    /*addRecipient() {
        const newRecipient = {
            FirstName: 'First Name',
            LastName: 'Last Name',
            Email: 'Email@example.com',
            LastLoginDate: null
        };

        this.mycustomerlist = [...this.mycustomerlist, newRecipient];
        console.log('mycustomerlist',this.mycustomerlist)
    }*/

    getCustomerList() {
        this.showSpinner = true;
        getCustomerList()
            .then(result => {
                console.log('result----->' + JSON.stringify(result));
                if (result.length == 0) {
                    this.isCustomer = false;
                } else {
                    this.isCustomer = true;
                }
                this.mycustomerlist = result;
                this.setDefaultAddress();
                console.log('this.mycustomerlist------->' + JSON.stringify(this.mycustomerlist));

                this.allRecords = result;
                this.filterAndPaginateCustomers();
                this.updatePagination();
                this.showSpinner = false;
            })
            .catch(error => {
                console.error('Error fetching customer list:', error);
            });
    }

    setDefaultAddress() {
        this.mycustomerlist = this.mycustomerlist.map(customer => {
            const primaryAddress = customer.Addresses.find(address => address.primary);
            const firstAddress = customer.Addresses.length > 0 ? customer.Addresses[0] : null;

            const formatAddress = (address) => {
                const addressParts = [];
                
                if (address.Name) addressParts.push(address.Name);
                if (address.AddressLine2) addressParts.push(address.AddressLine2);
                if (address.City) addressParts.push(address.City);
                if (address.State) addressParts.push(address.State);
                if (address.Zip) addressParts.push(address.Zip);
                
                return addressParts.length > 0 ? addressParts.join(', ') : null;
            };

            customer.displayAddress = primaryAddress
                ? formatAddress(primaryAddress)
                : firstAddress
                    ? formatAddress(firstAddress)
                    : 'No addresses found';

            return customer;
        });

    }


    filterAndPaginateCustomers() {
        const searchKeyLower = this.searchKey.toLowerCase();

        this.allRecords = this.mycustomerlist.filter(customer =>
            (customer.FirstName && customer.FirstName.toLowerCase().includes(searchKeyLower)) ||
            (customer.LastName && customer.LastName.toLowerCase().includes(searchKeyLower)) ||
            (customer.Email && customer.Email.toLowerCase().includes(searchKeyLower))
        );

        this.filteredCustomers = this.mycustomerlist.filter(customer =>
            (customer.FirstName && customer.FirstName.toLowerCase().includes(searchKeyLower)) ||
            (customer.LastName && customer.LastName.toLowerCase().includes(searchKeyLower)) ||
            (customer.Email && customer.Email.toLowerCase().includes(searchKeyLower))
        );

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
            this.allCustomers = [...this.registeredCustomers, ...this.unregisteredCustomers, ...this.newCustomers];
            if (this.allCustomers.length == 0) {
                this.isCustomer = false;
            } else {
                this.isCustomer = true;
            }
        } else if (this.customertype === 'registered-unregistered') {
            this.allCustomers = [...this.registeredCustomers, ...this.unregisteredCustomers];
        }
        console.log('this.registeredCustomers>>>' + JSON.stringify(this.registeredCustomers));
        console.log('this.allCustomers>>>' + JSON.stringify(this.allCustomers));

        this.totalRegisteredRecords = this.registeredCustomers.length;
        this.totalUnregisteredRecords = this.unregisteredCustomers.length;

        this.calculatePagination();
        this.noRegisteredRecords = this.registeredCustomers.length === 0;
        this.noUnregisteredRecords = this.unregisteredCustomers.length === 0;
        this.noRecordsFound = this.noRegisteredRecords && this.noUnregisteredRecords;

        this.totalRecords = this.filteredCustomers.length;

        if (this.searchKey && this.totalRecords === 0) {
            this.noSearchResults = true;
            this.searchMessage = 'No search results were found';
        } else {
            this.noSearchResults = false;
            this.searchMessage = '';
        }



    }

    redirectToHome() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/landing-page'
            }
        });
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
            Id: Math.random().toString(36).substring(2, 11),
            FirstName: '',
            LastName: '',
            Email: '',
            LastLoginDate: null,
            IsNew: true
        };

        this.newRecipients = [...this.newRecipients, newRecipient];
        console.log('newRecipients', JSON.stringify(this.newRecipients));
        //this.needScroll = true;
    }

    /*focusOnNewRecipient() {
       console.log('Focus being called');
       const scrollArea = this.template.querySelector('[data-scroll-area]');
       console.log('### scroll height '+scrollArea.scrollHeight);
       var hght = scrollArea.scrollHeight + 90;
       console.log('### scroll height '+hght);
       scrollArea.scrollTop = scrollArea.scrollHeight + 90;
    /*setTimeout(() => {
        const inputField = this.template.querySelector(`input[data-Id="${FirstName}"].target-section`);
        if (inputField) {
            inputField.focus();
            inputField.scrollIntoView({ behavior: 'smooth' });
        }
    }, 0);
   }*/


    // removeRecipient(event) {
    //     const recipientId = event.currentTarget.dataset.id;
    //     this.newRecipients = this.newRecipients.filter(recipient => recipient.Id !== recipientId);
    // }
    removeRecipient(event) {
        const recipientId = event.target.dataset.id;
        console.log('Removing recipient with ID:', recipientId);

        // Check each recipient's ID
        this.newRecipients.forEach(recipient => {
            console.log('Current recipient ID:', recipient.Id);
        });

        this.newRecipients = this.newRecipients.filter(recipient => recipient.Id !== recipientId);
        console.log('Remaining recipients:', this.newRecipients);
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

    // handleRecipient(event) {
    //     const field = event.target.name;
    //     const recipientId = event.target.dataset.id;

    //     this.newRecipients = this.newRecipients.map(recipient => {
    //         if (recipient.Id === recipientId) {
    //             // Update the field value
    //             recipient[field] = event.target.value;

    //             // Validation Logic
    //             if (field === 'FirstName') {
    //                 recipient.firstNameError = !recipient.FirstName;
    //             } else if (field === 'LastName') {
    //                 recipient.lastNameError = !recipient.LastName;
    //             } else if (field === 'Email') {
    //                 if (recipient.Email) {
    //                     const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    //                     recipient.emailError = !emailPattern.test(recipient.Email);
    //                 } else {
    //                     recipient.emailError = false;
    //                 }
    //             }
    //         }
    //         return recipient;
    //     });
    // }
    handleRecipient(event) {
        const field = event.target.name; // Get the field name (e.g., FirstName, LastName, Email)
        const recipientId = event.target.dataset.id; // Get the recipient's ID

        // Update the corresponding recipient in the newRecipients array
        this.newRecipients = this.newRecipients.map(recipient => {
            if (recipient.Id === recipientId) {
                // Update the value of the field
                recipient[field] = event.target.value;

                // Validation Logic
                if (field === 'FirstName') {
                    recipient.firstNameError = !recipient.FirstName; // Validation for FirstName
                } else if (field === 'LastName') {
                    recipient.lastNameError = !recipient.LastName;   // Validation for LastName
                } else if (field === 'Email') {
                    // Validation for Email format
                    if (recipient.Email) {
                        const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                        recipient.emailError = !emailPattern.test(recipient.Email); // Validate email format
                    } else {
                        recipient.emailError = true; // Set error if Email is empty
                    }
                }
            }
            return recipient;
        });
    }




    handleSearchKeyChange(event) {
        this.searchKey = event.target.value;
        this.currentPage = 1;
        this.filterAndPaginateCustomers();
        this.updatePagination();
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
        let hasErrors = false;

        this.newRecipients = this.newRecipients.map(recipient => {
            recipient.firstNameError = false;
            recipient.lastNameError = false;

            // Check for validation
            if (!recipient.FirstName) {
                recipient.firstNameError = true;
                hasErrors = true;
            }
            if (!recipient.LastName) {
                recipient.lastNameError = true;
                hasErrors = true;
            }
            if (!recipient.Email) {
                recipient.emailError = true;
                hasErrors = true;
            }

            return recipient;
        });

        if (hasErrors) {
            return;
        }

        // Proceed with saving recipients if validation passes
        if (this.newRecipients && this.newRecipients.length > 0) {
            const recipientsToSave = this.newRecipients.map(recipient => ({
                MSD_CORE_HEQ_FirstName__c: recipient.FirstName || '',
                MSD_CORE_HEQ_LastName__c: recipient.LastName || '',
                MSD_CORE_HEQ_Email__c: recipient.Email || ''
            }));

            saveRecipients({ recipients: recipientsToSave })
                .then(() => {
                    console.log('Recipients saved successfully');
                })
                .catch(error => {
                    console.error('Error saving recipients: ', error);
                });
        }

        const allSelectedCustomers = [...this.selectedCustomers];
        console.log('allSelectedCustomers>>', allSelectedCustomers);
        let shareclick = new CustomEvent('sharecustomerdata', { detail: { data: allSelectedCustomers, feature: this.feature, selfprint: this.selfPrint } });
        this.dispatchEvent(shareclick);
    }


    // handleShareClick() {

    //     // Check if there are any new recipients
    //     if (this.newRecipients && this.newRecipients.length > 0) {
    //         const recipientsToSave = this.newRecipients.map(recipient => ({
    //             MSD_CORE_HEQ_FirstName__c: recipient.FirstName || '',
    //             MSD_CORE_HEQ_LastName__c: recipient.LastName || '',
    //             MSD_CORE_HEQ_Email__c: recipient.Email || ''
    //         }));


    //         // Call Apex method to save recipients
    //         saveRecipients({ recipients: recipientsToSave })
    //             .then(() => {
    //                 // Handle successful save
    //                 console.log('Recipients saved successfully');
    //                 this.dispatchEvent(new CustomEvent('showtoast', { detail: { message: 'Recipients saved successfully!', variant: 'success' } }));
    //             })
    //             .catch(error => {
    //                 // Handle errors during saving
    //                 console.error('Error saving recipients: ', error);
    //                 this.dispatchEvent(new CustomEvent('showtoast', { detail: { message: 'Error saving recipients', variant: 'error' } }));
    //             });
    //     }

    //     const allSelectedCustomers = [...this.selectedCustomers];
    //     console.log('allSelectedCustomers>>', allSelectedCustomers);
    //     console.log('allSelectedCustomers>>>>' + JSON.stringify(allSelectedCustomers));
    //     console.log('allSelectedCustomers', JSON.stringify(this.allSelectedCustomers));
    //     let shareclick = new CustomEvent('sharecustomerdata', { detail: { data: allSelectedCustomers, feature: this.feature } });
    //     this.dispatchEvent(shareclick);
    // }

    emailToSelfCheckboxChange(event) {
        this.emailToSelf = event.target.checked; 

        // If checked, ensure to add self to the list if no other customer is selected
        if (this.emailToSelf) {
            const selfEmailExists = this.selectedCustomers.some(customer => customer.id === 'self');
            if (!selfEmailExists) {
                this.selectedCustomers.push({
                    name: this.fullName,
                    email: this.AEEmail
                    // isAccountExe: isAccountExe
                });
            }
        } else {
            this.selectedCustomers = this.selectedCustomers.filter(customer => customer.id !== 'self');
        }
        //this.dispatchEvent(new CustomEvent('sharecustomerdata', { detail: { data: this.selectedCustomers, feature: 'edeliver' } }));
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
                name: firstname + ' ' + lastname,
                email: email,
                isregister: isregister
            });
            } else {
                this.selectedCustomers = this.selectedCustomers.filter(customer => customer.id !== event.target.value);
            }
            //this.dispatchEvent(new CustomEvent('sharecustomerdata', { detail: { data: this.selectedCustomers, feature: 'edeliver' } }));
        }

    handleCheck(event) {

        let checkbox = event.target.checked;
        let { firstname, lastname, email } = event.currentTarget.dataset;

        if (checkbox) {
            this.selectedCustomers.push({
                name: firstname + ' ' + lastname,
                email: email
            });
        } else {
            this.selectedCustomers = this.selectedCustomers.filter;
        }
    }

    handleSelfPrint(event){
        let checkbox = event.target.checked;
        if (checkbox) {
            this.selfPrint = true;
        }else{
            this.selfPrint = false;
        }
    }

    showCancelModal() {
        let closeModel = new CustomEvent('closemodel', { detail: true });
        this.dispatchEvent(closeModel);
    }

    //Pagination
    resetVariableValue() {
        this.totalRecords = 0;
        this.totalPages = 1;
        this.currentPage = 1;
    }

    // Pagination
    updatePagination() {

        this.totalRecords = this.allRecords.length;
        console.log('this.totalRecords----->' + JSON.stringify(this.totalRecords));
        if (this.totalRecords > 0) {
            this.isPagination = true;
        }
        this.totalPages = Math.ceil(this.allRecords.length / parseInt(this.recordsPerPage));
        console.log('this.totalPages>>' + JSON.stringify(this.totalPages));

        const startIndex = (this.currentPage - 1) * parseInt(this.recordsPerPage);
        const endIndex = startIndex + parseInt(this.recordsPerPage);
        this.paginatedTopics = this.allRecords.slice(startIndex, endIndex);
        this.filteredCustomers = this.paginatedTopics;
        console.log('this.filteredCustomers>>>' + JSON.stringify(this.filteredCustomers));
        console.log('this.filteredCustomers>>>' + JSON.stringify(this.filteredCustomers.length));
        // Sync 2 Pagination Components
        let pagination = this.template.querySelectorAll('c-m-s-d_-c-o-r-e_-h-e-q_-pagination');
        for (let index = 0; index < pagination.length; index++) {
            pagination[index].updatecurrentpage(this.currentPage, this.totalRecords, this.totalPages);
        }
        // this.filterAndPaginateCustomers();
    }

    handlePageOptionChange(event) {
        this.currentPage = 1;
        this.recordsPerPage = event.detail.recordsPerPage;
        this.totalPages = Math.ceil(this.allRecords.length / parseInt(this.recordsPerPage));
        this.updatePagination();
    }

    handlePageChange(event) {
        this.currentPage = event.detail.currentPage;
        this.recordsPerPage = event.detail.recordsPerPage;
        this.totalPages = Math.ceil(this.allRecords.length / parseInt(this.recordsPerPage));
        this.updatePagination();
    }
}