@RestResource(urlMapping='/tbttemplateservice') 
global class MSD_CORE_HEQ_TemplateServiceDispatcher {
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
                resWrapperRec = MSD_CORE_HEQ_TBTTemplateServiceHandler.createTemplate(requestParamsMap);
            }
            when '2' {
                resWrapperRec = MSD_CORE_HEQ_TBTTemplateServiceHandler.updateTemplate(req.requestBody.toString());
            }
            when '3' {
                resWrapperRec = MSD_CORE_HEQ_TBTTemplateServiceHandler.getTemplateById(requestParamsMap);
            }
            when '4' {
                resWrapperRec = MSD_CORE_HEQ_TBTTemplateServiceHandler.getListOfTemplates(requestParamsMap);
            }
            when '5' {
                resWrapperRec = MSD_CORE_HEQ_TBTTemplateServiceHandler.updateTemplateResource(req.requestBody.toString());
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