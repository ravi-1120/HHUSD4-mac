trigger VEEVA_MOBILE_DEVICE_AFTER_UPSERT on Mobile_Device_vod__c (after insert, after update) {
    List<Mobile_Device_vod__c> mdList = new List<Mobile_Device_vod__c>();
    
    Mobile_Device_vod__c record = Trigger.new[0];
    system.debug('Md record map ' + record);
    
    if (record.Active_vod__c == true) {
        for (Mobile_Device_vod__c md: [Select Active_vod__c From Mobile_Device_vod__c
                                       Where Id != :record.Id And Active_vod__c = true And ((RecordTypeId = :record.RecordTypeId And Device_vod__c = :record.Device_vod__c) Or App_Deleted_Datetime_vod__c != null)]) {
            md.Active_vod__c = false;
            mdList.add(md);

        }
    }
    
    if (mdList.size() > 0) {   
       update mdList;
    }
}