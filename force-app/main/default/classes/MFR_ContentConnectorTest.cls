@IsTest
public class MFR_ContentConnectorTest {

    @isTest
    static void testDoPost() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestURI = '/ResourceMetaData/';
        RestContext.request.httpMethod = 'POST';

        User testUser = createUser();
        Test.startTest();
        System.runAs(testUser) {
            MFR_ContentConnectorWrapper reqBody = new MFR_ContentConnectorWrapper();
            reqBody.documentNumber = '1010101010101010';
            reqBody.documentId = '1234';
            reqBody.HCEIStatus = '200';
            reqBody.documentStatus = '201';
            reqBody.expirationDate = '2022-09-02';
            reqBody.globalVersionId = '3456';
            reqBody.globalId = '345678';
            reqBody.audience = new List<String>{'a'};
            reqBody.methodOfDelivery =new List<String>{'b'};
            reqBody.deliveryPlatform = new List<String>{'c'};
            reqBody.productId = new List<String>{'789'};
            reqBody.productFamilyId = new List<String>{'8889'};
            reqBody.name = 'Test';
            reqBody.resourceTitle='Test';
            
            RestContext.request.requestBody = Blob.valueOf(Json.serialize(reqBody));
            String result = MFR_ContentConnector.doPost();
            
            // Assuming that the result should be an ID, you can add an assertion like this:
            System.assertNotEquals(null, result, 'Expected a non-null result');

            // Additional assertions can be added based on specific requirements
            // For example, you can query the database to verify that a record was created or updated.
        }
        Test.stopTest();
    }
    
     static testMethod void testDoPost1() {
		User testUser = createUser();
        System.runAs(testUser) {         
            // Create a sample JSON string
            String jsonRequest = '{"documentNumber": "1010101010101010", ' +
                                 '"documentId": "1234", ' +
                                 '"version": "1.0", ' +
                                 '"globalVersionId": "GV-123", ' +
                                 '"globalId": "G-456", ' +
                                 '"expirationDate": "2023-12-31", ' +
                                 '"documentStatus": "Active", ' +
                                 '"HCEIStatus": "Approved", ' +
                                 '"documentVersionViewableRenditions": [{' +
                                     '"bucket": "bucket1", ' +
                                     '"key": "key1"' +
                                 '}, {' +
                                     '"bucket": "bucket2", ' +
                                     '"key": "key2"' +
                                 '}], ' +
                                 '"audience": ["a"], ' +
                                 '"methodOfDelivery": ["b"], ' +
                                 '"deliveryPlatform": ["c"], ' +
                                 '"productId": ["789"], ' +
                                 '"productFamilyId": ["8889"], ' +
                                 '"name": "Testing the resource title and name implementation, It also truncates the name to 80 characters if we receives more than 80 characters from the content manager system and we are updating resource field with 255 characters even if we receive more than 255 characters.", ' +
                                 '"resourceTitle": "Test", ' +
                                 '"owner": {' +
                                     '"users": ["user1", "user2"]' +
                                 '} }';
    
            RestRequest request = new RestRequest();
            RestResponse response = new RestResponse();
            request.requestURI = '/ResourceMetaData/';
            request.httpMethod = 'POST';
            request.requestBody = Blob.valueOf(jsonRequest);
    
            RestContext.request = request;
            RestContext.response = response;
    
            Test.startTest();
            	String result = MFR_ContentConnector.doPost();
            Test.stopTest();
			System.assertNotEquals(null, result, 'Expected a non-null result');
            // Retrieve the updated record
            MSD_CORE_Catalog__c updatedRecord = [SELECT MSD_CORE_Document_ID__c, MSD_CORE_Document_Number__c, MSD_CORE_HCEI_Status__c, 
                                                MSD_CORE_Document_Status__c, MSD_CORE_Expiration_Date__c, MSD_CORE_Global_ID__c,
                                                MSD_CORE_GlobalVersion_ID__c, MSD_CORE_Audience__c, MSD_CORE_Method_Of_Delivery__c,
                                                MSD_CORE_Delivery_Platform__c, MSD_CORE_Product_ID__c, MSD_CORE_Product_Family_ID__c,
                                                MSD_CORE_Document_Owner__c, MSD_CORE_Document_Version__c, Name, MSD_CORE_Resource_Title__c,
                                                MSD_CORE_Description__c, MSD_CORE_Document_Rendition__c
                                            FROM MSD_CORE_Catalog__c 
                                            WHERE Id = :result];
            
            System.assertEquals(80, updatedRecord.Name.length());
			System.assertEquals(254, updatedRecord.MSD_CORE_Resource_Title__c.length());
            System.assertEquals('1010101010101010', updatedRecord.MSD_CORE_Document_Number__c);
            System.assertEquals('1234', String.valueOf(updatedRecord.MSD_CORE_Document_ID__c));
    	}
     }

    private static User createUser() {
        Profile firstProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User user = new User(LastName = 'Userton',
                           FirstName='User',
                           Alias = 'usus',
                           Email = 'user.user@merck.com',
                           Username = Math.random() + '@' + Math.random(),
                           ProfileId = firstProfile.Id,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
        );
        insert user;
        return user;
    }

}