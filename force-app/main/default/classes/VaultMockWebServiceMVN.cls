/*
 * VaultMockWebServiceMVN
 * Created By: Samuel Rosen
 * Created Date: Oct 2013
 * Description: This class tests the Vault Seach Utility by creating the Mock web responses
 *
 * *** NOTE: Currently not used for the Merck implementation. ***
 */
global class VaultMockWebServiceMVN {
	global class VaultUtilityMockProperService implements HttpCalloutMock
	{
		global HTTPResponse respond(HTTPRequest req)
		{
			HTTPResponse response = new HTTPResponse();
			response.setHeader('Content-Type', 'application/json');
			response.setStatusCode(200);
			String responseBody;
			System.debug('Endpoint: ' + req.getBody());
			if(req.getBody().contains('target_doc_id__v')) {
				responseBody = '{"responseStatus": "SUCCESS", "responseDetails": {"limit": 1000,"offset": 0,"size": 2,"total": 2},"data": [{"target_doc_id__v": 11},{"target_doc_id__v": 6}]}';
			} else if(req.getBody().contains('id%3D')) {
				responseBody = '{"responseStatus":"SUCCESS","responseDetails":{"limit":50,"offset":0,"size":1,"total":1},"data":[{"id":11,"name__v":"Cholecap FAQ","title__v":"Cholecap FAQ","type__v":"FAQ","major_version_number__v":1,"minor_version_number__v":0,"status__v":"Published","size__v":null,"format__v":null,"subtype__v":null,"classification__v":null,"language__v":["English"],"document_country__vr":{"responseDetails":{"limit":250,"offset":0,"size":4,"total":4},"data":[{"abbreviation__vs":"US"},{"abbreviation__vs":"CA"},{"abbreviation__vs":"FR"},{"abbreviation__vs":"UK"}]},"document_product__vr":{"responseDetails":{"limit":250,"offset":0,"size":3,"total":3},"data":[{"external_id__v":"a0P17000000AEqHEAW"},{"external_id__v":"Voderal123"},{"external_id__v":"a0P17000000AEqMEAW"}]},"country__v":["1359657466445","1359657466468","1359657466730","1359657466425"],"product__v":["1359657466295","1381257889654","1381257833873"],"document_number__v":"VV-MED-00005"}, {"id":6,"name__v":"Cholecap FAQ","title__v":"Cholecap FAQ","type__v":"FAQ","major_version_number__v":1,"minor_version_number__v":0,"status__v":"Published","size__v":null,"format__v":null,"subtype__v":null,"classification__v":null,"language__v":["English"],"document_country__vr":{"responseDetails":{"limit":250,"offset":0,"size":4,"total":4},"data":[{"abbreviation__vs":"US"},{"abbreviation__vs":"CA"},{"abbreviation__vs":"FR"},{"abbreviation__vs":"UK"}]},"document_product__vr":{"responseDetails":{"limit":250,"offset":0,"size":3,"total":3},"data":[{"external_id__v":"a0P17000000AEqHEAW"},{"external_id__v":"Voderal123"},{"external_id__v":"a0P17000000AEqMEAW"}]},"country__v":["1359657466445","1359657466468","1359657466730","1359657466425"],"product__v":["1359657466295","1381257889654","1381257833873"],"document_number__v":"VV-MED-00005"}, {"id":5,"name__v":"Cholecap FAQ","title__v":"Cholecap FAQ","type__v":"FAQ","major_version_number__v":1,"minor_version_number__v":0,"status__v":"Published","size__v":null,"format__v":null,"subtype__v":null,"classification__v":null,"language__v":["English"],"document_country__vr":{"responseDetails":{"limit":250,"offset":0,"size":4,"total":4},"data":[{"abbreviation__vs":"US"},{"abbreviation__vs":"CA"},{"abbreviation__vs":"FR"},{"abbreviation__vs":"UK"}]},"document_product__vr":{"responseDetails":{"limit":250,"offset":0,"size":3,"total":3},"data":[{"external_id__v":"a0P17000000AEqHEAW"},{"external_id__v":"Voderal123"},{"external_id__v":"a0P17000000AEqMEAW"}]},"country__v":["1359657466445","1359657466468","1359657466730","1359657466425"],"product__v":["1359657466295","1381257889654","1381257833873"],"document_number__v":"VV-MED-00005"}]}';
			} else {
				responseBody = '{"responseStatus":"SUCCESS","responseDetails":{"limit":50,"offset":0,"size":1,"total":1},"data":[{"id":10,"name__v":"Cholecap FAQ","title__v":"Cholecap FAQ","type__v":"FAQ","major_version_number__v":1,"minor_version_number__v":0,"status__v":"Published","size__v":null,"format__v":null,"subtype__v":null,"classification__v":null,"language__v":["English"],"document_country__vr":{"responseDetails":{"limit":250,"offset":0,"size":4,"total":4},"data":[{"abbreviation__vs":"US"},{"abbreviation__vs":"CA"},{"abbreviation__vs":"FR"},{"abbreviation__vs":"UK"}]},"document_product__vr":{"responseDetails":{"limit":250,"offset":0,"size":3,"total":3},"data":[{"external_id__v":"a0P17000000AEqHEAW"},{"external_id__v":"Voderal123"},{"external_id__v":"a0P17000000AEqMEAW"}]},"country__v":["1359657466445","1359657466468","1359657466730","1359657466425"],"product__v":["1359657466295","1381257889654","1381257833873"],"document_number__v":"VV-MED-00005"}, {"id":6,"name__v":"Cholecap FAQ","title__v":"Cholecap FAQ","type__v":"FAQ","major_version_number__v":1,"minor_version_number__v":0,"status__v":"Published","size__v":null,"format__v":null,"subtype__v":null,"classification__v":null,"language__v":["English"],"document_country__vr":{"responseDetails":{"limit":250,"offset":0,"size":4,"total":4},"data":[{"abbreviation__vs":"US"},{"abbreviation__vs":"CA"},{"abbreviation__vs":"FR"},{"abbreviation__vs":"UK"}]},"document_product__vr":{"responseDetails":{"limit":250,"offset":0,"size":3,"total":3},"data":[{"external_id__v":"a0P17000000AEqHEAW"},{"external_id__v":"Voderal123"},{"external_id__v":"a0P17000000AEqMEAW"}]},"country__v":["1359657466445","1359657466468","1359657466730","1359657466425"],"product__v":["1359657466295","1381257889654","1381257833873"],"document_number__v":"VV-MED-00005"}, {"id":5,"name__v":"Cholecap FAQ","title__v":"Cholecap FAQ","type__v":"FAQ","major_version_number__v":1,"minor_version_number__v":0,"status__v":"Published","size__v":null,"format__v":null,"subtype__v":null,"classification__v":null,"language__v":["English"],"document_country__vr":{"responseDetails":{"limit":250,"offset":0,"size":4,"total":4},"data":[{"abbreviation__vs":"US"},{"abbreviation__vs":"CA"},{"abbreviation__vs":"FR"},{"abbreviation__vs":"UK"}]},"document_product__vr":{"responseDetails":{"limit":250,"offset":0,"size":3,"total":3},"data":[{"external_id__v":"a0P17000000AEqHEAW"},{"external_id__v":"Voderal123"},{"external_id__v":"a0P17000000AEqMEAW"}]},"country__v":["1359657466445","1359657466468","1359657466730","1359657466425"],"product__v":["1359657466295","1381257889654","1381257833873"],"document_number__v":"VV-MED-00005"}]}';
			}
			response.setBody(responseBody);
			return response;
		}
	}

	global class VaultUtilityMockNoRelatedDocs implements HttpCalloutMock
	{
		global HTTPResponse respond(HTTPRequest req)
		{
			HTTPResponse response = new HTTPResponse();
			response.setHeader('Content-Type', 'application/json');
			response.setStatusCode(200);
			String responseBody;
			String requestBody = req.getBody();
			System.debug('Considering carefully which body to return');
			if(requestBody.contains('target_doc_id__v')) {
				responseBody = '{"responseStatus": "SUCCESS", "responseDetails": {"limit": 1000, "offset": 0, "size": 0, "total": 0}, "data": []}';
			} else if(requestBody.contains('id%3D')) {
				responseBody = '{"responseStatus": "SUCCESS", "responseDetails": {"limit": 1000, "offset": 0, "size": 0, "total": 0}, "data": []}';
			} else if(requestBody.contains('test_external_id')) {
				System.debug('Ah I shall return the product response');
				responseBody = '{"responseStatus":"SUCCESS","responseDetails":{"limit":50,"offset":0,"size":1,"total":1},"data":[{"id":10,"name__v":"Cholecap FAQ Product","title__v":"Cholecap FAQ Product","type__v":"FAQ","major_version_number__v":1,"minor_version_number__v":0,"status__v":"Published","size__v":null,"format__v":null,"subtype__v":null,"classification__v":null,"language__v":["English"],"document_country__vr":{"responseDetails":{"limit":250,"offset":0,"size":4,"total":4},"data":[{"abbreviation__vs":"US"},{"abbreviation__vs":"CA"},{"abbreviation__vs":"FR"},{"abbreviation__vs":"UK"}]},"document_product__vr":{"responseDetails":{"limit":250,"offset":0,"size":3,"total":3},"data":[{"external_id__v":"a0P17000000AEqHEAW"},{"external_id__v":"Voderal123"},{"external_id__v":"a0P17000000AEqMEAW"}]},"country__v":["1359657466445","1359657466468","1359657466730","1359657466425"],"product__v":["1359657466295","1381257889654","1381257833873"],"document_number__v":"VV-MED-00005"}]}';
			} else {
				responseBody = '{"responseStatus":"SUCCESS","responseDetails":{"limit":50,"offset":0,"size":1,"total":1},"data":[{"id":10,"name__v":"Cholecap FAQ","title__v":"Cholecap FAQ","type__v":"FAQ","major_version_number__v":1,"minor_version_number__v":0,"status__v":"Published","size__v":null,"format__v":null,"subtype__v":null,"classification__v":null,"language__v":["English"],"document_country__vr":{"responseDetails":{"limit":250,"offset":0,"size":4,"total":4},"data":[{"abbreviation__vs":"US"},{"abbreviation__vs":"CA"},{"abbreviation__vs":"FR"},{"abbreviation__vs":"UK"}]},"document_product__vr":{"responseDetails":{"limit":250,"offset":0,"size":3,"total":3},"data":[{"external_id__v":"a0P17000000AEqHEAW"},{"external_id__v":"Voderal123"},{"external_id__v":"a0P17000000AEqMEAW"}]},"country__v":["1359657466445","1359657466468","1359657466730","1359657466425"],"product__v":["1359657466295","1381257889654","1381257833873"],"document_number__v":"VV-MED-00005"}]}';
			}
			response.setBody(responseBody);
			return response;
		}
	}

	global class VaultUtilityMockInactiveService implements HttpCalloutMock
	{
		global HTTPResponse respond(HTTPRequest req)
		{
			HTTPResponse response = new HTTPResponse();
			response.setHeader('Content-Type', 'application/json');
			response.setStatusCode(200);
			String responseBody = '{"responseStatus":"FAILURE","errors":[{"type":"INACTIVE_USER","message":"User is inactive or not found."}],"errorType" : "AUTHENTICATION_FAILED"}';


			response.setBody(responseBody);
			return response;
		}
	}
	global class VaultUtilityMockUserLockedOut implements HttpCalloutMock
	{
		global HTTPResponse respond(HTTPRequest req)
		{
			HTTPResponse response = new HTTPResponse();
			response.setHeader('Content-Type', 'application/json');
			response.setStatusCode(200);
			String responseBody = '{"responseStatus":"FAILURE","errors":[{"type":"USER_LOCKED_OUT","message":"User is inactive or not found."}],"errorType" : "AUTHENTICATION_FAILED"}';


			response.setBody(responseBody);
			return response;
		}
	}
	global class VaultUtilityMockInvalidSession implements HttpCalloutMock
	{
		global HTTPResponse respond(HTTPRequest req)
		{
			HTTPResponse response = new HTTPResponse();
			response.setHeader('Content-Type', 'application/json');
			response.setStatusCode(200);
			String responseBody = '{"responseStatus":"FAILURE","errors":[{"type":"INVALID_SESSION_ID","message":"User is inactive or not found."}],"errorType" : "AUTHENTICATION_FAILED"}';


			response.setBody(responseBody);
			return response;
		}
	}
	global class VaultUtilityMockInsufficientAccess implements HttpCalloutMock
	{
		global HTTPResponse respond(HTTPRequest req)
		{
			HTTPResponse response = new HTTPResponse();
			response.setHeader('Content-Type', 'application/json');
			response.setStatusCode(200);
			String responseBody = '{"responseStatus":"FAILURE","errors":[{"type":"INSUFFICIENT_ACCESS","message":"User is inactive or not found."}],"errorType" : "AUTHENTICATION_FAILED"}';


			response.setBody(responseBody);
			return response;
		}
	}
	global class VaultUtilityMockOther implements HttpCalloutMock
	{
		global HTTPResponse respond(HTTPRequest req)
		{
			HTTPResponse response = new HTTPResponse();
			response.setHeader('Content-Type', 'application/json');
			response.setStatusCode(200);
			String responseBody = '{"responseStatus":"FAILURE","errors":[{"type":"Other","message":"User is inactive or not found."}],"errorType" : "AUTHENTICATION_FAILED"}';


			response.setBody(responseBody);
			return response;
		}
	}



}