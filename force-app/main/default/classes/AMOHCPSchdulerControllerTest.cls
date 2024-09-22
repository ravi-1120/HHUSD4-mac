@isTest
private class AMOHCPSchdulerControllerTest{
    @isTest
    private static void getHCPAttestaionTest(){
        Test.startTest();
        AMOHCPSchdulerController.getHCPAttestaion(true);
        AMOHCPSchdulerController.getHCPAttestaion(false);
        Test.stopTest();
    }
    @isTest
    private static void encryptURLTest(){
        Test.startTest();
        AMOHCPSchdulerController.encryptURL(new HCP_Attestation__mdt(),true);
        AMOHCPSchdulerController.encryptURL(null,false);
        Test.stopTest();
    }
    @isTest
    private static void AMOHCPSchdulerControllerTest(){
        AMOHCPSchdulerController obj = new AMOHCPSchdulerController();
    }
}