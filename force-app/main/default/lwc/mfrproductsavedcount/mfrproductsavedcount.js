import { LightningElement,api,track } from 'lwc';
import USER_ID from "@salesforce/user/Id";
import getCatalogPerProdSaved from '@salesforce/apex/MSD_CORE_ProductList.getCatalogPerProdSaved';
export default class Mfrproductsavedcount extends LightningElement {

@api product;
savedcon=0;
connectedCallback() {
      console.log('--Inside the connected call back--');
    console.log('NNNN'+this.product);
    //this.appointmentCount=this.product;
       this.getCatalogPerProduct(this.product);
}
getCatalogPerProduct(productId){
        console.log('get saved 555'+productId);
           console.log('get saved 555'+USER_ID);
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

             getCatalogPerProdSaved({ recId: productId,userId:USER_ID})
            .then((result)=>{
               
             
               this.savedcon=result.length;
                // this.products = result;
               // this.products = result.condata;
               // this.savedcon = result.savedcount;
                //console.log('this.products==>',this.products);
            })
            .catch((error) => {
                console.log(' Error in Get saved 555'+JSON.stringify(error));
                this.error = error;
            });
    }
}