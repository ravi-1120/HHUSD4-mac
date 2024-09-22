trigger MRK_Sample_Send_Before_Update on Address_vod__c (before update) {
//bjd 9/10/2012 Set Address Send Status to "Unknown" whenever the address changes
//              Update Sample Send Status based on Address Send Status and Phone
String strRecalc_Send_Status = 'No';

for (Integer i = 0 ; i < Trigger.new.size(); i++) {
    strRecalc_Send_Status = 'No';
    Address_vod__c newAddr = trigger.new[i];
    Address_vod__c oldAddr = trigger.old[i];
    
    //If the address update initiated from a Call Submit, bypass the Unknown logic
    if(!SamplesHelper.shouldAvoidUnknownAddressStatusUpdate()){
    
        if( newAddr.Name != oldAddr.Name ||
            newAddr.Address_line_2_vod__c != oldAddr.Address_line_2_vod__c ||
            newAddr.City_vod__c != oldAddr.City_vod__c ||
            newAddr.State_vod__c != oldAddr.State_vod__c ||
            newAddr.Zip_vod__c != oldAddr.Zip_vod__c) {
        
            newAddr.Address_Send_Status_MRK__c = 'Unknown';
            strRecalc_Send_Status = 'Yes';
        }
    }
    
    if( newAddr.Phone_vod__c != oldAddr.Phone_vod__c ||
        newAddr.Address_Send_Status_MRK__c != oldAddr.Address_Send_Status_MRK__c){
        strRecalc_Send_Status = 'Yes';
    }
    //ONLY If the address, phone or address send status has been modified, 
    //then alter Sample Send Status based on Address Send Status and Phone
    if (strRecalc_Send_Status == 'Yes'){
        if ((newAddr.Address_Send_Status_MRK__c == 'Unknown')
         || (newAddr.Address_Send_Status_MRK__c == 'Valid')){
            if (newAddr.Phone_vod__c == NULL)
                newAddr.Sample_Send_Status_vod__c = 'Invalid_vod';   
            else
                newAddr.Sample_Send_Status_vod__c = 'Valid_vod';
        }
        else
            newAddr.Sample_Send_Status_vod__c = 'Invalid_vod';
    }
}  
}