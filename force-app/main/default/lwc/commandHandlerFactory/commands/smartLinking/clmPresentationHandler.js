import UserId from "@salesforce/user/Id";
import getCustomSettings from '@salesforce/apex/VeevaCustomSettingsService.getCustomSettings';
import BaseSmartLinkingHandler from "./baseSmartLinkingHandler";

export default class ClmPresentationHandler extends BaseSmartLinkingHandler {

    myInsightsPageController;
    constructor(myInsightsPageController) {
        super();
        this.myInsightsPageController = myInsightsPageController;
    }

    async handle(config) {
        const commonSettings = await getCustomSettings({
            customSettingObjectName: 'Veeva_Common_vod__c',
            settingFieldNames: ['Engage_Url_Prefix_vod__c'],
        });
        
        const { options } = config;

        // Ensure message has linking options, accountId, and Engage URL prefix
        const error = this.validateOptionsAndSettings(options, config.action, commonSettings);
        if (error) {
            this.throwCommandError(error);
        }

        return this.handlePresentationLaunch(options, commonSettings);
    }

    handlePresentationLaunch(options, settings) {
        // Generating message depending on parameters present
        let landingPage = `${settings.Engage_Url_Prefix_vod__c}/d.html?Action=LaunchMedia&accountid=${encodeURIComponent(options.prefill.Call2_vod__c.Account_vod__c)}`
            + `&uid=${encodeURIComponent(UserId)}`;
        if (options.record?.Presentation_Id_vod__c && options.record?.Key_Message_vod__c?.Media_File_Name_vod__c) {
            landingPage += `&presentationid=${encodeURIComponent(options.record.Presentation_Id_vod__c)}` +
                `&keymessagemediafilename=${encodeURIComponent(options.record.Key_Message_vod__c.Media_File_Name_vod__c)}`;
        }
        this.myInsightsPageController.navigateToUrl(landingPage);
        return { success: true };
    }

    validateOptionsAndSettings(options, action, settings) {        
        if (!options) {
            return "Did not receive linking options"
        }

        if (action !== 'launch') {
            return "Received unrecognized action";
        }

        if (!options.prefill?.Call2_vod__c?.Account_vod__c) {
            return "Did not receive accountId for Clm_Presentation_vod__c";
        }

        if (options.record?.Presentation_Id_vod__c && !options.record?.Key_Message_vod__c?.Media_File_Name_vod__c) {
            return "Received presentationId but did not receive keyMessageMediaFileName";
        }

        if (!options.record?.Presentation_Id_vod__c && options.record?.Key_Message_vod__c?.Media_File_Name_vod__c) {
            return "Received keyMessageMediaFileName but did not receive presentationId";
        }

        if (!settings?.Engage_Url_Prefix_vod__c) {
            return "Could not retrieve URL prefix for Engage landing page";
        }

        return null;
    }

    throwCommandError(message) {
        this.myInsightsPageController.closeLoadingModal();
        super.throwCommandError(message);
    }
}