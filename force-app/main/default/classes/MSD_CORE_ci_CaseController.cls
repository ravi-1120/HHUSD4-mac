public without sharing class MSD_CORE_ci_CaseController {

    private static final String RECORD_TYPE_DEV_NAME_PARENT = 'Interaction_MVN';
    private static final String RECORD_TYPE_DEV_NAME_CHILD = 'Request_MVN';
    private static final String S_OBJECT_TYPE_CASE = 'Case';
    private static final String CASE_ORIGIN = 'Web/Portal';
    private static final String CASE_TYPE = 'Request';
    private static final String CONTACT_RELATED_TO = 'Request';
    private static final String NOT_APPLICABLE = 'Not Applicable';
    private static final String CLASS_NAME = 'MSD_CORE_RequestCaseController';

    public class CaseResponse {
        @AuraEnabled
        public Boolean isSuccess;
        @AuraEnabled
        public String errorMessage;
        @AuraEnabled
        public String caseId;
        @AuraEnabled
        public String caseNumber;

        public CaseResponse(Boolean isSuccess, String caseId, String caseNumber) {
            this.isSuccess = isSuccess;
            this.caseId = caseId;
            this.caseNumber = caseNumber;
        }

        public CaseResponse(Boolean isSuccess, String errorMessage) {
            this.isSuccess = isSuccess;
            this.errorMessage = errorMessage;
        }
    }

    public class FileData {
        public Blob fileBlob;
        public String fileName;
        public String size;
    }

    @AuraEnabled
    public static CaseResponse createRequestCase(Map<String, Object> caseDetails) {
        Savepoint sp = Database.setSavepoint();
        
        try {
            System.debug('Processing request case details for interaction case creation.');
            String userChoice = 'Employee';
            Id parentId = createInteractionCase(caseDetails, userChoice);
            System.debug('Interaction case created with Id: ' + parentId);
            Case childCase = new Case();
            childCase.Origin = CASE_ORIGIN;
            childCase.ParentId = parentId;
            childCase.Type = CASE_TYPE;
            childCase.Customer_Type_MVN__c = 'EMPLOYEE';
            Map<Object, Object> stage1Details = (Map<Object, Object>) caseDetails.get('stage1');
            childCase.RecordTypeId = getRecordTypeId(RECORD_TYPE_DEV_NAME_CHILD, S_OBJECT_TYPE_CASE);
            childCase = setupCaseDetails(childCase, caseDetails);
            System.debug('Final child case details: ' + childCase);
            insert childCase;
            System.debug('Child case inserted with Id: ' + childCase.Id);
            String caseNumber = 'NA';
            List<Case> caseList = [SELECT CaseNumber FROM Case WHERE Id = :childCase.Id];
            if (caseList.size() > 0) {
                caseNumber = caseList[0].CaseNumber;
            }

            // Upload attachments from stage 3
            Map<Object, Object> stage3Details = (Map<Object, Object>) caseDetails.get('stage3');
            List<Object> uploadedFiles = (List<Object>) stage3Details.get('uploadedFiles');
            if (uploadedFiles != null && !uploadedFiles.isEmpty()) {
                uploadAttachments(childCase.Id, uploadedFiles);
            }

            System.debug('Creating CaseResponse with success.');
            return new CaseResponse(true, childCase.Id, caseNumber);
        } catch (Exception ex) {
            Database.rollback(sp);
            System.debug('Exception in createRequestCase: ' + ex);
            AMOExceptionHandler.logException(ex, CLASS_NAME, 'createRequestCase', null, 'Error');
            System.debug(LoggingLevel.ERROR, 'createRequestCase - Exception: ' + ex.getMessage());
            sendErrorEmail(ex.getTypeName() + ' - ' + ex.getMessage());
            return new CaseResponse(false, 'Error: ' + ex.getTypeName() + ' - ' + ex.getMessage());
        } finally {
            System.debug('Exiting createRequestCase');
        }
    }

    public static Case setupCaseDetails(Case cs, Map<String, Object> caseDetails) {
        Map<Object, Object> details = (Map<Object, Object>) caseDetails.get('stage1');
        cs.Description = 'Request case created for an employee from the portal.';
        return cs;
    }

    public static Id createInteractionCase(Map<String, Object> caseDetails, String userChoice) {
        try {
            Id recId = getRecordTypeId(RECORD_TYPE_DEV_NAME_PARENT, S_OBJECT_TYPE_CASE);
            Case interactionCase = new Case();
            Map<Object, Object> stage1Details = (Map<Object, Object>) caseDetails.get('stage1');
            interactionCase.Referred_By_MVN__c = (String)stage1Details.get('EmployeeId');
            interactionCase.RecordTypeId = recId;
            interactionCase.Origin = CASE_ORIGIN;
            interactionCase.Customer_Type_MVN__c = userChoice;
            interactionCase.MSD_CORE_Source__c = getSourceId('Request Self Service Portal');           
            insert interactionCase;
            System.debug('Exiting createInteractionCase with Id: ' + interactionCase.Id);
            return interactionCase.Id;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'createInteractionCase - Exception: ' + ex.getMessage());
            AMOExceptionHandler.logException(ex, CLASS_NAME, 'createInteractionCase', null, 'Error');
            return null;
        }
    }

    public static FileData uploadAttachments(Id childCaseId, List<Object> uploadedFilesObjList) {
        FileData fileData = new FileData();
        try {
            if (uploadedFilesObjList.isEmpty()) {
                System.debug('Error: No files provided for upload.');
                return null;
            }

            Map<Object, Object> fileDetails = (Map<Object, Object>) uploadedFilesObjList.get(0);
            fileData.fileBlob = EncodingUtil.base64Decode((String) fileDetails.get('base64'));
            fileData.fileName = (String) fileDetails.get('filename');
            fileData.size = (String) fileDetails.get('size');        
            Decimal fileSize = Decimal.valueOf(fileData.size);
            
            Case childCase  = [SELECT Id, MSD_CORE_Attachment_Count__c, MSD_CORE_Attachment_Size__c FROM Case WHERE Id = :childCaseId FOR UPDATE];
            childCase.MSD_CORE_Attachment_Count__c = (childCase.MSD_CORE_Attachment_Count__c == null ? 0 : childCase.MSD_CORE_Attachment_Count__c) + 1;
            childCase.MSD_CORE_Attachment_Size__c = (childCase.MSD_CORE_Attachment_Size__c == null ? 0 : childCase.MSD_CORE_Attachment_Size__c) + fileSize;

            Attachment attachment = new Attachment();
            attachment.Name = fileData.fileName;
            attachment.Body = fileData.fileBlob;
            attachment.ParentId = childCase.Id;
            Savepoint sp = Database.setSavepoint();
            try {
                update childCase;
                insert attachment;
            } catch (Exception e) {
                Database.rollback(sp);
                throw e;
            }

            System.debug('Child case updated successfully with new attachment count and size.');
        } catch (Exception ex) {
            System.debug('Error during file upload: ' + ex.getMessage());
            AMOExceptionHandler.logException(ex, CLASS_NAME, 'uploadAttachments', null ,'Error');
            return null;
        }

        return fileData;
    }

    @AuraEnabled(cacheable=true)
    public static String getRecordTypeId(String devName, String sObjectType) {
        List<RecordType> recordTypes = [SELECT Id FROM RecordType WHERE DeveloperName = :devName AND SObjectType = :sObjectType LIMIT 1];
        if (recordTypes.size() > 0) {
            return recordTypes[0].Id;
        }
        return null;
    }

    public static Id getSourceId(String sourceName) {
        List<MSD_CORE_Source__c> sources = [SELECT Id FROM MSD_CORE_Source__c WHERE Name = :sourceName LIMIT 1];
        if (sources.size() > 0) {
            return sources[0].Id;
        }
        return null;
    }

    public static void sendErrorEmail(String errorMessage) {
        try {
            OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Request Self-Service Portal' LIMIT 1];
            MSD_CORE_ae_PortalSetting__mdt setting = [SELECT Support_Email__c FROM MSD_CORE_ae_PortalSetting__mdt LIMIT 1];

            if (owea == null || setting == null || String.isEmpty(setting.Support_Email__c)) {
                system.debug('Org Wide Address or Portal Setting Missing');
                return;
            }

            List<String> emailAddresses = setting.Support_Email__c.split(';');
            String emailBody = 'Hello,\n\nThere was a failure in creating a request case through the Request Self-Service Portal.\n\nError Details: '
                            + errorMessage + '\nPlease review the issue to prevent future occurrences.\n\nRegards,\nRequest Self-Service Portal Team';

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(emailAddresses);
            mail.setSubject('Request Portal: Case Creation Failure Notification');
            mail.setPlainTextBody(emailBody);
            mail.setOrgWideEmailAddressId(owea.Id);
            mail.setSaveAsActivity(false);

            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            if (results.size() > 0 && !results[0].isSuccess() && results[0].getErrors().size() > 0) {
                System.debug('Email sending error: ' + results[0].getErrors()[0].getMessage());
            }
        } catch (Exception ex) {
            AMOExceptionHandler.logException(ex, CLASS_NAME, 'sendErrorEmail', null, 'Error');
        }
    }
}