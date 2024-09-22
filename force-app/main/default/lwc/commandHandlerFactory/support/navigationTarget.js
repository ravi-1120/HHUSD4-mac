export default class NavigationTarget {

    static findTarget(targets, htmlReports) {
        let matchingTarget;
        let matchingHtmlReport;
        for (const target of targets) {
            matchingHtmlReport = htmlReports.find(htmlReport => matchesTarget(target, htmlReport));
            if (matchingHtmlReport) {
                matchingTarget = target;
                break;
            }
        }

        return matchingTarget ? {
            targetObject: matchingTarget,
            targetSalesforceId: matchingHtmlReport.Id
        } : undefined;
    }

}


function matchesTarget(target, htmlReport) {
    return (Object.prototype.hasOwnProperty.call(target,'ID')
            && htmlReport.Id === target.ID)
        || (Object.prototype.hasOwnProperty.call(target,'External_Id_vod__c')
            && htmlReport.External_Id_vod__c === target.External_Id_vod__c)
        || (Object.prototype.hasOwnProperty.call(target,'Studio_Id_vod__c')
            && htmlReport.Studio_Id_vod__c === target.Studio_Id_vod__c)
}