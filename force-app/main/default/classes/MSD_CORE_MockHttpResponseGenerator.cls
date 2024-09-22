@isTest
global class MSD_CORE_MockHttpResponseGenerator Implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('Pir Submitted Successfully');
        res.setStatusCode(200);
        return res;
    }
    
    global HTTPResponse respondFailure(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('Error Submitting Pir');
        res.setStatusCode(500);
        return res;
    }
    
    global HTTPResponse respondFailure2(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('Network Failure');
        res.setStatusCode(408);
        return res;
    }

}