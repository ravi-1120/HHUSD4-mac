/*
* Company		: Merck Co.
* Date			: 07-30-2018	
* Author		: Ramesh Elapakurthi
* Description	: Schedulable class to retry submitting PIR  to BUS. This runs every 5 mins.
* History		: First version
*/
global class MSD_CORE_ScheduledPIRs_RTB implements Schedulable{
    static final String REQ_STATUS_RETRY = 'RETRY';
    
   global void execute(SchedulableContext sc){
       System.debug('Running the scheduler for every 1 hr...');
        RetryPIRs();
        RetryCasePIRs();
    }
    
    public void RetryPIRs(){
        
        MSD_CORE_Aws_Api__c api = MSD_CORE_Aws_Api__c.getOrgDefaults();
        List<MSD_CORE_PIR_Request__c> pirRetries = [SELECT Id,PIR_Id__c, Status__c 
                                            FROM MSD_CORE_PIR_Request__c 
                                            WHERE Status__c =: REQ_STATUS_RETRY 
                                            AND PIR_Id__c != null 
                                            Limit 1];
        
        if(pirRetries.size()>=1){
            List<String> pirIdList = new List<String>();
            pirIdList.add(pirRetries[0].PIR_Id__c);
            System.debug('executing SubmitPirToBus '+ pirRetries[0].PIR_Id__c);
            
			pirRetries[0].Status__c = 'RETRIED';
            update pirRetries;
            
            MSD_CORE_AwsApiIntegration.submitPirToBus(pirIdList);
        }
            
        
    }
    
    public void RetryCasePIRs(){
        
        MSD_CORE_Aws_Api__c api = MSD_CORE_Aws_Api__c.getOrgDefaults();
        List<MSD_CORE_PIR_Request__c> pirRetries = [SELECT Id,Case_Id__c, Status__c 
                                            FROM MSD_CORE_PIR_Request__c 
                                            WHERE Status__c =: REQ_STATUS_RETRY 
                                            AND Case_Id__c != null AND MSD_CORE_Case_Type__c != 'AE' 
                                            Limit 1];
        if(pirRetries.size()>=1){
            List<String> pirIdList = new List<String>();
            pirIdList.add(pirRetries[0].Case_Id__c);
            System.debug('executing SubmitCaseToBus '+ pirRetries[0].Case_Id__c);
            
            pirRetries[0].Status__c = 'RETRIED';
            update pirRetries;
            
            MSD_CORE_AwsApiIntegration.submitCaseToBus(pirIdList);
        }
        
    }
}