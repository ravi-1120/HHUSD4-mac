trigger MRK_Assessment_AfterInsertAndUpdate on Assessment_MRK__c (after insert, after update) {

    /**
     * BMP 2013-04-05 - 3.1
     *
     * * Added Override Lock logic for data loads.
     * * Adjusted inactivation logic for records that represent historical versions of an assessment
     *
     * BMP 2012-11-13 - 3.0
     * 
     * In support of CLM assessments, this populates the Account.Assessment_Data_MRK__c field with the
     * most recent assessment record id for the given assessment defintion.  The Assessment_Data_MRK__c
     * contains a JSON string which is an assessment defintion id to assessment record if map.
     *
     **/

    if (MRK_AssessmentManager.disableTriggers == true) {
        return;
    }

    static Id systemUserId = null;
    Map<Id,Account> accountsToUpdateMap = new Map<Id,Account>();
    List<Assessment_MRK__c> assessmentsToInactivate = new List<Assessment_MRK__c>();
    List<Assessment_MRK__c> assessmentsToArchive = new List<Assessment_MRK__c>();

    List<Map<String,String>> assessmentsToProcess = new List<Map<String,String>>();

    for (Assessment_MRK__c r : Trigger.new) {

        if (r.Active_MRK__c == false || r.Version_MRK__c == null || r.OwnerId != UserInfo.getUserId() ) {
            continue;
        }

        if (systemUserId == null) {
            systemUserId = [select Id from User where username like '%integration@merck.com%'].Id;
        }

        Map<String,String> assessmentToProcess = new Map<String,String>();
        assessmentToProcess.put('Account_MRK__c', r.Account_MRK__c);
        assessmentToProcess.put('Assessment_Definition_ID_MRK__c', r.Assessment_Definition_ID_MRK__c);
        assessmentsToProcess.add(assessmentToProcess);

        List<Assessment_MRK__c> assessementsForAccount = [SELECT Id, OwnerId, IsDeleted, Name, RecordTypeId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, Account_MRK__c, Active_MRK__c, Answer_01_MRK__c, Answer_02_MRK__c, Answer_03_MRK__c, Answer_04_MRK__c, Answer_05_MRK__c, Answer_06_MRK__c, Answer_07_MRK__c, Answer_08_MRK__c, Answer_09_MRK__c, Answer_10_MRK__c, Answer_11_MRK__c, Answer_12_MRK__c, Answer_13_MRK__c, Answer_14_MRK__c, Answer_15_MRK__c, Answer_16_MRK__c, Answer_17_MRK__c, Answer_18_MRK__c, Answer_19_MRK__c, Answer_20_MRK__c, Answer_21_MRK__c, Answer_22_MRK__c, Assessment_Date_MRK__c, Assessment_Definition_ID_MRK__c, Assessment_Name_MRK__c, Mobile_ID_vod__c, Product_Share_MRK__c, Question_01_MRK__c, Question_02_MRK__c, Question_03_MRK__c, Question_04_MRK__c, Question_05_MRK__c, Question_06_MRK__c, Question_07_MRK__c, Question_08_MRK__c, Question_09_MRK__c, Question_10_MRK__c, Question_11_MRK__c, Question_12_MRK__c, Question_13_MRK__c, Question_14_MRK__c, Question_15_MRK__c, Question_16_MRK__c, Question_17_MRK__c, Question_18_MRK__c, Question_19_MRK__c, Question_20_MRK__c, Question_21_MRK__c, Question_22_MRK__c, Version_MRK__c FROM Assessment_MRK__c WHERE Account_MRK__c = :r.Account_MRK__c AND Assessment_Definition_ID_MRK__c = :r.Assessment_Definition_ID_MRK__c ORDER BY Version_MRK__c DESC, LastModifiedDate DESC];

        // grab the most recent assessment record for this account
        Assessment_MRK__c latestAssessment = assessementsForAccount[0];

        Account acct = accountsToUpdateMap.get(r.Account_MRK__c);
        if (acct == null) {
            acct = [SELECT Id, Assessment_Data_MRK__c FROM Account WHERE Id = :r.Account_MRK__c];
            accountsToUpdateMap.put(acct.Id, acct);
        }

        // ******************************************************************
        // store the Id of the most recent version of the assessment on the account
        Map<String,String> idMap = null;
        if (acct.Assessment_Data_MRK__c == null) {
            idMap = new Map<String,String>();
        } else {
            idMap = (Map<String,String>)JSON.deserialize(acct.Assessment_Data_MRK__c, Map<String,String>.class);
        }

        idMap.put(r.Assessment_Definition_ID_MRK__c, latestAssessment.Id);

        acct.Assessment_Data_MRK__c = JSON.serialize(idMap);
        // ******************************************************************

        if (assessementsForAccount.size() > 1) {
            assessementsForAccount.remove(0);

            for (Assessment_MRK__c a : assessementsForAccount) {
                if (a.Active_MRK__c) {

                    Assessment_MRK__c assessmentToInactivate = new Assessment_MRK__c(Id=a.Id);
                    assessmentsToInactivate.add(assessmentToInactivate);

                    // clone assessment to inactivate and set owner to a "defined"
                    // system user
                    Assessment_MRK__c assessmentArchive = a.clone();
                    assessmentArchive.Active_MRK__c = false;
                    assessmentArchive.OwnerId = systemUserId;
                    assessmentArchive.CreatedById = systemUserId;
                    assessmentArchive.LastModifiedById = systemUserId;
                    assessmentArchive.Original_Owner_MRK__c = a.OwnerId;
                    
                    assessmentsToArchive.add(assessmentArchive);

                    a.Active_MRK__c = false;
                }
            }

        }
    }

    if (assessmentsToInactivate.size() > 0) {
        // delete old versions of the assessment to ensure these records are
        // not displayed in iRep.  A workaround the VMOC limitations.
        delete assessmentsToInactivate;

        // high volume object so empty right away to avoid build up
        try {
            Database.emptyRecycleBin(assessmentsToInactivate);    
        } catch (Exception e) { /* eat exception.  this isn't critical if it fails */ }        
    }

    // insert the assessment history
    insert assessmentsToArchive;

    update accountsToUpdateMap.values();

}