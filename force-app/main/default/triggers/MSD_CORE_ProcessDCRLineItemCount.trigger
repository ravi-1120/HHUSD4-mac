trigger MSD_CORE_ProcessDCRLineItemCount on Data_Change_Request_Line_vod__c (after delete, after insert, after update) {

    Set<id> DCRIds = new Set<id>();
    
    List<Data_Change_Request_vod__c> DCRsToUpate = new List<Data_Change_Request_vod__c>();   

    
    if (Trigger.isUpdate || Trigger.isDelete) {
       for (Data_Change_Request_Line_vod__c item : Trigger.old){
           DCRIds.add(item.Data_Change_Request_vod__c);
       }
    }else{
        for (Data_Change_Request_Line_vod__c item : Trigger.new){
            DCRIds.add(item.Data_Change_Request_vod__c);
        }
    }

    Map<id,Data_Change_Request_vod__c> DCRMap = new Map<id,Data_Change_Request_vod__c>(
        [select id, MSD_CORE_DCR_Line_Item_Count__c 
         from Data_Change_Request_vod__c 
         where id IN :DCRIds]);

    for (Data_Change_Request_vod__c dcr : [select Id, 	MSD_CORE_DCR_Line_Item_Count__c,(select id from Data_Change_Request_Lines_vod__r) from Data_Change_Request_vod__c where Id IN :DCRIds]) {
        DCRMap.get(dcr.Id).MSD_CORE_DCR_Line_Item_Count__c = dcr.Data_Change_Request_Lines_vod__r.size();
        DCRsToUpate.add(DCRMap.get(dcr.Id));
    }

    update DCRsToUpate;
}