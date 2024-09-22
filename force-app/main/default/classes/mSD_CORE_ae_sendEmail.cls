/*
 * mSD_CORE_ae_sendEmail 
 * Created By:      FocalCXM (SaiRohith)
 * Created Date:    11/28/2023
 * Description:     This class sends an email for reporting an issue in the Merck Self-Service Adverse Event Portal
 */


public class mSD_CORE_ae_sendEmail {
    private static final String CLASS_NAME = 'mSD_CORE_ae_sendEmail';
    @AuraEnabled
    public static Boolean sendEmail(String recipientEmail, String senderName, String messageBody, String filesDataJson) {
        try {
            OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'AE Self-Service Portal' LIMIT 1];
            MSD_CORE_ae_PortalSetting__mdt setting = [SELECT Support_Email__c FROM MSD_CORE_ae_PortalSetting__mdt LIMIT 1];
            
            if (owea == null || setting == null || String.isEmpty(setting.Support_Email__c)) {
                system.debug('Org Wide Address or Portal Setting Missing');
                return false;
            }
            List<String> emailAddresses = setting.Support_Email__c.split(';');
            System.debug('OrgWideEmailAddress retrieved: ' + owea.Id);
            String emailBody = 'Name: ' + senderName + '\nEmail: ' + recipientEmail + '\nMessage:\n' + messageBody;
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject('Adverse Event Self-Service Portal: Report an Issue Notification');
            mail.setToAddresses(emailAddresses);
            mail.setPlainTextBody(emailBody);
            mail.setOrgWideEmailAddressId(owea.Id);
            mail.setSaveAsActivity(false);
            List<FileData> filesData = (List<FileData>)JSON.deserialize(filesDataJson, List<FileData>.class);
            if (filesData != null && !filesData.isEmpty()) {
                List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                for (FileData file : filesData) {
                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                    attachment.setFileName(file.filename);
                    attachment.setBody(EncodingUtil.base64Decode(file.base64));
                    attachments.add(attachment);
                    System.debug('File attached: ' + file.filename);
                }
                mail.setFileAttachments(attachments);
            } else {
                System.debug('No files to attach.');
            }
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            if (results.size() > 0 && !results[0].isSuccess()) {
                for (Messaging.SendEmailResult result : results) {
                    if (!result.isSuccess()) {
                        System.debug('Email sending error: ' + result.getErrors()[0].getMessage());
                        return false;
                    }
                }
            } else {
                System.debug('Email sent successfully.');
                return true;
            }
        }  catch (Exception ex) {
            AMOExceptionHandler.logException(ex, CLASS_NAME, 'sendEmail', null, 'Error');
            System.debug('Exception caught - generic exception: ' + ex.getMessage());
            return false;
        }
        return false;
    }
    public class FileData {
        public String filename;
        public String base64;
    }
}