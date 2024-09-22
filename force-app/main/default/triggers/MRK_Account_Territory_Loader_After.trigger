trigger MRK_Account_Territory_Loader_After on Account_Territory_Loader_vod__c (after insert, after update) {
    //get integration user
    Id integrationUserId = [SELECT ID FROM User WHERE Name = 'Integration User' LIMIT 1].Id;
    List<GAS_Alignment_History_vts__c> histories = new List<GAS_Alignment_History_vts__c>();
    GAS_Alignment_History_vts__c history;
    Map<String,TSF_vod__c> existingTSFs = new Map<String,TSF_vod__c>();
    List<Id> accountIds = new List<Id>();
    List<TSF_vod__c> TSFs = new List<TSF_vod__c>();
    TSF_vod__c TSF;
    
    if (UserInfo.getUserId() == integrationUserId) {
        
        //Get Account Ids
        for (Account_Territory_Loader_vod__c atl : trigger.new) {
            if (String.isNotBlank(atl.Territory_To_Add_vod__c)) {
                accountIds.add(atl.Account_vod__c);
            }
        }
        
        //exit if we aren't adding any new territories
        if (accountIds.isEmpty()) {
            system.debug('not adding territories. exiting');
            return;
        }
        
        //Get existing TSF
        for (TSF_vod__c t : [SELECT Account_vod__c,Alignment_Type_MRK__c,External_Id_vod__c,Territory_vod__c 
                             FROM TSF_vod__c 
                             WHERE Account_vod__c IN :accountIds]) {
            existingTSFs.put(t.External_Id_vod__c,t);
        } 
        
        //get ODA histories
        List<GAS_Alignment_History_vts__c> odaHistoriesToUpdate = new List<GAS_Alignment_History_vts__c>();
        List<GAS_Alignment_History_vts__c> odaHistories = new List<GAS_Alignment_History_vts__c>();
        odaHistories = [SELECT Account__c,Processed_MRK__c,Source_MRK__c 
                        FROM GAS_Alignment_History_vts__c
                        WHERE Source_MRK__c = 'ODA' AND Processed_MRK__c = false AND Account__c IN :accountIds];
        
        for (Account_Territory_Loader_vod__c atl : trigger.new) {
            if (String.isNotBlank(atl.Territory_To_Add_vod__c)) {
                for (String ut : atl.Territory_To_Add_vod__c.split(';')) {
                    //check if history exists. source = ODA and territory = new territory set process = true and account = account
                    for (GAS_Alignment_History_vts__c h : odaHistories) {
                        if (h.Account__c == atl.Account_vod__c && h.New_Territory__c == ut) {
                         h.Processed_MRK__c = true;
                         odaHistoriesToUpdate.add(h);
                        }
                    }
                
                    history = new GAS_Alignment_History_vts__c();
                    history.Account__c = atl.Account_vod__c;
                    history.Account_Territory_Loader__c = atl.Id;
                    history.New_Territory__c = ut;
                    history.Processed_MRK__c = false;
                    history.Source_MRK__c = 'AM';
                    histories.add(history);
    
                    if (!existingTSFs.containsKey(atl.Account_vod__c + '__' + ut)) {
                        TSF = new TSF_vod__c();
                        TSF.Account_vod__c = atl.Account_vod__c;
                        TSF.Territory_vod__c = ut;
                        TSF.Sync_MRK__c = true;
                        TSFs.add(TSF);
                    }
                }
            }//end if territory to add != null
        }
        
        insert histories;
        insert TSFs;
        if (!odaHistoriesToUpdate.isEmpty()) {
            update odaHistoriesToUpdate;
        }
    }
    
    
}