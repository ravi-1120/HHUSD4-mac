@isTest
private class mSD_CORE_ae_sendEmailTest {
    private static void OrgWide() {
        OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'AE Self-Service Portal' LIMIT 1];
    }
    @isTest static void testEmailException() {
        Test.startTest();
        mSD_CORE_ae_sendEmail.sendEmail('sairohith.ramini@merck.com', 'Sender', 'This is a test message', '{}');
        Test.stopTest();
    }
        private static String createFileData() {
        mSD_CORE_ae_sendEmail.FileData fileData = new mSD_CORE_ae_sendEmail.FileData();
        fileData.filename = 'testFile.txt';
        fileData.base64 = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));
        List<mSD_CORE_ae_sendEmail.FileData> filesData = new List<mSD_CORE_ae_sendEmail.FileData>{ fileData };
        return JSON.serialize(filesData);
    }

    @isTest static void testEmailPositive() {
        OrgWide();
        String DataJson = createFileData();
        Test.startTest();
        mSD_CORE_ae_sendEmail.sendEmail('sairohith.ramini@merck.com', 'Sender', 'This is a test message', DataJson);
        Test.stopTest();
    }
}