public class MyInsightsHTMLReportOptionsService {
    private final VisualEditor.DesignTimePageContext context;
    private final MyInsightsVisualEditorConfiguration configuration;
    
    public MyInsightsHTMLReportOptionsService(VisualEditor.DesignTimePageContext context) {
        this.context = context;
        this.configuration = new MyInsightsVisualEditorConfiguration();
    }

    public VisualEditor.DynamicPickListRows sortAndCreateRows(Boolean queryExtId) {
        List<HtmlReportWithUniqueName> sortedReports = sortRows(getHtmlReportOptions(queryExtId), queryExtId);
        VisualEditor.DynamicPickListRows  reportOptions = new VisualEditor.DynamicPickListRows();
        for (HtmlReportWithUniqueName htmlReportWithUniqueName : sortedReports) {
            HTML_Report_vod__c report = htmlReportWithUniqueName.getReport();
            VisualEditor.DataRow reportOption = null;
            if (queryExtId) {
                reportOption = new VisualEditor.DataRow(htmlReportWithUniqueName.getUniqueName(),
                    JSON.serialize(new MyInsightsReportOptionId(String.valueOf(report.External_Id_vod__c), this.context.pageType, this.context.entityName)));
            } else {
                reportOption = new VisualEditor.DataRow(htmlReportWithUniqueName.getUniqueName(), String.valueOf(report.Id));
            }
            reportOptions.addRow(reportOption);
        }
        return reportOptions;
    }

    private List<HTML_Report_vod__c> getHtmlReportOptions(Boolean queryExtId) {
        List<HTML_Report_vod__c> reports = new List<HTML_Report_vod__c>();
        if (userCanReadHtmlReports()) {
            String objectName = this.context.entityName;
            List<String> recordTypeNames = this.configuration.getRecordTypesNamesFor(objectName);
            if (this.context.pageType == 'RecordPage' && recordTypeNames != null && !recordTypeNames.isEmpty()) {
                reports = queryReports(recordTypeNames, queryExtId);
            } else {
                List<String> defaultRecordTypeNames = this.configuration.getDefaultRecordTypeNames();
                reports = queryReports(defaultRecordTypeNames, queryExtId);
            }
        }
        return reports;
    }

    private List<HtmlReportWithUniqueName> sortRows(List<HTML_Report_vod__c> reports, Boolean useExtId) {
        UniqueReportNameGenerator uniqueReportNameGenerator = new UniqueReportNameGenerator();
        List<HtmlReportWithUniqueName> uniqueHtmlReportNameByHtmlReport = new List<HtmlReportWithUniqueName>(); 
        if (useExtId) {
            uniqueHtmlReportNameByHtmlReport = uniqueReportNameGenerator.retrieveHtmlReportsWithUniqueNamesExtId(reports);
        } else {
            uniqueHtmlReportNameByHtmlReport = uniqueReportNameGenerator.retrieveHtmlReportsWithUniqueNames(reports);           
        }
        uniqueHtmlReportNameByHtmlReport.sort();
        return uniqueHtmlReportNameByHtmlReport;        
    }

    private boolean userCanReadHtmlReports() {
        return HTML_Report_vod__c.getSObjectType().getDescribe().isAccessible();
    }

    private List<HTML_Report_vod__c> queryReports(List<String> recordTypeNames, Boolean queryExtId) {
        List<HTML_Report_vod__c> reports = new List<HTML_Report_vod__c>();
        // Changing query depending on if we want to consider external id or not
        if (queryExtId) {
            reports = [SELECT Id, External_Id_vod__c, Name, RecordType.Name, Object_RecordType_vod__c FROM HTML_Report_vod__c WHERE RecordType.DeveloperName in :recordTypeNames AND Platform_vod__c includes ('Lightning_vod') AND External_Id_vod__c != null];
        } else {
            reports = [SELECT Id, Name, RecordType.Name, Object_RecordType_vod__c FROM HTML_Report_vod__c WHERE RecordType.DeveloperName in :recordTypeNames AND Platform_vod__c includes ('Lightning_vod')];
        }
        return reports;
    }
}