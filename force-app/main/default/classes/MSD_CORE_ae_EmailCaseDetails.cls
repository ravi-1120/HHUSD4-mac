public class MSD_CORE_ae_EmailCaseDetails {
    @AuraEnabled
    public static void sendEmail(String recipientEmail, String caseNumber, String submissionDateTime) {
        OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'AE Self-Service Portal' LIMIT 1];
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { recipientEmail });
        email.setSubject('Confidential: Email Acknowledgement Receipt of Adverse Event received through the Adverse Event Reporting Self-Service Portal');
        
        String emailBody = '<p><strong>Confidential</strong></p>' +
            '<p>Dear Reporter,</p>' +
            '<p>This email confirms that we have received your report of an adverse experience through the Adverse Event Reporting Self-Service Portal.</p>' +
            '<p>Please see the Adverse Event Confirmation Details below.</p>' +
            '<p>Service Cloud Case Number: ' + caseNumber + '<br>' +
            'Submission Date/Time: ' + submissionDateTime + '</p>' +
            '<p>Sincerely,<br>' +
            'The Merck Adverse Event Reporting Self-Service Portal Team</p>' +
            '<p>You may have elected to receive e-mails and other online communications from Merck. If you no longer wish to receive Proprietary communications from Merck, please <a href="mailto:merck_privacy_office@merck.com?subject=E-mail%20Opt%20Out%20Request%20(NSC)">click here</a>. If you have trouble accessing this link, please send an e-mail to <a href="mailto:merck_privacy_office@merck.com?subject=E-mail%20Opt%20Out%20Request%20(NSC)">merck_privacy_office@merck.com</a> with a subject line of: E-mail Opt Out Request - NSC.</p>' +
            '<p>Merck Privacy Office, 351 N Sumneytown Pike, UG4B-24, North Wales, PA 19454, USA</p>';
        
        email.setHtmlBody(emailBody); // Use HTML body to support the "click here" link
        
        if (owea != null) {
            email.setOrgWideEmailAddressId(owea.Id);
        }
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}