/**
 * Simple wrapper around the REST version of the Salesforce Tooling API, 
 *   initially created to dynamically obtain Custom Object and Field Id's
 *
 * source: https://github.com/afawcett/apex-toolingapi/blob/master/apex-toolingapi/src/classes/ToolingAPI.cls
 **/
public without sharing class MRK_ToolingAPI 
{
        private String sessionId;
        
        public MRK_ToolingAPI(String sessionId)
        {
                this.sessionId = sessionId;
        }
        
        public MRK_ToolingAPI()
        {
                this.sessionId = UserInfo.getSessionId();        
        }

        public CustomObjectQueryResult queryCustomObject(String whereClause)
        {
                return (CustomObjectQueryResult) 
                        query('Select Id, DeveloperName, NamespacePrefix From CustomObject Where ' + whereClause, 
                                        CustomObjectQueryResult.class);
        }

        public CustomFieldQueryResult queryCustomField(String whereClause)
        {
                return (CustomFieldQueryResult) 
                        query('Select Id, DeveloperName, NamespacePrefix, TableEnumOrId From CustomField Where ' + whereClause, 
                                        CustomFieldQueryResult.class);
        }
        
        public class CustomObject
        {
                public Id id;
                public String DeveloperName;
                public String NamespacePrefix;
        }
        
        public class CustomField
        {
                public Id id;
                public String DeveloperName;
                public String NamespacePrefix;
                public String TableEnumOrId;
        }
        
        public class ErrorResponse
        {
                public String errorCode;
                public String message;                
        }

        public abstract class QueryResult
        {
                public Integer size;
                public Integer totalSize;
                public Boolean done;
        }
        
        public class CustomObjectQueryResult extends QueryResult
        {
                public List<CustomObject> records;
        }
        
        public class CustomFieldQueryResult extends QueryResult
        {
                public List<CustomField> records;
        }
        
        public class ToolingAPIException extends Exception
        {
                public ToolingAPIException(List<ErrorResponse> errorResponses)
                {
                        this(errorResponses[0].errorCode + ' : ' + errorResponses[0].message);
                }
        }
                
        private Object query(String soql, Type responseType)
        {
            Http h = new Http();            
            HttpRequest queryReq = new HttpRequest();
            queryReq.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v29.0/tooling/query/?q=' + EncodingUtil.urlEncode(soql, 'UTF-8'));
            queryReq.setHeader('Authorization', 'OAuth ' + sessionId);
            queryReq.setHeader('Content-Type', 'application/json');
            queryReq.setMethod('GET');
            HttpResponse queryRes = h.send(queryReq);
            if(queryRes.getStatusCode() != 200)
                    throw new ToolingAPIException((List<ErrorResponse>) JSON.deserialize(queryRes.getBody(), List<ErrorResponse>.class));
            return JSON.deserialize(queryRes.getBody(), responseType);
        }        
}