/*
 *  CaseMVN
 *  Created By:     Roman Lerman
 *  Created Date:   3/1/2013
 *  Modified By:    Samuel Rosen 
 *  Description:    This is a generic Case trigger used for calling any Case logic
 *                  KRB 6/23/2017 Added the MSD_CORE_Clear_NotApplicable_AE_Values call
 * Change Log:
 * Updated Date: 7/7/2021
 * Description: Updated Below Methods
 * 				MSD_CORE_Clear_NotApplicable_AE_Values
 * 				MSD_CORE_CaseCampaignProductTrigger
 * 				MSD_CORE_AddAEContactsToAETrigger
 * 				MSD_CORE_CasePopulateLegalAEPQCTrigger
 */
trigger CaseMVN on Case (before insert, before update, after insert, after update) {
    new TriggersMVN()
        .bind(TriggersMVN.Evt.beforeupdate, new MSD_CORE_Clear_NotApplicable_AE_Values())
        .bind(TriggersMVN.Evt.beforeupdate, new MSD_CORE_TrackTimeWithOwnerTrigger())
        .bind(TriggersMVN.Evt.beforeinsert, new MSD_CORE_CaseCampaignProductTrigger())
        .bind(TriggersMVN.Evt.afterinsert, new MSD_CORE_AddAEContactsToAETrigger())
        .bind(TriggersMVN.Evt.afterinsert, new MSD_CORE_CasePopulateLegalAEPQCTrigger())
        .bind(TriggersMVN.Evt.afterinsert, new MSD_CORE_CopyLotNumbersToCRFromTETrigger())
        .bind(TriggersMVN.Evt.afterinsert, new MSD_CORE_ManageVeevaCaseTrigger())
        .bind(TriggersMVN.Evt.afterupdate, new MSD_CORE_CasePopulateLegalAEPQCTrigger())
        .bind(TriggersMVN.Evt.afterupdate, new UpdateRequestsWhenInteractionChangedMVN())
        .bind(TriggersMVN.Evt.afterupdate, new ReopenParentCaseWhenChildReopenedMVN())
        .bind(TriggersMVN.Evt.afterupdate, new ChangeCaseOwnershipTriggerMVN())
        .bind(TriggersMVN.Evt.afterupdate, new CloseChildCasesWhenInteractClosedMVN())
        .bind(TriggersMVN.Evt.afterupdate, new MSD_CORE_TouchFRWhenFRCaseNotesChanges())
        .bind(TriggersMVN.Evt.afterupdate, new MSD_CORE_ManageVeevaCaseTrigger())
        .manage();

    /* Currently not using the code below so it should only fire when being
       run through unit tests so that the tests do not break */
    if(Test.isRunningTest()){
        new TriggersMVN()
            .bind(TriggersMVN.Evt.beforeinsert, new CreateInteractionForRequestMVN())
            .bind(TriggersMVN.Evt.afterupdate, new CloseMedInqryWhenInteractClosedMVN())
            .manage();
    }
}