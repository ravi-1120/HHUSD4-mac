public without sharing class MRK_RedirectWithVariables {

    //apex/MRK_Redirect_With_Variables?object=Account_Tactic_vod&vars=Description_vod|testestets|Priority_MRK|high
    ///apex/MRK_Redirect_With_Variables?object=Account_Tactic_vod&vars=Objective_MRK|{!Objective_MRK__c.Name}|Account_Plan_vod|{!Objective_MRK__c.Account_Plan_MRK__c}|Account_vod|{!Objective_MRK__c.Account_Name_MRK__c}
    
    public PageReference redirectUser() {
        String objectName = ApexPages.currentPage().getParameters().get('object');
        system.debug('jk - objectName: ' + objectName);
        Schema.Sobjecttype myObject = Schema.getGlobalDescribe().get(objectName + '__c');
        system.debug('jk - myObject: ' + myObject);
        Map<String,String> fieldNameToValue = new Map<String,String>();
        List<String> variables = new List<String>();
        variables = ApexPages.currentPage().getParameters().get('vars').split('\\|');
        system.debug('jk - variables: ' + variables);
        
        for (Integer i = 0; i < variables.size(); i+=2) {
            fieldNameToValue.put(variables.get(i),variables.get(i+1));
        }
        system.debug('jk - fieldNamesToValues: ' + fieldNameToValue);
        
        PageReference returnPageReference = new PageReference('/' +  myObject.getDescribe().getKeyPrefix() + '/e');
        
        // Constructs the Tooling API wrapper (default constructor uses user session Id)                
        MRK_ToolingAPI toolingAPI = new MRK_ToolingAPI();
        
        // Query CustomObject object by DeveloperName (note no __c suffix required)
        List<MRK_ToolingAPI.CustomObject> customObjects = 
                toolingAPI.queryCustomObject('DeveloperName = \'' + objectName + '\'').records;
                
        system.debug('jk - customObjects: ' + customObjects);
        
        // Query CustomField object by TableEnumOrId (use CustomObject Id not name for Custom Objects)
        MRK_ToolingAPI.CustomObject customObject = customObjects[0];
        Id customObjectId = customObject.Id;
        List<MRK_ToolingAPI.CustomField> customFields = 
                toolingAPI.queryCustomField('TableEnumOrId = \'' + customObjectId + '\'').records;
        
        //Create map of Field Name to ID
        Map<String,String> fieldNameToID = new Map<String,String>();
        for (MRK_ToolingAPI.CustomField cf : customFields) {
            String fieldId = (string)cf.Id;
            //get 15 digit ID as opposed to 18 digit ID
            fieldId = fieldId.substring(0,fieldId.length()-3);
            System.debug('jk cf.Id='+cf.Id+' fieldId='+fieldId);
            fieldNameToID.put(cf.DeveloperName,fieldId);
        }
        
        Map<String, String> parameters = returnPageReference.getParameters();
        parameters.put('nooverride', '1');
        parameters.put('retURL', ApexPages.currentPage().getParameters().get('retURL'));
        for (String f : fieldNameToValue.keyset()) {
            if (fieldNameToId.containsKey(f)) {
                parameters.put('CF'+fieldnameToId.get(f),fieldNameToValue.get(f));
            }
        }
        system.debug('jk - page ref: ' + returnPageReference);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,returnPageReference.getUrl()));
        
                
        return returnPageReference;
    }
}