public class MSD_CORE_ae_EmailCaseDetails {
    @AuraEnabled
    public static void sendEmail(String recipientEmail, String caseNumber, String submissionDateTime) {
        System.debug('Method sendEmail called');
        System.debug('Recipient Email: ' + recipientEmail);
        System.debug('Case Number: ' + caseNumber);
        System.debug('Submission Date/Time: ' + submissionDateTime);

        // Query Org Wide Email Address
        OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'AE Self-Service Portal' LIMIT 1];
        
        // Query Email Template
        EmailTemplate emailTemplate = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Adverse_Event_Reporting_Template' LIMIT 1];
        System.debug('Email Template Id: ' + emailTemplate.Id);
        System.debug('Email Template HTML Value: ' + emailTemplate.HtmlValue);
        
        // Query custom metadata for Logo URL
        MSD_CORE_ae_PortalSetting__mdt Mercklogo = MSD_CORE_ae_PortalSetting__mdt.getInstance('AE_Portal');
        String logoUrl = Mercklogo.Logo_Url__c;
        System.debug('Logo URL: ' + logoUrl);
        
        // Add global font-family style for "Invention"
        String style = '<style> body, table, td { font-family: Invention; } </style>';
        // Replace placeholders in the email template
        String emailBody = style + emailTemplate.HtmlValue
            .replace('{CaseNumber}', '<span style="color:#00857c;">' + caseNumber + '</span>')
            .replace('{CreatedDate}', '<span style="color:#00857c;">' + submissionDateTime + '</span>')
            .replace('logoUrl', logoUrl);
        
        System.debug('Email Body After Replacement: ' + emailBody);
        
        // Create the email message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { recipientEmail });
        email.setSubject('Confidential: Email Acknowledgement Receipt of Adverse Event received through the Adverse Event Reporting Self-Service Portal');
        email.setHtmlBody(emailBody);
        
        if (owea != null) {
            email.setOrgWideEmailAddressId(owea.Id);
        }
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}