import { LightningElement,track, api, wire } from 'lwc';
import rightarrow from '@salesforce/resourceUrl/rightarrow2';
import downarrow from '@salesforce/resourceUrl/downarrow';
import getactivity from '@salesforce/apex/MSD_CORE_Notification.getActivity';
import { refreshApex } from '@salesforce/apex';
// import getactivity from '@salesforce/apex/mfr_Notification.getactivity_1';
import USER_ID from "@salesforce/user/Id";
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';


export default class Mfr_activitytab extends NavigationMixin(LightningElement) {

    arrow = rightarrow;
    downarrow = downarrow;
    showmorevar = false;
    showmorevar1 = false;
    refreshApexData;
    @track activitydata = [];
    @api productname;

    totalCount
    pageSize =6
    pageNumber =1
    currentPageReference = null;
    urlStateParameters;
    recId;
    subscription = null;
    @track productNameval;

    @api contentname;
    @track passcontentname;
    

 
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
            console.log('urlStateParameters' , this.urlStateParameters);
            this.recId = this.urlStateParameters.recordId;
            console.log('this.recId' , this.recId);
        }
    }

    renderedCallback() {
        // this.getactivity();
        console.log('<---renderedCallback--->');
        console.log('productname-->',this.productname);
        if(this.productname!=undefined){
            this.productNameval = this.productname;
        }
        
        console.log('this.productNameval In Activity==>',this.productNameval);
        
        
        console.log('contname>>>>>',this.contentname);
    if(this.contentname!=''){
    this.passcontentname = this.contentname;
    }
     console.log('passcontentname>>>>>',this.passcontentname);
    }

    connectedCallback(){
        
    this.getactivitydata();
    }

    getactivitydata(){
        console.log('recId-->',this.recId);
        console.log('USER_ID-->',USER_ID);
        console.log('pageSize-->',this.pageSize);
        console.log('pageNumber-->',this.pageNumber);
        getactivity({userid: USER_ID,prodID: this.recId,pageSize:this.pageSize,pageNumber :this.pageNumber})
        .then((result) => {
            console.log('GET ACTIVITY DATA');
            console.log({result});
            if (result != null) {            
                document.body.scrollTop = document.documentElement.scrollTop = 0;
                this.refreshApexData=result;
                var c = result.notificationList;
                console.log({c});
                this.totalCount = result.totalNotificationRecord;
                console.log(this.totalCount);
                this.activitydata =[];
                var test = [];
                for(var key in c){
                    console.log(key);
                    console.log(c[key]);
                    if (c[key].length > 0) {
                        this.activitydata.push({value:c[key],key:key});
                    }
                }
                console.log('this.activitydata-->',this.activitydata);
            }

        })
        .catch((error)=> {
            console.log({error});
        })
    }


    showmore(){
        console.log('<--SHOW MORE-->');
        this.showmorevar = true;
    }
    hidemore(){
        console.log('<--HIDE MORE-->');
        this.showmorevar = false;
    }
    showmore1(){
      //  this.showmorevar1 = true;
    }
    hidemore1(){
        this.showmorevar1 = false;
    }

    handlePagination(event){
        console.log('Handle Pagination');
        console.log({event});
        console.log('handlePagination',  event.detail.pageNo);
        this.pageNumber = event.detail.pageNo;
        console.log('this.pageNumber-->',this.pageNumber);
    }
    handleCustomEvent(event){
        console.log('Handle CustomEvent');
        console.log({event});
        console.log('handlePagination ---- ',  event.detail);
        this.pageNumber = event.detail;
        console.log('this.pageNumber-->',this.pageNumber);
        this.getactivitydata();
    }
    handleShow(){
        this.showmorevar1=false;
    }
    refreshActivityDetailLWC() {
        this.template.querySelectorAll("c-mfr_activity-detail")
            .forEach(element => {
                element.refreshActivityDetail();
            });
    }
    get showPagination() {
        return this.totalCount <= 6 ? false : true;
    }
}