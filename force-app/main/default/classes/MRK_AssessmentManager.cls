global class MRK_AssessmentManager implements Schedulable {

	public static boolean disableTriggers = false;
	
	public MRK_AssessmentManager() {
		
	}

	global void execute(SchedulableContext sc) {
		MRK_AssessmentManager.collapse();
	}

  public static void deleteAllAssessments() {

      List<sObject> assessmentList = [select Id from Assessment_MRK__c];
      System.debug('assessmentList.size() = ' + assessmentList.size());

      // safety checks just in case ran in wrong environment
      if (assessmentList.size() > 100) {
          return;
      }

      delete assessmentList;
      try {
          Database.emptyRecycleBin(assessmentList);    
      } catch (Exception e) { /* eat exception.  this isn't critical if it fails */ }        

      List<Account> accountList = [select Id, Assessment_Data_MRK__c from Account where Assessment_Data_MRK__c != null];

      // safety checks just in case ran in wrong environment
      if (accountList.size() > 100) {
          return;
      }

      for (Account account : accountList) {
          account.Assessment_Data_MRK__c = null;
      }

      update accountList;

  }	

  public static void collapseImpl() {  	

  	Id systemUserId = [select Id from User where username like '%integration@merck.com%'].Id;

    Map<String, List<Assessment_MRK__c>> assessmentMap = new Map<String, List<Assessment_MRK__c>>();
    List<Assessment_MRK__c> assessmentList = [select Id, OwnerId, IsDeleted, Name, RecordTypeId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, Account_MRK__c, Active_MRK__c, Answer_01_MRK__c, Answer_02_MRK__c, Answer_03_MRK__c, Answer_04_MRK__c, Answer_05_MRK__c, Answer_06_MRK__c, Answer_07_MRK__c, Answer_08_MRK__c, Answer_09_MRK__c, Answer_10_MRK__c, Answer_11_MRK__c, Answer_12_MRK__c, Answer_13_MRK__c, Answer_14_MRK__c, Answer_15_MRK__c, Answer_16_MRK__c, Answer_17_MRK__c, Answer_18_MRK__c, Answer_19_MRK__c, Answer_20_MRK__c, Answer_21_MRK__c, Answer_22_MRK__c, Assessment_Date_MRK__c, Assessment_Definition_ID_MRK__c, Assessment_Name_MRK__c, Mobile_ID_vod__c, Product_Share_MRK__c, Question_01_MRK__c, Question_02_MRK__c, Question_03_MRK__c, Question_04_MRK__c, Question_05_MRK__c, Question_06_MRK__c, Question_07_MRK__c, Question_08_MRK__c, Question_09_MRK__c, Question_10_MRK__c, Question_11_MRK__c, Question_12_MRK__c, Question_13_MRK__c, Question_14_MRK__c, Question_15_MRK__c, Question_16_MRK__c, Question_17_MRK__c, Question_18_MRK__c, Question_19_MRK__c, Question_20_MRK__c, Question_21_MRK__c, Question_22_MRK__c, Version_MRK__c from Assessment_MRK__c where Account_MRK__c != null order by Assessment_Date_MRK__c desc, LastModifiedDate desc];

    MRK_Logger.debug('MRK_AssessmentManager.collapseImpl: processing ' + assessmentList.size() + ' assessments');

    for (Assessment_MRK__c a : assessmentList) {
        String assessmentForAccountKey = a.Assessment_Name_MRK__c + '_' + a.Account_MRK__c;
        List<Assessment_MRK__c> assessmentsForAccountList = assessmentMap.get(assessmentForAccountKey);
        if (assessmentsForAccountList == null) {
            assessmentMap.put(assessmentForAccountKey, new List<Assessment_MRK__c>{a});
        } else {
            assessmentsForAccountList.add(a);
        }
    }

    List<List<Assessment_MRK__c>> assessmentListsToCollapse = new List<List<Assessment_MRK__c>>();
    List<Assessment_MRK__c> singleRecordAssessmentList = new List<Assessment_MRK__c>();
    for (String assessmentForAccountKey : assessmentMap.keySet()) {
        List<Assessment_MRK__c> assessmentsForAccountList = assessmentMap.get(assessmentForAccountKey);
        if (assessmentsForAccountList.size() > 1) {
        	assessmentListsToCollapse.add(assessmentsForAccountList);
        } else {
        	singleRecordAssessmentList.add(assessmentsForAccountList[0]);
        }
    }

    List<Assessment_MRK__c> assessmentsToInactivate = new List<Assessment_MRK__c>();
    List<Assessment_MRK__c> assessmentsToArchive = new List<Assessment_MRK__c>();

    List<Assessment_MRK__c> collapsedAssessmentRecords = new List<Assessment_MRK__c>();

    MRK_Logger.debug('MRK_AssessmentManager.collapseImpl: collapsing ' + assessmentListsToCollapse.size() + ' assessments');

    List<String> fields = 'Answer_01_MRK__c,Answer_02_MRK__c,Answer_03_MRK__c,Answer_04_MRK__c,Answer_05_MRK__c,Answer_06_MRK__c,Answer_07_MRK__c,Answer_08_MRK__c,Answer_09_MRK__c,Answer_10_MRK__c,Answer_11_MRK__c,Answer_12_MRK__c,Answer_13_MRK__c,Answer_14_MRK__c,Answer_15_MRK__c,Answer_16_MRK__c,Answer_17_MRK__c,Answer_18_MRK__c,Answer_19_MRK__c,Answer_20_MRK__c,Answer_21_MRK__c,Answer_22_MRK__c'.split(',');
    for (List<Assessment_MRK__c> assessmentListToCollapse : assessmentListsToCollapse) {
    	Map<String, String> targetFieldValueMap = new Map<String, String>();

    	for (String fieldName : fields) {

    		for (Assessment_MRK__c assessment : assessmentListToCollapse) {

    			// if a value for the field exists, then it's the one to keep
					String fieldValue = targetFieldValueMap.get(fieldName);
					if (fieldValue == null) {
						// if there's a value for the field, store it in the map
						fieldValue = (String)assessment.get(fieldName);
						if ((fieldValue != null) && (fieldValue != '')) {
							targetFieldValueMap.put(fieldName, fieldValue);
						}
					}

    		}

    	}

    	// merge value into most recent record and mark as v1
 			for (String fieldName : fields) {
 				String fieldValue = targetFieldValueMap.get(fieldName);
 				if (fieldValue != null) {
 					assessmentListToCollapse[0].put(fieldName, fieldValue);
 					assessmentListToCollapse[0].Version_MRK__c = '001';
 					assessmentListToCollapse[0].Active_MRK__c = true;
 				}
 			}

 			collapsedAssessmentRecords.add(assessmentListToCollapse[0]);

 			// inactivate all other records
 			for (Integer i = 1; i < assessmentListToCollapse.size(); i++) {
 				Assessment_MRK__c a = assessmentListToCollapse[i];
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
 			}

    }

		// update single record assessments
		MRK_Logger.debug('MRK_AssessmentManager.collapseImpl: updating version for ' + singleRecordAssessmentList.size() + ' single record assessment(s)');
		for (Assessment_MRK__c assessment : singleRecordAssessmentList) {
			assessment.Version_MRK__c = '001';
			assessment.Active_MRK__c = true;
		}

	  // delete old versions of the assessment to ensure these records are
	  // not displayed in iRep.  A workaround the VMOC limitations.
	  MRK_Logger.debug('MRK_AssessmentManager.collapseImpl: deleting ' + assessmentsToInactivate.size() + ' historical assessment(s)');
	  delete assessmentsToInactivate;

	  // high volume object so empty right away to avoid build up
	  try {
	  	MRK_Logger.debug('MRK_AssessmentManager.collapseImpl: emptying to recycle bin for ' + assessmentsToInactivate.size() + ' historical assessment(s)');
	      Database.emptyRecycleBin(assessmentsToInactivate);    
	  } catch (Exception e) { /* eat exception.  this isn't critical if it fails */ }

		// update records
		List<Assessment_MRK__c> assessmentRecordsToUpdate = new List<Assessment_MRK__c>();
		assessmentRecordsToUpdate.addAll(singleRecordAssessmentList);
		assessmentRecordsToUpdate.addAll(collapsedAssessmentRecords);
		MRK_Logger.debug('MRK_AssessmentManager.collapseImpl: updating ' + assessmentRecordsToUpdate.size() + ' assessments');
		update assessmentRecordsToUpdate;

	  // insert the assessment history
	  MRK_Logger.debug('MRK_AssessmentManager.collapseImpl: inserting ' + assessmentsToArchive.size() + ' re-ownered historical assessment(s)');
	  insert assessmentsToArchive;

	  Integer totalVersionedAssessmentsCount = Database.countQuery('select count() from Assessment_MRK__c where Version_MRK__c != null');

	  if (totalVersionedAssessmentsCount == assessmentRecordsToUpdate.size()) {
	  	MRK_Logger.debug('MRK_AssessmentManager.collapseImpl: count of versioned assessments matches count of updated assessments');	
	  } else {
	  	MRK_Logger.error('MRK_AssessmentManager.collapseImpl: count of versioned assessments DOES NOT MATCH count of updated assessments');	
	  }
	  
  }

  public static void collapse() {

  	try {
  		MRK_Logger.loggingEnabled = false;
  		disableTriggers = true;
  		collapseImpl();
  		syncAccountAssessmentData();
  	} catch (Exception e) {
  		MRK_Logger.debug(e.getMessage());
  	} finally {
  		disableTriggers = false;
  		MRK_Logger.flush();
  		MRK_Logger.loggingEnabled = false;
  	}

  }

  public static void syncAccountAssessmentData() {
  	List<Assessment_MRK__c> assessmentList = [select Id, Account_MRK__c, Assessment_Definition_ID_MRK__c from Assessment_MRK__c where Active_MRK__c = true and Version_MRK__c != null];
  	Set<String> accountIdSet = new Set<String>();
  	for (Assessment_MRK__c a : assessmentList) {
  		accountIdSet.add(a.Account_MRK__c);
  	}

  	List<Account> accountList = [SELECT Id, Assessment_Data_MRK__c FROM Account WHERE Id IN :accountIdSet];

  	Map<String, Map<String,String>> accountAssessmentDataMap = new Map<String, Map<String,String>>();
  	for (Account a : accountList) {
				Map<String,String> idMap = null;
        if (a.Assessment_Data_MRK__c == null) {
            idMap = new Map<String,String>();
        } else {
            idMap = (Map<String,String>)JSON.deserialize(a.Assessment_Data_MRK__c, Map<String,String>.class);
        }

        accountAssessmentDataMap.put(a.Id, idMap);
  	}

  	for (Assessment_MRK__c a : assessmentList) {
  		Map<String,String> idMap = accountAssessmentDataMap.get(a.Account_MRK__c);
  		idMap.put(a.Assessment_Definition_ID_MRK__c, a.Id);
  	}

  	for (Account a : accountList) {
  		Map<String,String> idMap = accountAssessmentDataMap.get(a.Id);
  		a.Assessment_Data_MRK__c = JSON.serialize(idMap);
  	}

  	update accountList;

  }

}