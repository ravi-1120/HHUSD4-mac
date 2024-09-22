trigger MSD_CORE_SuggestionRequest_BEFORE_INSUPDATE on MSD_CORE_Suggestion_Request__c (before insert, before update) {

//KRB Release 11.0 - Pulled code from Global. 

     Set<Id> Ids = new Set<Id>();
     //Set<String> MDMIds = new Set<String>();
     Set<String> custIds = new Set<String>();
     List<Account> accts = new List<Account>(); 
     Map<String,List<MSD_CORE_Suggestion_Request__c>> requestMap = new Map<String, List<MSD_CORE_Suggestion_Request__c>>();
     
     for(MSD_CORE_Suggestion_Request__c req:Trigger.New){
                custIds.add(req.MSD_CORE_Merck_ID__c);
    
            if(requestMap.containsKey(req.MSD_CORE_Merck_ID__c)) {
                List<MSD_CORE_Suggestion_Request__c> requests = requestMap.get(req.MSD_CORE_Merck_ID__c);
                requests.add(req);
                requestMap.put(req.MSD_CORE_Merck_ID__c, requests);
            } else {
                requestMap.put(req.MSD_CORE_Merck_ID__c, new List<MSD_CORE_Suggestion_Request__c> { req });
                System.debug('Cust ID 0 '+req.MSD_CORE_Merck_ID__c);
        
            }
     }
       System.debug('Cust Ids'+custIds );
     
     for (List<Account> accts : [SELECT id,Merck_ID_MRK__c FROM Account WHERE Merck_ID_MRK__c IN: custIds ]) {
                System.debug('HERE ACCTS'+accts);               
            for(Account acct:accts){
                if(requestMap.containsKey(acct.Merck_ID_MRK__c )) {
                    List<MSD_CORE_Suggestion_Request__c> requests = requestMap.get(acct.Merck_ID_MRK__c );
                    for(MSD_CORE_Suggestion_Request__c rq:requests){
                        rq.MSD_CORE_Account__c = acct.Id;
                        System.debug('Here'+acct.Id);
                    }
                }    
            }    
         
      }

}