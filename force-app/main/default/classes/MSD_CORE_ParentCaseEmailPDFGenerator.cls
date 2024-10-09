public class MSD_CORE_ParentCaseEmailPDFGenerator {
    @AuraEnabled
    public static Map<String, Object> generatePDFFromEmails(Id caseId) {
        Map<String, Object> result = new Map<String, Object>();
        List<String> debugLogs = new List<String>();
        try {
            Case c = [SELECT Id, CaseNumber FROM Case WHERE Id = :caseId];
            List<EmailMessage> emails = [SELECT Id, Subject, TextBody, FromAddress, ToAddress, MessageDate 
                                         FROM EmailMessage 
                                         WHERE ParentId = :caseId 
                                         ORDER BY MessageDate DESC];
            
            debugLogs.add('Found ' + emails.size() + ' emails for case ' + c.CaseNumber);
            
            if (emails.isEmpty()) {
                result.put('success', false);
                result.put('message', 'No emails found for this case.');
                result.put('debugLogs', String.join(debugLogs, '\n'));
                return result;
            }

            // Rename existing email summaries


            // Generate PDF content
            String pdfContent = generatePDFContent(c, emails);

            // Create new PDF Attachment
            Attachment pdfAtt = new Attachment();
            pdfAtt.ParentId = caseId;
            pdfAtt.Name = 'Case_' + c.CaseNumber + '_Emails_Summary.pdf';
            pdfAtt.Body = Blob.toPdf(pdfContent);
            pdfAtt.ContentType = 'application/pdf';
            insert pdfAtt;
            debugLogs.add('New PDF summary created with Id: ' + pdfAtt.Id);

            // Process email attachments
            Integer attachmentCount = processEmailAttachments(caseId, emails, debugLogs);

            result.put('success', true);
            result.put('message', 'New PDF summary added. ' + attachmentCount + ' email attachments processed.');
            result.put('pdfAttachmentId', pdfAtt.Id);
            result.put('debugLogs', String.join(debugLogs, '\n'));
            return result;
        } catch (Exception e) {
            result.put('success', false);
            result.put('message', 'Error: ' + e.getMessage() + ' Stack Trace: ' + e.getStackTraceString());
            result.put('debugLogs', String.join(debugLogs, '\n'));
            return result;
        }
    }



    public static Integer processEmailAttachments(Id caseId, List<EmailMessage> emails, List<String> debugLogs) {
        List<Attachment> newAttachments = new List<Attachment>();
        Set<Id> emailIds = new Set<Id>();
        
        for (EmailMessage email : emails) {
            emailIds.add(email.Id);
        }
        
        debugLogs.add('Processing email attachments for ' + emailIds.size() + ' emails');
        
        if (!emailIds.isEmpty()) {
            List<ContentDocumentLink> contentLinks = [SELECT ContentDocumentId, LinkedEntityId 
                                                      FROM ContentDocumentLink 
                                                      WHERE LinkedEntityId IN :emailIds];
            
            debugLogs.add('Found ' + contentLinks.size() + ' ContentDocumentLinks for all emails');
            
            if (!contentLinks.isEmpty()) {
                Set<Id> contentDocumentIds = new Set<Id>();
                for (ContentDocumentLink link : contentLinks) {
                    contentDocumentIds.add(link.ContentDocumentId);
                }
                
                List<ContentVersion> contentVersions = [SELECT Id, Title, VersionData, FileExtension, ContentDocumentId, FileType 
                                                        FROM ContentVersion 
                                                        WHERE ContentDocumentId IN :contentDocumentIds 
                                                        AND IsLatest = true];
                
                debugLogs.add('Found ' + contentVersions.size() + ' ContentVersions');
                
                for (ContentVersion cv : contentVersions) {
                    Attachment newAtt = new Attachment();
                    newAtt.ParentId = caseId;
                    newAtt.Name = cv.Title + (String.isBlank(cv.FileExtension) ? '' : '.' + cv.FileExtension);
                    newAtt.Body = cv.VersionData;
                    newAtt.ContentType = getMimeType(cv.FileExtension);
                    newAttachments.add(newAtt);
                }
            }
        }
        
        if (!newAttachments.isEmpty()) {
            insert newAttachments;
            debugLogs.add('Inserted ' + newAttachments.size() + ' new attachments');
        } else {
            debugLogs.add('No new attachments to insert');
        }
        
        return newAttachments.size();
    }

    private static String getMimeType(String fileExtension) {
        Map<String, String> mimeTypes = new Map<String, String>{
            'pdf' => 'application/pdf',
            'png' => 'image/png',
            'jpg' => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'gif' => 'image/gif',
            'csv' => 'text/csv',
            'xls' => 'application/vnd.ms-excel',
            'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'doc' => 'application/msword',
            'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'txt' => 'text/plain'
        };
        
        String mimeType = mimeTypes.get(fileExtension.toLowerCase());
        return mimeType != null ? mimeType : 'application/octet-stream';
    }

    private static String generatePDFContent(Case c, List<EmailMessage> emails) {
        String pdfContent = '<h1>Emails for Case: ' + escapeHtml(c.CaseNumber) + '</h1>';
        for (EmailMessage email : emails) {
            pdfContent += '<div style="margin-bottom: 20px; border-bottom: 1px solid #ccc; padding-bottom: 10px;">';
            pdfContent += '<p><strong>From:</strong> ' + escapeHtml(email.FromAddress) + '</p>';
            pdfContent += '<p><strong>To:</strong> ' + escapeHtml(email.ToAddress) + '</p>';
            pdfContent += '<p><strong>Date:</strong> ' + escapeHtml(email.MessageDate.format()) + '</p>';
            pdfContent += '<p><strong>Subject:</strong> ' + escapeHtml(email.Subject) + '</p>';
            pdfContent += '<p><strong>Body:</strong></p>';
            pdfContent += '<pre>' + escapeHtml(email.TextBody) + '</pre>';
            pdfContent += '</div>';
        }
        return pdfContent;
    }

    private static String escapeHtml(String input) {
        if (input == null) {
            return '';
        }
        String escaped = input.replace('&', '&amp;')
                              .replace('<', '&lt;')
                              .replace('>', '&gt;')
                              .replace('"', '&quot;')
                              .replace('\'', '&#39;');
        return escaped;
    }
}