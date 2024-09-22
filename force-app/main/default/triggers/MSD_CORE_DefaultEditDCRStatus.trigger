trigger MSD_CORE_DefaultEditDCRStatus on Data_Change_Request_vod__c (before insert) {
/*
 * KRB 6/15/2015 REL 6.0 - The purpose of this trigger is to default the statuses 
 * of DCRs of Type "Edit". DCRs of Type 'New' will be handled by the MSD_CORE_DCRService Class
*/

    for(Data_Change_Request_vod__c dcr: Trigger.new){
        if(dcr.Type_vod__c == 'Edit_vod'){
            
            if(dcr.Status_vod__c != 'Rejected'){
               dcr.Status_vod__c = 'Submitted';
               dcr.MSD_CORE_DCR_Status__c = 'Pre-Approved';
            }
        } 
    }

}