public class ItemsToApproveController {
   
    private String UserId = UserInfo.getUserId() ;
    public Map<String, String> labels = new Map<String, String>();
    public Map<String, String> APINames = new Map<String, String>();
    public String baseURL;
    public String manageAllURL;
    public String UserLang = UserInfo.getLanguage() ;
    public List<ProcessInstanceWorkitem> items ;
 
    public ItemsToApproveController(){
    	items = getItemsToDisplay();
    }
    
    public List<ProcessInstanceWorkitem > getItems(){
    	return items;
    }
    
	public List<ProcessInstanceWorkitem > getItemsToDisplay() {

        //get all User Group and Queue Affiliations
        Set<ID> userorqueueids = new Set<ID> {UserInfo.getUserId()};
        UserGroupAffiliations uga = new UserGroupAffiliations();
        System.debug('uga = ' + uga);
        if(uga.getRelatedQueueIds()!=null && uga.getRelatedQueueIds().size() > 0){
        	System.debug('uga.getRelatedQueueIds() = ' + uga.getRelatedQueueIds());
        	userorqueueids.addAll(uga.getRelatedQueueIds());
        }
        System.debug('userorqueueids = ' + userorqueueids);
        
        // Query for Items to approve
    	List<ProcessInstanceWorkitem> results = Database.query(
        	'SELECT ActorId, Actor.Name, Id, ProcessInstanceId, ProcessInstance.TargetObjectId, ProcessInstance.TargetObject.Name, ProcessInstance.ProcessDefinition.TableEnumOrId, ProcessInstance.CreatedById, ProcessInstance.CreatedBy.Name, ProcessInstance.CreatedDate ' +   
            'FROM ProcessInstanceWorkitem ' + 
            'WHERE ActorId in: userorqueueids'

    	);    
        
        // Get Labels for Object Types
        for (Integer i = 0; i < results.size(); i++) {
            List<Schema.DescribeSObjectResult> describeSobjectsResult = Schema.describeSObjects(new List<String>{results[i].ProcessInstance.ProcessDefinition.TableEnumOrId});
            this.labels.put(results[i].id, describeSobjectsResult[0].getLabel());
        }
        
        // Retrieve API Names from Results List
        for (Integer i = 0; i < results.size(); i++) {
            this.APINames.put(results[i].id, results[i].ProcessInstance.ProcessDefinition.TableEnumOrId);
        }
        
    	return results;
	}
    
    // Return Labels for Object Type
    public Map<String, String> getLabels() {
        return labels;
    }
    
    // Return API Names for Object Type
    public Map<String, String> getAPINames() {
        return APINames;
    }
    
    // Return Base URL
    public String getBaseURL() {
        this.baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        
        return baseURL;
    }
    
    // Return URL for Custom Items to Approve Controller
    public String getManageAllURL() {
        this.manageAllURL = this.getBaseURL() + '/apex/ItemsToApproveController';
        
        return manageAllURL;
    }
    
    // Get User's Language
    public String getUserLang() {
        return UserLang;
    }
}