import { LightningElement, api, track, wire } from 'lwc';
import USER_ID from "@salesforce/user/Id";
import getCatalogPerProdSaved from '@salesforce/apex/MSD_CORE_ProductList.getCatalogPerProdSaved';
export default class MfrproductResCount extends LightningElement {

    @api product;
    @track appointmentCount = 0;
    connectedCallback() {
        this.getCatalogPerProduct(this.product);
    }

    @api
    callGoogleEvent() {
        this.dispatchEvent(new CustomEvent('gahandler', { detail: this.appointmentCount }));
    }
    // // getCatalogPerProduct(productId){
    //     @wire(getCatalogPerProdSaved, { recId: '$product',userId:USER_ID})
    //         wiredCatalogcount({ error, data }) {
    //             console.log('-->wiredCatalogcount<--');
    //             console.log({data});

    //             if (data) {
    //                 this.appointmentCount=data.length;
    //             } else if(error){
    //                 console.log({error});
    //             }
    //             console.log('this.appointmentCount-->',this.appointmentCount);
    //         }
    // // }



    getCatalogPerProduct(productId) {
        console.log('get Appointments 555' + productId);
        console.log('get Appointments 555' + USER_ID);
        /*  getCatalog({ recId: productId,userid:USER_ID})
              .then((result)=>{
                  console.log('GET Appointments---'+JSON.stringify(result));
                  console.log('GET Appointments SIZE---'+result.length);
                 this.appointmentCount=result.length;
                  // this.products = result;
                 // this.products = result.condata;
                 // this.savedcon = result.savedcount;
                  //console.log('this.products==>',this.products);
              })
              .catch((error) => {
                  console.log(' Error in Get Appointments'+JSON.stringify(error));
                  this.error = error;
              });
              */
        getCatalogPerProdSaved({ recId: productId, userId: USER_ID })
            .then((result) => {
                console.log('GET Appointments 555---' + JSON.stringify(result));
                console.log('GET Appointments SIZE 555---' + result.length);
                this.appointmentCount = result.length;
                // this.products = result;
                // this.products = result.condata;
                // this.savedcon = result.savedcount;
                //console.log('this.products==>',this.products);
            })
            .catch((error) => {
                console.log(' Error in Get Appointments 555' + JSON.stringify(error));
                this.error = error;
            });
    }

    renderedCallback() {
        const selectedEvent = new CustomEvent("redirectpage", {
            detail: this.appointmentCount
        });

        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }
}