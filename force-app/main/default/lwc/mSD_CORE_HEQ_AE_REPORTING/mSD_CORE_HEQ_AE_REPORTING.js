import { LightningElement, wire, track} from 'lwc';
import getAssetList from '@salesforce/apex/MSD_CORE_HEQ_AE_REPORTING_Handler.getAssetList';
export default class MSD_CORE_HEQ_AE_REPORTING extends LightningElement {

    get options() {
        return [
            { label: '--', value: 'Please Select a Report Type' },
            { label: 'Assets in My Collection Report', value: 'Assets in My Collection Report' },
            { label: 'My Downloads Report', value: 'My Downloads Report' },
            { label: 'My Shared Collections Report', value: 'My Shared Collections Report' }
        ];
    }
    showReports = false;
    @track error;
    @track assetList ;
    @track lstToBeShown;
    @track recToBeDiplayed;
    reportType;

    @track columns = [];
    
    @wire(getAssetList)
    wiredAccounts({
        error,
        data
    }) {
        if (data) {
            console.log('### Here');
            this.assetList = data;
            console.log('### Here '+JSON.stringify(this.assetList));
        } else if (error) {
            console.log('### Here error '+JSON.stringify(error));
            this.error = error;
        }
    }

    

    handleChange(event) {
        this.columns = [];
        this.reportType = event.detail.value;
        if(this.reportType == 'Please Select a Report Type') {
            this.showReports = false;
        } else {
            if(this.reportType == 'Assets in My Collection Report') {
                this.lstToBeShown = this.assetList.filter((rec) => rec.reportName == 'Assets in My Collection Report');
            } else if(this.reportType == 'My Shared Collections Report') {
                this.lstToBeShown = this.assetList.filter((rec) => rec.reportName == 'My Shared Collections Report');
            }
            
            this.lstToBeShown[0].lstOfFieldsToBeShown.forEach((element) => this.columns.push({label: element.split(';')[0],fieldName: element.split(';')[1],type: 'text',sortable: false}));
            this.showReports = true;
            this.recToBeDiplayed = this.lstToBeShown[0].lstContentShadowDocLinkWrapper
            
        }
        
    }
}