public with sharing class VeevaCommonMessageExtension {
    public VeevaCommonMessageExtension(ApexPages.StandardController controller) {
    }

    public String getTranslatedNew() {
        return VOD_VEEVA_MESSAGE.getMsgWithDefault('NEW', 'Common', 'New');    
    }

    public String getTranslatedEdit() {
        return VOD_VEEVA_MESSAGE.getMsgWithDefault('EDIT', 'Common', 'Edit');    
    }
}