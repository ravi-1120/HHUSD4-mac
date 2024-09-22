public with sharing class VeevaDetailController {
    
	public String objectName {get;set;}
    
    public VeevaDetailController(ApexPages.StandardSetController controller) {
    }
    
	private ApexPages.StandardController controller;
    public VeevaDetailController(ApexPages.StandardController controller) {
        this.controller = controller;
    }

    public VeevaDetailController() {
    }

    public String getTranslatedOk() {
        return VOD_VEEVA_MESSAGE.getMsgWithDefault('OK', 'Common', 'Ok');    
    }
    
    public String getTranslatedCancel() {
        return VOD_VEEVA_MESSAGE.getMsgWithDefault('CANCEL', 'Common', 'Cancel');
    }
    
    public Boolean getContractTabVisibility() {
            List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
            for(DescribeTabSetResult tsr : tabSetDesc) {
                if (tsr.isSelected()){
                    List<Schema.DescribeTabResult> tabDesc = tsr.getTabs();
                    for(Schema.DescribeTabResult tr : tabDesc) {
                        if (tr.getSobjectName().equals(objectName)) {
                            return true;
                        }
                    }
                }
            }
        return false;
    }
}