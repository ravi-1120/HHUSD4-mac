global class MRK_ProcessGasODAlignmntHistBatchable implements Database.Batchable<sObject>{
 
    /*
     * KRB - 3/27/2014 - REL 5.0 
     *   Batch Job processes new One Day Alignment GAS_Alignment_History_vts__c records. 
     *   For each new record added, if the associated Account does not
     *   have an associated unsubmitted calls, adds a Drop to the Accounts ATL 
     *   record for the given New Territory. Once Processed, Job updated the Processed Flag on 
     *   to True so that records are not pulled in during subsequent Batch Runs.
     */
    
    
   global final String Query;

   global MRK_ProcessGasODAlignmntHistBatchable(String q){
      Query=q;
       System.debug('in the constructor...');
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
         system.debug('MRK_ProcessGasODAlignmntHistBatchable: Starting execute Method');           
  
        List<Id> gahODASourceAccountIdList = new List<Id>();
        List<GAS_Alignment_History_vts__c> gahODASourceNoSavedCallsList = new List<GAS_Alignment_History_vts__c>();
       
        //REL 5.1B Enhancement 
        List<GAS_Alignment_History_vts__c> gahODASourceWithSavedCallsList = new List<GAS_Alignment_History_vts__c>();
  
        List<GAS_Alignment_History_vts__c> gahODASourceList = new List<GAS_Alignment_History_vts__c>();
        Map<Id,Integer> gahODASourceAccountsWithSavedCallsMap = new Map<Id,Integer>();
        
        //cache required data: unsubmitted call counts for each account associated to the new records
        for(sObject sObj: scope){
           GAS_Alignment_History_vts__c gah = (GAS_Alignment_History_vts__c)sObj;
           gahODASourceAccountIdList.add(gah.Account__c); //need this for Queries
           gahODASourceList.add(gah);
        }
        
        AggregateResult[] accountsWithSavedCalls
          = [SELECT Account_vod__c, count(Id) 
             FROM   Call2_vod__c
             WHERE  Status_vod__c = 'Saved_vod'
             AND    Account_vod__c in : gahODASourceAccountIdList
             Group By Account_vod__c];
        
       for (AggregateResult ar : accountsWithSavedCalls)  {
          System.debug('Account_vod__c' + ar.get('Account_vod__c'));
          System.debug('count' + ar.get('expr0'));
                     
          gahODASourceAccountsWithSavedCallsMap.put((Id)ar.get('Account_vod__c'), (Integer)ar.get('expr0'));
           
       }
        
       //Data Cached, Entering Processing Logic
       
       //REL 5.1B Enhancement - Added logic to drop Alignment if the Account has saved calls, but those
       //saved calls are not assoicated to the User that created the Temporary Alignment. 
       
       //Need all the Temp Alignment Records, with Account and User Id
       //Use gahODASourceList - GAS_Alignment_History_vts__c
       
       //Need a list of saved Calls - Account_vod__c,CreatedById 
        List<Call2_vod__c> ODAAccountAssociatedSavedCalls = new List<Call2_vod__c>();
        
        ODAAccountAssociatedSavedCalls = new List<Call2_vod__c>(
                    [
                       SELECT Account_vod__c, Territory_vod__c, CreatedById
                       FROM   Call2_vod__c
                       WHERE  Status_vod__c = 'Saved_vod'
                       AND    Account_vod__c in : gahODASourceAccountIdList
                    ]
                   );
 
        
       // REL 5.1B Enhancement - Identify all Non AM Source gah records that DO have a "saved" call... -Start
       List<Id> gahODASourceWithSavedCallsAccountIdList = new List<Id>();
       // REL 5.1B Enhancement - End
  
       //Identify all Non AM Source gah records that do not have a "saved" call... 
       List<Id> gahODASourceNoSavedCallsAccountIdList = new List<Id>();
       
       for(GAS_Alignment_History_vts__c gahODASourceRec : gahODASourceList){
           
           //No Saved Calls
           if(!gahODASourceAccountsWithSavedCallsMap.containsKey(gahODASourceRec.Account__c)){
               gahODASourceNoSavedCallsList.add(gahODASourceRec);
               gahODASourceNoSavedCallsAccountIdList.add(gahODASourceRec.Account__c);
           }
           
           //REL 5.1 Enhancment - Start
           //ODA Has Saved Calls
           else{
               gahODASourceWithSavedCallsAccountIdList.add(gahODASourceRec.Account__c);
               gahODASourceWithSavedCallsList.add(gahODASourceRec);
           }
           //REL 5.1 Enhancment - End

       }       
       
       //5.1B Enhancement - Start
       //for each ODA in the gahODASourceWithSavedCallsList determine if any of the saved Calls
       //have a Territory that matches the "New Territory" Record in the ODA, for the given account. If they do, we dont want to drop the Alignment...
       
       for (GAS_Alignment_History_vts__c ODAwithSavedCallsRec: gahODASourceWithSavedCallsList ){
           boolean ODAHasSavedCallWithMatchingTerritoryAccount = false;
           system.debug('MRK_ProcessGasODAlignmntHistBatchable: in 5.1B code for Loop 1: Account: ' + ODAwithSavedCallsRec.Account__c + ' Territory: ' + ODAwithSavedCallsRec.New_Territory__c);           
           
           for (Call2_vod__c callRec: ODAAccountAssociatedSavedCalls ){

               system.debug('MRK_ProcessGasODAlignmntHistBatchable: in 5.1B code for Loop 2: Account: ' + callRec.Account_vod__c + ' Territory: ' + callRec.Territory_vod__c);                
               
               if((ODAwithSavedCallsRec.Account__c == callRec.Account_vod__c) && 
                  (ODAwithSavedCallsRec.New_Territory__c == callRec.Territory_vod__c)){
                   system.debug('Found a Match...breaking out of loop');                

                   ODAHasSavedCallWithMatchingTerritoryAccount = true;
                   break;
               }
           }
           
           if (!ODAHasSavedCallWithMatchingTerritoryAccount){
               system.debug('ODAHasSavedCallWithMatchingTerritoryAccount value: ' + ODAHasSavedCallWithMatchingTerritoryAccount);                
               gahODASourceNoSavedCallsList.add(ODAwithSavedCallsRec);
               gahODASourceNoSavedCallsAccountIdList.add(ODAwithSavedCallsRec.Account__c);
           }
       }
       
       //5.1B Enhancement - End
       
       //add a ATL drop record for all records in the gahODASourceNoSavedCallsList
       //Pull all the necessary ATL records -> Account_Territory_Loader_vod__c
       Map<Id, Account_Territory_Loader_vod__c> ATLToUpdateMap
           = new Map<Id, Account_Territory_Loader_vod__c> (
            [SELECT Id, Account_vod__c, Territory_to_Drop_vod__c
             FROM   Account_Territory_Loader_vod__c
             WHERE  Account_vod__c in : gahODASourceNoSavedCallsAccountIdList]
           );
       
       /*
         We need to sort all the gahs that we are about to load as Drops. 
         Due to the Future 9 Digit Territory schema, and the 255 field length
         will only handle 25 territory drops for a given account. 
        */
       
       Integer maxTerritories = 25;
        
       List<GAS_Alignment_History_vts__c> gahsToBeMarkedAsProcessed = new List<GAS_Alignment_History_vts__c>();
       
       map<id, list<String>> atlIdTerritoryStringForDropListMap = new map<id, list<String>>(); 
      
       for (GAS_Alignment_History_vts__c gah : gahODASourceNoSavedCallsList){
          //Need to make sure that the ATL record was pull back above. 
          
           if(ATLToUpdateMap.containsKey(gah.Account_Territory_Loader__c)){
 

              if(atlIdTerritoryStringForDropListMap.get(gah.Account_Territory_Loader__c) == null){
                  system.debug('gah.Account_Territory_Loader__c was null');                
                  system.debug('Adding a record for the Following: gah.Account_Territory_Loader__c = ' + gah.Account_Territory_Loader__c);                
                  system.debug('Adding a record for the Following: gah.New_Territory__c = ' + gah.New_Territory__c);                
                  system.debug('Adding a record for the Following: gah.New_Territory__c = ' + gah.Account__c);                

                 atlIdTerritoryStringForDropListMap.put(gah.Account_Territory_Loader__c, new list<String>{gah.New_Territory__c});
                 gahsToBeMarkedAsProcessed.add(gah);
              
              }else{
                  system.debug('gah.Account_Territory_Loader__c NOT null');                

                  if (atlIdTerritoryStringForDropListMap.get(gah.Account_Territory_Loader__c).size() < maxTerritories ){
                    atlIdTerritoryStringForDropListMap.get(gah.Account_Territory_Loader__c).add(gah.New_Territory__c);
                    gahsToBeMarkedAsProcessed.add(gah);
                 }
              }
          }
       
       }
                
        //Fill in the ATL Drop Field
        List <Account_Territory_Loader_vod__c> atlsForUpdateList = new List <Account_Territory_Loader_vod__c>();
 
       for (Id atlId : atlIdTerritoryStringForDropListMap.keySet()){
           
           //For each record, Build the String of Territories to Drop
           List<String> territoryStringList = atlIdTerritoryStringForDropListMap.get(atlId);
 
           String territoriesToDrop = '';
           if (!territoryStringList.isEmpty()){
              
               territoriesToDrop = ';';
               
               for(String x : territoryStringList){
                   territoriesToDrop = territoriesToDrop + x + ';' ;
               }
           }
 
           Account_Territory_Loader_vod__c atlRec =  ATLToUpdateMap.get(atlId);
           atlRec.Territory_to_Drop_vod__c = territoriesToDrop;
                  system.debug('Creating an Account_Territory_Loader_vod__c record: Territories to Drop: ' + territoriesToDrop);                


           atlsForUpdateList.add(atlRec);
       }
        
        for (GAS_Alignment_History_vts__c gahODASouced: gahsToBeMarkedAsProcessed){
            gahODASouced.Processed_MRK__c = true;
        }
        
        update gahsToBeMarkedAsProcessed;
        update atlsForUpdateList;  
   }

   global void finish(Database.BatchableContext BC){
        
     /* Get the ID of the AsyncApexJob representing this batch job
        from Database.BatchableContext.
        Query the AsyncApexJob object to retrieve the current job's information.
     */
       
     AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
     TotalJobItems, CreatedBy.Email
     FROM AsyncApexJob WHERE Id =
     :BC.getJobId()]; 
       
     System.debug('The batch Apex job, MRK_ProcessGasODAlignmntHistBatchable, processed ' + a.TotalJobItems +
      ' batches with '+ a.NumberOfErrors + ' failures.');  
     
   }
    
}