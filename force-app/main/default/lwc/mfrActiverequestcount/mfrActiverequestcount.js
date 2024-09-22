import { LightningElement,api,track } from 'lwc';
import USER_ID from "@salesforce/user/Id";
import getActiveRequests from '@salesforce/apex/MSD_CORE_ProductList.getActiveRequests';
export default class MfrActiverequestcount extends LightningElement {

@api product;
activeCount=0;
connectedCallback() {
      console.log('--Inside the connected call back--');
    console.log('NNNN'+this.product);
       this.getActivePerProduct(this.product);
}
getActivePerProduct(productId){
        console.log('get Active 123');
        getActiveRequests({ recId: productId, userId: USER_ID})
            .then((result)=>{
                console.log('GET Active---'+JSON.stringify(result));
                console.log('GET Active SIZE---'+result.length);
               this.activeCount=result.length;
               console.log('Active Count='+activeCount);
            })
            .catch((error) => {
                console.log(' Error in Get Active'+JSON.stringify(error));
                this.error = error;
            });
    }
}