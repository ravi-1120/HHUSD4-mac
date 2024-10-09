/*
* Class		    : 	MSD_CORE_HEQ_Print_IntegrationHandler
* Author		:	Ambadas Joshi (joshi.ambadas@merck.com)
* Purpose		: 	This class handles the API integration with Hibbert (print vendor)
* Date Created	:	03-Oct-2024
*/
public class MSD_CORE_HEQ_Print_IntegrationHandler 
{
    @future(callout=true)
    public static void submitOrder(){//(List<Id> lstOrderId){
        String accessToken = MSD_CORE_HEQ_AuthenticationHelper.generateAccessToken();
        system.debug('accessToken>>>>' + accessToken);
        //list<MSD_CORE_HEQ_Order__c> lstOrder = [SELECT id FROM MSD_CORE_HEQ_Order__c 
          //                                           WHERE Id in: lstOrderId AND 
            //                                            MSD_CORE_Integration_Status__c = 'SUBMITTED'];
        for(MSD_CORE_HEQ_Order__c order : [select id from MSD_CORE_HEQ_Order__c limit 2]){
            
            String requestBody = createRequest(order);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://demo.uat.order2ucloud.com:10460/v3/placeOrder');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('jwtToken', accessToken);
            req.setHeader('Accept', 'application/json');

            req.setBody(requestBody);

            Http http = new Http();
            
            HttpResponse res;
            try {
                res = http.send(req);
                String responseBody = res.getBody();
                system.debug('RestContext.request>>>>>>>'+req.getBody());
                System.debug('Response Body: ' + responseBody);
                updateOrderWithResponse(responseBody);
            } 
            
            catch (Exception e) {
                System.debug('Exception: ' + e.getMessage());
            }
        }
    }

    public static string createRequest(MSD_CORE_HEQ_Order__c order){
        string request = '{"billToAddress1":"400 Pennington Ave","billToCity":"Trenton","billToCountry":"US","billToEmailAddress":"jsample@hibbertgroup.com","billToFirstName":"John","billToLastName":"Sample","billToZipCode":"08618","billToState":"NJ","customerOrderNumber":"12345-ABC","attribute1":"Merck Health EQ ID","allItems":[{"itemQty":1,"itemId":"537778","printFilename":"MerckHealthEQ.PDF","printFileContent":"slkdjfslfkjlsdjfslkdfjvpxuZXYHLASKJ;ls+///"},{"itemQty":1,"itemId":"537777","printFilename":""}],"serviceType":"FEDG","customerNumber":"1000","wmsWarehouseId":"HIXX","shipToAddress1":"400 Pennington Ave","shipToCity":"Trenton","shipToCountry":"US","shipToEmailAddress":"ssample@hibbertgroup.com","shipToFirstName":"Sammy","shipToHomePhone":"","shipToLastName":"Sample","shipToPhone":"1234567890","shipToZipCode":"12345","shipToState":"XX"}';
        return request;
    }

    public static void updateOrderWithResponse (string orderResponse){

    }

}