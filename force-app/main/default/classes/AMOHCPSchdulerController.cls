public with sharing class AMOHCPSchdulerController {
    
    @AuraEnabled
    public static String getHCPAttestaion(Boolean isHCP) {
        String redirectURL ='';
        try {
            HCP_Attestation__mdt hcpAttestationDetails =HCP_Attestation__mdt.getInstance('Merck_Medical_Portal');
            redirectURL = hcpAttestationDetails.URL__c +'?';
            //String queryParams = 'country=' + hcpAttestationDetails.Country__c + '&isHCP='+ String.valueOf(isHCP);
            String queryParams = encryptURL(hcpAttestationDetails,isHCP);
            redirectURL = redirectURL + EncodingUtil.urlEncode(queryParams,'UTF-8');
        } catch (Exception ex) { 
            System.debug('exception-->'+ex); 
        }
        return redirectURL;
    }
    
    public static String encryptURL(HCP_Attestation__mdt hcpAttestationDetails,Boolean isHCP){
        String queryParams;
        String encrypted64 = '';
        try{
            queryParams = 'country=' + hcpAttestationDetails.Country__c + '&isHCP='+ String.valueOf(isHCP);
           // Blob key = Crypto.generateAesKey(256);
            Blob key = EncodingUtil.base64Decode(hcpAttestationDetails.AES_Key__c);
            Blob source = Blob.valueOf(queryParams);
            Blob encrypted = Crypto.encryptWithManagedIV('AES256', key, source);
            encrypted64 = EncodingUtil.base64Encode(encrypted);
            Blob dest = EncodingUtil.base64Decode(encrypted64);
            Blob decrypted = Crypto.decryptWithManagedIv('AES256', key, dest);
            String decryptedText = decrypted.toString();
        } catch (Exception ex) { 
            System.debug('exception-->'+ex); 
        }
        return encrypted64;
    }
}