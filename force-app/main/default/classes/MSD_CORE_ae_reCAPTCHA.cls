/*
 * MSD_CORE_ae_reCAPTCHA 
 * Created By:      FocalCXM (Sairohith Ramini)
 * Version 2.0:     FocalCXM (Sairohith Ramini)
 * Created Date:    05/06/2024
 * Description:     This class validates reCAPTCHA v3 verification for Case Submission for the Merck Self-Service Adverse Event Portal
 */


public class MSD_CORE_ae_reCAPTCHA {
    // Nested class to store the reCAPTCHA verification result
    public class RecaptchaVerificationResult {
       @AuraEnabled
       public Boolean isSuccess;
       @AuraEnabled
       public Decimal score;
       @AuraEnabled
       public String errorMessage;
    }

    @AuraEnabled
    public static RecaptchaVerificationResult verifyRecaptcha(String response) {
       RecaptchaVerificationResult result = new RecaptchaVerificationResult();
       try {
          // Retrieve the reCAPTCHA secret key from a custom metadata type
          MSD_CORE_ae_PortalSetting__mdt recaptchaToken = MSD_CORE_ae_PortalSetting__mdt.getInstance('AE_Portal');
          String recaptchaSecretKey = recaptchaToken.reCaptcha_Secret_Key__c;
          
          // Set up the HTTP request
          Http http = new Http();
          HttpRequest request = new HttpRequest();
          request.setEndpoint('https://www.google.com/recaptcha/api/siteverify');
          request.setMethod('POST');
          request.setBody('secret=' + recaptchaSecretKey + '&response=' + response);
          
          // Send the HTTP request
          HttpResponse res = http.send(request);
          
          // Check the response status code
          if (res.getStatusCode() == 200) {
             // Parse the JSON response
             Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
             result.isSuccess = (Boolean) jsonResponse.get('success');
             result.score = jsonResponse.containsKey('score') ? (Decimal) jsonResponse.get('score') : 0;
             
             // Check the reCAPTCHA score
             if (result.isSuccess && result.score >= 0.7) {
                System.debug('reCAPTCHA verification successful. Score: ' + result.score);
                System.debug('Value returned to javascript' + result);
                return result;
                
             } else {
                result.isSuccess = false;
                result.errorMessage = 'reCAPTCHA verification failed. Score: ' + result.score;
                System.debug('reCAPTCHA verification failed. Score: ' + result.score);
                return result;
                 
             }
          } else {
             result.isSuccess = false;
             result.errorMessage = 'reCAPTCHA verification request failed with status: ' + res.getStatusCode();
             System.debug('reCAPTCHA verification request failed with status: ' + res.getStatusCode());
             return result;
          }
       } catch (Exception ex) {
          result.isSuccess = false;
          result.errorMessage = 'Error during reCAPTCHA verification: ' + ex.getMessage();
          System.debug('Error during reCAPTCHA verification: ' + ex.getMessage());
          return result;
       }
    }
}