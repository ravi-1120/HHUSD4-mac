trigger MSD_CORE_Prevent_Del on Account_Plan_vod__c (before delete) {

/* Code to prevent Deletion of Account Account Plan is Approved or Submitted */

for(Account_Plan_vod__c AP:Trigger.old){

if(AP.Status__c == 'Approved' || AP.Status__c == 'Submitted' || AP.Status__c == 'Revisions Required' ){
    AP.addError('Only Draft Account Plans can be deleted');
}
}
}