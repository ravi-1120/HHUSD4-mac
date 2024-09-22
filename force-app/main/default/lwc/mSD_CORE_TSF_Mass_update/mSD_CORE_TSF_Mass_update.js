import { LightningElement, track, wire, api } from 'lwc';
import TSFQuery from '@salesforce/apex/MSD_CORE_TSF_Mass_update.TSFQuery';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//let i=0;

export default class MSD_CORE_TSF_Mass_Update extends LightningElement {
    @track columns = [
        {
            label: 'Account Id',
            fieldName: 'account_Id',
            type: 'url',
            typeAttributes: {label: { fieldName: 'Account_vod__c' }, 
            target: '_blank'},
       },
      
        {
            label: 'Account Name',
            fieldName: 'accountName',
            type: 'text'
        },
        {
            label: 'Call Deck Status',
            fieldName: 'Call_Deck_Status_MRK__c',
            type: 'text'

        },

        {
            label: 'My Target',
            fieldName: 'MSD_CORE_My_Target__c',
            type: 'boolean',
            editable: true
        },
        {
            label: 'Last Activity Date',
            fieldName: 'Last_Activity_Date_vod__c',
            type: 'text'
        },
        {
            label: 'My Last Used Address',
            fieldName: 'preferredName',
            type: 'lookup'
        },
        {
            label: 'My Last Used Location',
            fieldName: 'preferredLocation',
            type: 'lookup'
        },
        {
            label: 'Territory',
            fieldName: 'Territory_vod__c',
            type: 'text'
        } 
    ];

    draftValues = [];

    @track accList;
    @track isLoading = true;
    @track error
    @track wiredTSFList
    @track page = 1;
    @track items = [];
    @track data = [];
    @track startingRecord = 1;
    @track endingRecord = 0;
    @track pageSize = 200;
    @track totalRecountCount = 0;
    @track totalPage = 0;
    @api searchKey = '';
    @api sortedDirection = 'asc';
    @api sortedBy = 'MSD_CORE_My_Target__c,Account_vod__r.Name';



  /*  @wire(TSFQuery, { searchKey: '$searchKey', sortBy: '$sortedBy', sortDirection: '$sortedDirection' })
    wiredAccount(result) {
        this.wiredTSFList = result;
        if (result.data) {
            let nameUrl;
            let address;
            let Lastlocation;
            this.items = result.data.map(row => {
                nameUrl = '/' + row.Account_vod__r.Id;
                //nameUrl = row.Account_vod__r.Id;
                console.log('row ' + JSON.stringify(row));
                if(row.Address_vod__c != null)
                {
                    address = row.Address_vod__r.Name; 
                }
                else{
                    address = '';
                }
                if(row.Preferred_Account_vod__c != null)
                {
                    Lastlocation = row.Preferred_Account_vod__r.Name; 
                }
                else{
                    Lastlocation = '';
                }
                return { ...this.items, account_Id:nameUrl, 
                                        Account_Name: row.Account_vod__r.Name,
                                        Call_Deck_Status:row.Call_Deck_Status_MRK__c,
                                        My_Target:row.MSD_CORE_My_Target__c,
                                        Last_Activity_Date:row.Last_Activity_Date_vod__c,
                                        My_Last_Used_Address:address,
                                        My_Last_Used_Location:Lastlocation,
                                        Territory_vod__c:row.Territory_vod__c
                                    }
            })
          */  
           @wire(TSFQuery , {searchKey:'$searchKey', sortBy: '$sortedBy', sortDirection: '$sortedDirection'})
           wiredAccount(result) {
                                               this.wiredTSFList = result;
if (result.data) {
                                                                                   let nameUrl;
this.items = result.data.map(row=>{
                                                                                   nameUrl = '/'+row.Account_vod__r.Id;   
                                                                                   
if(row.Address_vod__c != null && row.Preferred_Account_vod__c != null){
    return{...row, accountName: row.Account_vod__r.Name,account_Id:nameUrl,preferredName: row.Address_vod__r.Concatenated_Address_MRK__c,preferredLocation:row.Preferred_Account_vod__r.Name}
}else if(row.Address_vod__c != null && row.Preferred_Account_vod__c == null) {
    return{...row, accountName: row.Account_vod__r.Name,account_Id:nameUrl,preferredName: row.Address_vod__r.Name}
}  else if (row.Address_vod__c == null && row.Preferred_Account_vod__c != null){
    return{...row, accountName: row.Account_vod__r.Name,account_Id:nameUrl,preferredLocation:row.Preferred_Account_vod__r.Name}
} else{                                                                           
return{...row, accountName: row.Account_vod__r.Name,account_Id:nameUrl,}
} 
})

            //console.log('Ankur ' + JSON.stringify(this.items));
            this.error = undefined;
            this.totalRecountCount = result.data.length;
            this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
            this.data = this.items.slice(0, this.pageSize);
            this.endingRecord = this.pageSize;
            this.isLoading = false;
        } else if (result.error) {
            this.error = result.error;
            this.record = undefined;
        }
    }
    handleSave(event) {

        const recordInputs = event.detail.draftValues.map(draft => {
            const fields = Object.assign({}, draft)
            return { fields }
        })
        console.log("recordInputs", recordInputs)
        const promises = recordInputs.map(recordInput => updateRecord(recordInput))
        Promise.all(promises).then(result => {
            this.showToastMsg('Success', 'My Targets Updated')
            this.draftValues = []
            return refreshApex(this.wiredTSFList)
        }).catch(error => {
            this.showToastMsg('Error updating record', error.body.message, error)
        })
    }
    showToastMsg(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant || 'success'
            })

        )
    }
    handleKeyChange(event) {
        this.searchKey = event.target.value;
        return refreshApex(this.wiredTSFList);
    }
    sortColumns(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        return refreshApex(this.wiredTSFList);

    }

    previousHandler() {
        if (this.page > 1) {
            this.page = this.page - 1; //decrease page by 1
            this.displayRecordPerPage(this.page);
        }
    }
    nextHandler() {
        if ((this.page < this.totalPage) && this.page !== this.totalPage) {
            this.page = this.page + 1; //increase page by 1
            this.displayRecordPerPage(this.page);
        }
    }
    displayRecordPerPage(page) {
        this.startingRecord = ((page - 1) * this.pageSize);
        this.endingRecord = (this.pageSize * page);

        this.endingRecord = (this.endingRecord > this.totalRecountCount)
            ? this.totalRecountCount : this.endingRecord;

        this.data = this.items.slice(this.startingRecord, this.endingRecord);
        this.startingRecord = this.startingRecord + 1;
    }
}