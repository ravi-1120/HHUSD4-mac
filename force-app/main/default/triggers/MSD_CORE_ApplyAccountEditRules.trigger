trigger MSD_CORE_ApplyAccountEditRules on Data_Change_Request_Line_vod__c (after insert) {

    // prevent re-entry
    if (MSD_CORE_ApplyAccountEditRulesHelper.isTriggerLogicRunning) {
        return;
    }
    MSD_CORE_ApplyAccountEditRulesHelper.isTriggerLogicRunning = true;
    
    List<Data_Change_Request_Line_vod__c> dcrlInsertList = new List<Data_Change_Request_Line_vod__c>();
	Set<Id> dcrIdSet = new Set<Id>();
    
    Set<String> personRecordTypeSet = new Set<String>{'HCP', 'HBP'};
    Set<String> organizationRecordTypeSet = new Set<String>{'Organization_vod', 'Hospital_vod', 'Pharmacy_vod'};

    // requery Account Edits only to get corresponding lookup records
    for (Data_Change_Request_Line_vod__c dcrl : [select Data_Change_Request_vod__r.Account_Record_Type__c, Data_Change_Request_vod__r.Account_vod__r.Class_of_Trade_MRK__c, Data_Change_Request_vod__r.Account_vod__r.Class_of_Trade_Sub_MRK__c, Data_Change_Request_vod__r.Account_vod__r.Class_of_Trade_Owner_MRK__c, Data_Change_Request_vod__r.Account_vod__r.IMS_Specialty_MRK__c, Account_Type__c, Data_Change_Request_vod__c, Display_Order__c, Error_vod__c, External_Field_API_Name_vod__c, Field_API_Name_vod__c, Field_Name_vod__c, Final_Value_vod__c, Id, Name, New_Localized_Value_vod__c, New_Value_vod__c, Old_Localized_Value_vod__c, Old_Value_vod__c from Data_Change_Request_Line_vod__c where Id in :Trigger.newMap.keySet() and Data_Change_Request_vod__r.Type_vod__c = 'Edit_vod']) {

      dcrIdSet.add(dcrl.Data_Change_Request_vod__c);
        
      // person accounts
      if ( personRecordTypeSet.contains(dcrl.Data_Change_Request_vod__r.Account_Record_Type__c) ) {
        
        if (dcrl.Field_API_Name_vod__c == 'Class_of_Trade_Sub_MRK__c') {
          // If Sub-Type is populated in DCRLI. Populate Type (Class_of_Trade_MRK__c) & Owner Code (Class_of_Trade_Owner_MRK__c)  Note : New Value in Owner Code = Value in Sub-Type.

          dcrlInsertList.add(
            new Data_Change_Request_Line_vod__c(
              Data_Change_Request_vod__c = dcrl.Data_Change_Request_vod__c,
              Old_Value_vod__c = dcrl.Data_Change_Request_vod__r.Account_vod__r.Class_of_Trade_MRK__c,
              New_Value_vod__c = dcrl.Data_Change_Request_vod__r.Account_vod__r.Class_of_Trade_MRK__c,
              Field_Name_vod__c = 'Type',
              Field_API_Name_vod__c = 'Class_of_Trade_MRK__c',
              Display_Order__c = 30
            )
          );

        dcrlInsertList.add(
          new Data_Change_Request_Line_vod__c(
            Data_Change_Request_vod__c = dcrl.Data_Change_Request_vod__c,
            Old_Value_vod__c = dcrl.Old_Value_vod__c,
            New_Value_vod__c = dcrl.New_Value_vod__c,
            Field_Name_vod__c = 'Owner Code',
            Field_API_Name_vod__c = 'Class_of_Trade_Owner_MRK__c',
            Display_Order__c = 50
          )
          );
        }

        if (dcrl.Field_API_Name_vod__c == 'Credentials_vod__c') {
          // If Credentials (Credentials_vod__c) is populated in DCRLI. Populate Type (Class_of_Trade_MRK__c) & Sub-Type (Class_of_Trade_Sub_MRK__c).
          dcrlInsertList.add(
            new Data_Change_Request_Line_vod__c(
              Data_Change_Request_vod__c = dcrl.Data_Change_Request_vod__c,
              Old_Value_vod__c = dcrl.Data_Change_Request_vod__r.Account_vod__r.Class_of_Trade_MRK__c,
              New_Value_vod__c = dcrl.Data_Change_Request_vod__r.Account_vod__r.Class_of_Trade_MRK__c,
              Field_Name_vod__c = 'Type',
              Field_API_Name_vod__c = 'Class_of_Trade_MRK__c',
              Display_Order__c = 30
            )
          );

        dcrlInsertList.add(
          new Data_Change_Request_Line_vod__c(
            Data_Change_Request_vod__c = dcrl.Data_Change_Request_vod__c,
            Old_Value_vod__c = dcrl.Data_Change_Request_vod__r.Account_vod__r.Class_of_Trade_Sub_MRK__c,
            New_Value_vod__c = dcrl.Data_Change_Request_vod__r.Account_vod__r.Class_of_Trade_Sub_MRK__c,
            Field_Name_vod__c = 'Sub-Type',
            Field_API_Name_vod__c = 'Class_of_Trade_Sub_MRK__c',
            Display_Order__c = 40
          )
        );


        }

        if (dcrl.Field_API_Name_vod__c == 'IMS_Sub_Specialty_MRK__c') {
          // If Speciality(IMS_Sub_Specialty_MRK__c) is populated in DCRLI. Populate Speciality Group (IMS_Specialty_MRK__c).

        dcrlInsertList.add(
          new Data_Change_Request_Line_vod__c(
            Data_Change_Request_vod__c = dcrl.Data_Change_Request_vod__c,
            Old_Value_vod__c = dcrl.Data_Change_Request_vod__r.Account_vod__r.IMS_Specialty_MRK__c,
            New_Value_vod__c = dcrl.Data_Change_Request_vod__r.Account_vod__r.IMS_Specialty_MRK__c,
            Field_Name_vod__c = 'Speciality Group',
            Field_API_Name_vod__c = 'IMS_Specialty_MRK__c',
            Display_Order__c = 10
          )
        );

        }
        
      }

      // org accounts
      if ( organizationRecordTypeSet.contains(dcrl.Data_Change_Request_vod__r.Account_Record_Type__c) ) {

        if (dcrl.Field_API_Name_vod__c == 'Class_of_Trade_Sub_MRK__c') {
          // If Sub-Type is populated in DCRLI. Populate Type (Class_of_Trade_MRK__c) & Owner Code (Class_of_Trade_Owner_MRK__c) . Note : Owner Code will  be blank.

          dcrlInsertList.add(
            new Data_Change_Request_Line_vod__c(
              Data_Change_Request_vod__c = dcrl.Data_Change_Request_vod__c,
              Old_Value_vod__c = dcrl.Data_Change_Request_vod__r.Account_vod__r.Class_of_Trade_MRK__c,
              New_Value_vod__c = dcrl.Data_Change_Request_vod__r.Account_vod__r.Class_of_Trade_MRK__c,
              Field_Name_vod__c = 'Type',
              Field_API_Name_vod__c = 'Class_of_Trade_MRK__c',
              Display_Order__c = 30
            )
          );

        dcrlInsertList.add(
          new Data_Change_Request_Line_vod__c(
            Data_Change_Request_vod__c = dcrl.Data_Change_Request_vod__c,
            Old_Value_vod__c = '',
            New_Value_vod__c = '',
            Field_Name_vod__c = 'Owner Code',
            Field_API_Name_vod__c = 'Class_of_Trade_Owner_MRK__c',
            Display_Order__c = 50
          )
        );          
        }
        
      }

    }
    
    // re-query current state to filter out any duplicates as existing dcrl recs created by OOTB Veeva take precendence
    Set<String> dcrIdFieldApiNameSet = new Set<String>();
    for (Data_Change_Request_Line_vod__c dcrl : [select Data_Change_Request_vod__c, Field_API_Name_vod__c from Data_Change_Request_Line_vod__c where Data_Change_Request_vod__c in :dcrIdSet]) {
    	dcrIdFieldApiNameSet.add(dcrl.Data_Change_Request_vod__c + '_' + dcrl.Field_API_Name_vod__c);
    }
    
    // filter duplicates within our own logic
    Set<String> dedupedDcrIdFieldApiNameSet = new Set<String>();
    List<Data_Change_Request_Line_vod__c> dedupedDcrlInsertList = new List<Data_Change_Request_Line_vod__c>();
    for (Data_Change_Request_Line_vod__c dcrl : dcrlInsertList) {
        String dcrIdAndFieldApiName = dcrl.Data_Change_Request_vod__c + '_' + dcrl.Field_API_Name_vod__c;
        if (!dcrIdFieldApiNameSet.contains(dcrIdAndFieldApiName)  && !(dedupedDcrIdFieldApiNameSet.contains(dcrIdAndFieldApiName))) {
            dedupedDcrlInsertList.add(dcrl);
            dedupedDcrIdFieldApiNameSet.add(dcrIdAndFieldApiName);
        }
    }

    if (dedupedDcrlInsertList.size() > 0) {
      insert dedupedDcrlInsertList;
    }
}