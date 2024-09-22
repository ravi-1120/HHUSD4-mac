import { LightningElement ,api} from 'lwc';
import USER_ID from "@salesforce/user/Id";
import getApprovedPending from '@salesforce/apex/MSD_CORE_ProductList.getPending';
export default class MfrPendingcount extends LightningElement {
    
@api product;
@api pendingCount=0;


connectedCallback() {
      console.log('--Inside the connected call back--');
    console.log('NNNN'+this.product);
    //this.pendingCount=this.product;
       this.getPendingPerProduct(this.product);
}
@api
callGoogleEvent(){
    this.dispatchEvent(new CustomEvent('gahandler', { detail:this.pendingCount}));
}
getPendingPerProduct(productId){
        console.log('get Pending 123');
        getApprovedPending({ recId: productId, userId: USER_ID})
            .then((result)=>{
                console.log('GET Pending---'+JSON.stringify(result));
                console.log('GET Pending SIZE---'+result.length);
               this.pendingCount=result.length;
                // this.products = result;
               // this.products = result.condata;
               // this.savedcon = result.savedcount;
                //console.log('this.products==>',this.products);
            })
            .catch((error) => {
                console.log(' Error in Get Pending'+JSON.stringify(error));
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