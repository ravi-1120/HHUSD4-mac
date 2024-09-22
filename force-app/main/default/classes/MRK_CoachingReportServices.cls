/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_CoachingReportServices.cls
* @description - Services class for Coaching Reports
* @createdate - July 8th, 2013
* @modified - Ankur Mehrotra, April 4th, 2014
*/

public class MRK_CoachingReportServices {

    public static final String SETTING_NAME = 'COACHING_AND_FEEDBACK';
    private static MRK_CoachingReportServices instance = null;

    public static MRK_CoachingReportServices getInstance() {
        if (instance == null) {
            instance = new MRK_CoachingReportServices();
        }
        return instance;
    }

    public void beforeInsertUpdateTriggerHandler(Coaching_Report_vod__c cr) {

        String inProgressStatusValue = MRK_Setting.getString(SETTING_NAME, 'in progress status value');
        String pendingApprovalStatusValue = MRK_Setting.getString(SETTING_NAME, 'pending approval status value');
        String approvedStatusValue = MRK_Setting.getString(SETTING_NAME, 'approved status value');
        String rejectedStatusValue = MRK_Setting.getString(SETTING_NAME, 'rejected status value');

    // set the manager to the record creator
    if (cr.Manager_vod__c == null) {
        cr.Manager_vod__c = UserInfo.getUserId();           
    }

    // show count of approved Coaching Report for employee YTD
    if (cr.Field_Visit_YTD_MRK__c == null) {
        Integer fieldVisitsYTDCount = [select count() from Coaching_Report_vod__c where Employee_vod__c = :cr.Employee_vod__c and Status__c = :approvedStatusValue and Review_Date__c = THIS_YEAR];

        // field visits YTD including this current one
        cr.Field_Visit_YTD_MRK__c = fieldVisitsYTDCount + 1;
    }

    // make visible to employee once approved
    if (cr.Status__c == approvedStatusValue && (cr.OwnerId != cr.Employee_vod__c)) {
        cr.OwnerId = cr.Employee_vod__c;
    }

    validate(cr);

    }

    public String getRecordTypeUserFriendlyName(Coaching_Report_vod__c cr) {
        String uscoRecordTypeDeveloperName = MRK_Setting.getString(SETTING_NAME, 'usco record type name');
        //New record type added. AM 4/8/2014
        String CoachingRecordTypeDeveloperName = MRK_Setting.getString(SETTING_NAME, 'MRK_Coaching record type name');
        String vaccinesRecordTypeDeveloperName = MRK_Setting.getString(SETTING_NAME, 'vaccines record type name');

        Id uscoRecordTypeId = [select Id from RecordType where sObjectType = 'Coaching_Report_vod__c' and DeveloperName = :uscoRecordTypeDeveloperName].Id;
        //New Code Added. Release 5.0. AM 4/8/2014
        Id CoachingRecordTypeId = [select Id from RecordType where sObjectType = 'Coaching_Report_vod__c' and DeveloperName = :CoachingRecordTypeDeveloperName].Id;
        Id vaccinesRecordTypeId = [select Id from RecordType where sObjectType = 'Coaching_Report_vod__c' and DeveloperName = :vaccinesRecordTypeDeveloperName].Id;
          
        //New else if statement added. AM 4/8/2014
        if (cr.RecordTypeId == uscoRecordTypeId) {
            return 'usco';
        } else if (cr.RecordTypeId == vaccinesRecordTypeId) {
            return 'vaccines';
        } else if (cr.RecordTypeId == CoachingRecordTypeId) {
            return 'MRK_Coaching';
        } else {
            return null;
        }
    }

    public void validate(Coaching_Report_vod__c cr) {

        String recordTypeUserFriendlyName = getRecordTypeUserFriendlyName(cr);

      String skillAssessmentDefaultValue = MRK_Setting.getString(SETTING_NAME, 'skills assessment default value');
      String complianceFollowUpDefaultValue = MRK_Setting.getString(SETTING_NAME, 'compliance follow up default value');
      String complianceActionDefaultValue = MRK_Setting.getString(SETTING_NAME, 'compliance action default value');
      String complianceAreaDefaultValue = MRK_Setting.getString(SETTING_NAME, 'Select Area(s) if follow-up needed');
      String complianceAcknowledgementRequiredValue = MRK_Setting.getString(SETTING_NAME, 'compliance acknowledgement required value');

      // at least 1 skill assessment selected
      Boolean atLeastOneSkillAssessmentSelected = false;
      List<Object> allSkillFieldNames = getAllSkillFieldNamesForRecordType(recordTypeUserFriendlyName);
      for (Object fieldName : allSkillFieldNames) {
        String fieldValue = (String)cr.get((String)fieldName);
      if ((fieldValue != skillAssessmentDefaultValue) && (fieldValue != null) && (fieldValue != '')) {
          atLeastOneSkillAssessmentSelected = true;
      }                
      }

      if (!atLeastOneSkillAssessmentSelected) {
        cr.addError( MRK_Setting.getString(SETTING_NAME, 'messages.one skill assessment required') );
      }

      // at least 1 skill assessment must be selected in the category if
      // there is a summary for that category

      List<String> skillSectionNameList = getSkillSectionNames(recordTypeUserFriendlyName);
      for (String skillSectionName : skillSectionNameList) {
        String summaryFieldName = (String)getSummaryFieldName(recordTypeUserFriendlyName, skillSectionName);
        String summaryFieldValue = (String)cr.get(summaryFieldName);
            
            if ((summaryFieldValue != null) && (summaryFieldValue.trim() != '')) {
                
                Boolean oneSkillAssessmentSelected = false;

                List<Object> sectionSkillFieldNameList = getSkillFieldNames(recordTypeUserFriendlyName, skillSectionName);
              for (Object fieldName : sectionSkillFieldNameList) {
                String fieldValue = (String)cr.get((String)fieldName);
              if ((fieldValue != skillAssessmentDefaultValue) && (fieldValue != null) && (fieldValue != '')) {
                  oneSkillAssessmentSelected = true;
              }                
              }

              if (!oneSkillAssessmentSelected) {
                cr.addError( String.format(MRK_Setting.getString(SETTING_NAME, 'messages.summary requires skill assessment to be selected'), new String[]{skillSectionName}) );
              }

            }
      }

      // compliance follow up action needed required
      if (cr.Compliance_Follow_Up_MRK__c == complianceFollowUpDefaultValue) {
        cr.Compliance_Follow_Up_MRK__c.addError( MRK_Setting.getString(SETTING_NAME, 'messages.compliance follow up action needed required') );
      }

      Boolean complianceAreaSelected = atLeastOneComplianceAreaValueSelected(cr);

      if (cr.Compliance_Follow_Up_MRK__c == 'Yes') {
        if (cr.COMPL_Action_Needed_MRK__c == complianceActionDefaultValue) {
            cr.COMPL_Action_Needed_MRK__c.addError( MRK_Setting.getString(SETTING_NAME, 'messages.select compliance follow up action') );
        }

        if ( !complianceAreaSelected ) {
            cr.addError( MRK_Setting.getString(SETTING_NAME, 'messages.select at least one compliance area') );
        }

      }

      if ( (cr.Compliance_Follow_Up_MRK__c == 'No') && complianceAreaSelected ) {
        cr.Compliance_Follow_Up_MRK__c.addError( MRK_Setting.getString(SETTING_NAME, 'messages.no compliance follow up with area values selected') );
      }

      if ((cr.COMPL_Action_Needed_MRK__c != complianceActionDefaultValue) && (!complianceAreaSelected || (cr.Compliance_Follow_Up_MRK__c == 'No'))) {
        cr.COMPL_Action_Needed_MRK__c.addError( MRK_Setting.getString(SETTING_NAME, 'messages.compliance action specified but no follow up indicated or no area selected') );
      }

      // compliance acknowledgement required
      if (cr.Compliance_Acknowledgement_MRK__c != complianceAcknowledgementRequiredValue) {
            cr.Compliance_Acknowledgement_MRK__c.addError( MRK_Setting.getString(SETTING_NAME, 'messages.compliance acknowledgement required') );       
      }

    }

    public Boolean atLeastOneComplianceAreaValueSelected(Coaching_Report_vod__c cr) {
        String complianceAreaDefaultValue = MRK_Setting.getString(SETTING_NAME, 'compliance area default value');
        List<Object> complianceAreaFieldNameList = MRK_Setting.getObjectList(SETTING_NAME, 'compliance area field names');
        Boolean oneComplianceAreaFieldSelected = false;
        for (Object complianceAreaFieldName : complianceAreaFieldNameList) {
            String fieldValue = (String)cr.get((String)complianceAreaFieldName);
            if ((fieldValue != complianceAreaDefaultValue) && (fieldValue != null) && (fieldValue != '')) {
                oneComplianceAreaFieldSelected = true;
            }
        }
        return oneComplianceAreaFieldSelected;
    }

    public List<String> getSkillSectionNames(String recordTypeName) {

        List<String> sectionNames = new List<String>();

        List<Object> sections = MRK_Setting.getObjectList(SETTING_NAME, recordTypeName + '.sections');
        for (Object section : sections) {
            String secType = (String)((Map<String, Object>)section).get('type');
            if (secType == 'skills section') {
                String secName = (String)((Map<String, Object>)section).get('name');
                sectionNames.add(secName);
            }           
        }

        return sectionNames;
    }

    public List<Object> getSkillFieldNames(String recordTypeName, String sectionName) {

        List<Object> sections = MRK_Setting.getObjectList(SETTING_NAME, recordTypeName + '.sections');
        for (Object section : sections) {
            String secName = (String)((Map<String, Object>)section).get('name');
            if (sectionName == secName) {
                return (List<Object>)((Map<String, Object>)section).get('skill fields');
            }       }

        return null;
    }

    public List<Object> getAllSkillFieldNamesForRecordType(String recordTypeName) {
        List<Object> fieldNames = new List<Object>();
        List<String> sectionNameList = getSkillSectionNames(recordTypeName);
        for (String sectionName : sectionNameList) {
            fieldNames.addAll( getSkillFieldNames(recordTypeName, sectionName) );
        }
        return fieldNames;
    }

    public Object getSummaryFieldName(String recordTypeName, String sectionName) {

        List<Object> sections = MRK_Setting.getObjectList(SETTING_NAME, recordTypeName + '.sections');
        for (Object section : sections) {
            String secName = (String)((Map<String, Object>)section).get('name');
            if (sectionName == secName) {
                return (Object)((Map<String, Object>)section).get('summary field');
            }       }

        return null;
    }


    public List<Object> getAllSummaryFieldNamesForRecordType(String recordTypeName) {
        List<Object> fieldNames = new List<Object>();
        List<String> sectionNameList = getSkillSectionNames(recordTypeName);
        for (String sectionName : sectionNameList) {
            fieldNames.add( getSummaryFieldName(recordTypeName, sectionName) );
        }
        return fieldNames;
    }


    public static void scratchpad() {
        List<Object> sectionFieldNames = MRK_CoachingReportServices.getInstance().getSkillFieldNames('usco', 'customer interactions');      
        System.debug( JSON.serializePretty(sectionFieldNames) );

        List<String> sectionNames = MRK_CoachingReportServices.getInstance().getSkillSectionNames('usco');
        System.debug( 'sectionNames = \n' + JSON.serializePretty(sectionNames) );

        List<Object> fieldNames = MRK_CoachingReportServices.getInstance().getAllSkillFieldNamesForRecordType('usco');
        System.debug( 'fieldNames = \n' + JSON.serializePretty(fieldNames) );


    }

}