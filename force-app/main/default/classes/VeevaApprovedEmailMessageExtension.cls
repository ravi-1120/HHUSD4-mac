public with sharing class VeevaApprovedEmailMessageExtension {
    public VeevaApprovedEmailMessageExtension(ApexPages.StandardController controller) {
    }

    public String getTranslatedSendEmail() {
        return VOD_VEEVA_MESSAGE.getMsgWithDefault('SEND_EMAIL_PAGE_TITLE', 'ApprovedEmail', 'Send Email');    
    }
}