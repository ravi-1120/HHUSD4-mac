global class PDS_EmailApprovalHandler implements Messaging.InboundEmailHandler{
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        try {
            String status = email.subject;
            String plainTextBody = email.plainTextBody;

            if (status != null && plainTextBody != null) {

                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                if(status.contains('approve')){
                    req.setAction('Approve');
                }else if(status.contains('reject')){
                    req.setAction('Reject');
                }
                req.setWorkitemId(plainTextBody);
                
                Approval.ProcessResult approvalResult = Approval.process(req);
                
                if (approvalResult.isSuccess()) {
                    result.success = true;
                    result.message = 'Approval process successfully approved for request ';
                } else {
                    result.success = false;
                    result.message = 'Failed to approve the request. Error: ' + approvalResult.getErrors()[0].getMessage();
                    System.debug('Approval processing failed: ' + approvalResult.getErrors()[0].getMessage());
                }

            } else {
                result.success = false;
                result.message = 'Unable to fetch status';
                System.debug('Unable to fetch status from email subject: ' + status);
            }
        } catch (Exception e) {
            result.success = false;
            result.message = 'An error occurred while processing the email: ' + e.getMessage();
            System.debug('An error occurred while processing the email: ' + e.getMessage());
        }
        
        return result;
    }
    
}