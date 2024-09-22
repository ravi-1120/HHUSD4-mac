public with sharing class MRK_CampaignCleanupProcess implements Database.Batchable<sObject>, Database.Stateful
{
    private String currentStep;
    private Integer scopeSize = 200;
	private list<String>  listNames = new list<String>();
    private list<String>  viewNames = new list<String>();
	private list<String>  delviewNames = new list<String>();
	private list<String>  listIds = new list<String>();
	private list<String>  productIds = new list<String>();
    private String status = 'active';
	private Integer lmt = 9990;

    public MRK_CampaignCleanupProcess(String step,list<String>  plistNames,list<String>  pviewNames,list<String>  plistIds,list<String>  pproductIds)
    {
        currentStep = step;
		listNames = plistNames;
		viewNames = pviewNames;
		listIds = plistIds;
		productIds = pproductIds;
    }

    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        String qry;
        String externalProductType = 'Campaign';
        String productType = 'Detail';
        
        if(currentStep == 'LISTITEMS')
        {
            qry = 'SELECT Id,MSD_CORE_Status__c FROM MSD_CORE_List_Item__c WHERE MSD_CORE_List__c IN :listIds AND MSD_CORE_Status__c = :status LIMIT :lmt';
        }
        else if(currentStep == 'MYSETUPPRODUCTS')
        {
            qry = 'SELECT Id FROM My_Setup_Products_vod__c WHERE Product_vod__c IN :productIds LIMIT :lmt';
        }
		else if(currentStep == 'PRODUCTMETRICS')
        {
            qry = 'SELECT Id FROM Product_Metrics_vod__c WHERE Products_vod__c IN :productIds LIMIT :lmt';
	    }
		else if (currentStep == 'VIEW')
        {
            qry = 'SELECT Id,Name FROM View_vod__c WHERE Name IN :viewnames';
	    }
		else if(currentStep == 'PRODUCTS')
		{
		    qry = 'SELECT Id FROM Product_vod__c WHERE External_Product_Type_MRK__c = :externalProductType  and Product_Type_vod__c = :productType and Name IN :listnames';
		}
        return Database.getQueryLocator(qry);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope)
    {
        if(currentStep == 'LISTITEMS')
		{
			for(SObject record: scope) {
			record.put('MSD_CORE_Status__c', 'inactivated');
			}
			update scope;
		} 
        else{
		    if(currentStep == 'VIEW'){
			for(SObject record: scope) {
				delviewNames.add((String)record.get('Name'));
			}
			}
			delete scope;
		}		
    }

    public void finish(Database.BatchableContext BC)
    {
        if(currentStep == 'LISTITEMS')
        {
	        list<MSD_CORE_List_Item__c> pendingListItems= [SELECT Id,MSD_CORE_Status__c FROM MSD_CORE_List_Item__c WHERE MSD_CORE_List__c IN :listIds AND MSD_CORE_Status__c = :status];
			if(pendingListItems != null && !pendingListItems.isEmpty()) {
			   MRK_CampaignCleanupProcess mb = new MRK_CampaignCleanupProcess(currentStep,listNames,viewNames,listIds,productIds);
               Database.executeBatch(mb,scopeSize);
			}else {
			   MRK_CampaignCleanupProcess mb = new MRK_CampaignCleanupProcess('MYSETUPPRODUCTS',listNames,viewNames,listIds,productIds);
               Database.executeBatch(mb, scopeSize);
			}
        }
        else if (currentStep == 'MYSETUPPRODUCTS')
        {
            list<My_Setup_Products_vod__c> pendingMysetupProducts= [SELECT Id FROM My_Setup_Products_vod__c WHERE Product_vod__c IN :productIds];
			if(pendingMysetupProducts != null && !pendingMysetupProducts.isEmpty()) {
			   MRK_CampaignCleanupProcess mb = new MRK_CampaignCleanupProcess(currentStep,listNames,viewNames,listIds,productIds);
               Database.executeBatch(mb, scopeSize);
			}else {
			   MRK_CampaignCleanupProcess mb = new MRK_CampaignCleanupProcess('PRODUCTMETRICS',listNames,viewNames,listIds,productIds);
               Database.executeBatch(mb, scopeSize);
			}
        }
		else if (currentStep == 'PRODUCTMETRICS')
        {
            list<Product_Metrics_vod__c> pendingProductMetrics = [SELECT Id FROM Product_Metrics_vod__c WHERE Products_vod__c IN :productIds];
			if(pendingProductMetrics != null && !pendingProductMetrics.isEmpty()) {
			   MRK_CampaignCleanupProcess mb = new MRK_CampaignCleanupProcess(currentStep,listNames,viewNames,listIds,productIds);
               Database.executeBatch(mb, scopeSize);
			}else {
			   MRK_CampaignCleanupProcess mb = new MRK_CampaignCleanupProcess('VIEW',listNames,viewNames,listIds,productIds);
               Database.executeBatch(mb, scopeSize);
			}
        }
		else if (currentStep == 'VIEW')
        {
            MRK_CampaignCleanupProcess mb = new MRK_CampaignCleanupProcess('PRODUCTS',listNames,delviewNames,listIds,productIds);
            Database.executeBatch(mb, scopeSize);
        }
		else if (currentStep == 'PRODUCTS')
        {
		     string emailBody = '<!DOCTYPE html><html><head><style>body, table { font-family: Calibri,sans-serif; border-collapse: collapse; width: 100%;}th { border: 1px solid #dddddd; text-align: left; padding: 8px; background:#00857c; color:white;}td { border: 1px solid #dddddd; text-align: left; padding: 8px;}</style></head><body><p>Hi Team</p><p>Campaign Cleanup Process completed for this month. Please find the details of the campaign and views removed from user visibility.</p><table> <tr> <th>Campaign Name</th> <th>View Name</th></tr>';
             string emailtable = '';
              for(String viewName:viewNames)
              {   
                  string recordhtml = '<tr><td>'+viewName.replaceFirst('\\~ \\s*','')+'</td> <td>'+viewName+'</td></tr>';	  
                  emailtable = emailtable + recordhtml;	  	  
              }
              
              Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
              Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
              String[] toAddresses = new list<string> {'ghhveeva_msoteam@merck.com'};
              String subject ='Monthly Campaign Cleanup Job Report on '+Datetime.now().format('MM-dd-YYYY');
              email.setSubject(subject);
              email.setToAddresses( toAddresses );
              email.setHtmlBody(emailBody+emailtable+'</table><p> Thanks,<br/>Veeva Support Team</p></body></html>');
              Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});   
        }
    }
}