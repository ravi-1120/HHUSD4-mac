import RecordTypeSelector from "c/recordTypeSelector";

export default class MyScheduleRecordTypeSelector extends RecordTypeSelector {

    goToNext() {
        this.dispatchEvent(new CustomEvent('newrecordmodalopen', { 
            detail : {
                recordTypeId: this.selectedRtId
            }
        }));
      }
    
      finishFlow() {
        this.exitEarly = true;
        this.dispatchEvent(new CustomEvent('newrecordmodalclose'));
      }

}