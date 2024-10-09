@RestResource(urlMapping='/tbtdesignservice') 
global class MSD_CORE_HEQ_DesignServiceDispatcher {
    @HttpPost
    global static void templateServiceHandler() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        Map<string, object> requestParamsMap = new Map<string, string>();
        ResponseWrapper resWrapperRec;
        
        requestParamsMap = (Map<string, object>)JSON.deserializeUnTyped(req.requestBody.toString()); 
        String methodCode = requestParamsMap.get('method_code') != NULL? (String)requestParamsMap.get('method_code'):'';
        
        
        switch on methodCode {
            when '1' {
                resWrapperRec = MSD_CORE_HEQ_TBTDesignServiceHandler.getListOfDesigns(requestParamsMap);
            }
            when '2' {
                resWrapperRec = MSD_CORE_HEQ_TBTDesignServiceHandler.getDesignByJobCode(requestParamsMap);
            }
            when '3' {
                resWrapperRec = MSD_CORE_HEQ_TBTDesignServiceHandler.upsertDesign(req.requestBody.toString(), requestParamsMap);
            }
            when '' {
                resWrapperRec = new ResponseWrapper(400, JSON.serialize(new Map<String, Object>{'error' => 'Missing required parameter: method_code'}));
            }            
            
        }
        if(resWrapperRec != NULL) {
            res.statusCode = resWrapperRec.statusCode;
            res.responseBody = Blob.valueOf(resWrapperRec.responseBody);
        } else {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Something went wrong. Please try again!');
        }
    }  
    
    global class ResponseWrapper {
        public Integer statusCode;
        public String responseBody;
        
        public ResponseWrapper(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
    }
    
}