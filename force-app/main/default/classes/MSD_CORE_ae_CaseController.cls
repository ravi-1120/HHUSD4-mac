/*
 * MSD_CORE_ae_CaseController 
 * Created By:      FocalCXM (Joshi, Sairohith Ramini)
 * Version 2.0:     FocalCXM (Sairohith Ramini)
 * Created Date:    11/01/2023
 * Description:     This class creates an AE Case for the Merck Self-Service Adverse Event Portal
 */

public without sharing class MSD_CORE_ae_CaseController {

    private static final String RECORD_TYPE_DEV_NAME = 'Interaction_MVN';
    private static final String S_OBJECT_TYPE_CASE = 'Case';
    private static final String CASE_ORIGIN = 'Web/Portal';
    private static final String CASE_TYPE = 'Adverse Event';
    private static final String CASE_CATEGORY = 'Adverse Experience Report';
    private static final String CONTACT_RELATED_TO = 'AE';
    //private static final String recaptchaSecretKey = getRecaptchaSecretKey();
    //private static final String recaptchaSecretKey = '6LcEd5IpAAAAANAweOZfx_9uHDowpHzJ3AbkPpG6';
    private static final String NOT_APPLICABLE = 'Not Applicable';
    private static final String UNKNOWN_VALUE = 'Unknown by Reporter';
    private static final String REFUSED = 'Refused to Answer';
    private static final String LicensedHCP = 'Licensed Healthcare Professional';
    private static final String LicensedHBP = 'Healthcare Office Worker or Facility Personnel';
    private static final String UNKNOWN = 'Unknown';
    private static final String UNSPECIFIED = 'Unspecified';
    private static final String CLASS_NAME = 'MSD_CORE_ae_CaseController';
    private static final Map<String,String> REPORTER_TYPE_MAP = new Map<String,String>{
        'Consumer'=>'Consumer', 'HEALTHCARE BUSINESS PROF'=>'Healthcare Worker', 'Employee'=>'Employee'};
    
  /*public static Boolean verifyRecaptcha(String response) {
    MSD_CORE_ae_PortalSetting__mdt recaptchaToken = MSD_CORE_ae_PortalSetting__mdt.getInstance('AE_Portal');
    String recaptchaSecretKey = recaptchaToken.reCaptcha_Secret_Key__c;	
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint('https://www.google.com/recaptcha/api/siteverify');
    request.setMethod('POST');
    system.debug('recaptchaSecretKey---->'+recaptchaSecretKey);
    request.setBody('secret=' + recaptchaSecretKey + '&response=' + response);
    System.debug(LoggingLevel.INFO, 'Sending reCAPTCHA verification request with response token: ' + response);   
    HttpResponse res = http.send(request);
    System.debug(LoggingLevel.INFO, 'reCAPTCHA verification response status: ' + res.getStatusCode());
    System.debug(LoggingLevel.INFO, 'reCAPTCHA verification response body: ' + res.getBody()); 
    if (res.getStatusCode() == 200) {
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Boolean isSuccess = (Boolean)result.get('success');
        //Decimal score = (Decimal) result.get('score');
        //if (isSuccess && score >= 0.9) { // Adjust the score threshold as needed
                //return true;
        //}
        System.debug(LoggingLevel.INFO, 'reCAPTCHA verification success: ' + isSuccess);
        return isSuccess;
    }
    return false;
}*/

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
    public class FileData{
        public Blob fileBlob;
        public String fileName;
        public String size;
    }
     /*private static String getRecaptchaSecretKey() {
        MSD_CORE_ae_PortalSetting__mdt portalSetting = [
            SELECT reCaptcha_Secret_Key__c
            FROM MSD_CORE_ae_PortalSetting__mdt
            WHERE DeveloperName = 'AE_Portal'
            LIMIT 1
        ];
        return portalSetting.reCaptcha_Secret_Key__c;
    }*/

    @AuraEnabled
    //public static CaseResponse createAeCase(Map<String,Object> caseDetails, String recaptchaToken){
    public static CaseResponse createAeCase(Map<String,Object> caseDetails){
           /*if (!verifyRecaptcha(recaptchaToken)) {
                 return new CaseResponse(false, 'reCAPTCHA verification failed.');
           }*/
        Savepoint sp = Database.setSavePoint();
        //System.debug('Received caseDetails: ' + caseDetails);
        try {
            System.debug('Processing stage1 details for interaction case creation.');
            Map<Object, Object> stage1Details = (Map<Object, Object>) caseDetails.get('stage1');
            String userChoice = (String) stage1Details.get('userChoice');

            Id parentId = createInteractionCase(caseDetails,userChoice);
            System.debug('Interaction case created with Id: ' + parentId);
            Case childCase = new Case();
            childCase.Origin = CASE_ORIGIN;
            childCase.MSD_CORE_Source__c = getSourceId('AE Self Service Portal');
            childCase.ParentId = parentId;
            childCase.Type = CASE_TYPE;
            childCase.Category_MVN__c = CASE_CATEGORY;

            Map<Object, Object> stage2Details = (Map<Object, Object>) caseDetails.get('stage2');
            String patientID = (String)stage2Details.get('PatientID'); //to be merged in AE description field
            childCase = setupStage2(childCase, stage2Details, userChoice);
            Map<Object, Object> stage3Details = (Map<Object, Object>) caseDetails.get('stage3');
            childCase = setupStage3(childCase, stage3Details, stage2Details, userChoice);
            String previousCase = (String)stage3Details.get('Desc');
            Map<Object, Object> stage5Details = (Map<Object, Object>) caseDetails.get('stage5');
            childCase = setupStage5(childCase, stage5Details, previousCase, PatientID, userChoice);
            Map<Object, Object> stage6Details = (Map<Object, Object>) caseDetails.get('stage6');
            childCase = setupStage6(childCase, stage6Details);
            System.debug('Final child case details: ' + childCase);
            insert childCase;
            System.debug('Child case inserted with Id: ' + childCase.Id);
            List<SObject> relatedRecords = new List<SObject>();
            
            if (stage2Details.containsKey('uploadFile') && stage2Details.get('uploadFile') == 'Yes' && stage2Details.containsKey('uploadedFiles')) {
               uploadAttachments(childCase.Id, (List<Object>) stage2Details.get('uploadedFiles'));
            }

            //insert Additional AE Contacts from Stage3
            relatedRecords = createAeContacts(childCase.Id, caseDetails,userChoice);
            //insert AE Products from Stage 4
            List<Object> stage4Details = (List<Object>) caseDetails.get('stage4');
            relatedRecords.addAll(createAeProducts(childCase.Id, stage4Details));
            //Inserting AE Contacts & AE Products
            // Enqueue related records for asynchronous insertion
            if (!relatedRecords.isEmpty() && childCase.Id !=null) {
                System.enqueueJob(new MSD_CORE_ae_RelatedRecords(relatedRecords));
            }

            String caseNumber = 'NA';
            List<Case> caseLst = [Select CaseNumber from Case Where Id=:childCase.Id];
            if(caseLst.size()>0){
                caseNumber = caseLst[0].CaseNumber;
            }
            System.debug('Creating CaseResponse with success.');
            return new CaseResponse(true, childCase.Id, caseNumber);
        } catch (Exception ex) {
            Database.rollback(sp);
             System.debug('Exception in createAeCase: ' + ex);
            AMOExceptionHandler.logException(ex,CLASS_NAME,'createAeCase',null ,'Error');
            System.debug(LoggingLevel.ERROR, 'createAe Child Case - Exception: ' + ex.getMessage());
            sendEmail(ex.getTypeName() + ' - ' + ex.getMessage());
            return new CaseResponse(false, 'Error: ' + ex.getTypeName() + ' - ' + ex.getMessage());
        }  finally {
               System.debug('Exiting createAeCase');
           }
    }

    public static Id createInteractionCase(Map<String,Object> caseDetails, String userChoice) {
        try{
            Id recId = getRecordTypeId(RECORD_TYPE_DEV_NAME, S_OBJECT_TYPE_CASE);
            Case iCase = new Case();
            iCase.RecordTypeId = recId;
            System.debug(LoggingLevel.INFO, 'Record Type ID: ' + recId);
            iCase.Origin = CASE_ORIGIN;
            iCase.MSD_CORE_Source__c = getSourceId('AE Self Service Portal');
            iCase.MSD_CORE_AE_Present__c = true;
            iCase.MSD_CORE_Preferred_Language__c = 'English';
            if(userChoice.equals('Healthcare Professional')) {
                 Map<Object, Object> stage2Details = (Map<Object, Object>) caseDetails.get('stage2');
                 String licensedHCP = (String)stage2Details.get('licensedHCP'); // Assume this is how you get the licensedHCP value
                 if(licensedHCP == null || licensedHCP.equals('Licensed Healthcare Professional')) {
                     iCase.Customer_Type_MVN__c = 'INDIV HEALTHCARE PROF';
                 }else if(licensedHCP.equals('Healthcare Office Worker or Facility Personnel')) {
                     iCase.Customer_Type_MVN__c = 'HEALTHCARE BUSINESS PROF';
                 } else {
                    // Default to INDIV HEALTHCARE PROF if none of the conditions match
                    iCase.Customer_Type_MVN__c = 'INDIV HEALTHCARE PROF';
                 }
            } else {
                
               Map<Object, Object> stage3Details = (Map<Object, Object>) caseDetails.get('stage3');       
               Map<Object, Object> stage2Details = (Map<Object, Object>) caseDetails.get('stage2');
               if(userChoice == 'Merck Employee' && (String)stage2Details.get('FieldBased') == 'yes') {
                  iCase.Referred_By_MVN__c = (String)stage2Details.get('EmployeeId');
              }
                if((String)stage3Details.get('ReporterType')=='Patient') {
                     iCase.Customer_Type_MVN__c = 'EMPLOYEE';
                 } 
                if((userChoice == 'PSP Representative')){
                    iCase.Customer_Type_MVN__c = (String)stage3Details.get('ReporterType');
                 }
                if((userChoice == 'Merck Employee')){
                    iCase.Customer_Type_MVN__c = 'EMPLOYEE';
                }
             }
            insert iCase;
            System.debug('Exiting createInteractionCase with Id: ' + iCase.Id);
            return iCase.Id;   
        }catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'createAeCase - Exception: ' + ex.getMessage());
            AMOExceptionHandler.logException(ex, CLASS_NAME, 'createInteractionCase', null, 'Error');
           return null;
        }
   }

    public static Case setupStage2(Case cs, Map<Object,Object> stage2Details, String userChoice) {        
        System.debug('Entering setupStage2. User Choice: ' + userChoice + ', Stage 2 Details: ' + stage2Details);
        if (stage2Details.containsKey('Adverse_Event_MVN')) {
            cs.RecordTypeId = (Id)stage2Details.get('Adverse_Event_MVN');
            System.debug('Setting RecordTypeId for Adverse Event.');
        }
        if(userChoice == 'Merck Employee') {
            if((String)stage2Details.get('FieldBased') == 'yes'){
               cs.Referred_By_MVN__c = (String)stage2Details.get('EmployeeId');
            }
            cs.MSD_CORE_PSP_Program_Name__c = NOT_APPLICABLE;
            cs.MSD_CORE_PSP_Company__c = NOT_APPLICABLE;
            cs.MSD_CORE_PSP_Number__c = NOT_APPLICABLE;
            cs.MSD_CORE_PSP_Number_Other__c = NOT_APPLICABLE;
            cs.MSD_CORE_PSP_Program_Name_Other__c = NOT_APPLICABLE;
            cs.MSD_CORE_PSP_Company_Other__c = NOT_APPLICABLE;
            cs.MSD_CORE_PSP_Agent_Name__c = NOT_APPLICABLE;
        } else if (userChoice == 'PSP Representative') {
            cs.MSD_CORE_PSP_Program_Name__c = String.isBlank((String)stage2Details.get('PSPProgramName')) ? UNKNOWN_VALUE : (String)stage2Details.get('PSPProgramName');
            cs.MSD_CORE_PSP_Company__c = String.isBlank((String)stage2Details.get('PSPCompany')) ? UNKNOWN_VALUE : (String)stage2Details.get('PSPCompany');
            cs.MSD_CORE_PSP_Number__c = String.isBlank((String)stage2Details.get('PSPNumber')) ? UNKNOWN_VALUE : (String)stage2Details.get('PSPNumber');
            if ((String)stage2Details.get('PSPCompany') != 'Other') {
                cs.MSD_CORE_PSP_Company_Other__c = NOT_APPLICABLE;
            } else {
                cs.MSD_CORE_PSP_Company_Other__c = String.isBlank((String)stage2Details.get('PSPCompanyOther')) ? UNKNOWN_VALUE : (String)stage2Details.get('PSPCompanyOther');
            }
            if ((String)stage2Details.get('PSPNumber') != 'Other') {
                cs.MSD_CORE_PSP_Number_Other__c = NOT_APPLICABLE;
            }else { 
                cs.MSD_CORE_PSP_Number_Other__c = String.isBlank((String)stage2Details.get('PSPNumberOther')) ? UNKNOWN_VALUE : (String)stage2Details.get('PSPNumberOther');
            }
            if ((String)stage2Details.get('PSPProgramName') != 'Other') {
                cs.MSD_CORE_PSP_Program_Name_Other__c = NOT_APPLICABLE;
            } else {
                cs.MSD_CORE_PSP_Program_Name_Other__c = String.isBlank((String)stage2Details.get('PSPProgramNameOther')) ? UNKNOWN_VALUE : (String)stage2Details.get('PSPProgramNameOther');
            }
            cs.MSD_CORE_PSP_Agent_Name__c = String.isBlank((String)stage2Details.get('Agentname')) ? REFUSED : (String)stage2Details.get('Agentname');
        } else if (userChoice == 'Healthcare Professional'){
           cs.MSD_CORE_PSP_Program_Name__c = NOT_APPLICABLE;
            cs.MSD_CORE_PSP_Company__c = NOT_APPLICABLE;
            cs.MSD_CORE_PSP_Number__c = NOT_APPLICABLE;
            cs.MSD_CORE_PSP_Number_Other__c = NOT_APPLICABLE;
            cs.MSD_CORE_PSP_Program_Name_Other__c = NOT_APPLICABLE;
            cs.MSD_CORE_PSP_Company_Other__c = NOT_APPLICABLE;
            cs.MSD_CORE_PSP_Agent_Name__c = NOT_APPLICABLE; 
        }
        System.debug('Exiting setupStage2 with case: ' + cs);    
        return cs;
    }

    public static Case setupStage3(Case cs, Map<Object,Object> stage3Details, Map<Object,Object> stage2Details, String userChoice){
        
        if(userChoice.equals('Healthcare Professional')) {
        String licensedHCP = (String)stage2Details.get('licensedHCP'); // Assuming 'licensedHCP' key exists in stage2Details
        if(licensedHCP == null || licensedHCP.equals('Licensed Healthcare Professional')) {
            cs.Customer_Type_MVN__c = 'INDIV HEALTHCARE PROF';
        } else if(licensedHCP.equals('Healthcare Office Worker or Facility Personnel')) {
            cs.Customer_Type_MVN__c = 'HEALTHCARE BUSINESS PROF';
        }
    } else {
        // Existing logic for setting Customer_Type_MVN__c for other userChoices
        cs.Customer_Type_MVN__c = (userChoice.equals('Merck Employee')) ? 'EMPLOYEE' : (String)stage3Details.get('ReporterType');
    }
        //cs.Customer_Type_MVN__c = (userChoice == 'Merck Employee')? 'EMPLOYEE' : (String)stage3Details.get('ReporterType'); //for making the Knowledge article Search available
        if((String)stage3Details.get('ReporterType')=='Patient') {
            if((String)stage2Details.get('FieldBased') == 'yes'){
                cs.Patient_First_Name_MVN__c = String.isBlank((String)stage2Details.get('FirstName')) ? UNKNOWN_VALUE : (String)stage2Details.get('FirstName');
                cs.Patient_Last_Name_MVN__c = String.isBlank((String)stage2Details.get('LastName')) ? UNKNOWN_VALUE : (String)stage2Details.get('LastName');            }
            else{
                cs.Patient_First_Name_MVN__c = String.isBlank((String)stage3Details.get('RepFirstName')) ? UNKNOWN_VALUE : (String)stage3Details.get('RepFirstName');
                cs.Patient_Last_Name_MVN__c = String.isBlank((String)stage3Details.get('RepLastName')) ? UNKNOWN_VALUE : (String)stage3Details.get('RepLastName');
            }    
            cs.MSD_CORE_AE_Patient_Date_of_Birth__c = String.isBlank((String)stage3Details.get('RepDOB')) ? REFUSED : (String)stage3Details.get('RepDOB');
            cs.MSD_CORE_AE_Patient_Age__c = String.isBlank((String)stage3Details.get('RepAge')) ? REFUSED : (String)stage3Details.get('RepAge');
            cs.MSD_CORE_AE_Patient_Gender__c = String.isBlank((String)stage3Details.get('RepGender')) ? REFUSED : (String)stage3Details.get('RepGender');
            if(cs.MSD_CORE_AE_Patient_Gender__c == 'Female') {
               cs.MSD_CORE_AE_Is_Patient_Pregnant__c = String.isBlank((String)stage3Details.get('isRepPregnant')) ? UNKNOWN_VALUE : (String)stage3Details.get('isRepPregnant');
               if(cs.MSD_CORE_AE_Is_Patient_Pregnant__c == 'Yes') {
                  cs.MSD_CORE_AE_Pregnancy_Gestation_or_LMP__c = String.isBlank((String)stage3Details.get('RepGestationOrLMP')) ? UNKNOWN_VALUE : (String)stage3Details.get('RepGestationOrLMP');
               } else {
                  cs.MSD_CORE_AE_Pregnancy_Gestation_or_LMP__c = NOT_APPLICABLE;
               }
               } else {
                  cs.MSD_CORE_AE_Is_Patient_Pregnant__c = NOT_APPLICABLE;
                  cs.MSD_CORE_AE_Pregnancy_Gestation_or_LMP__c = NOT_APPLICABLE;
               }
               }else{
        cs.Patient_First_Name_MVN__c = String.isBlank((String)stage3Details.get('PatientFirstName')) ? UNKNOWN_VALUE : (String)stage3Details.get('PatientFirstName');
        cs.Patient_Last_Name_MVN__c = String.isBlank((String)stage3Details.get('PatientLastName')) ? UNKNOWN_VALUE : (String)stage3Details.get('PatientLastName');
        cs.MSD_CORE_AE_Patient_Date_of_Birth__c = String.isBlank((String)stage3Details.get('PatientDOB')) ? UNKNOWN_VALUE : (String)stage3Details.get('PatientDOB');
        cs.MSD_CORE_AE_Patient_Age__c = String.isBlank((String)stage3Details.get('PatientAge')) ? UNKNOWN_VALUE : (String)stage3Details.get('PatientAge');
        cs.MSD_CORE_AE_Patient_Gender__c = String.isBlank((String)stage3Details.get('PatientGender')) ? UNKNOWN_VALUE : (String)stage3Details.get('PatientGender');
        if(cs.MSD_CORE_AE_Patient_Gender__c == 'Female') {
           cs.MSD_CORE_AE_Is_Patient_Pregnant__c = String.isBlank((String)stage3Details.get('isPatientPregnant')) ? UNKNOWN_VALUE : (String)stage3Details.get('isPatientPregnant');
           if(cs.MSD_CORE_AE_Is_Patient_Pregnant__c == 'Yes') {
              cs.MSD_CORE_AE_Pregnancy_Gestation_or_LMP__c = String.isBlank((String)stage3Details.get('GestationOrLMP')) ? UNKNOWN_VALUE : (String)stage3Details.get('GestationOrLMP');
           } else {
             cs.MSD_CORE_AE_Pregnancy_Gestation_or_LMP__c = NOT_APPLICABLE;
           }
        }   else {
            cs.MSD_CORE_AE_Is_Patient_Pregnant__c = NOT_APPLICABLE;
            cs.MSD_CORE_AE_Pregnancy_Gestation_or_LMP__c = NOT_APPLICABLE;
        }
        }
        return cs;
    }

    /*public static FileData uploadAttachments(Id csId, List<Object> uploadedFilesObjList ){
        FileData fileData = new FileData();
            if(uploadedFilesObjList.size() < 1) {
                return null;
            }
            Map<Object, Object> fileDetails = (Map<Object, Object>) uploadedFilesObjList[0];
            fileData.fileBlob = EncodingUtil.base64Decode((String) fileDetails.get('base64'));
            fileData.fileName = (String) fileDetails.get('filename');

            ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S'; 
            conVer.PathOnClient = fileData.fileName;
            conVer.Title = fileData.fileName; 
            conVer.VersionData = fileData.fileBlob;
            insert(conVer);

            Id conDocument = [SELECT ContentDocumentId FROM ContentVersion where Id =: conVer.Id].ContentDocumentId;
            ContentDocumentLink docLink = new ContentDocumentLink();
            docLink.ContentDocumentId = conDocument; 
            docLink.LinkedEntityId = csId; 
            docLink.ShareType = 'I';
            insert docLink;

            return fileData;      
    }*/
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
        AMOExceptionHandler.logException(ex,CLASS_NAME,'uploadAttachments',null ,'Error');
        return null;
    }

    return fileData;
}




    public static List<SObject> createAeContacts(Id csId, Map<String,Object> caseDetails, String userChoice){
        
        
        System.debug('csId: ' + csId);
        System.debug('User Choice: ' + userChoice);
        Map<Object, Object> stage3Details = (Map<Object, Object>) caseDetails.get('stage3');
        Map<Object, Object> stage2Details = (Map<Object, Object>) caseDetails.get('stage2');
        List<SObject> contactList = new List<SObject>();
        MSD_CORE_AE_Contact__c con = new MSD_CORE_AE_Contact__c();
        if((String)stage3Details.get('ReporterHCPSame') != 'Yes' && !String.isBlank((String)stage3Details.get('ReporterType')) && (String)stage3Details.get('ReporterType') !='Patient'){
            System.debug('Creating reporter contact');
            con.MSD_CORE_Contact_Related_To__c = CONTACT_RELATED_TO;
            con.MSD_CORE_Adverse_Event__c = csId;
            con.MSD_CORE_First_Name__c = String.isBlank((String) stage3Details.get('RepFirstName')) ? REFUSED : (String) stage3Details.get('RepFirstName');
            con.MSD_CORE_Last_Name__c = String.isBlank((String) stage3Details.get('RepLastName')) ? REFUSED : (String) stage3Details.get('RepLastName');
            con.MSD_CORE_Phone__c = (String)stage3Details.get('RepPhone');
            con.MSD_Core_Email__c = (String)stage3Details.get('RepEmail');
            con.MSD_CORE_Address_Line_1__c = (String)stage3Details.get('RepAddress');
            con.MSD_CORE_Address_Line_2__c = (String)stage3Details.get('RepAddressLine2');
            con.MSD_CORE_City__c = (String)stage3Details.get('RepCity');
            con.MSD_CORE_State_Province__c = (String)stage3Details.get('RepState');
            con.MSD_CORE_Postal_Code__c = (String)stage3Details.get('RepZip');
            con.MSD_CORE_Country__c = (String)stage3Details.get('RepCountry');
            String reporterType = (String)stage3Details.get('ReporterType');
            if(REPORTER_TYPE_MAP.containsKey(reporterType)){
                con.MSD_CORE_Type__c = REPORTER_TYPE_MAP.get(reporterType);
            }else{
                con.MSD_CORE_Type__c = (String)stage3Details.get('RepType');
            }
            con.MSD_CORE_PracBusNm__c = (String)stage3Details.get('RepFacilityName');
            con.MSD_CORE_Primary_Contact__c = (userChoice == 'PSP Representative') ? true:false;
            
            contactList.add(con);
            System.debug('Reporter Contact: ' + con);
        }
        
        con = new MSD_CORE_AE_Contact__c();
        //Below code for storing the Patient HCP & in case of Reporter HCP Same only below code will excecute
        if(!String.isBlank((String)stage3Details.get('ReporterType'))){
            con.MSD_CORE_Contact_Related_To__c = CONTACT_RELATED_TO;
            con.MSD_CORE_Adverse_Event__c = csId;
            con.MSD_CORE_First_Name__c = String.isBlank((String)stage3Details.get('HCPFirstName')) ? REFUSED : (String)stage3Details.get('HCPFirstName');
            con.MSD_CORE_Last_Name__c = String.isBlank((String)stage3Details.get('HCPLastName')) ? REFUSED : (String) stage3Details.get('HCPLastName');
            con.MSD_CORE_Phone__c = (String)stage3Details.get('HCPPhone');
            con.MSD_Core_Email__c = (String)stage3Details.get('HCPEmail');
            con.MSD_CORE_Address_Line_1__c = (String)stage3Details.get('HCPAddress');
            con.MSD_CORE_Address_Line_2__c = (String)stage3Details.get('HCPAddressLine2');
            con.MSD_CORE_City__c = (String)stage3Details.get('HCPCity');
            con.MSD_CORE_Postal_Code__c = (String)stage3Details.get('HCPZip');
            con.MSD_CORE_State_Province__c = (String)stage3Details.get('HCPState');
            con.MSD_CORE_Country__c = (String)stage3Details.get('HCPCountry');
            if(userChoice == 'HealthCare Professional'){
               con.MSD_CORE_Permission_to_Contact__c = String.isBlank((String)stage3Details.get('permissionContact'))? UNSPECIFIED : (String)stage3Details.get('permissionContact'); 
            }else{
               con.MSD_CORE_Permission_to_Contact__c = String.isBlank((String)stage3Details.get('HCPPermission'))? UNSPECIFIED : (String)stage3Details.get('HCPPermission');
            }
            con.MSD_CORE_Type__c = (String)stage3Details.get('HCPType');
            con.MSD_CORE_Credentials__c = (String)stage3Details.get('HCPCredential');
            con.MSD_CORE_PracBusNm__c = (String)stage3Details.get('HCPFacilityName');
            con.MSD_CORE_Correspondence_Contact__c = true; //Patient HCP should have Correspondence Contact checked
            if((String)stage3Details.get('ReporterHCPSame') == 'Yes' && userChoice == 'PSP Representative'){
                con.MSD_CORE_Primary_Contact__c = true; //If Reporter and Patient HCP same, mark primary also true
            }
             
            contactList.add(con);
            System.debug('HCP Contact: ' + con);
        }
        con = new MSD_CORE_AE_Contact__c();
        if((String)stage2Details.get('FieldBased') == 'yes'){
            System.debug('User Entered Merck Field Based Employee Loop');
            con.MSD_CORE_Contact_Related_To__c = CONTACT_RELATED_TO;
            con.MSD_CORE_Adverse_Event__c = csId;
            con.MSD_CORE_Employee_ID_WIN__c = (String)stage2Details.get('WinId');
            con.MSD_CORE_First_Name__c = (String)stage2Details.get('FirstName');
            con.MSD_CORE_Last_Name__c = (String)stage2Details.get('LastName');
            con.MSD_CORE_Phone__c = (String)stage2Details.get('Phone');
            con.MSD_Core_Email__c = (String)stage2Details.get('Email');
            con.MSD_CORE_Primary_Contact__c = true;
            con.MSD_CORE_Type__c = 'Employee';
            if((String)stage3Details.get('ReporterType')=='Patient') {
                con.MSD_CORE_Address_Line_1__c = (String)stage3Details.get('RepAddress');
                con.MSD_CORE_Address_Line_2__c = (String)stage3Details.get('RepAddressLine2');
                con.MSD_CORE_City__c = (String)stage3Details.get('RepCity');
                con.MSD_CORE_State_Province__c = (String)stage3Details.get('RepState');
                con.MSD_CORE_Postal_Code__c = (String)stage3Details.get('RepZip');
            }
            con.MSD_CORE_Country__c = 'US';
            contactList.add(con);
        }
        con = new MSD_CORE_AE_Contact__c();
        if(userChoice == 'HealthCare Professional'){
            System.debug('Entered Stage 2 HCP Contact Saving');
            con.MSD_CORE_Contact_Related_To__c = CONTACT_RELATED_TO;
            con.MSD_CORE_Primary_Contact__c = (userChoice == 'HealthCare Professional') ? true:false;
            con.MSD_CORE_Adverse_Event__c = csId;
            con.MSD_CORE_First_Name__c = String.isBlank((String) stage2Details.get('hcpFirstName')) ? REFUSED : (String) stage2Details.get('hcpFirstName');
            con.MSD_CORE_Last_Name__c = String.isBlank((String) stage2Details.get('hcpLastName')) ? REFUSED : (String) stage2Details.get('hcpLastName');
            con.MSD_CORE_Phone__c = (String)stage2Details.get('hcpPhone');
            con.MSD_Core_Email__c = (String)stage2Details.get('hcpEmail');
            con.MSD_CORE_Address_Line_1__c = (String)stage2Details.get('hcpAddress');
            con.MSD_CORE_Address_Line_2__c = (String)stage2Details.get('hcpAddressLine2');
            con.MSD_CORE_City__c = (String)stage2Details.get('hcpCity');
            con.MSD_CORE_State_Province__c = (String)stage2Details.get('hcpState');
            con.MSD_CORE_Postal_Code__c = (String)stage2Details.get('hcpZip');
            con.MSD_CORE_Country__c = (String)stage2Details.get('hcpCountry');
            // con.MSD_CORE_Permission_to_Contact__c = String.isBlank((String)stage3Details.get('permissionContact'))? UNSPECIFIED : (String)stage3Details.get('permissionContact');
            if((String)stage2Details.get('licensedHCP') == LicensedHCP){
                //con.MSD_CORE_Contact_Related_To__c = CONTACT_RELATED_TO;
                con.MSD_CORE_Primary_Contact__c = true;
                con.MSD_CORE_Type__c = (String)stage2Details.get('HCPType');
                con.MSD_CORE_Credentials__c = (String)stage2Details.get('hcpCredential');
            } else if((String)stage2Details.get('licensedHCP') == LicensedHBP){
                con.MSD_CORE_Type__c = (String)stage2Details.get('HBPType');
            }
            if((String)stage3Details.get('PatientsHC') == 'Yes'){
                con.MSD_CORE_Correspondence_Contact__c = true;
                con.MSD_CORE_Permission_to_Contact__c = String.isBlank((String)stage3Details.get('permissionContact'))? UNSPECIFIED : (String)stage3Details.get('permissionContact');
            }
            con.MSD_CORE_PracBusNm__c = (String)stage2Details.get('hcpFacilityName');
            contactList.add(con);
            
        } 
        con = new MSD_CORE_AE_Contact__c();
        if((String)stage3Details.get('PatientsHC') == 'No'|| (String)stage2Details.get('licensedHCP') == LicensedHBP){
            con.MSD_CORE_Contact_Related_To__c = CONTACT_RELATED_TO;
            con.MSD_CORE_Adverse_Event__c = csId;
            con.MSD_CORE_First_Name__c = String.isBlank((String) stage3Details.get('HCPFirstName')) ? REFUSED : (String) stage3Details.get('HCPFirstName');
            con.MSD_CORE_Last_Name__c = String.isBlank((String) stage3Details.get('HCPLastName')) ? REFUSED : (String) stage3Details.get('HCPLastName');
            con.MSD_CORE_Phone__c = (String)stage3Details.get('HCPPhone');
            con.MSD_Core_Email__c = (String)stage3Details.get('HCPEmail');
            con.MSD_CORE_Address_Line_1__c = (String)stage3Details.get('HCPAddress');
            con.MSD_CORE_Address_Line_2__c = (String)stage3Details.get('HCPAddressLine2');
            con.MSD_CORE_City__c = (String)stage3Details.get('HCPCity');
            con.MSD_CORE_State_Province__c = (String)stage3Details.get('HCPState');
            con.MSD_CORE_Postal_Code__c = (String)stage3Details.get('HCPZip');
            //con.MSD_CORE_Country__c = 'US';
            con.MSD_CORE_Permission_to_Contact__c = String.isBlank((String)stage3Details.get('permissionContact'))? UNSPECIFIED : (String)stage3Details.get('permissionContact');
            con.MSD_CORE_Country__c = (String)stage3Details.get('HCPCountry');
            con.MSD_CORE_Correspondence_Contact__c = true;
            con.MSD_CORE_Type__c = (String)stage3Details.get('HCPType');
            con.MSD_CORE_Credentials__c = (String)stage3Details.get('HCPCredential');
            con.MSD_CORE_PracBusNm__c = (String)stage3Details.get('HCPFacilityName');
            contactList.add(con);
        }
        
        if((String)stage2Details.get('FieldBased') == 'no' &&  userChoice == 'Merck Employee'){
            System.debug('It entered this Loop for Non Field Based Employee');
            con.MSD_CORE_Contact_Related_To__c = CONTACT_RELATED_TO;
            con.MSD_CORE_Employee_ID_WIN__c = (String)stage2Details.get('NEmployeeId');
            con.MSD_CORE_Adverse_Event__c = csId;
            con.MSD_CORE_First_Name__c = (String)stage2Details.get('NFirstName');
            con.MSD_CORE_Last_Name__c = (String)stage2Details.get('NName');
            con.MSD_CORE_Phone__c = (String)stage2Details.get('NempPhone');
            con.MSD_Core_Email__c = (String)stage2Details.get('NempEmail');
            con.MSD_CORE_Country__c = (String)stage2Details.get('NempCountry');
            con.MSD_CORE_Primary_Contact__c = true;
            con.MSD_CORE_Type__c = 'Employee';
            if((String)stage3Details.get('ReporterType')=='Patient') {
                con.MSD_CORE_Address_Line_1__c = (String)stage3Details.get('RepAddress');
                con.MSD_CORE_Address_Line_2__c = (String)stage3Details.get('RepAddressLine2');
                con.MSD_CORE_City__c = (String)stage3Details.get('RepCity');
                con.MSD_CORE_State_Province__c = (String)stage3Details.get('RepState');
                con.MSD_CORE_Postal_Code__c = (String)stage3Details.get('RepZip');
            }
            contactList.add(con);
        }
        return contactList;
    }

    public static List<SObject> createAeProducts(Id csId, List<Object> stage4Details){

        List<SObject> prodList = new List<SObject>();
        Boolean isFirstProduct = true;
        for(Object sobj : stage4Details){
            MSD_CORE_AE_Product__c prod = new MSD_CORE_AE_Product__c();
            System.debug('Linked product to Adverse Event with ID: ' + csId);
            prod.MSD_CORE_Adverse_Event__c = csId; // pass case id to link AE Product
            prod.MSD_CORE_Related_to__c	= CONTACT_RELATED_TO;
            Map<Object,Object> detailMap = (Map<Object,Object>) sobj;
            Map<Object,Object> valuesMap = (Map<Object,Object>) detailMap.get('values');
            if((String)valuesMap.get('ProductId') == 'OtherProductField'){
                prod.MSD_CORE_Other_Company_Product__c = (String)valuesMap.get('Product');
            }else{
                prod.MSD_CORE_Product_Lookup__c = (String)valuesMap.get('ProductId');
            }
            prod.MSD_CORE_Catalog_Number__c = String.isBlank((String)valuesMap.get('CatalogNumber')) ? UNKNOWN_VALUE  : (String)valuesMap.get('CatalogNumber');
            prod.MSD_CORE_Dose_Frequency__c = String.isBlank((String)valuesMap.get('DoseFrequency')) ? UNKNOWN_VALUE : (String)valuesMap.get('DoseFrequency') ;
            prod.MSD_CORE_Expiration_Date__c =  String.isBlank((String)valuesMap.get('formattedDate')) ? UNKNOWN_VALUE : (String)valuesMap.get('formattedDate');
            prod.MSD_CORE_Lot_Number__c = String.isBlank((String)valuesMap.get('LotNumber')) ? UNKNOWN_VALUE : (String)valuesMap.get('LotNumber');
            prod.MSD_CORE_Serial_Number__c = String.isBlank((String)valuesMap.get('SerialNumber')) ? UNKNOWN_VALUE : (String)valuesMap.get('SerialNumber');
            prod.MSD_CORE_Model_Number__c = String.isBlank((String)valuesMap.get('ModelNumber')) ? UNKNOWN_VALUE : (String)valuesMap.get('ModelNumber');
            prod.MSD_CORE_Unique_Identifier__c =String.isBlank((String)valuesMap.get('UniqueIdentifier')) ? UNKNOWN_VALUE : (String)valuesMap.get('UniqueIdentifier');
            prod.MSD_Core_Product_Operator_of_Device__c = String.isBlank((String)valuesMap.get('OperatorOfDevice')) ? 'Unknown' : (String)valuesMap.get('OperatorOfDevice');
            prod.MSD_CORE_Product_Circular__c = NOT_APPLICABLE;
            prod.MSD_CORE_Primary_Product__c = isFirstProduct;
            isFirstProduct = false;
            prodList.add(prod);
             System.debug('Product added to list.');
        }
        System.debug('Completed product creation. Total products created: ' + prodList.size());    
        return prodList;
    } 
    public static Case setupStage5(Case cs, Map<Object,Object> stage5Details, String previousCase, String patientID, String userChoice){        

        String finalDescription = ' Received from the AE Self-Service Portal: Report submitted by ' + userChoice + '\n' ;

    // Append patient ID to finalDescription if it is not blank
    if(String.isNotBlank(patientID)) {
        finalDescription += 'Patient ID: ' + patientID + ' ';
    }

    // Append previous case number to finalDescription if it is not blank
    if(String.isNotBlank(previousCase)) {
        finalDescription += ' Additional AE Information – Previous Case# ' + previousCase + '';
    }

    // Retrieve and append the AE description
    finalDescription += '\n' + (String)stage5Details.get('AE') + '\n';
        cs.MSD_CORE_AE_Description__c = finalDescription;
        cs.AE_Start_Date_MVN__c  = String.isBlank((String)stage5Details.get('AOD')) ? UNKNOWN_VALUE : (String)stage5Details.get('AOD');
        String mpiValue = (String)stage5Details.get('MPI');
        cs.MSD_Core_Multiple_Patients_Involved__c  = mpiValue.equalsIgnoreCase('Yes');
        if(userChoice == 'Healthcare Professional'){
            cs.MSD_CORE_AE_PQC_Company_Awareness_Date__c = Date.today();
        } else {
                 String companyAwarenessDate = (String)stage5Details.get('CAD');
                 cs.MSD_CORE_AE_PQC_Company_Awareness_Date__c = Date.valueOf(companyAwarenessDate);
        }
        return cs;
    }
     
    
    public static Case setupStage6(Case cs, Map<Object,Object> stage6Details){  

        String defaultValue = cs.MSD_Core_Multiple_Patients_Involved__c ? NOT_APPLICABLE : UNKNOWN_VALUE;
        cs.MSD_CORE_AE_Did_the_Patient_Die__c = String.isBlank((String)stage6Details.get('patientdeath')) ? defaultValue : (String)stage6Details.get('patientdeath');
        if(cs.MSD_CORE_AE_Did_the_Patient_Die__c == 'Yes'){
            cs.MSD_CORE_AE_Cause_of_Death__c = String.isBlank((String)stage6Details.get('causedeath')) ? UNKNOWN_VALUE : (String)stage6Details.get('causedeath');
            cs.MSD_CORE_AE_Date_of_Death__c = String.isBlank((String)stage6Details.get('deathdate')) ? UNKNOWN_VALUE : (String)stage6Details.get('deathdate');
        }
        else {
            cs.MSD_CORE_AE_Cause_of_Death__c = NOT_APPLICABLE;
            cs.MSD_CORE_AE_Date_of_Death__c = NOT_APPLICABLE;
        }
        cs.MSD_CORE_AE_Hospitalization_or_Prolonged__c = String.isBlank((String)stage6Details.get('AEhospitilization')) ? defaultValue : (String)stage6Details.get('AEhospitilization');
        cs.MSD_CORE_AE_Life_Threatening__c  = String.isBlank((String)stage6Details.get('illness')) ? defaultValue : (String)stage6Details.get('illness');
        cs.MSD_CORE_AE_Sig_Disability_or_Incapacity__c = String.isBlank((String)stage6Details.get('disability')) ? defaultValue : (String)stage6Details.get('disability');
        cs.MSD_CORE_AE_Is_Was_AE_Congenital_Anomaly__c = String.isBlank((String)stage6Details.get('birthdefect')) ? defaultValue : (String)stage6Details.get('birthdefect');
        cs.MSD_CORE_AE_Is_Was_the_AE_Cancer__c = String.isBlank((String)stage6Details.get('cancer'))? defaultValue : (String)stage6Details.get('cancer');
        cs.MSD_CORE_AE_Patient_Overdose__c = String.isBlank((String)stage6Details.get('overdose'))? defaultValue : (String)stage6Details.get('overdose');
        cs.MSD_CORE_AE_Intervention_Prevent_Serious__c = String.isBlank((String)stage6Details.get('intervention'))? defaultValue : (String)stage6Details.get('intervention');    
        cs.MSD_CORE_AE_Indication__c = String.isBlank((String)stage6Details.get('indication'))? defaultValue : (String)stage6Details.get('indication');
        cs.MSD_CORE_AE_Route_of_Administration__c = String.isBlank((String)stage6Details.get('roa'))? defaultValue : (String)stage6Details.get('roa');
        cs.MSD_CORE_AE_Therapy_Start_Date__c = String.isBlank((String)stage6Details.get('TherapySD'))? defaultValue : (String)stage6Details.get('TherapySD');
        cs.MSD_CORE_AE_Was_Therapy_Discontinued__c = String.isBlank((String)stage6Details.get('therapyque'))? defaultValue : (String)stage6Details.get('therapyque');
        if(cs.MSD_CORE_AE_Was_Therapy_Discontinued__c == 'Yes'){
            cs.MSD_CORE_AE_Therapy_End_Date__c = String.isBlank((String)stage6Details.get('TherapyED')) ? UNKNOWN_VALUE : (String)stage6Details.get('TherapyED');
            cs.MSD_CORE_AE_Dechallenge__c = String.isBlank((String)stage6Details.get('dechallenge')) ? UNKNOWN_VALUE : (String)stage6Details.get('dechallenge');
            cs.MSD_CORE_AE_Rechallenge__c = String.isBlank((String)stage6Details.get('rechallenge')) ? UNKNOWN_VALUE : (String)stage6Details.get('rechallenge');
        }
        else {
            cs.MSD_CORE_AE_Therapy_End_Date__c = NOT_APPLICABLE;
            cs.MSD_CORE_AE_Dechallenge__c = NOT_APPLICABLE;
            cs.MSD_CORE_AE_Rechallenge__c = NOT_APPLICABLE;
        }

        cs.MSD_CORE_AE_Sought_Medical_Attention__c = String.isBlank((String)stage6Details.get('sma'))? defaultValue : (String)stage6Details.get('sma');
        cs.MSD_CORE_AE_Was_Treatment_Given_for_AE__c = String.isBlank((String)stage6Details.get('Treatmentque'))? defaultValue : (String)stage6Details.get('Treatmentque');
        if(cs.MSD_CORE_AE_Was_Treatment_Given_for_AE__c == 'Yes'){
            cs.MSD_CORE_AE_Treatment_Provided__c = String.isBlank((String)stage6Details.get('isTreatment')) ? UNKNOWN_VALUE : (String)stage6Details.get('isTreatment');
        } else {
            cs.MSD_CORE_AE_Treatment_Provided__c = NOT_APPLICABLE;
        }
        cs.MSD_CORE_AE_Present_Status__c = String.isBlank((String)stage6Details.get('presentstatus'))? defaultValue : (String)stage6Details.get('presentstatus');
        if(cs.MSD_CORE_AE_Present_Status__c == 'Recovered'){
            cs.MSD_CORE_AE_Recovery_Date__c = String.isBlank((String)stage6Details.get('RecoveryDate')) ? UNKNOWN_VALUE : (String)stage6Details.get('RecoveryDate');
        } else {
            cs.MSD_CORE_AE_Recovery_Date__c = NOT_APPLICABLE;
        }
        cs.MSD_CORE_AE_Concomitant_Medication__c = String.isBlank((String)stage6Details.get('CM'))? defaultValue : (String)stage6Details.get('CM');
        cs.MSD_CORE_AE_Pertinent_Medical_History__c = String.isBlank((String)stage6Details.get('PMH'))? defaultValue : (String)stage6Details.get('PMH');
        cs.MSD_CORE_AE_Drug_Reactions_Allergies__c = String.isBlank((String)stage6Details.get('DRA'))? defaultValue : (String)stage6Details.get('DRA');
        cs.MSD_CORE_AE_Lab_Diagnostics_Studies__c = String.isBlank((String)stage6Details.get('LD'))? defaultValue : (String)stage6Details.get('LD');
       
        return cs;
    }

    @AuraEnabled(cacheable=true)
    public static String getRecordTypeId(String devName, String sObjectType) {
        List<RecordType> recordTypes = [SELECT Id FROM RecordType WHERE DeveloperName =: devName AND SobjectType =: sObjectType LIMIT 1];
        if(recordTypes.size()>0){
            return recordTypes[0].Id;
        }
        System.debug(LoggingLevel.INFO, 'Record Type ID: ' + recordTypes[0].Id);
        return null;
    }

    public static Id getSourceId(String sourceName) {
        List<MSD_CORE_Source__c> sources = [SELECT Id FROM MSD_CORE_Source__c WHERE Name =: sourceName LIMIT 1];
        if(sources.size()>0) {
            return sources[0].Id;
        }
        System.debug(LoggingLevel.INFO, 'getSourceId - Source ID: ' + sources[0].Id);
        return null;
    }

    public static void sendEmail(String errorMessage) {
        try {
            OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'AE Self-Service Portal' LIMIT 1];
            MSD_CORE_ae_PortalSetting__mdt setting = [SELECT Support_Email__c FROM MSD_CORE_ae_PortalSetting__mdt LIMIT 1];

            if (owea == null || setting == null || String.isEmpty(setting.Support_Email__c)) {
                system.debug('Org Wide Address or Portal Setting Missing');
                return;
            }
            List<String> emailAddresses = setting.Support_Email__c.split(';');

            String emailBody = 'Hello,\n\nThere was a failure in creating a case through the Adverse Event Self-Service Portal.\n\nError Details: '
                            + errorMessage + '\nPlease review the issue to prevent future occurrences.\n\nRegards,\nAdverse Event Self-Service Portal Team';

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(emailAddresses);
            mail.setSubject('Adverse Event Portal: Case Creation Failure Notification');
            mail.setPlainTextBody(emailBody);
            mail.setOrgWideEmailAddressId(owea.Id);
            mail.setSaveAsActivity(false);
            //Future POC
           /* if (fileData != null && fileData.fileBlob != null && String.isNotBlank(fileData.fileName)) {
                System.debug('FileData prepared with Blob and filename: ' + fileData.fileName);
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setBody(fileData.fileBlob);
                attachment.setFileName(fileData.fileName);
                attachment.setContentType(determineMimeType(fileData.fileName));
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
            }
            else {
                System.debug('No file to attach in the email');
            }*/

            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            if (results.size() > 0 && !results[0].isSuccess() && results[0].getErrors().size() > 0) {
                System.debug('Email sending error: ' + results[0].getErrors()[0].getMessage());
            }
        }catch (Exception ex) {
            AMOExceptionHandler.logException(ex, 'MSD_CORE_ae_CaseController', 'sendEmail', null, 'Error');
        }
    }
    public static void sendErrorEmail(String errorMessage) {
        try {
            OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'AE Self-Service Portal' LIMIT 1];
            MSD_CORE_ae_PortalSetting__mdt setting = [SELECT Support_Email__c FROM MSD_CORE_ae_PortalSetting__mdt LIMIT 1];

            if (owea == null || setting == null || String.isEmpty(setting.Support_Email__c)) {
                system.debug('Org Wide Address or Portal Setting Missing');
                return;
            }
            List<String> emailAddresses = setting.Support_Email__c.split(';');

            String emailBody = 'Hello,\n\nThere was a failure in Inserting Additional Case Contacts for Creating a Case through the Adverse Event Self-Service Portal.\n\nError Details: '
                            + errorMessage + '\nPlease review the issue to prevent future occurrences.\n\nRegards,\nAdverse Event Self-Service Portal Team';

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(emailAddresses);
            mail.setSubject('Adverse Event Portal: Additional Case Contacts Insertion Failure Notification');
            mail.setPlainTextBody(emailBody);
            mail.setOrgWideEmailAddressId(owea.Id);
            mail.setSaveAsActivity(false);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            if (results.size() > 0 && !results[0].isSuccess() && results[0].getErrors().size() > 0) {
                System.debug('Email sending error: ' + results[0].getErrors()[0].getMessage());
            }
        }catch (Exception ex) {
            AMOExceptionHandler.logException(ex, 'MSD_CORE_ae_CaseController', 'sendErrorEmail', null, 'Error');
        }
    }
}