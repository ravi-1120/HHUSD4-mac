import { LightningElement,api,track } from 'lwc';
import USER_ID from "@salesforce/user/Id";
import getApprovedAppointment from '@salesforce/apex/MSD_CORE_ProductList.getAppointments';
export default class MfrAppointmentcount extends LightningElement {

@api product;
@api appointmentCount=0;

connectedCallback() {
      console.log('--Inside the connected call back--');
    console.log('NNNN'+this.product);
    //this.appointmentCount=this.product;
       this.getAppointmentsPerProduct(this.product);
}
@api
callGoogleEvent(){
    this.dispatchEvent(new CustomEvent('gahandler', { detail:this.appointmentCount}));
}
getAppointmentsPerProduct(productId){
        console.log('get Appointments 123');
        getApprovedAppointment({ recId: productId, userId: USER_ID})
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
    }
    renderedCallback(){
        const selectedEvent = new CustomEvent("redirectpage", {
            detail: this.appointmentCount
          });
      
          // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }
}