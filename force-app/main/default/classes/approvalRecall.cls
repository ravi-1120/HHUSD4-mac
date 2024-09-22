global class approvalRecall
{
   @InvocableMethod
    webservice static void recallApproval(List<Id> recId)   
    {       
        List<ProcessInstanceWorkitem> piwi = [SELECT Id, ProcessInstanceId, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: recId];
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setAction('Removed');       
        req.setWorkitemId(piwi.get(0).Id);
   
        Approval.process(req,false);
    }
}