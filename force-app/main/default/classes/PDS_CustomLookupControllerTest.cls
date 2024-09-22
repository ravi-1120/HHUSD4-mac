@isTest
public class PDS_CustomLookupControllerTest {
    @isTest
    static void testgetRecords(){
        Test.startTest();
        List<SObject> reqTest = PDS_CustomLookupController.getRecords( 'PDS_Contact__c','Pending');
        List<SObject> reqTest2 = PDS_CustomLookupController.getRecords( 'PDS_Donation_Request__c','Pending');
        List<SObject> reqTest3 = PDS_CustomLookupController.getRecords( 'PDS_Contact__c','');
        List<SObject> reqTest4 = PDS_CustomLookupController.getRecords( 'PDS_Donation_Request__c','');
        List<SObject> reqTest5 = PDS_CustomLookupController.getRecords( 'NA','');
        List<SObject> reqTest6 = PDS_CustomLookupController.getRecords( '','');
        Test.stopTest(); 
    }
    @isTest
    static void testGetPicklistValue() {
        List<String> result = PDS_CustomLookupController.getPicklistValue('PDS_Donation_Request__c', 'PDS_Donation_Request_Status__c');
        System.assertNotEquals(null, result);
        System.assertNotEquals(0, result.size());
    }
    
    public static PDS_Contact__c createPDSContact(){
            PDS_Contact__c contact = new PDS_Contact__c(
            Name = 'John Smith',
            PDS_Shipping_Street__c = '123 Existing St',
            PDS_Address_2__c = 'North West',
            PDS_Address_3__c = 'Beside',
            PDS_Shipping_Country__c = 'Albania',
            PDS_Shipping_State__c = 'New Jersey',
            PDS_Shipping_Postal_Code__c = '12345',
            PDS_Phone__c = '123-456-7890',
            PDS_Fax_Number__c = '098-765-4321',
            PDS_Phone_2__c = '987-654-3210',
            PDS_Email__c = 'john@merkc.com',
            PDS_Email_Address_2__c = 'john@merkc.com',
            PDS_Email_Address_3__c = 'john@merkc.com',
            PDS_Unit__c = '12',
            PDS_Organization__c = 'NA'
        );
        insert contact; 
        return contact; 
    }
    @isTest
    static void testsaveContacts(){
        String recordData = '{"name":"New Contact","street":"123 New St","addone":"New Address 1","addtwo":"New Address 2","country":"New Country","state":"New State","zipcode":"67890","phone":"234-567-8901","fax":"345-678-9012","mobile":"456-789-0123","email":"new@example.com","emailtwo":"new2@example.com","emailthree":"new3@example.com","unit":"New Unit","organization":"New Org"}';
        Test.startTest();
        try{
        	List<PDS_Contact__c> result = PDS_CustomLookupController.saveContacts(recordData);
        	PDS_Contact__c contact = result[0];   
        }
        catch (Exception e) {
        System.debug('Exception: ' + e.getMessage());
    	}
        Test.stopTest();  
    }
    @isTest
    static void testsaveContacts2() {
        PDS_Contact__c con = createPDSContact();

        String recordData = '{"id":"' + con.Id + '","name":"Updated Contact","street":"456 Updated St","addone":"Suite 6","addtwo":"Building D","country":"USA","state":"TX","zipcode":"67891","phone":"987-654-3212","fax":"987-654-3213","mobile":"123-123-1235","email":"updated@example.com","emailtwo":"updated2@example.com","emailthree":"updated3@example.com","unit":"Unit 3","organization":"Updated Org"}';

        Test.startTest();
        List<PDS_Contact__c> result;
        try{
            result = PDS_CustomLookupController.saveContacts(recordData);
        }
        catch(Exception e){
            System.debug('Caught exception: ' + e.getMessage());
        }
        Test.stopTest();
 
    }
    @isTest
    static void testgetRecordById(){
        PDS_Contact__c con = createPDSContact();
        Test.startTest();
        List<SObject> result = PDS_CustomLookupController.getRecordById(con.Id);
        Test.stopTest();
    }
}