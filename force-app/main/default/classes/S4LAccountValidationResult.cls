global class S4LAccountValidationResult {

    global enum S4LAccountValidationError {
        ACCOUNT_ERROR,
        PRODUCT_ERROR,
        SEGMENT_ERROR
    }

    @AuraEnabled
    global String errorCode;
    @AuraEnabled
    global String accountFormattedName;
    @AuraEnabled
    global String productName;
    @AuraEnabled
    global String clmPresentationName;

    // product error (allowed product/ restricted product violation)
    public S4LAccountValidationResult(S4LAccountValidationError errorCode, String accountFormattedName,
                                        String productName, String clmPresentationName) {
        this(errorCode, accountFormattedName);
        this.productName = productName;
        this.clmPresentationName = clmPresentationName;
    }

    // Segmentation error
    public S4LAccountValidationResult(S4LAccountValidationError errorCode, String accountFormattedName) {
        this.errorCode = String.valueOf(errorCode);
        this.accountFormattedName = accountFormattedName;
    }

}