global class VEEVA_BATCH_STATE_LEVEL_RESTRICTIONS implements Database.Batchable<sObject> {
     
    private final String initialState;
    String query;
    // variables to get credentials, states, restricted products
    List<sObject> samplestateObjectList = new List<sObject> (); // this list holds object of type Samples_State_Credential_settings_vod__c
    Set<String> credentialsSet = new Set<String> (); // set that has all the credentials in samples_state_credential_settings_vod__c
    Set<String> stateSet = new Set<String> (); // set that has all the satets in samples_state_credential_settings_vod__c
    // map to hold credential , state, call reminder strings
    Map<String, Map<String, String>> callRemindersPerCredentialPerSateMap = new Map<String, Map<String,String>> ();   
    // map of map
    Map<String, Map<String, Set<String>>> credentialStateProductsMap = new Map<String, Map<String, Set<String>>> ();
    
    global VEEVA_BATCH_STATE_LEVEL_RESTRICTIONS() {
        // this is calling to set initial data
        System.debug('before calling to find in data from constructor');
        getDataFromSampleStateCredentialSetting();    
    }
    
    // private functions to get the credentials, state and restricted products. variables set in this will be used by start and execute method of this class
    private void getDataFromSampleStateCredentialSetting() {    
    
        System.debug('inside the method to fill in the sample state credentials   ');  
        samplestateObjectList = [SELECT Credential_vod__c, State_vod__c, Restricted_Products_vod__c from Samples_State_Credential_settings_vod__c]; 
        
        for (sObject sObj: samplestateObjectList) {
            Samples_State_Credential_settings_vod__c sampleStateObj = (Samples_State_Credential_settings_vod__c) sObj;  
            String credential = sampleStateObj.Credential_vod__c;
            System.debug('the credentials ' + credential); 
            // credential set will be used to query accounts
            credentialsSet.add(credential);
            String state = sampleStateObj.State_vod__c; 
            System.debug('the state ' + state); 
            // stateSet will be used to query accounts
            stateSet.add(state);
            String restrictedProducts = sampleStateObj.Restricted_Products_vod__c; 
            System.debug('the restricted products ' + restrictedProducts); 
            List<String> restrictedProductsList = new List<String> ();
            if (restrictedProducts != null) {// get the list of restricted products for a credential, state which are seperated by ;;
                restrictedProductsList = restrictedProducts.split(';;');
            }
            // display all the restricted products after split for debugging
            for(String restrictedProduct :  restrictedProductsList) {
                System.debug('restrcited products for state  ' + state + '  are  ' + restrictedProduct);
            }
            
            if (credentialStateProductsMap.containsKey(credential)) {
                System.debug('inside populating map credential matched ' + credential);
                Map<String, Set<String>> stateProductsMap = credentialStateProductsMap.get(credential);
                // now check if the state already exists in the map 
                if(stateProductsMap.containsKey(state)) {
                    System.debug('inside populating map state matched ' + state);
                    Set<String> restrictedProductsSet = stateProductsMap.get(state);
                    // now add the list of restricted products to the stae
                    for (String product: restrictedProductsList) {
                        restrictedProductsSet.add(product);    
                    }
                    stateProductsMap.put(state, restrictedProductsSet); 
                    credentialStateProductsMap.put(credential, stateProductsMap); 
                } else { // first time state appearing for the credential                    
                    // so create the product set from the restricted list and add entry to the map for the particular
                    //Map<String, Set<String>> newStateProductsMap = new Map<String, Set<String>> ();
                    Set<String> restrictedProductsSet = new  Set<String> ();
                    for (String product: restrictedProductsList) {
                        restrictedProductsSet.add(product);    
                    }
                    stateProductsMap.put(state, restrictedProductsSet); 
                    credentialStateProductsMap.put(credential, stateProductsMap); 
                    System.debug('first time state getting into map');
                }  
            
            } else { // credential appearing first time so there is no way state or prdocust exist for this credential yet
                Map<String, Set<String>> stateProductsMap = new Map<String, Set<String>> ();
                // so create the product set from the restricted list and add entry to the map
                Set<String> restrictedProductsSet = new  Set<String> ();
                for (String product: restrictedProductsList) {
                    restrictedProductsSet.add(product);    
                }
                stateProductsMap.put(state, restrictedProductsSet);    
                // now add the credential and the state product map
                credentialStateProductsMap.put(credential, stateProductsMap); 
                System.debug('first time credential getting into map');
            }           
                       
        }     
        
        // upload the stae reminder map with the latest. The reason is some more products could have been added as restricted for a particular state
        // for each credential, each state form the reminder string        
        Set<String> credentialKeys = credentialStateProductsMap.keySet();
        for(String credential: credentialKeys) {
            Map<String, set<String>> stateProductsMap = credentialStateProductsMap.get(credential);          
            Set<String> stateKeys = stateProductsMap.keySet();
            for(string state :stateKeys) {
                Set<String> productsPerState = stateProductsMap.get(state);
                String stateCallReminder = null;
                Integer productCount = 0;                
                for(String product: productsPerState) {
                    if (product.equals('null_vod')) { // means if null_vod then its the only and first entry so break
                        stateCallReminder = product;
                        continue;
                    }
                    productCount++;
                    if (productcount > 1) {
                        stateCallReminder = stateCallReminder + ',' +state + '-' + product;  
                    } else { // first time
                        stateCallReminder = state + '-' + product;    
                    }                                     
                }
                // now for a state product based reminders has been added put in the map
                Map<String, String> stateReminderMap = new Map<String, String> ();
                if (callRemindersPerCredentialPerSateMap.containsKey(credential)){
                    // means some state already exists for the credential so just add the new state
                     stateReminderMap = callRemindersPerCredentialPerSateMap.get(credential);                     
                } else { // first time credential appearing
                    stateReminderMap = new Map<String, String> ();
                }
                if (stateCallReminder != null) {
                    stateReminderMap.put(state, stateCallReminder);
                    System.debug(' the call reminder for state ' + state + ' is ' + stateCallReminder);
                    callRemindersPerCredentialPerSateMap.put(credential, stateReminderMap); 
                }                                             
            }            
        }
        
        // display the credential state reminder strings
        for(String credential: credentialKeys) {
            if (callRemindersPerCredentialPerSateMap.containsKey(credential)) {
                Map<String, String> testMap = callRemindersPerCredentialPerSateMap.get(credential);
                Set<String> stateKeys = testMap.keySet();
                for(String state: stateKeys){
                    system.debug('omg please work ');
                    system.debug('for credential value '+ credential + 'state reminder for state ' + state + ' is ' + testMap.get(state));                
                }
            }            
        }        
        
        // for debug purposes display all the map values
        Set<String> credSet = credentialStateProductsMap.keySet();
        for(String credKey:credSet) {
            System.debug('cred keys initially  ' + credKey);           
        }
        // for all the credentials display the state and products for debugging
        for(String credKey:credentialsSet) {
            Map<String, Set<String>> testMap = credentialStateProductsMap.get(credKey);
            Set<String> stateKeys = testMap.keySet();
            for(String stateKey:stateKeys) {
                System.debug('state keys initially ' + stateKey + 'for credential ' + credKey); 
                // now display the products for state
                Set<String> productSet = testMap.get(stateKey);
                for(String prod:productSet) {
                    System.debug('product for state ' + stateKey + 'is  ' + prod); 
                    // now display the products for state
                }
            }
        }
    }
    
    // private function to return state call reminder for a credential
    private String getCallReminderForCredentialStates(String credentialAccount, Set<String> childProcessedStates){
        String call_reminder = null;
        Integer count = 0;
        Map<String, Set<String>> stateProdcutMap =   credentialStateProductsMap.get(credentialAccount);
        for (String state_vod:childProcessedStates) {                  
            System.debug('inside the for loop for address objects the state is  ' + state_vod);
            if(stateProdcutMap.containsKey(state_vod)) {
            // get all the products                                                                                    
                Set<String> productsPerState = stateProdcutMap.get(state_vod);                            
                if (productsPerState != null) {
                    // form the call reminder string for each of the state/ products                                
                    for (String restrictedProduct: productsPerState) {
                        if (restrictedProduct.equals('null_vod')) {
                            continue; // this means skip the processing for this state/ product since the products have been wiped out
                        }
                        count++; 
                        System.debug('inside the for loop for products per state ' + state_vod);
                        if (count == 1) { // first time add the credential to the string
                            call_reminder = '[' +  credentialAccount + '] ';   
                        } else {
                            call_reminder = call_reminder + ',';    
                        }                                                          
                        call_reminder = call_reminder + state_vod + '-' + restrictedProduct; 
                        System.debug(' formation of call reminder strings ' + call_reminder);
                    }                       
                }                    
            } 
        } 
        return call_reminder;        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {                 
        
        // This query gets all the accounts that need to be updated        
        query = 'Select id, Call_Reminder_vod__c,Credentials_vod__c, Name, IsPersonAccount,' +
              ' (Select Parent_Account_vod__r.Call_Reminder_vod__c, Parent_Account_vod__r.Id from Child_Account_vod__r),'+ 
              ' (Select State_vod__C from Address_vod__r where State_vod__c in :stateSet)' +
              ' from Account where Credentials_vod__c  in :credentialsSet'; 
        System.debug('query statement to fetch data   '  + query);        
        return Database.getQueryLocator(query);
    }
    
    
    global void execute(Database.BatchableContext BC, List<sObject> batch) {
        
        // Loop through all the accounts and find if Call_Reminder_vod__c has changed for the given condition is yes update the field.
        // format of value that need to be updated is [CD1] s1-p1,s1-p2,s2-p1,s3-p3;;[CD2] s1-p1,s2-p4 where CDx- credential, sx- state and px- product 
        // create a map with salesforce id as key and call_reminder to be updated as value
        
        System.debug('inside the execute method');
        Map<String, String> updateObjectMap = new Map<String, String> ();
       
        // now for all the accounts in the batch fetch the parent account if exists and get the states from address
        Map<String, Map<String, Set<String>>> ChildParentAccountStatesMap = new Map<String, Map<String, Set<String>>> ();
        Map<String, Set<String>> ChildParentIdMap = new Map<String, Set<String>> ();
        Set<String> parentAccountIds = new Set<String> ();
        
        // we need another data structure for holding the call reminder string of all parent
        Map<String, Set<String>> parentIdCallReminderMap = new Map<String, Set<String>> ();
        // for Business account call reminder processing we need to fill in what credential and what state has been processed 
        //already so we can recreate the call reminder per credebntial per state
        Map<String, Map<String, Set<String>>> prarentIdCredentialStatesMap = new Map<String, Map<String, Set<String>>> ();
        
        for (sObject accountObj : batch) {            
            Account updateAccount = (Account) accountObj;
            String accountId = updateAccount.Id;
            String accountName = updateAccount.Name;
            SObject[] childAccountObjects = accountObj.getSObjects('Child_Account_vod__r');
            if (childAccountObjects != null) { // this account is a child of some parent
                // this is a child of some parent so look for states only that matches parent and see if parent call_reminder need updating as well
                System.debug('initializing parent account states'); 
                Integer childCount = 0;
                for(SObject childAccount: childAccountObjects) {
                    childCount++;
                    system.debug('no of child objects got form the relation is ' + childCount);
                    Child_Account_vod__c childAct = (Child_Account_vod__c) childAccount;  
                    String parentAccountId = childAct.Parent_Account_vod__r.Id; 
                    parentAccountIds.add(parentAccountId);
                    // check if the entry exists or new
                    if (ChildParentIdMap.containsKey(accountId)) {
                        Set<String> parentIdsSet = ChildParentIdMap.get(accountId);
                        parentIdsSet.add(parentAccountId);
                        ChildParentIdMap.put(accountId, parentIdsSet);
                    } else {
                        Set<String> parentIdsSet = new Set<String> ();
                        parentIdsSet.add(parentAccountId);
                        ChildParentIdMap.put(accountId, parentIdsSet);
                    }                               
                    
                    // for all parent id create a entry for call reminder sets
                    String parent_call_reminder = childAct.Parent_Account_vod__r.Call_Reminder_vod__c;             
                    Set<String> callReminderSet = new Set<String> ();
                    if (parent_call_reminder != null) {
                        System.debug('existing call reminder is ');
                        List<String> callRemindersPerCredential = parent_call_reminder.split(';;');
                        // now fill in the map with the call reminder lists                         
                        for (String callReminder: callRemindersPerCredential) {                            
                            callReminderSet.add(callReminder);    
                        }
                        System.debug(' for the parent account ' + parentAccountId + ' call reminder is ' + parent_call_reminder);                    
                        parentIdCallReminderMap.put(parentAccountId, callReminderSet);                         
                    }                   
                }
            }          
        }
        
        // now for each parent id, and the call reminder see what credential and what state is already there
        Boolean validCred = false;
        Boolean validStateForCredential = false;
        if (parentIdCallReminderMap.size() > 0 ) {
            Set<String> parentIdsForReminder = parentIdCallReminderMap.keySet();
            for (String parentId: parentIdsForReminder) {
                Set<String> callReminders = parentIdCallReminderMap.get(parentId);
                for(String callReminder: callReminders) {
                    // now for each call reminder find out what credential and state it belomgs to
                    for(String credential: credentialsSet) {
                        // check if the string contains this credential
                        if (callReminder.contains(credential)) {
                            validCred = true;
                            // now look at the vaild states of this credential and see what states the credential has been processed
                            Map<String, set<String>> stateProductsMap = credentialStateProductsMap.get(credential);          
                            Set<String> stateKeys = stateProductsMap.keySet();
                            for(string state :stateKeys) { 
                                if (callReminder.contains(state)) {
                                    // now if cred is valid add this state for the parent id and credential
                                    if (validCred) {
                                        if (prarentIdCredentialStatesMap.containsKey(parentId)) {
                                            // parent id already exists see if the credential exists
                                            Map<String, Set<String>> credStatesMap = prarentIdCredentialStatesMap.get(parentId);
                                            if (credStatesMap.containsKey(credential)) {
                                                Set<String> statesSet = credStatesMap.get(credential);
                                                statesSet.add(state);
                                                credStatesMap.put(credential, statesSet);
                                                prarentIdCredentialStatesMap.put(parentId, credStatesMap);
                                            } else { // first time credential entering for the map
                                                Map<String, Set<String>> credStateMap = new Map<String, Set<String>> ();
                                                Set<String> statesSet = new Set<String> ();
                                                statesSet.add(state);
                                                credStateMap.put(credential, statesSet);
                                                prarentIdCredentialStatesMap.put(parentId, credStateMap);
                                            }
                                        } else { // first time entry for parent
                                            Map<String, Set<String>> credStatesMap = new Map<String, Set<String>> ();
                                            Set<String> statesSet = new Set<String> ();
                                            statesSet.add(state);
                                            credStatesMap.put(credential, statesSet);
                                            prarentIdCredentialStatesMap.put(parentId, credStatesMap);
                                        }
                                    }
                                }
                            }
                        }                    
                    }
                }                
            }
        } 
        
        // now for all the parent id fetch the address object to get the states
        String queryParentAddress = 'Select Account_vod__c, State_vod__c from Address_vod__c where Account_vod__c in :parentAccountIds' ;
        List<Address_vod__c> addressObjectsParent = Database.query(queryParentAddress);
        
        // now browse through the results and fill in the states for the appropriate parent/ child combination
        for(Address_vod__c addressObj:  addressObjectsParent) {            
            System.debug('inside the for loop for fetching parent states query was successful');
            String state_vod = addressObj.State_vod__c;
            String account_vod = addressObj.Account_vod__c;
            // now get all the child and see whose parent this record is
            Set<string> childIdKeys = ChildParentIdMap.keySet();
            for(String childId: childIdKeys) {
                Set<String> parentIdsSet = ChildParentIdMap.get(childId);
                // debuggin output
                for (String parentId: parentIdsSet) {
                    System.debug('entry for child id ' + childId + 'list of parent is ' + parentId);
                }
                
                // check if the parent is equal to the current record fetched
                if(parentIdsSet.contains(account_vod)) { // parents child has been identified move on to filling the data
                    // now update the states for this entry
                    // check first time entry or not
                    if (ChildParentAccountStatesMap.containsKey(childId)) {
                        Map<String, Set<String>> ParentIdStatesMap = ChildParentAccountStatesMap.get(childId);
                        if (ParentIdStatesMap.containsKey(account_vod)) {
                            Set<String> parentStates = ParentIdStatesMap.get(account_vod);
                            parentStates.add(state_vod);
                            ParentIdStatesMap.put(account_vod, parentStates);
                            ChildParentAccountStatesMap.put(childId, parentIdStatesMap);                             
                        } else { // first time this parent appearing for the child
                            System.debug('first time parent entering for child ' + childId + 'for parent new ' + account_vod + 'states ' + state_vod);
                            Set<String> parentStates = new Set<String> ();
                            parentStates.add(state_vod);
                            ParentIdStatesMap.put(account_vod, parentStates);
                            ChildParentAccountStatesMap.put(childId, parentIdStatesMap);
                        }                        
                    } else { // first entry for the child
                        Map<String, Set<String>> ParentIdStatesMap = new Map<String, Set<String>> ();
                        Set<String> parentStates = new Set<String> ();
                        parentStates.add(state_vod);
                        ParentIdStatesMap.put(account_vod, parentStates);
                        ChildParentAccountStatesMap.put(childId, parentIdStatesMap);  
                        
                    }                   
                }                
            }                 
        }
        
        // for all the parent child display the parent child states map just for debugging        
        Set<String> childKeys = ChildParentAccountStatesMap.keySet();
        for (String childID: childKeys) {
            Map<String, Set<String>> testMap = ChildParentAccountStatesMap.get(childID);
            Set<String> parentKeys = testMap.keySet();
            for(String parentId :parentKeys) {
                System.debug('child id  ' + childId + 'and parentKey ' + parentId); 
                // now display the products for state
                Set<String> states = testMap.get(parentId);
                for(String state:states) {
                    System.debug('state for parent id  ' + parentId + 'is  ' + state); 
                    // now display the products for state
                }
            }
        }
        
        // now the actual processing since we got all the data
        for (sObject accountObj : batch) {            
            Account updateAccount = (Account) accountObj;
            String accountId = updateAccount.Id;
            String accountName = updateAccount.Name;
            Boolean isPersonAcct = updateAccount.IsPersonAccount;
            String credentialAccount = updateAccount.Credentials_vod__c;
            String callReminderAccount = updateAccount.Call_Reminder_vod__c;
            SObject[] addressObjects = accountObj.getSObjects('Address_vod__r');
            // get the child account relationship
            SObject[] childAccountObjects = accountObj.getSObjects('Child_Account_vod__r');          
            String parentAccountId;
            Set<String> callReminderSet = new Set<String> (); 
            String reminderToRemove = null;
            
            if (childAccountObjects != null) { // this account is a child of some parent
                // this is a child of some parent so look for states only that matches parent               
                System.debug('initializing parent accout states'); 
                // fetch the child states
                Set<String> childStates = new Set<String> ();
                if (addressObjects != null) {
                    for (SObject addressObj:addressObjects) {                    
                        Address_vod__c addrObject = (Address_vod__c) addressObj;
                        String state_vod = addrObject.State_vod__c;
                        System.debug(' child states for child id ' + accountId + ' are ' + state_vod);
                        childStates.add(state_vod);
                    }
                }               
                
                
                // now we have child states as well as parent states do processing for child call reminder
                Map<String, Set<String>> stateProdcutMap =   credentialStateProductsMap.get(credentialAccount);       
              
                // if the credential is not there we do not have to find a match for state         
                Set<String> reminderStates = new Set<String> ();
                
                if (stateProdcutMap != null) { // means there is a match for the credential
                    for (String state_vod: childStates) {                        
                        if(stateProdcutMap.containsKey(state_vod)) {
                            //for this credential and state there is a valid credential with restricted product
                            reminderStates.add(state_vod);
                        }                                             
                    }
                }
                
                // now for the current string and see if update is needed for the child
                String newReminder = getCallReminderForCredentialStates(credentialAccount, reminderStates);
                // find the match and update only if the account needs updating
                if (newReminder != null) { 
                    if (callReminderAccount != null) {
                        if (!(callReminderAccount.equals(newReminder))) {
                            // needs updating for the person account who is child for some parent                                    
                            updateObjectMap.put(accountId, newReminder);
                            System.debug('not equal case');
                            System.debug('call reminder need to be updated for childId ' + accountId + ' with string ' + newReminder);
                        }
                    } else { // account does not have anything yet so just update it
                        updateObjectMap.put(accountId, newReminder);
                        System.debug('no call reminder case');
                        System.debug('call reminder need to be updated for childId ' + accountId + ' with string ' + newReminder);
                    }
                } else { // could be the case only state the credential had needs to be wiped out
                     if (callReminderAccount != null) { // if call reminder was not null but the new reminder is null lets remove this value and update
                         updateObjectMap.put(accountId, newReminder);
                         System.debug('not equal case');    
                     }                
                }
                
                Integer parentCount = 0;                
                // for this child get the parent states
                // get the parent states
                
                Set<String> childProcessedState = new Set<String> ();
                
                for(SObject childAccount: childAccountObjects) { // process all parents of this child
                    
                    parentCount++;
                    System.debug('parent count for account ' + accountId + ' is ' + parentCount);
                    Child_Account_vod__c childAct = (Child_Account_vod__c) childAccount;  
                    parentAccountId = childAct.Parent_Account_vod__r.Id;                 
                   
                    // now for this batch get the call reminders split per credential
                    callReminderSet = parentIdCallReminderMap.get(parentAccountId); 
                    
                    // get the parent states for a child
                    Set<String> parentStates = new Set<String> ();
                    if (ChildParentAccountStatesMap.containsKey(accountId)) {
                        Map<String, Set<String>> childParentStateMap = ChildParentAccountStatesMap.get(accountId);                        
                        // now for this child, this parent get the states
                        Set<String> parentIds = childParentStateMap.keySet();
                        for (String parentId: parentIds) {
                            if (parentId.equals(parentAccountId)) {
                                parentStates = childParentStateMap.get(parentAccountId);  
                                System.debug('fetching the parent states for child id ' +  accountId + 'from the database for parent id ' + parentAccountId + 'states are ' + parentStates);    
                            }
                        }                        
                    }        
                    
                    // if the credential is not there we do not have to find a match for state
                    boolean call_reminder_childAccount = false;  
                    Integer count = 0; 
                
                    Set<String> parentChildMatchedStates = new Set<String> ();
                    if (stateProdcutMap != null) { // means there is a match for the credential                      
                        for (String state_vod: childStates) {                        
                            if(stateProdcutMap.containsKey(state_vod) && (parentStates.contains(state_vod))) {
                                parentChildMatchedStates.add(state_vod);
                                System.debug(' matched state between child and parent ' + state_vod);
                                call_reminder_childAccount = true;                                                      
                            }                                             
                        }
                        // now update the child accounts call_reminder if needed and update the parent account call reminder as well
                        if (call_reminder_childAccount) {                                                   
                            // now check if the parent account call reminder needs updating 
                            //Boolean modifiedAny = false;
                            // check for this parent id if call reminder string exists for this state and this credential
                            Boolean addCredentialReminder = false;
                            Boolean credForStateNotMatching = false;
                            Boolean stateForCredNotExisting = false;
                            Boolean firstReminder = false;
                            System.debug(' just before checking the map contains parentId ');
                            System.debug(' size of the map is ' + parentIdCallReminderMap.size() + ' parent id is '+ parentAccountId); 
                            if(parentIdCallReminderMap.containsKey(parentAccountId)) {
                                // now for this parent id there is already some call reminders check if it belongs to this credential and state
                                Set<String> callReminders = parentIdCallReminderMap.get(parentAccountId);
                                system.debug(' the value of call reminder is for debugging' + callReminders);
                                for(String callReminderPerCred: callReminders) {
                                    // just display the value
                                    system.debug(' the values of call reminder for parent id ' + parentAccountId + ' is ' + callReminderPerCred);
                                }
                                String callReminderForThisCredential = null;
                                for(String callReminderPerCred: callReminders) {
                                    if (callReminderPerCred != null) {
                                        if (callReminderPerCred.contains(credentialAccount)) {
                                            callReminderForThisCredential = callReminderPerCred; 
                                        }
                                    }
                                }                         
                            
                                if(callReminderForThisCredential  != null) {
                                    // now move on to see if the call reminders has the state which we are processing now
                                    for(String processedState: parentChildMatchedStates) {
                                        if(callReminderForThisCredential.contains(processedState)) {
                                            // now check if the state call reminder is up to date
                                            Map<String, String> stateRemindersPerCred = callRemindersPerCredentialPerSateMap.get(credentialAccount);
                                            system.debug('the credential value is ' + credentialAccount);
                                            String stateReminder = stateRemindersPerCred.get(processedState);
                                            System.debug('state reminder for state ' + stateReminder + 'and compared cred' + callReminderForThisCredential );
                                            system.debug('parent id is ' + parentAccountId + ' credential is ' + credentialAccount + ' state is ' + processedState);
                                            if (stateReminder != null) {
                                                if (!(callReminderForThisCredential.contains(stateReminder))) {                                                                                              
                                                    callReminders.remove(callReminderForThisCredential);
                                                    parentIdCallReminderMap.put(parentAccountId, callReminders); 
                                                    credForStateNotMatching = true;
                                                    System.debug('state reminder not matching for parent id ' + parentAccountId);
                                                }
                                            }                                            
                                        } else { // now this is new state for the existing credential for this business account.                                           
                                            stateForCredNotExisting = true;
                                            callReminders.remove(callReminderForThisCredential);
                                            parentIdCallReminderMap.put(parentAccountId, callReminders);
                                        }
                                    }
                                } else { // for this parent id first time credential is appearing so add the credential based string to the set                                   
                                    addCredentialReminder = true;                                     
                                } 
                            
                                if (addCredentialReminder) {
                                    // here we need to process and add all credentials of all states processed so far for the parent id
                                    String callReminderToList = getCallReminderForCredentialStates(credentialAccount, parentChildMatchedStates);
                                    if (callReminderToList != null) {
                                        callReminders.add(callReminderToList);
                                        System.debug('entry for the second time for the parent id is ' + parentAccountId + 'is ' + callReminderToList);
                                        parentIdCallReminderMap.put(parentAccountId, callReminders);
                                    }                                     
                                    
                                    // add entry into parent, credential and state
                                    // might be a new call reminder for this parent id but there may be other credentials processed
                                    if (prarentIdCredentialStatesMap.containsKey(parentAccountId)) {
                                        Map<String, Set<String>> credentialStates  = prarentIdCredentialStatesMap.get(parentAccountId);                                        
                                        if (credentialStates.containsKey(credentialAccount)) { // for this  parent , this credential there are already states
                                            Set <String> states = credentialStates.get(credentialAccount);
                                            states.addAll(parentChildMatchedStates);
                                            credentialStates.put(credentialAccount, states);
                                            prarentIdCredentialStatesMap.put(parentAccountId, credentialStates);                                        
                                        } else { // for this parent id this is new credential
                                            Set<String> states = new Set<String> ();
                                            for(String processedState: parentChildMatchedStates) {
                                                states.add(processedState);   
                                            }
                                            Map<String, Set<String>> credentialStatesSet = new Map<String, Set<String>> ();
                                            credentialStatesSet.put(credentialAccount, states);
                                            prarentIdCredentialStatesMap.put(parentAccountId, credentialStatesSet);
                                       }
                                    }
                                    
                                }
                                if (credForStateNotMatching || stateForCredNotExisting) { //this case already a credential exists 
                                    // for this credential and for this states and also for the states alredy processed form a call reminder string and update map
                                    System.debug('either state did not exist or did not match ' + parentAccountId );
                                    Set<String> callRemindersSet = parentIdCallReminderMap.get(parentAccountId);
                                    String newCallReminder = null;
                                    Set<String> combinedStates = new Set<String> ();
                                    if (parentChildMatchedStates != null) {
                                        combinedStates.addAll(parentChildMatchedStates);
                                    }
                                    Map<String, Set<String>> credentialStatesMap = prarentIdCredentialStatesMap.get(parentAccountId);
                                    Set<String> statesSet = credentialStatesMap.get(credentialAccount);
                                    if (statesSet != null) {
                                        combinedStates.addAll(statesSet);
                                    }
                                    // now we reformed the credential reminder for all states update the string
                                    newCallReminder = getCallReminderForCredentialStates(credentialAccount, combinedStates);
                                    if (newCallReminder != null) {
                                        callRemindersSet.add(newCallReminder);
                                        System.debug(' new call reminder for already exisitng condition is ' + newCallReminder);
                                        parentIdCallReminderMap.put(parentAccountId, callRemindersSet); 
                                    }
                                    
                                    // add the cred and states as processed
                                    Map<String, Set<String>> credentialStates = prarentIdCredentialStatesMap.get(parentAccountId);
                                
                                    if (parentChildMatchedStates != null) {
                                        Set<String> states = credentialStates.get(credentialAccount);
                                        if (states != null) {
                                            states.addAll(combinedStates);
                                            credentialStates.put(credentialAccount, states);
                                        }                                   
                                    }
                                    prarentIdCredentialStatesMap.put(parentAccountId, credentialStates);
                                }                        
                            } else {
                                // add the call reminder text to the map and also the state processed for the credential
                                System.debug('first time entry getting inside map for parent id ' + parentAccountId);                                 
                                // here add the call reminder for the credential and the state
                                String callReminderToList = getCallReminderForCredentialStates(credentialAccount, parentChildMatchedStates);
                                system.debug(' first time credential for parent the call reminder value is ' + callReminderToList);
                                if (callReminderToList != null) {
                                    firstReminder = true;
                                    Set<String> callReminders = new Set<String> ();
                                    callReminders.add(callReminderToList);
                                    parentIdCallReminderMap.put(parentAccountId,callReminders);
                                    // also add the credential and state to the parent id association to know which one has been processed for this batch
                                    Set<String> states = new Set<String> ();
                                    for(String processedState: parentChildMatchedStates) {
                                        System.debug('states processed for parent id  ' + parentAccountId + 'for state ' + processedState);
                                        states.add(processedState);   
                                    }
                                    Map<String, Set<String>> credentialStates = new Map<String, Set<String>> ();
                                    credentialStates.put(credentialAccount, states);
                                    prarentIdCredentialStatesMap.put(parentAccountId, credentialStates); 
                                    System.debug(' first entry into the parentId cred Map for id ' + parentAccountId + 'call reminder ' + call_reminder_childAccount);
                                }                         
                            }
                            if (addCredentialReminder || credForStateNotMatching || stateForCredNotExisting || firstReminder) {
                                // here parent record to be put in update map
                                Set<String> finalCallReminders = parentIdCallReminderMap.get(parentAccountId);
                                if (finalCallReminders != null) {
                                    List<String> updateLst=  new List<String> (); //finalCallReminders.addAll();
                                    updateLst.addAll(finalCallReminders);
                                    String updatedReminder = String.join(updateLst, ';;');
                                    updateObjectMap.put(parentAccountId, updatedReminder);
                                    System.debug('complicated business account call reminder update for parent id  ' + parentAccountId + ' the reminder is'  + updatedReminder );                   
                                }
                            }
                        }                    
                    }
                }// end for loop for all the parent objects check
            } else { // this account is a person account who is not a child of any parent so just update the call_reminder_vod based on credential/ state match
                
                System.debug('inside the else part for PA with no parent');
                Set<String> credSet1 = credentialStateProductsMap.keySet();
                for(String credKey:credSet1) {
                    System.debug('cred keys initially  ' + credKey);           
                }           
                
                Map<String, Set<String>> stateProdcutMap =   credentialStateProductsMap.get(credentialAccount);
                // for debugging display the map value
                Set<String> credSet = credentialStateProductsMap.keySet();
                for (String credKey: credSet) {
                    System.debug(' credential keys when fetching'  + credKey );    
                }
                System.debug('the value of state product map for credential ' + credentialAccount + 'is ' +  stateProdcutMap);
              
                // if the credential is not there we do not have to find a match for state 
                String call_reminder = null;  
                if (stateProdcutMap != null) { // means there is a match for the credential
                     System.debug('inside the if loop if state product map is not null ');
                    Set<String> childStates = new Set<String> ();
                    if (addressObjects != null) {
                        for (SObject addressObj:addressObjects) {                    
                            Address_vod__c addrObject = (Address_vod__c) addressObj;
                            String state_vod = addrObject.State_vod__c;  
                            System.debug('inside the for loop for address objects the state is  ' + state_vod);
                            childStates.add(state_vod);                            
                        } // now for the particular credential we found all the state that matches and formed the call_reminder_vod string
                    }
                    call_reminder = getCallReminderForCredentialStates(credentialAccount,childStates);
                    if (call_reminder != null) {
                        // find the match and update only if the account needs updating
                        if (callReminderAccount != null) {
                            if (!(callReminderAccount.equals(call_reminder))) {
                                updateObjectMap.put(accountId, call_reminder);
                                System.debug('the call reminder that need to be updated for  ' + accountName + 'for credential ' + credentialAccount + ' is  ' + call_reminder); 
                            }
                        } else { // call reminder of the person account is empty so update is needed
                            updateObjectMap.put(accountId, call_reminder);
                            System.debug('the call reminder that need to be updated for  ' + accountName + 'for credential ' + credentialAccount + ' is  ' + call_reminder);                            
                        }
                    }  else { // if this is null check if account had reminder could be null_vod case need to be removed
                         if (callReminderAccount != null) {
                             updateObjectMap.put(accountId, call_reminder);
                             system.debug('case all the state or one state has null_vod so the call reminder need to be wiped out');
                         }
                    
                    }             
                } // credential matched                            
            }                          
        }
        
        // now lets display all the call reminders that need to be updated for each account
        Set<String> updateAccountIds = updateObjectMap.keySet();
        for(String accId: updateAccountIds) {
            System.debug(' the call reminder to be updated for account id  ' + accId + ' call remider string is ' +  updateObjectMap.get(accId) );            
        }
        
        // update methods to update the call reminders in the map  
        List<Account> accountsUpdateList = [Select Id, Call_Reminder_vod__c from Account where Id = :updateAccountIds];
        for(Account acct: accountsUpdateList) {
            for(String acctId: updateAccountIds) {
                String accountId = acct.Id;
                if (accountId.equals(acctId)) { 
                    acct.Call_Reminder_vod__c = updateObjectMap.get(acctId);                    
                }
            }
        }
        // now all are filled in just call update
        update accountsUpdateList;
        
}

global void finish(Database.BatchableContext BC) {
        // Access initialState here
        System.debug('inside the finish method');
    }
}