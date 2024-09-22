public with sharing class FeedbackMyInsightsService {
    // Returns the ID of the HTML Report whose External ID matches externalId and whose Record Type is Territory_Feedback_vod. If no match, returns null.
    @AuraEnabled(cacheable=true)
    public static Id getTerritoryFeedbackReportId(String externalId) {
        if (!SObjectType.HTML_Report_vod__c.isAccessible()) {
            return null;
        }

        List<HTML_Report_vod__c> feedbackReports = [
            SELECT Id
            FROM HTML_Report_vod__c
            WHERE External_Id_vod__c = :externalId AND RecordType.DeveloperName = 'Territory_Feedback_vod'
        ];

        return feedbackReports.isEmpty() ? null : feedbackReports.get(0).Id;
    }
}