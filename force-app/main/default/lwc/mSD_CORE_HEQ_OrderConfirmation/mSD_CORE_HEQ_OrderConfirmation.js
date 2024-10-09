import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

//Apex Classes
import getCustomerPrintOrders from '@salesforce/apex/MSD_CORE_HEQ_ResourceController.getCustomerPrintOrders';

//Custom Labels
import thumbURL from '@salesforce/label/c.MSD_CORE_HEQ_SandboxURL';

//Static Resources
import noImage from '@salesforce/resourceUrl/MSD_CORE_HEQ_No_Image';


export default class MSD_CORE_HEQ_OrderConfirmation extends NavigationMixin(LightningElement) {


    @track customerOrders = [];
    connectedCallback() {
        this.getPrintOrdersList();
    }

    getPrintOrders(data) {
        console.log('Confirmation data >>>', data);
        this.customerOrders = data.map((order, index) => {
            console.log('Entered customerOrders>>');

            const orderId = order.MSD_CORE_Cust_Order_Number__c || 'Unknown Order ID';
            const orderStatus = order.MSD_CORE_Integration_Status__c || 'Unknown Status';
            const CreatedDate = order.CreatedDate;

            const firstName = order.MSD_CORE_Customer__r?.FirstName || '';
            const lastName = order.MSD_CORE_Customer__r?.LastName || '';
            const customerName = `${firstName} ${lastName}`.trim() || 'Unknown Customer';

            const addressLine1 = order.MSD_CORE_HEQ_Address__r?.MSD_CORE_HEQ_Address_1__c || '';
            const city = order.MSD_CORE_HEQ_Address__r?.MSD_CORE_HEQ_City__c || '';
            const zipCode = order.MSD_CORE_HEQ_Address__r?.MSD_CORE_HEQ_Zip_Code__c || '';
            const address = `${addressLine1}, ${city}, ${zipCode}`.trim();
            let updatedURL = this.getThumbnailURL('Thumb');

            const orderItems = order.HEQ_Order_Items__r || [];

            if (orderId && orderStatus && customerName && address) {
                return {
                    orderId: orderId,
                    orderStatus: orderStatus,
                    customerName: customerName,
                    address: address,
                    CreatedDate: CreatedDate,
                    orderItems: orderItems.map(item => ({
                        thumbnailUrl: item.MSD_CORE_Resource_Id__c ? `${updatedURL}${item.MSD_CORE_Resource_Id__c}` : noImage,
                        resourceId: item.MSD_CORE_Resource_Id__c,
                        itemQuantity: item.MSD_CORE_Item_Quantity__c,
                    })),
                };
            } else {
                console.warn('Incomplete order data at index', index, order);
                return null;
            }
        }).filter(order => order !== null);
    }

    async getPrintOrdersList() {
        try{
            let data = await getCustomerPrintOrders();
            if(data){
                console.error('Data>>>' , data);
                this.customerOrders = data;
                this.getPrintOrders(data);
            }
        }catch(e){
            console.error('Error>>>' , e.message);
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

    redirectHomePage(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/landing-page'
            }
        });
    }
}