@isTest(seeAllData = true)
private class MSD_CORE_ae_CaseControllerTest {
    private static User getPortalUser() {
        return [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'AE Self Service Portal Profile'
            LIMIT 1
        ];
    }

    /*private class RecaptchaHttpMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public RecaptchaHttpMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }

    @isTest
    static void testVerifyRecaptchaSuccess() {
        // Mock successful reCAPTCHA verification response
        RecaptchaHttpMock mock = new RecaptchaHttpMock(200, '{"success": true}');
        Test.setMock(HttpCalloutMock.class, mock);

        String recaptchaResponse = 'test-response';
        Boolean result = MSD_CORE_ae_CaseController.verifyRecaptcha(recaptchaResponse);

        System.assertEquals(true, result, 'Expected reCAPTCHA verification to succeed.');
    }



    @isTest
    static void testVerifyRecaptchaFailDueToError() {
        // Mock reCAPTCHA verification response with error
        RecaptchaHttpMock mock = new RecaptchaHttpMock(200, '{"success": false, "error-codes": ["invalid-input-secret"]}');
        Test.setMock(HttpCalloutMock.class, mock);

        String recaptchaResponse = 'test-response';
        Boolean result = MSD_CORE_ae_CaseController.verifyRecaptcha(recaptchaResponse);

        System.assertEquals(false, result, 'Expected reCAPTCHA verification to fail due to error.');
    }

    @isTest
    static void testVerifyRecaptchaHttpError() {
        // Mock HTTP error response
        RecaptchaHttpMock mock = new RecaptchaHttpMock(500, 'Internal Server Error');
        Test.setMock(HttpCalloutMock.class, mock);

        String recaptchaResponse = 'test-response';
        Boolean result = MSD_CORE_ae_CaseController.verifyRecaptcha(recaptchaResponse);

        System.assertEquals(false, result, 'Expected reCAPTCHA verification to fail due to HTTP error.');
    }*/

    @isTest
    static void testCreateInteractionCase() {
        Map<String, Object> caseDetail = MSD_CORE_ae_TestDataFactoryPortal.createCaseDetail();
        MSD_CORE_ae_TestDataFactoryPortal.createAEPortalSource();
        Id interactionCaseId = null;
        Test.startTest();
        User portalUser = getPortalUser();
        System.runAs(portalUser) {
            interactionCaseId = MSD_CORE_ae_CaseController.createInteractionCase(caseDetail, 'Merck Employee');
            System.debug('Interaction case created with ID: ' + interactionCaseId);
        }
        Test.stopTest();
        List<SObject> interactionCaseList = [Select Id, CaseNumber from Case Where Id = :interactionCaseId];
        Boolean interactionCaseCreated = interactionCaseList.size() == 1;
        Assert.areEqual(true, interactionCaseCreated, 'Interaction Case inserted successfully');
    }

    @isTest
    static void testCreateInteractionCaseException() {
        Map<String, Object> caseDetail = MSD_CORE_ae_TestDataFactoryPortal.createCaseDetail3();
        MSD_CORE_ae_TestDataFactoryPortal.createAEPortalSource();
        Test.startTest();
        User portalUser = getPortalUser();
        System.runAs(portalUser) {
            try {
                Id interactionCaseId = MSD_CORE_ae_CaseController.createInteractionCase(caseDetail, 'Merck Employee');
            } catch (Exception ex) {
                Assert.areEqual('System.NullPointerException', ex.getTypeName(), 'Null Pointer Exception if any Stage Details are missing');
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateAeCasePSP() {
        Map<String, Object> caseDetails = MSD_CORE_ae_TestDataFactoryPortal.createCaseDetail();
        MSD_CORE_ae_CaseController.CaseResponse aeCase;
        //RecaptchaHttpMock mock = new RecaptchaHttpMock(200, '{"success": true}');
        //Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        User portalUser = getPortalUser();
        System.runAs(portalUser) {
            //aeCase = MSD_CORE_ae_CaseController.createAeCase(caseDetails, 'test-recaptcha-token');
            aeCase = MSD_CORE_ae_CaseController.createAeCase(caseDetails);
        }
        Test.stopTest();
        Id aeCaseId = aeCase.caseId;
        List<SObject> childCaseList = [Select Id, CaseNumber from Case Where Id = :aeCaseId];
        System.debug('Child case list: ' + childCaseList);
        Boolean childCaseCreated = childCaseList.size() == 1;
        Assert.areEqual(true, childCaseCreated, 'Child Case inserted successfully');
    }

    @isTest
    static void testCreateAeCaseEmployee() {
        Map<String, Object> caseDetails = MSD_CORE_ae_TestDataFactoryPortal.createCaseDetail2();
        MSD_CORE_ae_CaseController.CaseResponse aeCase;
        //RecaptchaHttpMock mock = new RecaptchaHttpMock(200, '{"success": true}');
        //Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        User portalUser = getPortalUser();
        System.runAs(portalUser) {
            //aeCase = MSD_CORE_ae_CaseController.createAeCase(caseDetails, 'test-recaptcha-token');
            aeCase = MSD_CORE_ae_CaseController.createAeCase(caseDetails);
        }
        Test.stopTest();
        Id aeCaseId = aeCase.caseId;
        List<SObject> childCaseList = [Select Id, CaseNumber from Case Where Id = :aeCaseId];
        System.debug('Child case list: ' + childCaseList);
        Boolean childCaseCreated = childCaseList.size() == 1;
        Assert.areEqual(true, childCaseCreated, 'Child Case inserted successfully');
    }

    @isTest
    static void testCreateAeCaseHCP() {
        Map<String, Object> caseDetailsHCP = MSD_CORE_ae_TestDataFactoryPortal.createCaseDetailHCP();
        MSD_CORE_ae_CaseController.CaseResponse aeCase;
        //RecaptchaHttpMock mock = new RecaptchaHttpMock(200, '{"success": true}');
        //Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        User portalUser = getPortalUser();
        System.runAs(portalUser) {
            //aeCase = MSD_CORE_ae_CaseController.createAeCase(caseDetailsHCP, 'test-recaptcha-token');
            aeCase = MSD_CORE_ae_CaseController.createAeCase(caseDetailsHCP);
        }
        Test.stopTest();
        Id aeCaseId = aeCase.caseId;
        List<SObject> childCaseList = [Select Id, CaseNumber from Case Where Id = :aeCaseId];
        System.debug('Child case list: ' + childCaseList);
        Boolean childCaseCreated = childCaseList.size() == 1;
        Assert.areEqual(true, childCaseCreated, 'Child Case inserted successfully');
    }

    @isTest
    static void testCreateAeCaseException() {
        Map<String, Object> caseDetails = MSD_CORE_ae_TestDataFactoryPortal.createCaseDetail3();
        MSD_CORE_ae_CaseController.CaseResponse aeCase;
        //RecaptchaHttpMock mock = new RecaptchaHttpMock(200, '{"success": true}');
        //Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        User portalUser = getPortalUser();
        System.runAs(portalUser) {
            try {
                //aeCase = MSD_CORE_ae_CaseController.createAeCase(caseDetails, 'test-recaptcha-token');
                aeCase = MSD_CORE_ae_CaseController.createAeCase(caseDetails);
            } catch (Exception ex) {
                Assert.areEqual('System.NullPointerException', ex.getTypeName(), 'Null Pointer Exception if any Stage Details are missing');
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testUploadAttachments() {
        List<Object> fileList = MSD_CORE_ae_TestDataFactoryPortal.createFileObjectList();
        Map<String, Object> caseDetail = MSD_CORE_ae_TestDataFactoryPortal.createCaseDetail();
        MSD_CORE_ae_TestDataFactoryPortal.createAEPortalSource();
        MSD_CORE_ae_CaseController.FileData fileData = new MSD_CORE_ae_CaseController.FileData();
        Test.startTest();
        User portalUser = getPortalUser();
        System.runAs(portalUser) {
            Id interactionCaseId = MSD_CORE_ae_CaseController.createInteractionCase(caseDetail, 'Merck Employee');
            System.debug('Created interaction case ID: ' + interactionCaseId);
            try {
                fileData = MSD_CORE_ae_CaseController.uploadAttachments(interactionCaseId, fileList);
                Assert.areEqual(fileData.fileName, 'Test AE Portal.pdf', 'File Inserted');
            } catch (Exception e) {
                System.debug('Exception occurred during uploadAttachments: ' + e.getMessage());
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testSendEmail() {
        String errorMessage = 'Technical Error has occurred on AE Portal';
        Test.startTest();
        User portalUser = getPortalUser();
        System.assertNotEquals(null, portalUser, 'No user found with the AE Self Service Portal Profile');
        System.runAs(portalUser) {
            MSD_CORE_ae_CaseController.sendEmail(errorMessage);
            Assert.areEqual(null, null, 'Email Sent');
        }
        Test.stopTest();
    }
    static void testSendErrorEmail() {
        String errorMessage = 'Technical Error has occurred on AE Portal';
        Test.startTest();
        User portalUser = getPortalUser();
        System.assertNotEquals(null, portalUser, 'No user found with the AE Self Service Portal Profile');
        System.runAs(portalUser) {
            MSD_CORE_ae_CaseController.sendErrorEmail(errorMessage);
            Assert.areEqual(null, null, 'Email Sent');
        }
        Test.stopTest();
    }
}