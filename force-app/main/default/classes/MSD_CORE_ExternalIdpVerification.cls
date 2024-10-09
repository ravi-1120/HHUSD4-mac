public interface MSD_CORE_ExternalIdpVerification {
    /**
     * This method verifies the response from an external IdP.
     * 
     * @param idpResponse The response received from the external IdP.
     * @return Boolean indicating if the response is valid or not.
     */
    Boolean verifyIdpResponse(String idpResponse);
    
    /**
     * Extracts user details (e.g., email, name) from the IdP response.
     * 
     * @param idpResponse The response received from the external IdP.
     * @return Map<String, String> containing user attributes.
     */
    Map<String, String> extractUserDetails(String idpResponse);
    
    /**
     * Issues a token or assertion from Salesforce based on the user details.
     * 
     * @param userDetails A map of user attributes extracted from the IdP response.
     * @return String token or assertion to be used for SSO.
     */
    String issueSalesforceAssertion(Map<String, String> userDetails);
}