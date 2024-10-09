global class PDS_DonationFormHandler implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        try {
            String senderEmail;
            String senderName;
            String body;  // Declare the body variable

            // Ensure we get the plainTextBody or fallback to HTML body if plainTextBody is null
            if (email.plainTextBody != null) {
                body = email.plainTextBody;
            } else if (email.htmlBody != null) {
                body = email.htmlBody;
            } else {
                body = '';  // Assign an empty string if both bodies are null
            }

            System.debug('Email body--->' + body);

            // Check if the email is forwarded by looking for common forwarding indicators
            if (body != null && (body.containsIgnoreCase('Forwarded') || body.containsIgnoreCase('Fwd:') || body.containsIgnoreCase('From:'))) {
                
                // Extract the original sender email from the body
                senderEmail = extractOriginalEmail(body);
                System.debug('Extracted senderEmail from body--->' + senderEmail);

                // If we cannot find the email in the body, default to the envelope sender email
                if (senderEmail == null) {
                    senderEmail = envelope.fromAddress;
                    System.debug('Fallback to envelope sender email--->' + senderEmail);
                }

            } else {
                // If the email is not forwarded, use the sender email from the envelope (i.e., the direct sender)
                senderEmail = envelope.fromAddress;
                System.debug('Direct email sender--->' + senderEmail);
            }

            // Check if the subject contains the keyword "Entity Donation"
            if (email.subject != null && email.subject.containsIgnoreCase('Entity Donation')) {

                // Create a new EmailLog record
                PDS_Entity_Donation_Verification__c emailLog = new PDS_Entity_Donation_Verification__c();

                // Capture the sender email (either from the body if forwarded, or from the envelope)
                emailLog.PDS_Email__c = senderEmail;
                insert emailLog;

                // Mark the email as successfully processed
                result.success = true;
            } else {
                // If the subject does not contain the required keyword, do not insert the record
                result.success = false;
                // result.message = 'Email ignored: Subject does not contain required keyword.';
            }

        } catch (Exception e) {
            // If something goes wrong, set success to false
            result.success = false;
            result.message = 'Error: ' + e.getMessage();
        }

        return result;
    }

    // Helper method to extract the original email address from the forwarded email body
    private String extractOriginalEmail(String body) {
        System.debug('Attempting to extract email from body--->' + body);

        // Define a pattern to match an email address (e.g., From: someone@example.com)
        Pattern emailPattern = Pattern.compile('(?i)From:\\s*([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})');
        Matcher matcher = emailPattern.matcher(body);

        // Find the first match
        if (matcher.find()) {
            String extractedEmail = matcher.group(1);
            System.debug('Extracted original email--->' + extractedEmail);
            return extractedEmail;  // Return the captured email address
        }

        // If no email address is found, return null
        System.debug('No email found in the body.');
        return null;
    }
}