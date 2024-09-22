public class VeevaSignatureRequestTestUtil {
    
    private static Account testAccount;
    public static String sigReqUUID = 'TestUUID';
        
    public static Map<Signature_Request_vod__c, Call2_vod__c> createSignatureRequestsWithCalls(
        Integer numCallsAndSigReqs, boolean linkSigReqUUIDToCall, boolean linkAccountToCall, boolean linkCallToSigReq, 
        boolean linkAccountToSigReq, String sigReqStatus, boolean insertCalls, boolean insertSigReqs) {
        
        List<Call2_vod__c> calls = null;
        if(linkSigReqUUIDToCall) {
            calls = createCalls(numCallsAndSigReqs, sigReqUUID, linkAccountToCall, insertCalls);
        } else {
            calls = createCalls(numCallsAndSigReqs, null, linkAccountToCall, insertCalls);
        }
        
        List<Call2_vod__c> callsToLink = null;
        if(linkCallToSigReq) {
            callsToLink = calls;
        }
        
        String accountId = null;
        if(linkAccountToSigReq) {
            Account newAccount = createAccount('TestingSigReqs1');
            accountId = newAccount.Id;
        }
        
		List<Signature_Request_vod__c> sigReqs = 
            createSignatureRequests(numCallsAndSigReqs, sigReqUUID, callsToLink, accountId, sigReqStatus, insertSigReqs);  
            
        Map<Signature_Request_vod__c, Call2_vod__c> sigReqToCallMap = new Map<Signature_Request_vod__c, Call2_vod__c>();
        for(Integer i=0; i<numCallsAndSigReqs; i++) {
            sigReqToCallMap.put(sigReqs.get(i), calls.get(i));
        }
            
        return sigReqToCallMap;
    }
    
    public static List<Call2_vod__c> createCalls(Integer numCalls, String sigReqUUIDForCall, boolean linkAccount, boolean insertCalls) {
        Account acc = null;
        if(linkAccount) {
        	acc = getTestAccount();
        }
        
        List<Call2_vod__c> calls = new List<Call2_vod__c>();
        for(Integer i=0; i<numCalls; i++) {
            String accountId = null;
            if(linkAccount) {
                accountId = acc.Id;
            }
            
            String newSigReqUUID = null;
            if(sigReqUUIDForCall != null) {
                newSigReqUUID = sigReqUUIDForCall+i;
            }
            
            calls.add(createCall(newSigReqUUID, accountId));
        }
        
        if(insertCalls) {
        	insert calls;
        }
        
        return calls;
    }
    
    public static Call2_vod__c createCall(String sigReqUUIDForCall, String accountId) {
        Call2_vod__c call = new Call2_vod__c(Signature_Request_UUID_vod__c = sigReqUUIDForCall, Account_vod__c = accountId);
		return call;
    }
    
    public static List<Signature_Request_vod__c> createSignatureRequests(
        Integer numSigReqs, String sigReqUUID, List<Call2_vod__c> calls, String accountId, String status, boolean insertSigReqs) {
        return createSignatureRequests(numSigReqs, sigReqUUID, calls, accountId, status, Datetime.now(), insertSigReqs);
    }
    
    public static List<Signature_Request_vod__c> createSignatureRequests(
        Integer numSigReqs, String sigReqUUID, List<Call2_vod__c> calls, String accountId, String status,
        DateTime engageLastModifiedDT, boolean insertSigReqs) {
        List<Signature_Request_vod__c> sigReqs = new List<Signature_Request_vod__c>();
        for(Integer i=0; i<numSigReqs; i++) {
            String callId = null;
            if(calls != null) {
                callId = calls.get(i).Id;
            }
            
            sigReqs.add(createSignatureRequest(sigReqUUID+i, callId, accountId, status, engageLastModifiedDT));
        }
            
        if(insertSigReqs) {
            insert sigReqs;
        }
        
        return sigReqs;
    }
    
    public static Signature_Request_vod__c createSignatureRequest(
        String sigReqUUID, String callId, String accountId, String status, DateTime engageLastModifiedDT) {
        Signature_Request_vod__c sigReq = new Signature_Request_vod__c(
            Signature_Request_UUID_vod__c = sigReqUUID, Call2_vod__c = callId, Account_vod__c = accountId, Status_vod__c = status,
        	Engage_Last_Modified_Datetime_vod__c = engageLastModifiedDT);
        
		return sigReq;
    }
    
    public static void assert(Map<Signature_Request_vod__c, Call2_vod__c> sigReqToCallMap, 
                              boolean assertCallId, boolean assertAccountId, boolean fetchSigReq) {
        Call2_vod__c call = sigReqToCallMap.values().get(0);
        
        Signature_Request_vod__c sigReq = null;
        if(fetchSigReq) {
            List<String> sigReqUUIDs = new List<String>();
            Set<Signature_Request_vod__c> sigReqs = sigReqToCallMap.keySet();
            for(Signature_Request_vod__c sigReqFromMap: sigReqs) {
                sigReqUUIDs.add(sigReqFromMap.Signature_Request_UUID_vod__c);
            }
            
            List<Signature_Request_vod__c> fetchedSigReqs = 
                [SELECT Id, Call2_vod__c, Account_vod__c FROM Signature_Request_vod__c WHERE Signature_Request_UUID_vod__c in :sigReqUUIDs];
            
            sigReq = fetchedSigReqs.get(0);
        } else {
            sigReq = sigReqToCallMap.keySet().iterator().next();
        }
        
        if(assertCallId) {
        	System.assert(String.isNotBlank(sigReq.Call2_vod__c));    
        	System.assertEquals(sigReq.Call2_vod__c, call.Id);    
        } else {
            System.assert(String.isBlank(sigReq.Call2_vod__c));
        }
        
        if(assertAccountId) {
        	System.assert(String.isNotBlank(sigReq.Account_vod__c));
        	System.assertEquals(sigReq.Account_vod__c, VeevaSignatureRequestTestUtil.getTestAccount().Id);
        } else {
            System.assert(String.isBlank(sigReq.Account_vod__c));
        }
    }
    
    public static Account createAccount(String accountName) {
        Account acc = new Account(Name = accountName);
        insert acc;
        
        return acc;
    }
    
    public static Account getTestAccount() {
        if(testAccount == null) {
        	testAccount = createAccount('TestingSigReqs');
        }
        
        return testAccount;
    }

    public static User createUserForTesting() {
        // setup user for testing
        Profile userProfile = [SELECT Id FROM Profile LIMIT 1];
        User testUser1 = new User(FirstName='Veeva',LastName='Systems2',UserName='veeva_systems_test2@veeva.com',Email='veeva_systems_test2@veeva.com',
            Alias='tUser2',TimeZoneSidKey='America/New_York',LocaleSidKey='en_US',EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',ProfileId=userProfile.Id);
        insert testUser1;
        return testUser1;
    }

    public static Signature_Request_vod__c createSignatureRequestWithMobileId(
        String sigReqUUID, String mobileId, String status, DateTime engageLastModifiedDT) {
        Signature_Request_vod__c sigReq;
        sigReq = new Signature_Request_vod__c(
            Signature_Request_UUID_vod__c = sigReqUUID, Call2_Mobile_Id_vod__c = mobileId, Status_vod__c = status,
            Engage_Last_Modified_Datetime_vod__c = engageLastModifiedDT);
        insert sigReq;
        return sigReq;
    }

    public static Signature_Request_vod__c getSignatureRequestById(Id id) {
        return [SELECT Id, AOC_ID_vod__c, Status_vod__c FROM Signature_Request_vod__c WHERE Id = :id];
    }

    public static Content_Acknowledgement_vod__c createContentAcknowledgementWithMobileId(String mobileId) {
        Content_Acknowledgement_vod__c aoc = new Content_Acknowledgement_vod__c(Mobile_Id_vod__c = mobileId);
        insert aoc;
        return aoc;
    }

    public static Content_Acknowledgement_vod__c getContentAcknowledgementById(Id id) {
        return [SELECT Id, Signature_Request_UUID_vod__c FROM Content_Acknowledgement_vod__c WHERE Id = :id];
    }

    public static Call2_vod__c getCallById(Id id) {
        return [SELECT Id, Override_Lock_vod__c FROM Call2_vod__c WHERE Id = :id];
    }
}