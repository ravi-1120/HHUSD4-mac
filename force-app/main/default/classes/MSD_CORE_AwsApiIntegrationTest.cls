@isTest(SeeAllData=true)
private class MSD_CORE_AwsApiIntegrationTest {
    
    @isTest static void PIRequestTest(){
        
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        MSD_CORE_RTB_Pir_Request_Info__c pirInfo = MSD_CORE_AwsApiIntegration.piRequestInfo();
        Case c =  new Case();
        c.AccountId = testAccount.Id;
        c.Type = 'General';
        c.Status = 'Open';
        c.Details_MVN__c = 'Test';
        c.case_AddressLine1_MVN__c = 'Address1';
        c.MSD_CORE_Customer_Contact_Salutation__c = 'Mr.';
        c.case_City_MVN__c = 'Herndon';
        c.case_Account_Phone_MVN__c = '5712689929';
        
        insert c;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(c.Id);   
        String requestId = MSD_CORE_AwsApiIntegration.generateNewRequestId();
        List<Case> pDataList = MSD_CORE_AwsApiIntegration.queryCasePirs(pirIdList);
        
        List<MSD_CORE_PirData> pData = MSD_CORE_AwsApiIntegration.buildPirCaseData( pDataList, pirInfo);
        MSD_CORE_PIRequest request = new MSD_CORE_PIRequest(pirInfo,pData,requestId , pirInfo.FS_Source_System__c);
        
        System.assertEquals(requestId, request.requestid);
    }
    
    @isTest static void PIRDataTest(){
        
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        testAccount.FirstName = 'Ramesh';
        insert testAccount;
        
        Case c =  new Case();
        c.AccountId = testAccount.Id;
        c.Type = 'General';
        c.Status = 'Open';
        c.Details_MVN__c = 'Test';
        insert c;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(c.Id);   
        String requestId = MSD_CORE_AwsApiIntegration.generateNewRequestId();
        List<Case> pDataList = MSD_CORE_AwsApiIntegration.queryCasePirs(pirIdList);
        MSD_CORE_RTB_Pir_Request_Info__c pirInfo = MSD_CORE_AwsApiIntegration.piRequestInfo();
        List<MSD_CORE_PirData> pData = MSD_CORE_AwsApiIntegration.buildPirCaseData( pDataList, pirInfo);
        
        System.assertEquals(c.Id , pData[0].external_req_id);
        System.assertEquals(c.Details_MVN__c, pData[0].question);
    }
    
    @isTest static void PIRDataTest2(){
        
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        
        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();
        inquiry.Account_vod__c = testAccount.Id;
        inquiry.Salutation_MRK__c ='Admiral';
        inquiry.Delivery_Method_vod__c = 'Email';
        inquiry.Requested_Date_MRK__c = Date.today();
        insert inquiry;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(inquiry.Id);  
        
        String requestId = MSD_CORE_AwsApiIntegration.generateNewRequestId();
        List<Medical_Inquiry_vod__c> pDataList = MSD_CORE_AwsApiIntegration.queryPirData(pirIdList);
        MSD_CORE_RTB_Pir_Request_Info__c pirInfo = MSD_CORE_AwsApiIntegration.piRequestInfo();
        List<MSD_CORE_PirData> pData = MSD_CORE_AwsApiIntegration.buildPirData( pDataList, pirInfo);
        
        System.assertEquals(inquiry.Id , pData.get(0).external_req_id);
    }
    
    @isTest static void PIRDataTest3(){
        
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        testAccount.Salutation = 'Mr';
        insert testAccount;
        
        Product_vod__c product = new Product_vod__c();
        product.Active_MRK__c = true;
        product.External_ID_vod__c = '700200';
        product.Name = 'Test product';
        product.Product_Type_vod__c = 'Detail';
        
        insert product;
        
        PIR_Concept_MRK__c concept = new PIR_Concept_MRK__c();
        concept.Concept_MRK__c = 'Test PIR Concept';
        concept.Product_MRK__c = product.Id;
        concept.Name = 'Test Product';
        concept.External_ID_MRK__c = '234324';
        insert concept;
        
        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();
        inquiry.Account_vod__c = testAccount.Id;
        inquiry.Salutation_MRK__c ='Admiral';
        inquiry.Delivery_Method_vod__c = 'Email';
        inquiry.Requested_Date_MRK__c = Date.today();
        inquiry.Concept_MRK__c = concept.Id;
        inquiry.Address_Line_1_vod__c = '13059 Elm Tree Drive';
        inquiry.Address_Line_2_vod__c = 'Apt #104';
        inquiry.City_vod__c = 'Herndon';
        inquiry.State_vod__c = 'VA';
        inquiry.Zip_vod__c = '20171';
        inquiry.Country_vod__c = 'USA';
        inquiry.Phone_Number_vod__c = '5712689928';
        inquiry.Email_vod__c = 'ramesh.elapakurthi@gmail.com';
        //inquiry.PIR_Concept_Name_MRK__c = concept.Concept_MRK__c;
        insert inquiry;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(inquiry.Id);  
        
        System.debug('PIR Concept Code '+ inquiry.PIR_Concept_Name_MRK__c);
        String requestId = MSD_CORE_AwsApiIntegration.generateNewRequestId();
        List<Medical_Inquiry_vod__c> pDataList = MSD_CORE_AwsApiIntegration.queryPirData(pirIdList);
        MSD_CORE_RTB_Pir_Request_Info__c pirInfo = MSD_CORE_AwsApiIntegration.piRequestInfo();
        List<MSD_CORE_PirData> pData = MSD_CORE_AwsApiIntegration.buildPirData( pDataList, pirInfo);
        
        System.assertNotEquals(null , pData.get(0).document);
    }
    
    @isTest static void InvokeRTBHelperTest(){
        
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        testAccount.Salutation = 'Mr';
        insert testAccount;
        
        Product_vod__c product = new Product_vod__c();
        product.Active_MRK__c = true;
        product.External_ID_vod__c = '700200';
        product.Name = 'Test product';
        product.Product_Type_vod__c = 'Detail';
        
        insert product;
        
        PIR_Concept_MRK__c concept = new PIR_Concept_MRK__c();
        concept.Concept_MRK__c = 'Test PIR Concept';
        concept.Product_MRK__c = product.Id;
        concept.Name = 'Test Product';
        concept.External_ID_MRK__c = '234324';
        insert concept;
        
        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();
        inquiry.Account_vod__c = testAccount.Id;
        inquiry.Salutation_MRK__c ='Admiral';
        inquiry.Delivery_Method_vod__c = 'Email';
        inquiry.Requested_Date_MRK__c = Date.today();
        inquiry.Concept_MRK__c = concept.Id;
        inquiry.Address_Line_1_vod__c = '13059 Elm Tree Drive';
        inquiry.Address_Line_2_vod__c = 'Apt #104';
        inquiry.City_vod__c = 'Herndon';
        inquiry.State_vod__c = 'VA';
        inquiry.Zip_vod__c = '20171';
        inquiry.Country_vod__c = 'USA';
        inquiry.Phone_Number_vod__c = '5712689928';
        inquiry.Email_vod__c = 'ramesh.elapakurthi@gmail.com';
        //inquiry.PIR_Concept_Name_MRK__c = concept.Concept_MRK__c;
        insert inquiry;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(inquiry.Id);  
        
        MSD_CORE_Invoke_RTB_Helper_For_Pir.invokeAwsApi(pirIdList);
        
    }
    
    @isTest static void submitPirToBusTest(){
        
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        
        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();
        inquiry.Account_vod__c = testAccount.Id;
        inquiry.Salutation_MRK__c ='Admiral';
        inquiry.Delivery_Method_vod__c = 'Email';
        inquiry.Requested_Date_MRK__c = Date.today();
        insert inquiry;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(inquiry.Id); 
        MSD_CORE_AwsApiIntegration.submitPirToBus(pirIdList);
        
    }
    
    @isTest static void submitCaseToBusTest(){
        
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        Case c =  new Case();
        c.AccountId = testAccount.Id;
        c.Type = 'General';
        c.Status = 'Open';
        insert c;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(c.Id);  
        
        MSD_CORE_AwsApiIntegration.submitCaseToBus(pirIdList);
    }
    
    @isTest static void InvokeRTBHelperTest2(){
        
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        Case c =  new Case();
        c.AccountId = testAccount.Id;
        c.Type = 'General';
        c.Status = 'Open';
        insert c;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(c.Id);  
        
        MSD_CORE_Invoke_RTB_Helper_For_Case.invokeAwsApiForCase(pirIdList);
    }
    
    @isTest static void serializePirTest(){
        
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        
        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();
        inquiry.Account_vod__c = testAccount.Id;
        inquiry.Salutation_MRK__c ='Admiral';
        inquiry.Delivery_Method_vod__c = 'Email';
        inquiry.Requested_Date_MRK__c = Date.today();
        insert inquiry;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(inquiry.Id);     
        List<Medical_Inquiry_vod__c> pDataList = MSD_CORE_AwsApiIntegration.queryPirData(pirIdList);
        MSD_CORE_RTB_Pir_Request_Info__c pirInfo = MSD_CORE_AwsApiIntegration.piRequestInfo();
        List<MSD_CORE_PirData> pData = MSD_CORE_AwsApiIntegration.buildPirData(pDataList,pirInfo);
        MSD_CORE_PIRequest request = new MSD_CORE_PIRequest(pirInfo,pData, MSD_CORE_AwsApiIntegration.generateNewRequestId(), pirInfo.FS_Source_System__c);
        String pirDataJson = MSD_CORE_AwsApiIntegration.serializePir(request);
        
        System.assert(pirDataJson!=null);
        
    }
    
    @isTest static void queryCasePirsCountTest(){
        
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        Case c =  new Case();
        c.AccountId = testAccount.Id;
        c.Type = 'General';
        c.Status = 'Open';
        insert c;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(c.Id);     
        List<Case> pDataList = MSD_CORE_AwsApiIntegration.queryCasePirs(pirIdList);
        System.assertEquals(1, pDataList.size());
        
    }
    
    @isTest static void queryCasePirsCaseNumberTest(){
        
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        Case c =  new Case();
        c.AccountId = testAccount.Id;
        c.Type = 'General';
        c.Status = 'Open';
        //c.CaseNumber = '00621103';
        insert c;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(c.Id);     
        system.debug('CaseNumber: '+ c.CaseNumber);
        List<Case> pDataList = MSD_CORE_AwsApiIntegration.queryCasePirs(pirIdList);
        c = [Select CaseNumber FROM Case Where Id =: c.Id];
        System.assertEquals(c.CaseNumber, pDataList[0].CaseNumber);
        
    }
    
    @isTest static void buildWebServiceRequestTest(){
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        
        Case c =  new Case();
        c.AccountId = testAccount.Id;
        c.Type = 'General';
        c.Status = 'Open';
        c.Details_MVN__c = 'Test';
        insert c;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(c.Id);     
        List<Case> pDataList = MSD_CORE_AwsApiIntegration.queryCasePirs(pirIdList);
        MSD_CORE_RTB_Pir_Request_Info__c pirInfo = MSD_CORE_AwsApiIntegration.piRequestInfo();
        List<MSD_CORE_PirData> pData = MSD_CORE_AwsApiIntegration.buildPirCaseData( pDataList, pirInfo);
        MSD_CORE_PIRequest request = new MSD_CORE_PIRequest(pirInfo,pData, MSD_CORE_AwsApiIntegration.generateNewRequestId(), pirInfo.FS_Source_System__c);
        MSD_CORE_Aws_Api__c awsApi = MSD_CORE_AwsApiIntegration.awsApiSettings();
        String pirDataJson = MSD_CORE_AwsApiIntegration.serializePir(request);
        
		HttpRequest req =  MSD_CORE_AwsApiIntegration.buildWebServiceRequest(pirDataJson, awsApi); 
        System.assertEquals(pirDataJson, req.getBody());
    }
    @isTest static void buildPirDataTest(){
        
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        
        Case c =  new Case();
        c.AccountId = testAccount.Id;
        c.Type = 'General';
        c.Status = 'Open';
        c.Details_MVN__c = 'Test';
        insert c;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(c.Id);     
        List<Case> pDataList = MSD_CORE_AwsApiIntegration.queryCasePirs(pirIdList);
        MSD_CORE_RTB_Pir_Request_Info__c pirInfo = MSD_CORE_AwsApiIntegration.piRequestInfo();
        List<MSD_CORE_PirData> pData = MSD_CORE_AwsApiIntegration.buildPirCaseData(pDataList, pirInfo);
        MSD_CORE_PIRequest request = new MSD_CORE_PIRequest(pirInfo,pData, MSD_CORE_AwsApiIntegration.generateNewRequestId(), pirInfo.FS_Source_System__c);
        MSD_CORE_Aws_Api__c awsApi = MSD_CORE_AwsApiIntegration.awsApiSettings();
        
        System.assert(request!=null);
        System.assertEquals('Test', request.data[0].question);
    }
    
    @isTest static void buildPirCaseDataTest(){
        
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        
        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();
        inquiry.Account_vod__c = testAccount.Id;
        inquiry.Salutation_MRK__c ='Admiral';
        inquiry.Delivery_Method_vod__c = 'Email';
        inquiry.Requested_Date_MRK__c = Date.today();
        insert inquiry;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(inquiry.Id);     
        List<Medical_Inquiry_vod__c> pDataList = MSD_CORE_AwsApiIntegration.queryPirData(pirIdList);
        MSD_CORE_RTB_Pir_Request_Info__c pirInfo = MSD_CORE_AwsApiIntegration.piRequestInfo();
        List<MSD_CORE_PirData> pData = MSD_CORE_AwsApiIntegration.buildPirData(pDataList, pirInfo);
        MSD_CORE_PIRequest request = new MSD_CORE_PIRequest(pirInfo, pData, MSD_CORE_AwsApiIntegration.generateNewRequestId(), pirInfo.FS_Source_System__c);
        
        System.assert(request!=null);
        System.assertEquals('Email', request.data[0].case_handling);
    }
    
    
    @isTest static void getUTCDateTimeTest(){
    
        System.assert(MSD_CORE_AwsApiIntegration.getUTCDateTime(System.now())!= null);
    }
    
    @isTest static void queryPirDataNullCheckTest(){
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        
        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();
        inquiry.Account_vod__c = testAccount.Id;
        inquiry.Salutation_MRK__c ='Admiral';
        inquiry.Delivery_Method_vod__c = 'Email';
        inquiry.Requested_Date_MRK__c = Date.today();
        insert inquiry;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(inquiry.Id);     
        List<Medical_Inquiry_vod__c> pDataList = MSD_CORE_AwsApiIntegration.queryPirData(pirIdList);
        System.assert(pDataList!=null);
    }
    
    
    
    @isTest static void pirInfoNotNullTest(){
        
        MSD_CORE_RTB_Pir_Request_Info__c pirInfo = MSD_CORE_AwsApiIntegration.piRequestInfo();
        System.debug('pirInfo:' + pirInfo);
        System.debug('PirInfo.Source_System__c'+ pirInfo.FS_Source_System__c);
        System.assert(pirInfo!=null);
    }
    
    @isTest static void saveRequestStatusTest(){
        
        String requestId = MSD_CORE_AwsApiIntegration.generateNewRequestId();
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        
        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();
        inquiry.Account_vod__c = testAccount.Id;
        inquiry.Salutation_MRK__c ='Admiral';
        inquiry.Delivery_Method_vod__c = 'Email';
        inquiry.Requested_Date_MRK__c = Date.today();
        insert inquiry;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(inquiry.Id);  
        
        MSD_CORE_AwsApiIntegration.saveRequestStatus(requestId, pirIdList, null, 'USVVAFS', null);
        List<MSD_CORE_PIR_Request__c> requestInfo = [SELECT Id, Message__c FROM MSD_CORE_PIR_Request__c WHERE Request_Id__c=: requestId];
        System.assert(requestInfo != null);
    }
    
    @isTest static void saveRequestStatusTest2(){
        
        HttpRequest req = new HttpRequest();
        HttpResponse response = new MSD_CORE_MockHttpResponseGenerator().respond(req);
        String requestId = MSD_CORE_AwsApiIntegration.generateNewRequestId();
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        
        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();
        inquiry.Account_vod__c = testAccount.Id;
        inquiry.Salutation_MRK__c ='Admiral';
        inquiry.Delivery_Method_vod__c = 'Email';
        inquiry.Requested_Date_MRK__c = Date.today();
        insert inquiry;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(inquiry.Id);  
        
        MSD_CORE_AwsApiIntegration.saveRequestStatus(requestId, pirIdList, response, 'USVVAMS', null);
        List<MSD_CORE_PIR_Request__c> requestInfo = [SELECT Id, Message__c, Status__c FROM MSD_CORE_PIR_Request__c WHERE Request_Id__c=: requestId];
        System.assertEquals('COMPLETED', requestInfo[0].Status__c);
       
    }
    
    @isTest static void saveRequestStatusTest3(){
        
        HttpRequest req = new HttpRequest();
        HttpResponse response = new MSD_CORE_MockHttpResponseGenerator().respondFailure(req);
        String requestId = MSD_CORE_AwsApiIntegration.generateNewRequestId();
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        
        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();
        inquiry.Account_vod__c = testAccount.Id;
        inquiry.Salutation_MRK__c ='Admiral';
        inquiry.Delivery_Method_vod__c = 'Email';
        inquiry.Requested_Date_MRK__c = Date.today();
        insert inquiry;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(inquiry.Id);  
        MSD_CORE_RTB_Pir_Request_Info__c  pirInfo = MSD_CORE_AwsApiIntegration.piRequestInfo();
        MSD_CORE_AwsApiIntegration.saveRequestStatus(requestId, pirIdList, response, pirInfo.FS_Source_System__c, null);
        List<MSD_CORE_PIR_Request__c> requestInfo = [SELECT Id, Message__c, Status__c FROM MSD_CORE_PIR_Request__c WHERE Request_Id__c=: requestId];
        System.assertEquals('ERROR', requestInfo[0].Status__c);
       
    }
    
    @isTest static void saveRequestStatusTest4(){
        
        HttpRequest req = new HttpRequest();
        HttpResponse response = new MSD_CORE_MockHttpResponseGenerator().respondFailure2(req);
        String requestId = MSD_CORE_AwsApiIntegration.generateNewRequestId();
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        
        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();
        inquiry.Account_vod__c = testAccount.Id;
        inquiry.Salutation_MRK__c ='Admiral';
        inquiry.Delivery_Method_vod__c = 'Email';
        inquiry.Requested_Date_MRK__c = Date.today();
        insert inquiry;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(inquiry.Id);  
        MSD_CORE_RTB_Pir_Request_Info__c  pirInfo = MSD_CORE_AwsApiIntegration.piRequestInfo();
        MSD_CORE_AwsApiIntegration.saveRequestStatus(requestId, pirIdList, response, pirInfo.FS_Source_System__c, null);
        List<MSD_CORE_PIR_Request__c> requestInfo = [SELECT Id, Message__c, Status__c FROM MSD_CORE_PIR_Request__c WHERE Request_Id__c=: requestId];
        System.assertEquals('RETRY', requestInfo[0].Status__c);
       
    }
    
    @isTest static void saveRequestStatusTest5(){
        
        HttpRequest req = new HttpRequest();
        HttpResponse response = new MSD_CORE_MockHttpResponseGenerator().respondFailure2(req);
        String requestId = MSD_CORE_AwsApiIntegration.generateNewRequestId();
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        
        Case c =  new Case();
        c.AccountId = testAccount.Id;
        c.Type = 'General';
        c.Status = 'Open';
        c.Details_MVN__c = 'Test';
        insert c;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(c.Id);  
        MSD_CORE_RTB_Pir_Request_Info__c  pirInfo = MSD_CORE_AwsApiIntegration.piRequestInfo();
        MSD_CORE_AwsApiIntegration.saveRequestStatus(requestId, pirIdList, response, pirInfo.SC_Source_System__c, null);
        List<MSD_CORE_PIR_Request__c> requestInfo = [SELECT Id, Source_System__c, Message__c, Status__c FROM MSD_CORE_PIR_Request__c WHERE Request_Id__c=: requestId];
        System.assertEquals(pirInfo.SC_Source_System__c, requestInfo[0].Source_System__c);
       
    }
    
    @isTest static void saveRequestStatusTest6(){
        
        HttpRequest req = new HttpRequest();
        HttpResponse response = new MSD_CORE_MockHttpResponseGenerator().respondFailure2(req);
        String requestId = MSD_CORE_AwsApiIntegration.generateNewRequestId();
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        
        Case c =  new Case();
        c.AccountId = testAccount.Id;
        c.Type = 'General';
        c.Status = 'Open';
        c.Details_MVN__c = 'Test';
        insert c;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(c.Id);  
        
        MSD_CORE_RTB_Pir_Request_Info__c  pirInfo = MSD_CORE_AwsApiIntegration.piRequestInfo();
        MSD_CORE_PIR_Request__c requestInfo1 = new MSD_CORE_PIR_Request__c();
        requestInfo1.Case_Id__c = c.Id;
        requestInfo1.Request_Id__c = MSD_CORE_AwsApiIntegration.generateNewRequestId();
        requestInfo1.Status__c = 'RETRY';
        requestInfo1.Message__c = 'Test 1';
        requestInfo1.Timestamp__c = System.now();
        requestInfo1.Source_System__c = pirInfo.SC_Source_System__c;
        insert requestInfo1;
        
        MSD_CORE_PIR_Request__c requestInfo2 = new MSD_CORE_PIR_Request__c();
        requestInfo2.Case_Id__c = c.Id;
        requestInfo2.Request_Id__c = MSD_CORE_AwsApiIntegration.generateNewRequestId();
        requestInfo2.Status__c = 'RETRY';
        requestInfo2.Message__c = 'Test 2';
        requestInfo2.Timestamp__c = System.now();
        requestInfo2.Source_System__c = pirInfo.SC_Source_System__c;
        insert requestInfo2;
        
        MSD_CORE_AwsApiIntegration.saveRequestStatus(requestId, pirIdList, response, pirInfo.SC_Source_System__c, null);
        List<MSD_CORE_PIR_Request__c> requestInfo = [SELECT Id, Source_System__c, Message__c, Status__c FROM MSD_CORE_PIR_Request__c WHERE Request_Id__c=: requestId];
        System.assertEquals('FAILED', requestInfo[0].Status__c);
       
    }
    
    
    @isTest static void pirInfoTest(){
        
        System.assertEquals(MSD_CORE_RTB_Pir_Request_Info__c.getOrgDefaults(),MSD_CORE_AwsApiIntegration.piRequestInfo());
    }
    
    @isTest static void pirInfoSourceSystemNotNullTest(){
        MSD_CORE_RTB_Pir_Request_Info__c pirInfo = MSD_CORE_AwsApiIntegration.piRequestInfo();
        
        System.assert(pirInfo.FS_Source_System__c!=null);
    }
    
    @isTest static void pIRequestForUSVeevaTest(){
        
        MSD_CORE_RTB_Pir_Request_Info__c pirInfo = MSD_CORE_AwsApiIntegration.piRequestInfo();
        String requestId = MSD_CORE_AwsApiIntegration.generateNewRequestId();
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        
        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();
        inquiry.Account_vod__c = testAccount.Id;
        inquiry.Salutation_MRK__c ='Admiral';
        inquiry.Delivery_Method_vod__c = 'Email';
        inquiry.Requested_Date_MRK__c = Date.today();
        insert inquiry;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(inquiry.Id);     
        List<Medical_Inquiry_vod__c> pDataList = MSD_CORE_AwsApiIntegration.queryPirData(pirIdList);
        List<MSD_CORE_PirData> pData = MSD_CORE_AwsApiIntegration.buildPirData(pDataList, pirInfo);
        MSD_CORE_PIRequest  piRequest = new MSD_CORE_PIRequest(pirInfo,pData, requestId, pirInfo.FS_Source_System__c);
        System.assertEquals(requestId, piRequest.requestid);
        
    }
    
    @isTest static void generateNewRequestIdNotNullTest(){
        
        System.assert(MSD_CORE_AwsApiIntegration.generateNewRequestId()!=null);
        
    }
    
    @isTest static void generateNewRequestIdUniqueTest(){
        System.assert(MSD_CORE_AwsApiIntegration.generateNewRequestId()!=MSD_CORE_AwsApiIntegration.generateNewRequestId());
    }
    
    @isTest static void veevaRetryCountTest(){
        
        String requestId = MSD_CORE_AwsApiIntegration.generateNewRequestId();
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        
        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();
        inquiry.Account_vod__c = testAccount.Id;
        inquiry.Salutation_MRK__c ='Admiral';
        inquiry.Delivery_Method_vod__c = 'Email';
        inquiry.Requested_Date_MRK__c = Date.today();
        insert inquiry;
        //insert inquiry;
        List<String> pirIdList = new List<String>();
        pirIdList.add(inquiry.id);
        MSD_CORE_PIR_Request__c pir =new MSD_CORE_PIR_Request__c();
        pir.PIR_Id__c = inquiry.id;
        pir.Status__c = 'RETRY';
        pir.Request_Id__c = requestId;
        insert pir;
        
        Map<String, Integer> existingPirs = MSD_CORE_AwsApiIntegration.veevaPirRetryCount(pirIdList, 'RETRY');
        System.assertEquals(1,existingPirs.size() );
        
    }
    
    @isTest static void scRetryCountTest(){
        
       	String requestId = MSD_CORE_AwsApiIntegration.generateNewRequestId();
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        Case c =  new Case();
        c.AccountId = testAccount.Id;
        c.Type = 'General';
        c.Status = 'Open';
        insert c;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(c.Id);     
        List<Case> pDataList = MSD_CORE_AwsApiIntegration.queryCasePirs(pirIdList);
        
        MSD_CORE_PIR_Request__c pir =new MSD_CORE_PIR_Request__c();
        pir.Case_Id__c = c.Id;
        pir.Status__c = 'RETRY';
        pir.Request_Id__c = requestId;
        pir.Message__c = 'Test Message';
        insert pir;
        
        Map<String, Integer> existingPirs = MSD_CORE_AwsApiIntegration.scPirRetryCount(pirIdList,'RETRY');
        System.assertEquals(1,existingPirs.size() );
        
    }
    
    @isTest static  void  MSD_CORE_ScheduledPIRs_RTBTest(){
       	 Test.startTest();
        //insert test data
		 String requestId = MSD_CORE_AwsApiIntegration.generateNewRequestId();
        Account testAccount = new Account();
        testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('HCP').getRecordTypeId();
        testAccount.LastName= 'Account For Aws testing';
        insert testAccount;
        
        Case c =  new Case();
        c.AccountId = testAccount.Id;
        c.Type = 'General';
        c.Status = 'Open';
        c.Details_MVN__c = 'Test';
        insert c;
        
        List<String> pirIdList = new List<String>();
        pirIdList.add(c.Id);  
        
        MSD_CORE_RTB_Pir_Request_Info__c  pirInfo = MSD_CORE_AwsApiIntegration.piRequestInfo();
        MSD_CORE_PIR_Request__c requestInfo1 = new MSD_CORE_PIR_Request__c();
        requestInfo1.Case_Id__c = c.Id;
        requestInfo1.Request_Id__c = MSD_CORE_AwsApiIntegration.generateNewRequestId();
        requestInfo1.Status__c = 'RETRY';
        requestInfo1.Message__c = 'Test 1';
        requestInfo1.Timestamp__c = System.now();
        requestInfo1.Source_System__c = pirInfo.SC_Source_System__c;
        insert requestInfo1;
        
         //Call the static method directly
        //MSD_CORE_ScheduledPIRs_RTB.scheduleIt();
        System.schedule('Job1', '0 0 * * * ?', new MSD_CORE_ScheduledPIRs_RTB());
        Test.stopTest();
       
	}
}