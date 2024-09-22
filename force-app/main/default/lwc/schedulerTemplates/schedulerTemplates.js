import { LightningElement, api,track, wire} from 'lwc';
import { ShowToastEvent }  from 'lightning/platformShowToastEvent';
import NAME_FIELD from '@salesforce/schema/Appointment_Template__c.Name';
import getTemplates from '@salesforce/apex/TemplateController.getTemplates';
import createSchedulerTemplates from '@salesforce/apex/TemplateController.createSchedulerTemplates';
import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
    { label: 'Inquiry Type', fieldName: NAME_FIELD.fieldApiName, type: 'text' },
    { label: 'Order', fieldName: 'Order',type: 'text', editable: "true" }
];

export default class SchedulerTemplates extends LightningElement {
    @api recordId;
    @api counter;
    @api preSelectedRows = [];
    @api isFromPrevious;
    templateData = [];
    @track templates=[] ;
    templateIds = [];
    @track showingTemplateIds=[];
    templateOrderValue = [];
    templateOrders = [];
    columns = COLUMNS;
    templateWrapper = [];
    productWrapper = [];
    @track products = [];
    allproductTemplates=[];
    @track alltemplates=[]
    @track productIds=[];
    @track wrapperdata=[];
    @api ready = false;

    @wire(getTemplates,{ schedulerId:'$recordId' })
    wiredAllTemp(result) {
        this.wrapperdata=result;
        let data=result.data;
        console.log('wiredAllTemp calling');
        if (data ) {
            if(data.listProducts){
                let allproducts=[];
                for (let i = 0; i <  data.listProducts.length; i++) {
                    allproducts.push({Id: data.listProducts[i].Id, Name: data.listProducts[i].Name, 
                        prodPreselect:false,order:''});
                }
                this.products = allproducts;
            }
            this.products.forEach((ele)=>{
                if(data.listExtProducts){
                    for (let i = 0; i <  data.listExtProducts.length; i++) {
                        if(ele.Id==data.listExtProducts[i].Product_Payor__c){
                            ele.prodPreselect=true;
                            ele.order=data.listExtProducts[i].Order__c;
                            this.productIds.push(ele.Id);
                            this.productWrapper.push({
                                id : ele.Id,
                                order : data.listExtProducts[i].Order__c
                            });
                            break;
                        }
                    }
                }
            });

            if(data.existingTemplates){
                for (let i = 0; i <  data.existingTemplates.length; i++) {
                    if(data.existingTemplates[i].Product_Payor__c && this.showingTemplateIds.includes(data.existingTemplates[i].Appointment_Template__c) == false){
                        this.templates.push({Id: data.existingTemplates[i].Appointment_Template__c, Name: data.existingTemplates[i].Appointment_Template__r.Name, order:data.existingTemplates[i].Order__c,
                            preselect:true,ProductPayorID:data.existingTemplates[i].Product_Payor__c});
                        this.templateIds.push(data.existingTemplates[i].Appointment_Template__c);
                        this.showingTemplateIds.push(data.existingTemplates[i].Appointment_Template__c);
                        this.templateWrapper.push({id : data.existingTemplates[i].Appointment_Template__c,order : data.existingTemplates[i].Order__c,
                            ProductPayorID:data.existingTemplates[i].Product_Payor__c});
                    }
                }   
            }

            if(data.listProductTemplates){
                let allproductTemplates=[];
                for (let i = 0; i <  data.listProductTemplates.length; i++) {
                    allproductTemplates.push({Id: data.listProductTemplates[i].Id, Appointment_Template__c: data.listProductTemplates[i].Appointment_Template__c,
                    ProductPayorID:data.listProductTemplates[i].Product_Payor__c,templateName:data.listProductTemplates[i].Appointment_Template__r.Name});
                    if(this.productIds){
                        if(this.productIds.includes(data.listProductTemplates[i].Product_Payor__c) && this.showingTemplateIds.includes(data.listProductTemplates[i].Appointment_Template__c)==false) {
                            this.templates.push({Id: data.listProductTemplates[i].Appointment_Template__c, Name: data.listProductTemplates[i].Appointment_Template__r.Name, order:'',
                                preselect:false,ProductPayorID:data.listProductTemplates[i].Product_Payor__c});
                            this.showingTemplateIds.push(data.listProductTemplates[i].Appointment_Template__c);
                        }
                    }           
                }
                this.allproductTemplates = allproductTemplates;
            }
        }else if (result.error) {
            this.error = result.error;
        }
    }
    
    connectedCallback() {
        this.ready = true;
        console.log('connectedCallback>> '); 
        refreshApex(this.wrapperdata);
    }
   
    handleChange(event){
        let order = event.target.value;
        let templateId = event.currentTarget.dataset.id;
        let productId;
        let isPresent = true;
        let index = event.currentTarget.dataset.index;
        console.log('index'+index);
        this.templates[index].order=order;
        let result = this.templates.find(obj => {
            return obj.Id ===templateId
        })
        if(result){
            productId=result.ProductPayorID;
        }
        if(this.templateWrapper && this.templateWrapper.length > 0){
            isPresent = false;
            this.templateWrapper.forEach( ele=> {
                if(ele.id == templateId){
                    ele.order = order;
                    isPresent = true;
                }
            });
        }else{
            this.templateWrapper.push({
                id : templateId,
                order : order,
                ProductPayorID:productId
            });
        }
        if(!isPresent){
            this.templateWrapper.push({
                id : templateId,
                order : order,
                ProductPayorID:productId
            });
        }
        console.log('templateWrapper ==>', JSON.stringify(this.templateWrapper));
    }

    handleChangeProduct(event){
        let order = event.target.value;
        let productId = event.currentTarget.dataset.id;
        let isPresent = true;
        let index = event.currentTarget.dataset.index;
        this.products[index].order=order;
        if(this.productWrapper && this.productWrapper.length > 0){
            isPresent = false;
            this.productWrapper.forEach( ele=> {
                if(ele.id == productId){
                    ele.order = order;
                    isPresent = true;

                }
            });
        } else{
            this.productWrapper.push({
                id : productId,
                order : order
            });
        }
        if(!isPresent){
            this.productWrapper.push({
                id : productId,
                order : order
            });
        }
        console.log('productWrapper ==>', JSON.stringify(this.productWrapper));
    }

    onProductSelect(event){
        let selectedRows = event.currentTarget.dataset;
        let checked= event.currentTarget.checked
        console.log('checked'+checked);
        let index = event.currentTarget.dataset.index;

        if(checked===true){
            let id = selectedRows.id;
            console.log('id '+id)
            this.productIds.push(id);
            if(this.allproductTemplates){
                for (let i = 0; i <  this.allproductTemplates.length; i++) {
                    if(this.allproductTemplates[i].ProductPayorID==id && this.showingTemplateIds.includes(this.allproductTemplates[i].Appointment_Template__c)==false){
                        this.templates.push({Id: this.allproductTemplates[i].Appointment_Template__c, Name: this.allproductTemplates[i].templateName, order:'',
                            preselect:false,ProductPayorID:this.allproductTemplates[i].ProductPayorID});
                        this.showingTemplateIds.push(this.allproductTemplates[i].Appointment_Template__c);
                    }
                }
            }
        }else{
            this.products[index].order='';
            let id = selectedRows.id;
            var idx = this.productIds.indexOf(selectedRows.id);
            console.log('idx '+idx)
            if (idx != -1) {
                this.productIds.splice(idx, 1)
            }
            console.log('this.productIds'+this.productIds)
            if(this.templates){
                for (let i = 0; i <  this.templates.length; i++) {
                    if(this.templates[i].ProductPayorID==id){
                        var idxt = this.templateIds.indexOf(this.templates[i].Id);
                        if (idxt != -1) {
                            this.templateIds.splice(idxt, 1)
                        }
                        this.templates.splice(i, 1);
                        this.showingTemplateIds.splice(i, 1)
                        i--;
                    }
                }
                this.templateIds=[];
                for (let i = 0; i <  this.templates.length; i++) {
                    this.templates[i].preselect=false;
                    this.templates[i].order='';
                }
                for (let i = 0; i <  this.allproductTemplates.length; i++) {
                    if(this.productIds && this.productIds.includes(this.allproductTemplates[i].ProductPayorID) && this.showingTemplateIds.includes(this.allproductTemplates[i].Appointment_Template__c)==false){
                        this.templates.push({Id: this.allproductTemplates[i].Appointment_Template__c, Name: this.allproductTemplates[i].templateName, order:'',
                            preselect:false,ProductPayorID:this.allproductTemplates[i].ProductPayorID});
                        this.showingTemplateIds.push(this.allproductTemplates[i].Appointment_Template__c);
                    }
                }
                console.log('JSON:'+JSON.stringify( this.templates))
            }
        }
    }

    selectedRow(event){
        let selectedRows = event.currentTarget.dataset;
        let checked= event.currentTarget.checked
        console.log('checked'+checked);
        let index = event.currentTarget.dataset.index;
        this.templates[index].preselect=checked;
        if(checked===true){
            this.templateIds.push(selectedRows.id);
        }else{
            this.templates[index].order=''; // to remove order when deselecting a template
            let idx = this.templateIds.indexOf(selectedRows.id);
            console.log('idx '+idx)
            if (idx != -1) {
                this.templateIds.splice(idx, 1)
            }
        }
    }
    
    handleNext(){
        console.log("counter"+this.counter);
        if(this.templateIds.length < 1){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: "select at least 1 Template",
                    variant: 'error'
                })
            ); 
        }else{
            //if(!this.isFromPrevious){
            let templateOrderWrapper = [];
            let productOrderWrapper = [];
            let tempIds= [];
            console.log('productIds ', JSON.stringify(this.productIds));
            console.log('templateIds ', JSON.stringify(this.templateIds));
            this.templateIds.forEach((ele)=>{
                if(!tempIds.includes(ele)){
                    tempIds.push(ele);
                }
            });
            this.templateWrapper.forEach((ele)=>{
                if(tempIds && tempIds.includes(ele.id) &&(ele.order !="" || ele.order.length !=0)){
                    templateOrderWrapper.push({
                        id : ele.id,
                        order : ele.order,
                        ProductPayorID:ele.ProductPayorID
                    });  
                }
            })

            this.productWrapper.forEach((ele)=>{
                if(this.productIds && this.productIds.includes(ele.id) &&(ele.order !="" || ele.order.length !=0)){
                    productOrderWrapper.push({
                        id : ele.id,
                        order : ele.order
                    });  
                }
            })

            console.log('templateOrderWrapper ==>', JSON.stringify(templateOrderWrapper));
            console.log('tempIds', JSON.stringify(tempIds));
            createSchedulerTemplates({ //imperative Apex call
                schedulerId: this.recordId, 
                templateIds : tempIds,
                orderIdMap: templateOrderWrapper,
                productIds:productOrderWrapper
            })
            .then(contacts => {
                refreshApex(this.wrapperdata);
                this.counter = this.counter + 1;
                this.dispatchEvent(new CustomEvent('next', {
                    detail: [this.counter, this.recordId]
                }));
                //code to execute if related contacts are returned successfully
            })
            .catch(error => {
                //code to execute if related contacts are not returned successfully
            });
            //} 
        }
    }

    handlePrevious(){
        console.log("counter ==>"+this.counter);
        // code to execute if create operation is successful
        this.counter = this.counter - 1;
        this.dispatchEvent(new CustomEvent('previous', {
            detail: [this.counter, this.recordId]
        }));
        
    }
}