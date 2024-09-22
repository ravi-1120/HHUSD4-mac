trigger MRK_Sample_Send_Before_Insert on Address_vod__c (before insert) {
//bjd 9/27/2012 If Sample Send Status is null, set to Invalid if no phone, valid if phone

for (Integer i = 0 ; i < Trigger.new.size(); i++) {
    If (Trigger.new[i]. Sample_Send_Status_vod__c == NULL) {
        if (Trigger.new[i].Phone_vod__c == NULL)
            Trigger.new[i].Sample_Send_Status_vod__c = 'Invalid_vod'; 
        else
            Trigger.new[i].Sample_Send_Status_vod__c = 'Valid_vod';
    }
}
    
}