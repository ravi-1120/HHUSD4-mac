export default class RemoveFromTerritoryLayoutParser {

    hasChallengeReasonsField;
    challengeReasonsRequired;

    constructor(layout) {
        if (layout && layout.sections) {
            layout.sections.forEach(section => {
                section.layoutRows.forEach(row => {
                    row.layoutItems.forEach(item => {
                        const fldRequired = item.required;
                        item.layoutComponents.forEach(cmp => {
                            if (cmp.apiName === "Challenge_Reasons_vod__c") {
                                this.hasChallengeReasonsField = true;
                                this.challengeReasonsRequired = fldRequired;
                            }
                        });
                    });
                });
            });
        }
    }
}