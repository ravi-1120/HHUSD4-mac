import { LightningElement, track, wire } from 'lwc';

import home from '@salesforce/label/c.MSD_CORE_HEQ_Home';

import MSD_CORE_HEQ_Thumbnail from '@salesforce/resourceUrl/MSD_CORE_HEQ_Thumbnail';
import noImage from '@salesforce/resourceUrl/MSD_CORE_HEQ_No_Image';
import thumbURL from '@salesforce/label/c.MSD_CORE_HEQ_SandboxURL';
import USER_ID from '@salesforce/user/Id';
import Close from '@salesforce/label/c.MSD_CORE_Close_Btn';

// Pagination 
import recordsperpage from '@salesforce/label/c.MSD_CORE_HEQ_OrderHistoryRecordPerPage';
import recordperpageoption from '@salesforce/label/c.MSD_CORE_HEQ_OrderHistoryrecordsPerPageOptions';

//import getedeliveryDetails from '@salesforce/apex/MSD_CORE_HEQ_ResourceController.getedeliveryDetails';
//import getResourcesForCustomer from '@salesforce/apex/MSD_CORE_HEQ_ResourceController.getResourcesForCustomer';
import getCustomerResources from '@salesforce/apex/MSD_CORE_HEQ_ResourceController.getCustomerResources';
import resendEmailNotification from '@salesforce/apex/MSD_CORE_HEQ_ResourceController.resendEmailNotification';
import getUser from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getuser';
import getCustomerPrintOrders from '@salesforce/apex/MSD_CORE_HEQ_ResourceController.getCustomerPrintOrders';


export default class MSD_CORE_HEQ_Order_History extends LightningElement {

    @track activeTab = 'print';
    @track deliveryDetails = [];
    @track error;
    @track resources;
    @track expandedRowId;
    @track customerResourceList = [];
    @track customerOrders = [];
    //@track searchKey = '';
    expandedCustomers = {};
    @track searchKey = '';
    @track showPopup = false;

    labels = {
        home,
        Close
    }

    MSD_CORE_HEQ_Thumbnail = MSD_CORE_HEQ_Thumbnail;

    // Pagination
    @track isPagination = false;
    @track totalRecords = 0;
    @track totalPages = 1;
    @track currentPage = 1;
    @track recordsPerPage = recordsperpage;
    //@track recordsPerPage = 2;
    @track recordsPerPageOptions = [];
    @track searchCategory = [];
    @track mobilescreen;
    @track isSearchCategory = false;

    connectedCallback() {
        this.fetchCustomerResources();

        const paramValue = this.getUrlParamValue(window.location.href, 'Id');
        console.log("Extracted paramValue (Id): " + paramValue);

        getUser({ userId: paramValue })
            .then(result => {
                this.userVar = result;
                this.userId = paramValue;
                const firstName = this.userVar.FirstName || '';
                const lastName = this.userVar.LastName || '';
                this.fullName = `${firstName} ${lastName}`.trim();
                console.log("getUser generic tiles==>: " + JSON.stringify(this.fullName));
            })
            .catch(error => {
                console.log("getUser error==>: " + JSON.stringify(error));
            });


        // Pagination
        this.recordsPerPageOptions = recordperpageoption.split(',').map(option => parseInt(option.trim()));
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    @wire(getCustomerPrintOrders)
    wiredgetCustomerPrintOrders({ error, data }) {
    if (data) {
        console.log('Raw data received from Apex:', JSON.stringify(data, null, 2)); // Log the full data for debugging

        try {
            if (Array.isArray(data)) {
                this.customerOrders = data.map((order, index) => {
                    console.log(`Processing order at index ${index}:`, JSON.stringify(order, null, 2));

                    const orderId = order.MSD_CORE_Cust_Order_Number__c || 'Unknown Order ID';
                    const orderStatus = order.MSD_CORE_Integration_Status__c || 'Unknown Status';
                    const CreatedDate = order.CreatedDate;

                    const firstName = order.MSD_CORE_Customer__r?.FirstName || '';
                    const lastName = order.MSD_CORE_Customer__r?.LastName || '';
                    const customerName = `${firstName} ${lastName}`.trim() || 'Unknown Customer'; // Concatenate first and last name

                    const addressLine1 = order.MSD_CORE_HEQ_Address__r?.MSD_CORE_HEQ_Address_1__c || ''; // Assuming there is an Address 1 field
                    const city = order.MSD_CORE_HEQ_Address__r?.MSD_CORE_HEQ_City__c || '';
                    const zipCode = order.MSD_CORE_HEQ_Address__r?.MSD_CORE_HEQ_Zip_Code__c || '';
                    const address = `${addressLine1}, ${city}, ${zipCode}`.trim(); // Concatenate address components

                    const orderItems = order.HEQ_Order_Items__r || []; 

                    if (orderId && orderStatus && customerName && address) {
                        return {
                            orderId: orderId,
                            orderStatus: orderStatus,
                            customerName: customerName,
                            address: address,
                            CreatedDate: CreatedDate,
                            orderItems: orderItems.map(item => ({
                                resourceId: item.MSD_CORE_Resource_Id__c,
                                itemQuantity: item.MSD_CORE_Item_Quantity__c,
                                detailsKey: `${orderId}-details-${item.Id}`
                            })),
                            isExpanded: false, 
                            statusKey: `${orderId}-status`
                        };
                    } else {
                        console.warn('Incomplete order data at index', index, order);
                        return null;
                    }
                }).filter(order => order !== null);

                console.log('Processed customer orders:', this.customerOrders);
            } else {
                console.warn('Data is not an array:', data);
            }
        } catch (error) {
            console.error('Error processing data:', error);
        }
    } else if (error) {
        console.error('Error fetching orders:', error);
    }
}

    handlePrintIconClick(event) {
    const orderId = event.currentTarget.dataset.orderId; // Get the order ID from the data attribute
    console.log(`Clicked order ID: ${orderId}`); // Log the clicked order ID

    // Find the order in customerOrders and toggle its isExpanded property
    const order = this.customerOrders.find(order => order.orderId === orderId);
    
    if (order) {
        order.isExpanded = !order.isExpanded; // Toggle the isExpanded state
        console.log(`Order ${orderId} expanded state: ${order.isExpanded}`); // Log the expanded state for debugging
    } else {
        console.warn(`Order with ID ${orderId} not found.`);
    }

    // Force a re-render if necessary
    this.customerOrders = [...this.customerOrders]; // Create a new array to trigger reactivity
}


    handleReshareClick(event) {
        const resourceId = event.currentTarget.dataset.resourceId;
        const customerName = event.currentTarget.dataset.customerName;
        const resourceName = event.currentTarget.dataset.resourceName;
        console.log(`Re-order for Resource ID: ${resourceId}, Customer: ${customerName}, Resource Name: ${resourceName}`);
        // Add your re-order logic here
    }








    async fetchCustomerResources() {
        try {
            const responseData = await getCustomerResources();
            console.log('Response Data:', responseData);
            const data = JSON.parse(responseData);

            if (!data || data.length === 0) {
                console.log('No customer resources available for this user.');
                return;
            }

            let customerResourceListtemp = data.map(customer => {
                console.log('customerResourceListtemp==>', JSON.stringify(customer));
                let updatedURL = this.getThumbnailURL('THUMB');
                const resources = customer.resources.map(resource => ({
                    ...resource,
                    lastShared: this.formatDate(resource.lastShared),
                    ThumbnailUrl: resource.resourceId ? `${updatedURL}${resource.resourceId}` : noImage
                }));
                console.log('customer.resources==>', JSON.stringify(resources));
                resources.sort((a, b) => new Date(b.lastShared) - new Date(a.lastShared));

                // Extract the last shared date from resources
                const lastSharedDateStr = resources.length > 0
                    ? resources.reduce((latest, resource) => {
                        return new Date(resource.lastShared) > new Date(latest) ? resource.lastShared : latest;
                    }, resources[0].lastShared)
                    : null;

                return {
                    ...customer,
                    resources,
                    lastSharedDateStr: this.formatDate(lastSharedDateStr),
                    isExpanded: this.expandedCustomers[customer.customerName] || false
                };
            });

            customerResourceListtemp.sort((a, b) => {
                const dateA = new Date(a.lastSharedDateStr);
                const dateB = new Date(b.lastSharedDateStr);
                return dateB - dateA;
            });

            // Initialize expandedCustomers map with all customers collapsed (false)
            customerResourceListtemp.forEach(customer => {
                this.expandedCustomers[customer.customerName] = false;
            });

            // Pagination
            this.allRecords = customerResourceListtemp;
            this.totalRecords = this.allRecords.length;
            this.isPagination = this.totalRecords > 0;
            this.totalPages = Math.ceil(this.allRecords.length / parseInt(this.recordsPerPage));
            this.updatePagination();

            console.log('Customer resource list:', JSON.stringify(this.customerResourceList, null, 2));
        } catch (error) {
            console.error('Error fetching customer resources:', error);
        }
    }

    getThumbnailURL(fileType) {
        console.log('ThumbURL Return ' + fileType);
        let updatedThumbURL;

        switch (fileType.toUpperCase()) {
            case 'JPG':
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=ORIGINAL_Jpg');
                console.log('Updated ThumbURL for JPG:', updatedThumbURL);
                break;
            case 'PNG':
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=ORIGINAL_Png');
                console.log('Updated ThumbURL for PNG:', updatedThumbURL);
                break;
            case 'PDF':
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=SVGZ');
                break;
            default:
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=THUMB720BY480');
        }

        console.log('Updated ThumbURL:', updatedThumbURL);
        return updatedThumbURL;
    }



    // Pagination
    updatePagination() {
        const startIndex = (this.currentPage - 1) * parseInt(this.recordsPerPage);
        const endIndex = startIndex + parseInt(this.recordsPerPage);
        if (this.allRecords != false) {
            this.paginatedTopics = this.allRecords.slice(startIndex, endIndex);
            this.customerResourceList = this.paginatedTopics;
        } else {
            this.customerResourceList = [];
        }
        // Sync 2 Pagination Components
        let pagination = this.template.querySelectorAll('c-m-s-d_-c-o-r-e_-h-e-q_-pagination');
        for (let index = 0; index < pagination.length; index++) {
            pagination[index].updatecurrentpage(this.currentPage, this.totalRecords, this.totalPages);
        }
    }

    // Pagination
    handlePageOptionChange(event) {
        this.currentPage = 1;
        this.recordsPerPage = event.detail.recordsPerPage;
        this.totalPages = Math.ceil(this.allRecords.length / parseInt(this.recordsPerPage));
        this.updatePagination();
    }

    // Pagination
    handlePageChange(event) {
        this.currentPage = event.detail.currentPage;
        this.recordsPerPage = event.detail.recordsPerPage;
        this.totalPages = Math.ceil(this.allRecords.length / parseInt(this.recordsPerPage));
        this.updatePagination();
    }

    handleSearchKeyChange(event) {
        this.searchKey = event.target.value;
    }

    get filteredCustomerResourceList() {
        if (!this.searchKey) return this.customerResourceList;
        const lowerCaseSearchKey = this.searchKey.toLowerCase();
        return this.customerResourceList.filter(customer => {
            return customer.customerName.toLowerCase().includes(lowerCaseSearchKey) ||
                customer.email.toLowerCase().includes(lowerCaseSearchKey);
        });
    }


    handleIconClick(event) {
        const customerName = event.currentTarget.dataset.customerName;
        console.log('custome>>' + JSON.stringify(customerName));
        // Toggle the expanded state for the clicked customer
        this.expandedCustomers = {
            ...this.expandedCustomers,
            [customerName]: !this.expandedCustomers[customerName] // Toggle true/false
        };
        console.log('this.expandedCustomers>>' + JSON.stringify(this.expandedCustomers));

        // Update the isExpanded property in customerResourceList to reflect the changes
        this.customerResourceList = this.customerResourceList.map(customer => ({
            ...customer,
            isExpanded: this.expandedCustomers[customer.customerName]
        }));

        console.log('this.customerResourceList>>' + JSON.stringify(this.customerResourceList));

        // Force the reactivity update by assigning the updated customerResourceList
        this.customerResourceList = [...this.customerResourceList];
        const svgElement = event.currentTarget.querySelector('path');
        if (this.expandedCustomers[customerName]) {
            // Change to arrow-up
            svgElement.setAttribute("d", "M15.8838 8.83998L8.42044 0.18579C8.20681 -0.06192 7.79546 -0.06192 7.57956 0.18579L0.11623 8.83998C-0.161031 9.16269 0.0889585 9.6354 0.536668 9.6354H15.4633C15.911 9.6354 16.161 9.16269 15.8838 8.83998Z");
        } else {
            // Change to arrow-down
            svgElement.setAttribute("d", "M15.8838 1.16002L8.42044 9.81421C8.20681 10.0619 7.79546 10.0619 7.57956 9.81421L0.11623 1.16002C-0.161031 0.837306 0.0889585 0.364598 0.536668 0.364598H15.4633C15.911 0.364598 16.161 0.837306 15.8838 1.16002Z");
        }
    }

    // handlePrintIconClick(event) {
    //     const orderId = event.currentTarget.dataset.orderId; // Get the order ID from the data attribute

    //     // Find the order in customerOrders and toggle its isExpanded property
    //     const order = this.customerOrders.find(order => order.orderId === orderId);
        
    //     if (order) {
    //         order.isExpanded = !order.isExpanded; // Toggle the isExpanded state
    //         console.log(`Order ${orderId} expanded state: ${order.isExpanded}`); // Log the expanded state for debugging
    //     }

    //     // Force a re-render if necessary
    //     this.customerOrders = [...this.customerOrders]; // Create a new array to trigger reactivity
    // }

    // handleReshareClick(event) {
    //     const resourceId = event.currentTarget.dataset.resourceId;
    //     const customerName = event.currentTarget.dataset.customerName;
    //     const resourceName = event.currentTarget.dataset.resourceName;
    //     console.log(`Re-order for Resource ID: ${resourceId}, Customer: ${customerName}, Resource Name: ${resourceName}`);
    //     // Add your re-order logic here
    // }




    formatDate(dateString) {
        const date = new Date(dateString);
        const day = ('0' + date.getDate()).slice(-2);
        const month = ('0' + (date.getMonth() + 1)).slice(-2);
        const year = String(date.getFullYear());
        let hours = date.getHours();
        const minutes = ('0' + date.getMinutes()).slice(-2);

        // Convert to 12-hour format
        const ampm = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12;
        hours = hours ? ('0' + hours).slice(-2) : '12';

        // Return formatted date and time in "MM/DD/YY, HH AM/PM"
        return `${month}/${day}/${year} ${hours}:${minutes} ${ampm}`;
    }


    handleTabClick(event) {
        this.activeTab = event.target.dataset.tab;
    }


    get printTabClass() {
        return `tab-button ${this.activeTab === 'print' ? 'active' : ''}`;
    }

    get eDeliveryTabClass() {
        return `tab-button ${this.activeTab === 'eDelivery' ? 'active' : ''}`;
    }

    get isPrintTabActive() {
        return this.activeTab === 'print';
    }

    get isEDeliveryTabActive() {
        return this.activeTab === 'eDelivery';
    }

    async handleResendClick(event) {
        // Extract parameters from data attributes
        const customername = event.currentTarget.dataset.customerName;
        const customerEmail = event.currentTarget.dataset.customerEmail;
        const resourceId = event.currentTarget.dataset.recordId;
        const resourceName = event.currentTarget.dataset.resourceName;
        const recordID = event.currentTarget.dataset.resourceId;
        const orderNum = event.currentTarget.dataset.resourceId;
        const resourceCode = event.currentTarget.dataset.resourceCode;

        const username = this.fullName; 

        console.log('Extracted values from data attributes:');
        console.log(`UserName: ${username}`);
        console.log(`Customer Email: ${customerEmail}`);
        console.log(`Resource ID: ${resourceId}`);
        console.log(`Resource Name: ${resourceName}`);
        console.log(`Record Id: ${recordID}`);
        console.log(`Order Number: ${orderNum}`);
         console.log(`resourceCode: ${resourceCode}`);
        console.log('this.userID==>', USER_ID);

        try {
            console.log(`Resource ID==> try : ${resourceId}`);
            const result = await resendEmailNotification({
                username,
                email: customerEmail,
                resourceId,
                resourceName,
                orderNum,
                userId: USER_ID,
                recordID,
                customername,
                resourceCode
            });


            await this.fetchCustomerResources();
            // Log the result from Apex
            console.log(`Email successfully resent to ${customerEmail} for resource ${resourceName}`);
            console.log('Apex method result:', result);
            this.showPopup = true;
        } catch (error) {
            // Log the error if something goes wrong
            console.error('Error resending email:', error);
        }
    }

    closePopup() {
        this.showPopup = false;
    }

}