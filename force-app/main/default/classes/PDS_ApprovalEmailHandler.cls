global class PDS_ApprovalEmailHandler implements Messaging.InboundEmailHandler{
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        try {
            String subject = email.subject;
            System.debug('subject:' +subject);
            String authNumber = extractAuthNumberFromSubject(subject);
            System.debug('authNumber:' +authNumber);
            
            if (authNumber != null) {
                PDS_Donation_Request__c request = getRequestRecord(authNumber);
                System.debug('request:' +request);
                
                if (request != null) {
                    System.debug('Request with auth num: ' + authNumber);
                    if (request.PDS_Donation_Request_Status__c !=null && request.PDS_Donation_Request_Status__c == 'Reviewed') {
                        System.debug('Request status: ' + request.PDS_Donation_Request_Status__c);
                        String senderEmail = envelope.fromAddress.contains('msd') ? envelope.fromAddress.replace('msd', 'Merck') : envelope.fromAddress;
                        String plainTextBody = email.plainTextBody;
                        System.debug('plainTextBody:' +plainTextBody);
                        
                        List<ProcessInstanceWorkitem> workItems = [SELECT Id, ActorId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :request.Id AND ProcessInstance.Status = 'Pending'];
                        
                        if (!workItems.isEmpty()) {
                            String approverId = workItems[0].ActorId;
                            System.debug('approverId:' +approverId);
                            User approver = getUserByEmail(senderEmail);
                            System.debug('approver:' +approver);
                            if (approver != null && approver.Id == approverId) {
                                // Process email attachments
                                System.debug('approver:' +approver);
                                System.debug('request:' +request);
                                System.debug('binaryAttachments:' +email.binaryAttachments);
                                
                                if(email.binaryAttachments != null){
                                    processAttachments(email.binaryAttachments, request);
                                }
                                
                                
                                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                                req.setAction('Approve');
                                req.setComments(plainTextBody);
                                req.setWorkitemId(workItems[0].Id);
                                
                                Approval.ProcessResult approvalResult = Approval.process(req);
                                
                                if (approvalResult.isSuccess()) {
                                    result.success = true;
                                    result.message = 'Approval process successfully approved for request ' + request.Name;
                                } else {
                                    result.success = false;
                                    result.message = 'Failed to approve the request. Error: ' + approvalResult.getErrors()[0].getMessage();
                                    System.debug('Approval processing failed: ' + approvalResult.getErrors()[0].getMessage());
                                }
                            }
                        } else {
                            result.success = false;
                            result.message = 'No user found with the email address ' + senderEmail + ' as the approver.';
                            System.debug('No user found with the email address ' + senderEmail + ' as the approver.');
                        }
                        
                    } else {
                        result.success = false;
                        result.message = 'The request is not in a state where approval is pending.';
                        System.debug('The request ' + request.Name + ' is not in a state where approval is pending.');
                    }
                } else {
                    result.success = false;
                    result.message = 'No request found with the provided auth number.';
                    System.debug('No request found with the provided auth number: ' + authNumber);
                }
            } else {
                result.success = false;
                result.message = 'Unable to extract authorization number from email subject.';
                System.debug('Unable to extract authorization number from email subject: ' + subject);
            }
        } catch (Exception e) {
            result.success = false;
            result.message = 'An error occurred while processing the email: ' + e.getMessage();
            System.debug('An error occurred while processing the email: ' + e.getMessage());
        }
        
        return result;
    }
    
    
    private String extractAuthNumberFromSubject(String subject) {
        // String authNumber = subject;       
        //return authNumber;
        String authNumber = '';
        Integer startIndex = subject.indexOf('(');
        Integer endIndex = subject.indexOf(')');
        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
            authNumber = subject.substring(startIndex + 1, endIndex);
            System.debug('authNumber:>'+authNumber);
        }
        return authNumber;
    }
    
    private PDS_Donation_Request__c getRequestRecord(String authNumber) {
        PDS_Donation_Request__c request = [SELECT Id, Name,PDS_Donation_Request_Status__c FROM PDS_Donation_Request__c WHERE Name =: authNumber LIMIT 1];
        return request;
    }
    
    private User getUserByEmail(String email) {
        User user = [SELECT Id FROM User WHERE Email = :email LIMIT 1];
        return user;
    }  
    private void processAttachments(List<Messaging.InboundEmail.BinaryAttachment> attachments, PDS_Donation_Request__c request) {
        System.debug('processAttachments...');
        System.debug('request...');
        
        List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();

        for(Messaging.InboundEmail.BinaryAttachment attachment : attachments) {
            ContentVersion newContentVersion = new ContentVersion();
        	newContentVersion.ContentLocation = 'S'; // 'S' indicates Salesforce file
            newContentVersion.PathOnClient = attachment.fileName;
            newContentVersion.Title = attachment.fileName;
            newContentVersion.VersionData = attachment.body;
            contentVersionsToInsert.add(newContentVersion);
        }

        if(!contentVersionsToInsert.isEmpty()) {
            insert contentVersionsToInsert;
            List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
            for(ContentVersion cv : contentVersionsToInsert) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.LinkedEntityId = request.Id; // Attach to the relevant record
                cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
                cdl.ShareType = 'V'; // 'V' indicates shared with all users who have access to the record
                cdl.Visibility = 'AllUsers';
                contentDocumentLinks.add(cdl);
            }
            
            if(!contentDocumentLinks.isEmpty()) {
                insert contentDocumentLinks;
            }
        }
        
        System.debug('processAttachments...');
    }
}