public with sharing class GenericException extends Exception {

    private String reasonCode;
    private String errorMsg;
    
    public GenericException(String reasonCode,String errorMsg) {
        this.reasonCode = reasonCode;
        this.errorMsg = errorMsg;
        System.debug('reasonCode--->'+reasonCode);
        System.debug('errorMsg--->'+errorMsg);
    }

    public String getErrorMsg() {
        return errorMsg;
    }
    public String getReasonCode() {
        return reasonCode;
    }
}