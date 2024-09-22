public class MyInsightsReportOptionId {
    @AuraEnabled
    public String id { get; set; }

    @AuraEnabled
    public String pageType { get; set; }

    @AuraEnabled
    public String objectType { get; set; }

    public MyInsightsReportOptionId(String id, String pageType, String objectType) {
        this.id = id;
        this.pageType = pageType;
        this.objectType = objectType;
    }

    public MyInsightsReportOptionId(String id) {
        this.id = id;
        this.pageType = null;
        this.objectType = null;
    }
    
    // No argument constructor is needed for calling MyInsightsService.getVisibleHTMLReports() from myInsights.js
    public MyInsightsReportOptionId() {
        this(null);
    }

    public Boolean isValid() {
        if (this.id == null) {
            return false;
        }
        
        // Check that external id:
        //     - Exists in destination org
        //     - Is valid in entry point in destination org
        List<HTML_Report_vod__c> reports = [SELECT RecordType.DeveloperName FROM HTML_Report_vod__c WHERE External_Id_vod__c = :this.id];
        if (reports.size() != 1) {
            return false;
        }

        Boolean valid = false;
        MyInsightsVisualEditorConfiguration configuration = new MyInsightsVisualEditorConfiguration();
        if (this.pageType == 'RecordPage') {
            List<String> reportRecordTypes = configuration.getRecordTypesNamesFor(this.objectType);
            valid = reportRecordTypes.contains(reports.get(0).RecordType.DeveloperName);
        } else {
            List<String> defaultRecordTypeNames = configuration.getDefaultRecordTypeNames();
            valid = defaultRecordTypeNames.contains(reports.get(0).RecordType.DeveloperName);
        }
        return valid;
    }
}